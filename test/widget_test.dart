import 'package:flutter_test/flutter_test.dart';
import 'package:memo/main.dart';
import 'package:memo/memo_card.dart';
import 'package:memo/memo_model.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  test('1. Test MemoStorage initial data seed & load', () async {
    final memos = await MemoStorage.loadMemos();
    expect(memos.length, 5);
    expect(memos.first.title, 'Tugas PPW');

    final folders = await MemoStorage.loadFolders();
    expect(folders, contains('Kuliah'));
    expect(folders, contains('Pribadi'));
  });

  test('2. Test Memo model serialization & copyWith', () async {
    final memo = Memo(
      id: 'test_1',
      title: 'Catatan Rapat',
      content: 'Membahas arsitektur Flutter',
      folder: 'Kuliah',
      hasVoice: true,
      colorIndex: 2,
      createdAt: DateTime(2026, 11, 15),
    );

    final json = memo.toJson();
    final reconstructed = Memo.fromJson(json);

    expect(reconstructed.id, 'test_1');
    expect(reconstructed.title, 'Catatan Rapat');
    expect(reconstructed.hasVoice, true);
    expect(reconstructed.colorIndex, 2);

    final modified = reconstructed.copyWith(title: 'Judul Baru');
    expect(modified.title, 'Judul Baru');
    expect(modified.content, 'Membahas arsitektur Flutter');
  });

  testWidgets('3. Memo app UI smoke test - Tampilan Home & Komponen Visual',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MemoApp());
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pump();
    });

    // Verifikasi Search Bar dengan hint 'Cari memo...'
    expect(find.text('Cari memo...'), findsOneWidget);

    // Verifikasi Filter Kategori/Folder bawaan
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Kuliah'), findsWidgets);
    expect(find.text('Pribadi'), findsWidgets);

    // Verifikasi Bottom Navigation Bar memiliki item Home, Camera, dan Smart AI
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Smart AI'), findsOneWidget);

    // Verifikasi MemoCard berhasil dimuat
    expect(find.byType(MemoCard), findsWidgets);

    // Tap tab Smart AI
    await tester.tap(find.text('Smart AI'));
    await tester.pump();

    // Verifikasi komponen Smart AI Assistant muncul
    expect(find.text('Memo AI Assistant'), findsOneWidget);
    expect(find.text('Rapikan Folder'), findsOneWidget);
    expect(find.text('Ekstrak Tugas'), findsOneWidget);
  });
}
