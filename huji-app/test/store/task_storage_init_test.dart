import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUpAll(() async {
    tempRoot = Directory.systemTemp.createTempSync('huji_task_storage_init');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (!StorageService.isInitialized) {
      await StorageService.init();
    }
  });

  tearDownAll(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await TaskStorage().resetDatabase();
    await TaskStorage().init();
  });

  test('calling init twice does not duplicate persisted tasks', () async {
    final storage = TaskStorage();
    final now = DateTime.now().millisecondsSinceEpoch;
    final task = DownloadTask(
      id: 'dup-init-$now',
      name: 'init-idempotency',
      url: 'https://example.com/file.bin',
      savePath: '/tmp/file.bin',
      isInstall: false,
      cacheKey: 'dup-init-$now',
      createdAt: now,
      status: TaskStatusEnum.completed,
    );

    await storage.addTask(task);
    expect(storage.tasks.where((t) => t.id == task.id).length, 1);

    await storage.init();
    await storage.init();

    expect(storage.tasks.where((t) => t.id == task.id).length, 1);
    expect(storage.tasks.map((t) => t.id).toSet().length, storage.tasks.length);
  });
}
