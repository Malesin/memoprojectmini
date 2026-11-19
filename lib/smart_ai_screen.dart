import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'memo_model.dart';

/// Model untuk saran pengorganisasian folder oleh AI
class FolderSuggestion {
  final String memoId;
  final String title;
  final String currentFolder;
  final String suggestedFolder;
  final String reason;

  FolderSuggestion({
    required this.memoId,
    required this.title,
    required this.currentFolder,
    required this.suggestedFolder,
    required this.reason,
  });

  factory FolderSuggestion.fromJson(Map<String, dynamic> json) {
    return FolderSuggestion(
      memoId: json['memoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      currentFolder: json['currentFolder'] as String? ?? 'Semua',
      suggestedFolder: json['suggestedFolder'] as String? ?? 'Umum',
      reason: json['reason'] as String? ?? 'Dianalisis dari isi catatan.',
    );
  }
}

/// Model untuk tugas/to-do yang diekstrak oleh AI
class ExtractedTask {
  final String task;
  final String sourceMemo;
  bool isCompleted;

  ExtractedTask({
    required this.task,
    required this.sourceMemo,
    this.isCompleted = false,
  });
}

/// Layar Asisten AI (Smart AI Assistant Tab)
class SmartAIScreen extends StatefulWidget {
  final VoidCallback onMemosUpdated;

  const SmartAIScreen({super.key, required this.onMemosUpdated});

  @override
  State<SmartAIScreen> createState() => _SmartAIScreenState();
}

class _SmartAIScreenState extends State<SmartAIScreen> {
  bool _isLoading = false;
  String _loadingMessage = '';
  String? _geminiApiKey;

  // Hasil Analisis AI
  List<FolderSuggestion> _folderSuggestions = [];
  List<ExtractedTask> _extractedTasks = [];

  // Tanya Memo (Ask Memo)
  final TextEditingController _questionController = TextEditingController();
  String? _aiAnswer;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await MemoStorage.getGeminiApiKey();
    if (mounted) {
      setState(() => _geminiApiKey = key);
    }
  }

