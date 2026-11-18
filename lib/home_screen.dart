import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'memo_card.dart';
import 'memo_form_screen.dart';
import 'memo_model.dart';

/// Layar Utama Memo (Layar Kiri Prototype)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Memo> _memos = [];
  List<String> _folders = ['Kuliah', 'Pribadi'];
  String _selectedFolder = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memuat data memo dan folder dari local storage (SharedPreferences)
  Future<void> loadData() async {
    setState(() => _isLoading = true);
    final loadedMemos = await MemoStorage.loadMemos();
    final loadedFolders = await MemoStorage.loadFolders();

    if (!mounted) return;
    setState(() {
      _memos = loadedMemos;
      _folders = loadedFolders;
      _isLoading = false;
    });
  }

  /// Menghapus memo beserta file gambar fisiknya dari memori perangkat
  Future<void> _deleteMemo(Memo memo) async {
    setState(() {
      _memos.removeWhere((item) => item.id == memo.id);
    });
    await MemoStorage.saveMemos(_memos);

    // Hapus file fisik gambar jika bukan dummy sample bawaan
    if (memo.imagePath != null && !memo.imagePath!.contains('sample_dummy')) {
      await MemoStorage.deleteImageFile(memo.imagePath);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo dihapus'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Menampilkan Pop-up Dialog konfirmasi hapus memo sesuai desain prototype
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
                  fontSize: 15,
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Menampilkan dialog tambah folder baru
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
            'Tambah Kategori Baru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: folderController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nama folder/kategori...',
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
                    _selectedFolder = newFolder;
                  });
                  await MemoStorage.saveFolders(_folders);
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

  /// Berpindah ke MemoFormScreen untuk tambah atau edit memo
  Future<void> _navigateToForm({
    Memo? memo,
    String? initialImagePath,
    bool autoStartVoice = false,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MemoFormScreen(
          memo: memo,
          initialImagePath: initialImagePath,
          defaultFolder: _selectedFolder == 'Semua' ? 'Kuliah' : _selectedFolder,
          autoStartVoice: autoStartVoice,
        ),
      ),
    );

    // Refresh daftar memo jika form berhasil disimpan
    if (result == true) {
      loadData();
    }
  }

  /// Aksi FAB Galeri: Pilih gambar dari galeri lalu teruskan ke form
  Future<void> _pickGalleryAndNavigate() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final permanentPath =
            await MemoStorage.copyImageToPermanentDir(pickedFile.path);
        _navigateToForm(initialImagePath: permanentPath);
      }
    } catch (e) {
      debugPrint('Error mengambil galeri: $e');
    }
  }

  /// Filter memo secara real-time berdasarkan query pencarian dan folder aktif
  List<Memo> get _filteredMemos {
    return _memos.where((m) {
      final matchesFolder =
          _selectedFolder == 'Semua' || m.folder == _selectedFolder;
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          m.title.toLowerCase().contains(query) ||
          m.content.toLowerCase().contains(query);
      return matchesFolder && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMemos;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar berbentuk pil di bagian paling atas
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
                  decoration: InputDecoration(
                    hintText: 'Cari memo...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9E9E9E),
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18, color: Color(0xFF9E9E9E)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // 2. Bar Filter Kategori / Folder secara Horizontal
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Chip "Semua"
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Semua'),
                      selected: _selectedFolder == 'Semua',
                      showCheckmark: false,
                      selectedColor: const Color(0xFF4A80F0),
                      backgroundColor: const Color(0xFFF0F2F5),
                      labelStyle: TextStyle(
                        color: _selectedFolder == 'Semua'
                            ? Colors.white
                            : const Color(0xFF616161),
                        fontWeight: _selectedFolder == 'Semua'
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide.none,
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => _selectedFolder = 'Semua');
                        }
                      },
                    ),
                  ),

                  // Chip folder dinamis dari database lokal
                  ..._folders.map(
                    (folder) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(folder),
                        selected: _selectedFolder == folder,
                        showCheckmark: false,
                        selectedColor: const Color(0xFF4A80F0),
                        backgroundColor: const Color(0xFFF0F2F5),
                        labelStyle: TextStyle(
                          color: _selectedFolder == folder
                              ? Colors.white
                              : const Color(0xFF616161),
                          fontWeight: _selectedFolder == folder
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide.none,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() => _selectedFolder = folder);
                          }
                        },
                      ),
                    ),
                  ),

                  // Tombol "+" di ujung kanan untuk menambah folder baru
                  InkWell(
                    onTap: _showAddFolderDialog,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 32,
                      width: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Color(0xFF4A80F0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Grid Daftar Memo (2 Kolom)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ada memo yang sesuai'
                                    : 'Belum ada memo di kategori ini',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final memo = filtered[index];
                            return MemoCard(
                              memo: memo,
                              onTap: () => _navigateToForm(memo: memo),
                              onLongPress: () => _showDeleteDialog(memo),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // 4. Expandable SpeedDial FAB sesuai prototype visual
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        activeBackgroundColor: const Color(0xFF455A64),
        activeForegroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          // Pilihan 1: Mikrofon (auto-start voice)
          SpeedDialChild(
            child: const Icon(
              Icons.mic_outlined,
              color: Color(0xFF263238),
              size: 22,
            ),
            backgroundColor: Colors.white,
            elevation: 3,
            onTap: () => _navigateToForm(autoStartVoice: true),
          ),
          // Pilihan 2: Galeri foto
          SpeedDialChild(
            child: const Icon(
              Icons.image_outlined,
              color: Color(0xFF263238),
              size: 22,
            ),
            backgroundColor: Colors.white,
            elevation: 3,
            onTap: _pickGalleryAndNavigate,
          ),
          // Pilihan 3: Huruf 'A' / Form Teks Biasa
          SpeedDialChild(
            child: const Text(
              'A',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 3,
            onTap: () => _navigateToForm(),
          ),
        ],
      ),
    );
  }
}
