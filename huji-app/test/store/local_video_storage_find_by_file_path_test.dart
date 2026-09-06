import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/video.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUpAll(() async {
    tempRoot = Directory.systemTemp.createTempSync('huji_video_storage_test');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (!StorageService.isInitialized) {
      await StorageService.init();
    }
  });

  tearDownAll(() async {
    final db = await LocalVideoStorage.database;
    if (db.isOpen) {
      await db.close();
    }
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().init();
  });

  test('findByFilePath returns null when no record matches', () async {
    expect(await LocalVideoStorage().findByFilePath('/nope.mp4'), isNull);
  });

  test('findByFilePath returns the record with that path', () async {
    final record = SavedVideoRecord(
      id: 'find-path-1',
      sportType: SportType.badminton,
      filePath: '/tmp/video_a.mp4',
      duration: 10.0,
      fileSize: 100,
    );
    await LocalVideoStorage().add(record);

    final found = await LocalVideoStorage().findByFilePath('/tmp/video_a.mp4');
    expect(found, isA<SavedVideoRecord>());
    expect(found!.id, 'find-path-1');
    expect(found.sportType, SportType.badminton);
  });
}
