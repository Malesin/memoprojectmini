import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'folder_screen.dart';
import 'home_screen.dart';
import 'memo_form_screen.dart';
import 'memo_model.dart';
import 'smart_ai_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Atur orientasi dan warna status bar agar bersih dan konsisten
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MemoApp());
}

/// Root Widget Aplikasi Memo
class MemoApp extends StatelessWidget {
  const MemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A80F0),
          primary: const Color(0xFF4A80F0),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFF212121)),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

/// Layar Pembungkus Utama dengan BottomNavigationBar 4 Tab
/// (Home, Camera Quick Capture, Folder, & Smart AI)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<FolderScreenState> _folderKey =
      GlobalKey<FolderScreenState>();

  /// Indeks tampilan halaman aktif dalam IndexedStack
  int get _activePageIndex {
    if (_currentIndex == 2) return 1; // FolderScreen
    if (_currentIndex == 3) return 2; // SmartAIScreen
    return 0; // HomeScreen
  }

  /// Fitur Quick Capture: Mengambil foto instan menggunakan kamera lalu langsung membuka form memo
  Future<void> _quickCaptureCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        // Salin ke penyimpanan dokumen lokal permanen
        final permanentPath =
            await MemoStorage.copyImageToPermanentDir(photo.path);

        if (!mounted) return;
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => MemoFormScreen(
              initialImagePath: permanentPath,
            ),
          ),
        );

        // Jika memo disimpan, refresh tampilan home dan folder
        if (result == true) {
          _homeKey.currentState?.loadData();
          _folderKey.currentState?.loadData();
        }
      }
    } catch (e) {
      debugPrint('Error quick capture camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengakses kamera'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _activePageIndex,
        children: [
          HomeScreen(key: _homeKey),
          FolderScreen(
            key: _folderKey,
            onMemosUpdated: () {
              _homeKey.currentState?.loadData();
            },
          ),
          SmartAIScreen(
            onMemosUpdated: () {
              _homeKey.currentState?.loadData();
              _folderKey.currentState?.loadData();
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4A80F0),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          onTap: (index) {
            if (index == 0) {
              setState(() => _currentIndex = 0);
            } else if (index == 1) {
              // Tab Camera adalah Quick Capture: langsung buka kamera tanpa meninggalkan layar aktif
              _quickCaptureCamera();
            } else if (index == 2) {
              _folderKey.currentState?.loadData();
              setState(() => _currentIndex = 2);
            } else if (index == 3) {
              setState(() => _currentIndex = 3);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              label: 'Camera',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'Folder',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'Smart AI',
            ),
          ],
        ),
      ),
    );
  }
}
