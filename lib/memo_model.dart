import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Palet warna pastel untuk kartu memo (sesuai spesifikasi SPEC2.md)
const List<Color> pastelColors = [
  Color(0xFFEAE6FF), // 0: Lavender / Ungu Muda
  Color(0xFFFFE8D6), // 1: Peach / Oranye Muda
  Color(0xFFFCE4EC), // 2: Soft Pink / Merah Muda
  Color(0xFFE0F2F1), // 3: Mint Green / Hijau Muda
  Color(0xFFFFF9C4), // 4: Soft Yellow / Kuning Muda
  Color(0xFFE1F5FE), // 5: Sky Blue / Biru Muda
];

/// Model Data Memo
class Memo {
  final String id;
  final String title;
  final String content;
  final String folder;
  final String? imagePath;
  final bool hasVoice;
  final int colorIndex;
  final DateTime createdAt;

  Memo({
    required this.id,
    required this.title,
    required this.content,
    required this.folder,
    this.imagePath,
    this.hasVoice = false,
    this.colorIndex = 0,
    required this.createdAt,
  });

  /// Mengubah objek Memo menjadi Map JSON untuk disimpan ke SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folder': folder,
      'imagePath': imagePath,
      'hasVoice': hasVoice,
      'colorIndex': colorIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Membuat objek Memo dari Map JSON SharedPreferences
  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Tanpa Judul',
      content: json['content'] as String? ?? '',
      folder: json['folder'] as String? ?? 'Kuliah',
      imagePath: json['imagePath'] as String?,
      hasVoice: json['hasVoice'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Helper untuk menyalin dan memodifikasi memo
  Memo copyWith({
    String? id,
    String? title,
    String? content,
    String? folder,
    String? imagePath,
    bool? hasVoice,
    int? colorIndex,
    DateTime? createdAt,
  }) {
    return Memo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      folder: folder ?? this.folder,
      imagePath: imagePath ?? this.imagePath,
      hasVoice: hasVoice ?? this.hasVoice,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Helper Penyimpanan Lokal (Local Database menggunakan SharedPreferences & File System)
class MemoStorage {
  static const String _keyMemos = 'memos_data';
  static const String _keyFolders = 'folders_data';
  static const String _keyGeminiApiKey = 'gemini_api_key';

  /// Mengambil Gemini API Key yang tersimpan di SharedPreferences
  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
  }

  /// Menyimpan Gemini API Key ke SharedPreferences
  static Future<void> saveGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, key.trim());
  }

  /// Memuat daftar memo dari SharedPreferences
  /// Jika belum ada data, muat data dummy awal sesuai spesifikasi prototype
  static Future<List<Memo>> loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? memosJson = prefs.getString(_keyMemos);

    if (memosJson == null || memosJson.isEmpty) {
      // Data awal belum ada, gunakan data dummy dan simpan otomatis
      final initialData = await _createInitialDummyMemos();
      await saveMemos(initialData);
      return initialData;
    }

    try {
      final List<dynamic> decoded = jsonDecode(memosJson) as List<dynamic>;
      return decoded
          .map((item) => Memo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error parsing memos data: $e');
      return [];
    }
  }

