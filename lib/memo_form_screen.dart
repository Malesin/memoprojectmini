import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'memo_model.dart';

/// Layar Form Tambah & Edit Memo (Layar Kanan Prototype)
class MemoFormScreen extends StatefulWidget {
  final Memo? memo;
  final String? initialImagePath;
  final String? defaultFolder;
  final bool autoStartVoice;

  const MemoFormScreen({
    super.key,
    this.memo,
    this.initialImagePath,
    this.defaultFolder,
    this.autoStartVoice = false,
  });

  @override
  State<MemoFormScreen> createState() => _MemoFormScreenState();
}

class _MemoFormScreenState extends State<MemoFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  String _selectedFolder = 'Kuliah';
  List<String> _folders = ['Kuliah', 'Pribadi'];
  String? _imagePath;
  bool _hasVoice = false;

  // Integrasi Speech to Text untuk fitur voice-to-text
  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dari memo yang sudah ada atau nilai awal
    _titleController = TextEditingController(
      text: widget.memo != null
          ? (widget.memo!.title == 'Tanpa Judul' ? '' : widget.memo!.title)
          : '',
    );
    _contentController = TextEditingController(
      text: widget.memo?.content ?? '',
    );

    _imagePath = widget.memo?.imagePath ?? widget.initialImagePath;
    _hasVoice = widget.memo?.hasVoice ?? false;

    _loadFolders();

    // Jika dipanggil dari FAB mikrofon, otomatis nyalakan rekaman setelah render UI
    if (widget.autoStartVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toggleVoiceRecording();
      });
    }
  }

  /// Memuat daftar folder dari penyimpanan lokal SharedPreferences
  Future<void> _loadFolders() async {
    final loaded = await MemoStorage.loadFolders();
    if (!mounted) return;
    setState(() {
      _folders = loaded;
      if (widget.memo != null) {
        _selectedFolder = widget.memo!.folder;
      } else if (widget.defaultFolder != null &&
          _folders.contains(widget.defaultFolder)) {
        _selectedFolder = widget.defaultFolder!;
      } else if (_folders.isNotEmpty) {
        _selectedFolder = _folders.first;
      }
      // Pastikan selectedFolder ada di list
      if (!_folders.contains(_selectedFolder)) {
        _folders.add(_selectedFolder);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  /// Fitur Ambil Foto dari Kamera atau Pilih dari Galeri
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Salin file gambar ke folder dokumen permanen aplikasi agar tidak hilang
        final permanentPath =
            await MemoStorage.copyImageToPermanentDir(pickedFile.path);
        setState(() {
          _imagePath = permanentPath;
        });
      }
    } catch (e) {
      debugPrint('Error mengambil gambar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengakses kamera/galeri'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  /// Menampilkan BottomSheet pilihan kamera atau galeri
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF4A80F0),
                    size: 26,
                  ),
                  title: const Text(
                    'Ambil dari Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF4A80F0),
                    size: 26,
                  ),
                  title: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Fitur Rekam Suara (Speech to Text) dengan fallback aman tanpa crash
  Future<void> _toggleVoiceRecording() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      if (!_isSpeechAvailable) {
        _isSpeechAvailable = await _speechToText.initialize(
          onError: (val) {
            debugPrint('Speech error: ${val.errorMsg}');
            if (mounted) setState(() => _isListening = false);
          },
          onStatus: (status) {
            debugPrint('Speech status: $status');
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
        );
      }

      if (_isSpeechAvailable) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty && mounted) {
              setState(() {
                _hasVoice = true;
                final text = result.recognizedWords;
                // Tambahkan teks hasil ucapan ke dalam isi catatan
                if (_contentController.text.trim().isEmpty) {
                  _contentController.text = text;
                } else if (!_contentController.text.contains(text)) {
                  _contentController.text =
                      '${_contentController.text.trim()} $text';
                }
                // Posisikan kursor di akhir teks
                _contentController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _contentController.text.length),
                );
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          localeId: 'id_ID',
          cancelOnError: true,
          partialResults: true,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur suara tidak tersedia di perangkat ini'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error speech recognition: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur suara tidak tersedia di perangkat ini'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Dialog untuk melihat foto dalam ukuran penuh (Full-screen preview)
  void _showFullScreenImage(String path) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: const Text('Foto lampiran tidak dapat dimuat'),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog tambah folder baru langsung dari form
  void _showAddFolderDialog() {
    final folderTextController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Folder Baru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: folderTextController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nama folder...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final name = folderTextController.text.trim();
                if (name.isNotEmpty) {
                  if (!_folders.contains(name)) {
                    setState(() {
                      _folders.add(name);
                      _selectedFolder = name;
                    });
                    await MemoStorage.saveFolders(_folders);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text(
                'Tambah',
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

  /// Menyimpan memo ke penyimpanan lokal
  Future<void> _saveMemo() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Validasi input: Jika judul, isi, dan foto kosong, tolak penyimpanan
    if (title.isEmpty && content.isEmpty && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan tidak boleh kosong'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    // Default judul jika user tidak mengisi judul
    final finalTitle = title.isEmpty ? 'Tanpa Judul' : title;
    final now = DateTime.now();

    final memoId = widget.memo?.id ?? now.millisecondsSinceEpoch.toString();
    final colorIdx = widget.memo?.colorIndex ??
        (now.millisecondsSinceEpoch % pastelColors.length);

    final savedMemo = Memo(
      id: memoId,
      title: finalTitle,
      content: content,
      folder: _selectedFolder,
      imagePath: _imagePath,
      hasVoice: _hasVoice,
      colorIndex: colorIdx,
      createdAt: widget.memo?.createdAt ?? now,
    );

    // Ambil data terkini, masukkan/perbarui, lalu simpan kembali
    final memos = await MemoStorage.loadMemos();
    if (widget.memo != null) {
      final idx = memos.indexWhere((m) => m.id == widget.memo!.id);
      if (idx != -1) {
        memos[idx] = savedMemo;
      } else {
        memos.insert(0, savedMemo);
      }
    } else {
      memos.insert(0, savedMemo);
    }

    await MemoStorage.saveMemos(memos);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 44,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF212121),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          isEditing ? 'Edit Memo' : 'Tambah Memo',
          style: const TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveMemo,
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Color(0xFF4A80F0),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Input Judul Memo
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
                decoration: const InputDecoration(
                  hintText: 'Judul Memo',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBDBDBD),
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4A80F0), width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Dropdown Pemilih Folder (Kapsul Abu-abu)
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _folders.contains(_selectedFolder)
                        ? _selectedFolder
                        : (_folders.isNotEmpty ? _folders.first : null),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF616161),
                      size: 20,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF424242),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    items: [
                      ..._folders.map(
                        (folder) => DropdownMenuItem(
                          value: folder,
                          child: Text(folder),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: '__add_new__',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 16, color: Color(0xFF4A80F0)),
                            SizedBox(width: 4),
                            Text(
                              'Folder Baru...',
                              style: TextStyle(
                                color: Color(0xFF4A80F0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == '__add_new__') {
                        _showAddFolderDialog();
                      } else if (value != null) {
                        setState(() => _selectedFolder = value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Input Isi Catatan (Multi-baris & Luas)
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF333333),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatanmu di sini...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              // 4. Thumbnail Foto Lampiran (Jika Ada)
              if (_imagePath != null && _imagePath!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showFullScreenImage(_imagePath!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 90,
                            height: 90,
                            color: const Color(0xFFEEEEEE),
                            child: File(_imagePath!).existsSync()
                                ? Image.file(
                                    File(_imagePath!),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.image, color: Colors.grey),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () async {
                            // Hapus gambar dari form
                            final oldPath = _imagePath;
                            setState(() => _imagePath = null);
                            // Jika bukan dummy, hapus file fisiknya
                            if (oldPath != null &&
                                !oldPath.contains('sample_dummy')) {
                              await MemoStorage.deleteImageFile(oldPath);
                            }
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 5. Dua Tombol Aksi di Bagian Bawah: Tambah Foto & Rekam Suara
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    // Tombol Kiri: Tambah Foto
                    Expanded(
                      child: InkWell(
                        onTap: _showImagePickerOptions,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD0D7DE),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF4A80F0),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tambah Foto',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Tombol Kanan: Rekam Suara
                    Expanded(
                      child: InkWell(
                        onTap: _toggleVoiceRecording,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isListening
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFFD0D7DE),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListening
                                    ? Icons.mic
                                    : Icons.mic_none_outlined,
                                color: _isListening
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF4A80F0),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isListening ? 'Mendengarkan...' : 'Rekam Suara',
                                style: TextStyle(
                                  color: _isListening
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF333333),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