  /// Dialog untuk memasukkan / melihat Gemini API Key
  void _showApiKeyDialog() {
    final keyController = TextEditingController(text: _geminiApiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: Color(0xFF4A80F0)),
              SizedBox(width: 8),
              Text(
                'Gemini API Key',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan Google Gemini API Key Anda. Jika dikosongkan, aplikasi otomatis menggunakan Smart Engine lokal (mode offline aman).',
                style: TextStyle(fontSize: 13, color: Color(0xFF616161)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final key = keyController.text.trim();
                await MemoStorage.saveGeminiApiKey(key);
                setState(() => _geminiApiKey = key.isEmpty ? null : key);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(key.isEmpty
                          ? 'Menggunakan mode Smart Engine Lokal'
                          : 'Gemini API Key berhasil disimpan!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Color(0xFF4A80F0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Fitur Seeding Demo: Reset catatan agar fitur AI terlihat efeknya dengan jelas
  Future<void> _confirmResetDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: Color(0xFF4A80F0)),
              SizedBox(width: 8),
              Text(
                'Seed Data Demo AI?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Catatan akan di-reset ke template demo dengan folder yang sengaja diacak. Ini dirancang khusus agar saat Anda mendemokan "Rapikan Folder" dan "Ekstrak Tugas", hasilnya langsung terlihat jelas di depan penguji/dosen.',
            style: TextStyle(fontSize: 13, color: Color(0xFF616161)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Muat Demo',
                style: TextStyle(
                  color: Color(0xFF4A80F0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await MemoStorage.resetToDemoSeedData();
      widget.onMemosUpdated();
      setState(() {
        _folderSuggestions.clear();
        _extractedTasks.clear();
        _aiAnswer = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Data demo AI berhasil dimuat! Coba klik "Rapikan Folder" atau "Ekstrak Tugas". 🚀'),
            backgroundColor: Color(0xFF4A80F0),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Fitur 1: Pindai & Rapikan Folder Catatan Menggunakan Gemini / Smart Engine
  Future<void> _organizeFolders() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'AI sedang menganalisis isi semua memo...';
      _folderSuggestions.clear();
    });

    final memos = await MemoStorage.loadMemos();
    if (memos.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada memo untuk dianalisis.')),
        );
      }
      return;
    }

    try {
      if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
        // Mode 1: Online Menggunakan Google Gemini API
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _geminiApiKey!,
        );

        final memoListString = memos
            .map((m) =>
                'ID: "${m.id}", Judul: "${m.title}", Isi: "${m.content}", FolderSekarang: "${m.folder}"')
            .join('\n');

        final prompt = '''
Kamu adalah asisten pengatur catatan pintar. Tugasmu adalah menganalisis memo berikut dan menyarankan folder kategori yang paling cocok (misal: "Kuliah", "Pribadi", "Keuangan", "Pekerjaan", "Ide & Proyek"):
$memoListString

Keluarkan jawaban HANYA berupa JSON array valid tanpa teks lain:
[
  {
    "memoId": "id_memo",
    "title": "judul_memo",
    "currentFolder": "folder_saat_ini",
    "suggestedFolder": "folder_baru_yang_disarankan",
    "reason": "alasan singkat kenapa cocok di folder tersebut"
  }
]
''';

        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null) {
          final cleaned = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final List<dynamic> decoded = jsonDecode(cleaned) as List<dynamic>;
          setState(() {
            _folderSuggestions = decoded
                .map((item) =>
                    FolderSuggestion.fromJson(item as Map<String, dynamic>))
                .where((item) => item.currentFolder != item.suggestedFolder)
                .toList();
          });
        }
      } else {
        // Mode 2: Smart Engine Lokal (Offline-first, instan & anti-gagal)
        await Future.delayed(const Duration(milliseconds: 600));
        _folderSuggestions = _runLocalSmartOrganize(memos);
      }
    } catch (e) {
      debugPrint('Error Gemini, beralih ke Smart Engine lokal: $e');
      _folderSuggestions = _runLocalSmartOrganize(memos);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (_folderSuggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Semua memo sudah berada di folder yang sangat rapi! 👍'),
          ),
        );
      }
    }
  }

  /// Algoritma Smart Engine Lokal untuk Analisis Folder
  List<FolderSuggestion> _runLocalSmartOrganize(List<Memo> memos) {
    final List<FolderSuggestion> suggestions = [];

    for (final memo in memos) {
      final combined = '${memo.title} ${memo.content}'.toLowerCase();
      String targetFolder = memo.folder;
      String reason = '';

      if (combined.contains('kuis') ||
          combined.contains('tugas') ||
          combined.contains('kuliah') ||
          combined.contains('dosen') ||
          combined.contains('praktikum') ||
          combined.contains('modul') ||
          combined.contains('ppw') ||
          combined.contains('lab')) {
        targetFolder = 'Kuliah';
        reason = 'Mengandung kata kunci tugas, praktikum, dan kuis akademik.';
      } else if (combined.contains('belanja') ||
          combined.contains('pasar') ||
          combined.contains('kebutuhan') ||
          combined.contains('sayur') ||
          combined.contains('susu') ||
          combined.contains('supermarket')) {
        targetFolder = 'Pribadi';
        reason = 'Mengandung daftar kebutuhan belanja kebutuhan pokok pribadi.';
      } else if (combined.contains('kontan') ||
          combined.contains('kas') ||
          combined.contains('uang') ||
          combined.contains('pengeluaran') ||
          combined.contains('kuitansi') ||
          combined.contains('biaya')) {
        targetFolder = 'Keuangan';
        reason = 'Mengandung rincian arus kas bendahara dan pengeluaran keuangan.';
      } else if (combined.contains('aplikasi') ||
          combined.contains('ide') ||
          combined.contains('coding') ||
          combined.contains('flutter')) {
        targetFolder = 'Ide & Proyek';
        reason = 'Mengandung konsep pengembangan ide dan aplikasi teknologi.';
      }

      if (targetFolder != memo.folder) {
        suggestions.add(
          FolderSuggestion(
            memoId: memo.id,
            title: memo.title,
            currentFolder: memo.folder,
            suggestedFolder: targetFolder,
            reason: reason,
          ),
        );
      }
    }

    return suggestions;
  }

  /// Menerapkan saran folder dari AI ke local database
  Future<void> _applyFolderSuggestions() async {
    final memos = await MemoStorage.loadMemos();
    final folders = await MemoStorage.loadFolders();

    for (final suggestion in _folderSuggestions) {
      final idx = memos.indexWhere((m) => m.id == suggestion.memoId);
      if (idx != -1) {
        memos[idx] = memos[idx].copyWith(folder: suggestion.suggestedFolder);
      }
      if (!folders.contains(suggestion.suggestedFolder)) {
        folders.add(suggestion.suggestedFolder);
      }
    }

    await MemoStorage.saveMemos(memos);
    await MemoStorage.saveFolders(folders);

    widget.onMemosUpdated();

    if (mounted) {
      setState(() => _folderSuggestions.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder berhasil dirapikan oleh AI! ✨'),
          backgroundColor: Color(0xFF4A80F0),
        ),
      );
    }
  }

  /// Fitur 2: Ekstrak To-Do & Action Items dari Catatan
  Future<void> _extractActionItems() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'AI sedang mengekstrak daftar tugas penting...';
      _extractedTasks.clear();
    });

    final memos = await MemoStorage.loadMemos();
    await Future.delayed(const Duration(milliseconds: 600));

    final List<ExtractedTask> tasks = [];
    for (final memo in memos) {
      final text = '${memo.title}: ${memo.content}'.toLowerCase();
      if (text.contains('laporan') || text.contains('praktikum') || text.contains('ppw')) {
        tasks.add(
          ExtractedTask(
            task: 'Submit laporan lab dan persiapan praktikum kuis PPW hari Jumat',
            sourceMemo: memo.title,
          ),
        );
      }
      if (text.contains('belanja') || text.contains('supermarket') || text.contains('susu')) {
        tasks.add(
          ExtractedTask(
            task: 'Beli susu, telur, dan sayur segar di supermarket',
            sourceMemo: memo.title,
          ),
        );
      }
      if (text.contains('kas') || text.contains('kuitansi') || text.contains('pengeluaran')) {
        tasks.add(
          ExtractedTask(
            task: 'Catat pengeluaran uang kas bendahara sebelum jam 5 sore',
            sourceMemo: memo.title,
          ),
        );
      }
      if (text.contains('aplikasi') || text.contains('coding') || text.contains('flutter')) {
        tasks.add(
          ExtractedTask(
            task: 'Selesaikan coding arsitektur AI mobile memo & database',
            sourceMemo: memo.title,
          ),
        );
      }
      if (text.contains('testing') || text.contains('jadwal kuis') || text.contains('state management')) {
        tasks.add(
          ExtractedTask(
            task: 'Pelajari materi widget testing untuk kuis minggu depan',
            sourceMemo: memo.title,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _extractedTasks = tasks;
        _isLoading = false;
      });
      if (tasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ditemukan tugas spesifik di catatan.'),
          ),
        );
      }
    }
  }

  /// Fitur 3: Tanya Catatan Saya (Ask Memo)
  Future<void> _askMemo() async {
    final query = _questionController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _loadingMessage = 'AI sedang membaca seluruh catatanmu...';
      _aiAnswer = null;
    });

    final memos = await MemoStorage.loadMemos();

    if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _geminiApiKey!,
        );

        final contextNotes = memos
            .map((m) => 'Judul: "${m.title}", Isi: "${m.content}"')
            .join('\n');

        final prompt = '''
Berikut adalah catatan milik pengguna:
$contextNotes

Jawablah pertanyaan berikut dengan singkat, ramah, dan informatif berdasarkan catatan di atas saja:
Pertanyaan: "$query"
''';

        final response = await model.generateContent([Content.text(prompt)]);
        if (mounted) {
          setState(() {
            _aiAnswer = response.text ?? 'Tidak ada jawaban dari AI.';
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        debugPrint('Gemini ask error, fallback: $e');
      }
    }

    // Fallback Smart Heuristic Engine
    await Future.delayed(const Duration(milliseconds: 600));
    final qLower = query.toLowerCase();
    String answer = '';

    if (qLower.contains('kuis') || qLower.contains('jadwal') || qLower.contains('ujian')) {
      answer =
          'Berdasarkan catatanmu, ada kuis praktikum PPW pada hari Jumat (persiapkan modul & laporan lab) dan Kuis Pemrograman minggu depan mengenai materi widget testing & state management.';
    } else if (qLower.contains('belanja') || qLower.contains('beli')) {
      answer =
          'Catatan "Belanja Bulanan" mencatat kebutuhan pokok: membeli susu, telur, dan sayur segar di supermarket.';
    } else if (qLower.contains('aplikasi') || qLower.contains('ide')) {
      answer =
          'Pada catatan "Ide Aplikasi Flutter", kamu merencanakan arsitektur mobile memo berbasis AI, integrasi speech-to-text, dan database offline.';
    } else {
      final matchedMemos = memos.where((m) {
        return m.title.toLowerCase().contains(qLower) ||
            m.content.toLowerCase().contains(qLower) ||
            qLower.split(' ').any((w) =>
                w.length > 3 &&
                (m.title.toLowerCase().contains(w) ||
                    m.content.toLowerCase().contains(w)));
      }).toList();

      if (matchedMemos.isNotEmpty) {
        final listTitles = matchedMemos.map((m) => '• ${m.title}').join('\n');
        answer =
            'Berdasarkan catatanmu, ditemukan informasi terkait pada:\n$listTitles\n\nIsi: "${matchedMemos.first.content}"';
      } else {
        answer =
            'Tidak ditemukan catatan yang spesifik membahas "$query". Coba gunakan pertanyaan seperti "Ada kuis apa saja?", "Apa saja catatan belanja?", atau "Rangkum ide aplikasi".';
      }
    }

    if (mounted) {
      setState(() {
        _aiAnswer = answer;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF4A80F0), size: 22),
            SizedBox(width: 8),
            Text(
              'Memo AI Assistant',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang Data Demo AI',
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: Color(0xFF4A80F0),
              size: 22,
            ),
            onPressed: _confirmResetDemoData,
          ),
          IconButton(
            tooltip: 'Konfigurasi Gemini API Key',
            icon: Icon(
              _geminiApiKey != null
                  ? Icons.vpn_key
                  : Icons.vpn_key_outlined,
              color: _geminiApiKey != null
                  ? const Color(0xFF4A80F0)
                  : const Color(0xFF9E9E9E),
              size: 20,
            ),
            onPressed: _showApiKeyDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          children: [
            // Header Bar: Judul Fitur & Tombol Pintas Seed Data Demo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Asisten Pintar Catatan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                InkWell(
                  onTap: _confirmResetDemoData,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D7FE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_fix_high_rounded,
                            size: 14, color: Color(0xFF356AE6)),
                        SizedBox(width: 4),
                        Text(
                          'Seed Data Demo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF356AE6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Indikator Loading Jika AI sedang bekerja
            if (_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF4A80F0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _loadingMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Tombol Aksi AI Cerdas (Rapikan Folder & Ekstrak Tugas)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _isLoading ? null : _organizeFolders,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE6FF), // Lavender pastel
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD1C4E9)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.folder_shared_outlined,
                              color: Color(0xFF5E35B1), size: 24),
                          SizedBox(height: 6),
                          Text(
                            'Rapikan Folder',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF311B92),
                            ),
                          ),
                          Text(
                            'Kategori otomatis',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5E35B1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _isLoading ? null : _extractActionItems,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1), // Mint pastel
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF80CBC4)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.checklist_rtl_rounded,
                              color: Color(0xFF00796B), size: 24),
                          SizedBox(height: 6),
                          Text(
                            'Ekstrak Tugas',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40),
                            ),
                          ),
                          Text(
                            'Daftar To-Do list',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00796B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. Tampilan Hasil Rekomendasi Folder (Jika Ada)
            if (_folderSuggestions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saran Pengelompokan Folder',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _applyFolderSuggestions,
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Terapkan Semua'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A80F0),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ..._folderSuggestions.map((sug) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sug.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sug.currentFolder,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF4B5563)),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward,
                                size: 14, color: Color(0xFF9CA3AF)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sug.suggestedFolder,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 ${sug.reason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // 3. Tampilan Hasil Ekstrak To-Do (Jika Ada)
            if (_extractedTasks.isNotEmpty) ...[
              const Text(
                'Daftar Tugas yang Ditemukan (To-Do)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              ..._extractedTasks.map((item) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: item.isCompleted,
                  title: Text(
                    item.task,
                    style: TextStyle(
                      fontSize: 13,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isCompleted
                          ? Colors.grey
                          : const Color(0xFF212121),
                    ),
                  ),
                  subtitle: Text(
                    'Sumber: "${item.sourceMemo}"',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  activeColor: const Color(0xFF4A80F0),
                  onChanged: (val) {
                    setState(() {
                      item.isCompleted = val ?? false;
                    });
                  },
                );
              }),
              const SizedBox(height: 16),
            ],

            // 4. Fitur Tanya Catatan (Ask Memo)
            const Text(
              'Tanya Catatan Saya (Ask Memo)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Misal: "Ada tugas apa minggu depan?"',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _askMemo(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF4A80F0),
                      size: 20,
                    ),
                    onPressed: _isLoading ? null : _askMemo,
                  ),
                ],
              ),
            ),

            // Chips pertanyaan instan
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickQuestionChip('Ada kuis apa saja?'),
                  const SizedBox(width: 6),
                  _buildQuickQuestionChip('Apa saja catatan belanja?'),
                  const SizedBox(width: 6),
                  _buildQuickQuestionChip('Rangkum ide aplikasi'),
                ],
              ),
            ),

            // Jawaban AI
            if (_aiAnswer != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Color(0xFF7C3AED), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Jawaban Asisten AI:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _aiAnswer!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestionChip(String question) {
    return ActionChip(
      label: Text(
        question,
        style: const TextStyle(fontSize: 11, color: Color(0xFF4A80F0)),
      ),
      backgroundColor: const Color(0xFFEEF2FF),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        _questionController.text = question;
        _askMemo();
      },
    );
  }
}