  /// Menyimpan daftar memo ke SharedPreferences dalam format JSON String
  static Future<void> saveMemos(List<Memo> memos) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mapList =
        memos.map((memo) => memo.toJson()).toList();
    await prefs.setString(_keyMemos, jsonEncode(mapList));
  }

  /// Memuat daftar folder/kategori
  static Future<List<String>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? folders = prefs.getStringList(_keyFolders);

    if (folders == null || folders.isEmpty) {
      const defaultFolders = ['Kuliah', 'Pribadi'];
      await prefs.setStringList(_keyFolders, defaultFolders);
      return defaultFolders;
    }
    return folders;
  }

  /// Menyimpan daftar folder baru ke SharedPreferences
  static Future<void> saveFolders(List<String> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFolders, folders);
  }

  /// Menyalin file gambar dari direktori cache sementara ke direktori dokumen permanen aplikasi
  /// Ini mencegah gambar hilang saat cache aplikasi dibersihkan oleh OS
  static Future<String> copyImageToPermanentDir(String tempPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extension = p.extension(tempPath);
    final fileName = 'memo_img_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destinationPath = p.join(appDir.path, fileName);

    final savedFile = await File(tempPath).copy(destinationPath);
    return savedFile.path;
  }

  /// Menghapus file gambar lokal secara permanen dari perangkat
  static Future<void> deleteImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Gagal menghapus file gambar lokal: $e');
    }
  }

  /// Membuat 1 file sample gambar sederhana untuk data dummy awal jika belum ada
  static Future<String?> _createSampleImageFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final sampleFile = File(p.join(appDir.path, 'sample_dummy_document.png'));
      if (!await sampleFile.exists()) {
        // 1x1 transparent PNG data bytes sebagai placeholder aman
        final Uint8List pngBytes = Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
          0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
          0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
          0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
          0x42, 0x60, 0x82
        ]);
        await sampleFile.writeAsBytes(pngBytes);
      }
      return sampleFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Menghasilkan memo awal contoh (Dummy Seed Data) sesuai kebutuhan demo & presentasi
  static Future<List<Memo>> _createInitialDummyMemos() async {
    final sampleImagePath = await _createSampleImageFile();
    final sampleDate = DateTime(2026, 11, 15);

    return [
      Memo(
        id: '1',
        title: 'Tugas PPW',
        content:
            'Submit laporan lab dan persiapan modul praktikum kuis PPW hari Jumat.',
        folder: 'Pribadi', // Sengaja diatur 'Pribadi' agar fitur AI Organize memindahkannya ke 'Kuliah'
        imagePath: sampleImagePath,
        hasVoice: false,
        colorIndex: 0, // Lavender
        createdAt: sampleDate,
      ),
      Memo(
        id: '2',
        title: 'Tanpa Judul', // Catatan tanpa judul agar AI otomatis membuatkan judul dari isi
        content:
            'Beli susu, telur, sayur segar, dan kebutuhan pokok di supermarket.',
        folder: 'Kuliah', // Sengaja diatur 'Kuliah' agar fitur AI Organize memindahkannya ke 'Pribadi'
        imagePath: sampleImagePath,
        hasVoice: false,
        colorIndex: 1, // Peach
        createdAt: sampleDate,
      ),
      Memo(
        id: '3',
        title: 'Rekapitulasi Kas',
        content:
            'Catat pengeluaran uang kas bendahara sebelum jam 5 sore dan simpan bukti kuitansi.',
        folder: 'Kuliah', // Sengaja diatur 'Kuliah' agar fitur AI Organize memindahkannya ke 'Keuangan'
        imagePath: null,
        hasVoice: true,
        colorIndex: 3, // Mint Green
        createdAt: sampleDate,
      ),
      Memo(
        id: '4',
        title: 'Tanpa Judul', // Catatan tanpa judul kedua untuk demonstrasi smart titling
        content:
            'Selesaikan coding arsitektur AI mobile memo, speech-to-text, dan database offline.',
        folder: 'Pribadi', // Sengaja diatur 'Pribadi' agar fitur AI Organize memindahkannya ke 'Ide & Proyek'
        imagePath: sampleImagePath,
        hasVoice: true,
        colorIndex: 2, // Soft Pink
        createdAt: sampleDate,
      ),
      Memo(
        id: '5',
        title: 'Jadwal Kuis Pemrograman',
        content:
            'Pelajari materi widget testing dan state management untuk kuis minggu depan.',
        folder: 'Kuliah',
        imagePath: sampleImagePath,
        hasVoice: true,
        colorIndex: 4, // Soft Yellow
        createdAt: sampleDate,
      ),
    ];
  }

  /// Reset data memo dan folder ke template demo agar fitur AI (organize folder & To-Do) langsung terlihat jelas efeknya
  static Future<void> resetToDemoSeedData() async {
    final demoMemos = await _createInitialDummyMemos();
    await saveMemos(demoMemos);
    await saveFolders(['Kuliah', 'Pribadi', 'Keuangan', 'Ide & Proyek']);
  }
}
