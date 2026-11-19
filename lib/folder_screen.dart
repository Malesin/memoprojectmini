import 'package:flutter/material.dart';
import 'memo_card.dart';
import 'memo_form_screen.dart';
import 'memo_model.dart';

/// Layar Daftar Folder Kategori (Tab Folder di Sebelah Kanan Kamera)
class FolderScreen extends StatefulWidget {
  final VoidCallback onMemosUpdated;

  const FolderScreen({super.key, required this.onMemosUpdated});

  @override
  State<FolderScreen> createState() => FolderScreenState();
}

class FolderScreenState extends State<FolderScreen> {
  List<String> _folders = ['Kuliah', 'Pribadi'];
  List<Memo> _memos = [];
  bool _isLoading = true;

  // Ikon & warna pemanis untuk masing-masing folder
  final Map<String, IconData> _folderIcons = {
    'Kuliah': Icons.school_outlined,
    'Pribadi': Icons.person_outline_rounded,
    'Keuangan': Icons.account_balance_wallet_outlined,
    'Ide & Proyek': Icons.lightbulb_outline_rounded,
    'Pekerjaan': Icons.work_outline_rounded,
  };

  final Map<String, Color> _folderColors = {
    'Kuliah': const Color(0xFF4A80F0),
    'Pribadi': const Color(0xFFE91E63),
    'Keuangan': const Color(0xFF2E7D32),
    'Ide & Proyek': const Color(0xFFF57C00),
    'Pekerjaan': const Color(0xFF673AB7),
  };

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Memuat data folder dan memo dari SharedPreferences
  Future<void> loadData() async {
    setState(() => _isLoading = true);
    final loadedFolders = await MemoStorage.loadFolders();
    final loadedMemos = await MemoStorage.loadMemos();

    if (!mounted) return;
    setState(() {
      _folders = loadedFolders;
      _memos = loadedMemos;
      _isLoading = false;
    });
  }

  /// Menghitung jumlah catatan dalam folder tertentu
  int _getMemoCountForFolder(String folder) {
    return _memos.where((m) => m.folder == folder).length;
  }

  /// Dialog tambah folder baru
  void _showAddFolderDialog() {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Folder Baru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: folderController,
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
                final newFolder = folderController.text.trim();
                if (newFolder.isNotEmpty && !_folders.contains(newFolder)) {
                  setState(() {
                    _folders.add(newFolder);
                  });
                  await MemoStorage.saveFolders(_folders);
                  widget.onMemosUpdated();
                }
                if (ctx.mounted) Navigator.pop(ctx);
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

  /// Dialog hapus folder
  void _showDeleteFolderDialog(String folder) {
    if (_folders.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 1 kategori tersisa.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hapus Folder "$folder"?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          content: Text(
            'Catatan di dalam folder "$folder" tidak akan terhapus, melainkan dipindahkan ke folder utama.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() {
                  _folders.remove(folder);
                  final fallback =
                      _folders.isNotEmpty ? _folders.first : 'Kuliah';
                  for (int i = 0; i < _memos.length; i++) {
                    if (_memos[i].folder == folder) {
                      _memos[i] = _memos[i].copyWith(folder: fallback);
                    }
                  }
                });
                await MemoStorage.saveFolders(_folders);
                await MemoStorage.saveMemos(_memos);
                widget.onMemosUpdated();
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
            Icon(Icons.folder_open_rounded,
                color: Color(0xFF4A80F0), size: 22),
            SizedBox(width: 8),
            Text(
              'Kategori Folder',
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
            tooltip: 'Tambah Folder Baru',
            icon: const Icon(Icons.create_new_folder_outlined,
                color: Color(0xFF4A80F0)),
            onPressed: _showAddFolderDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final count = _getMemoCountForFolder(folder);
                final icon = _folderIcons[folder] ?? Icons.folder_outlined;
                final accentColor =
                    _folderColors[folder] ?? const Color(0xFF4A80F0);

                return InkWell(
                  onTap: () async {
                    // Buka halaman detail isi memo di dalam folder tersebut
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderDetailScreen(
                          folderName: folder,
                          onMemosChanged: () {
                            loadData();
                            widget.onMemosUpdated();
                          },
                        ),
                      ),
                    );
                    loadData();
                  },
                  onLongPress: () => _showDeleteFolderDialog(folder),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  accentColor.withValues(alpha: 0.12),
                              child: Icon(icon, color: accentColor, size: 22),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFFBDBDBD),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folder,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count Catatan',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Layar Detail Menampilkan Daftar Memo di dalam Folder Tertentu
class FolderDetailScreen extends StatefulWidget {
  final String folderName;
  final VoidCallback onMemosChanged;

  const FolderDetailScreen({
    super.key,
    required this.folderName,
    required this.onMemosChanged,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<Memo> _folderMemos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolderMemos();
  }

  Future<void> _loadFolderMemos() async {
    setState(() => _isLoading = true);
    final allMemos = await MemoStorage.loadMemos();
    if (!mounted) return;
    setState(() {
      _folderMemos =
          allMemos.where((m) => m.folder == widget.folderName).toList();
      _isLoading = false;
    });
  }

  /// Menghapus memo
  Future<void> _deleteMemo(Memo memo) async {
    final allMemos = await MemoStorage.loadMemos();
    allMemos.removeWhere((m) => m.id == memo.id);
    await MemoStorage.saveMemos(allMemos);

    if (memo.imagePath != null && !memo.imagePath!.contains('sample_dummy')) {
      await MemoStorage.deleteImageFile(memo.imagePath);
    }

    _loadFolderMemos();
    widget.onMemosChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo dihapus'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteDialog(Memo memo) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Memo?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF616161),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteMemo(memo);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF212121),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Folder: ${widget.folderName}',
              style: const TextStyle(
                color: Color(0xFF212121),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_folderMemos.length} Catatan',
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
            )
          : _folderMemos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada catatan di folder "${widget.folderName}"',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _folderMemos.length,
                  itemBuilder: (context, index) {
                    final memo = _folderMemos[index];
                    return MemoCard(
                      memo: memo,
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MemoFormScreen(
                              memo: memo,
                              defaultFolder: widget.folderName,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadFolderMemos();
                          widget.onMemosChanged();
                        }
                      },
                      onLongPress: () => _showDeleteDialog(memo),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A80F0),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => MemoFormScreen(
                defaultFolder: widget.folderName,
              ),
            ),
          );
          if (result == true) {
            _loadFolderMemos();
            widget.onMemosChanged();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
