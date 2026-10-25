import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/settings/settings_manager.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_path_provider.dart';

/// Regression tests for the "cancelling a clip task looks like a no-op" bug:
/// background callbacks used to resurrect a cancelled task back to
/// `processing`/`completed`, so the UI flipped away from 取消 immediately.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUpAll(() async {
    tempRoot = Directory.systemTemp.createTempSync('huji_task_cancel_status');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Task status changes trigger a notification update, which resolves
    // SettingsManager through GetX. Register it with notifications disabled so
    // the local-notification plugin is never touched in the test VM.
    SharedPreferences.setMockInitialValues({'notifications': false});
    if (!Get.isRegistered<SettingsManager>()) {
      Get.put(SettingsManager(), permanent: true);
    }

    if (!StorageService.isInitialized) {
      await StorageService.init();
    }
  });

  tearDownAll(() async {
    final db = await TaskStorage().database;
    if (db.isOpen) {
      await db.close();
    }
    // Windows keeps the sqlite file handle for a short while after close, so
    // deleting the temp root can fail with "used by another process" even
    // though every test passed. Retry briefly before giving up on cleanup.
    for (var attempt = 0; attempt < 10; attempt++) {
      if (!tempRoot.existsSync()) return;
      try {
        tempRoot.deleteSync(recursive: true);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  setUp(() async {
    await TaskStorage().resetDatabase();
    await TaskStorage().init();
  });

  VideoClipTask clipTask(String id, TaskStatusEnum status) => VideoClipTask(
    id: id,
    name: 'clip',
    videoPath: '/tmp/in.mp4',
    outputPath: '',
    autoDownload: false,
    createdAt: DateTime.now().millisecondsSinceEpoch,
    status: status,
  );

  test('a cancelled task is not resurrected to processing', () async {
    final storage = TaskStorage();
    final task = clipTask('cancel-processing', TaskStatusEnum.cancelled);
    await storage.addTask(task);

    final updated = await storage.tryUpdateTask(
      task.id,
      (old) => old.copyWith(status: TaskStatusEnum.processing, progress: 0.5),
    );

    expect(updated!.status, TaskStatusEnum.cancelled);
    expect(storage.getTaskById(task.id)!.status, TaskStatusEnum.cancelled);
    // The rest of the update is still applied — only the status is pinned.
    expect(storage.getTaskById(task.id)!.progress, 0.5);
  });

  test('a cancelled task is not resurrected to completed', () async {
    final storage = TaskStorage();
    await storage.addTask(clipTask('cancel-completed', TaskStatusEnum.cancelled));

    await storage.tryUpdateTask(
      'cancel-completed',
      (old) => old.copyWith(status: TaskStatusEnum.completed, progress: 1.0),
    );

    expect(
      storage.getTaskById('cancel-completed')!.status,
      TaskStatusEnum.cancelled,
    );
  });

  test('a cancelled task can still be explicitly moved to pending', () async {
    // This is the escape hatch `TaskStorage.processTask` uses to restart a
    // (previously) cancelled task without being blocked by the guard.
    final storage = TaskStorage();
    await storage.addTask(clipTask('restart', TaskStatusEnum.cancelled));

    await storage.tryUpdateTask(
      'restart',
      (old) => old.copyWith(status: TaskStatusEnum.pending),
    );

    expect(storage.getTaskById('restart')!.status, TaskStatusEnum.pending);
  });

  test('a cancelled task may transition to failed (cancel wins over failure)', () async {
    // Failure is a terminal background outcome, not a resurrection: allowing
    // it keeps the guard from turning a real storage error into a hang.
    final storage = TaskStorage();
    await storage.addTask(clipTask('cancel-failed', TaskStatusEnum.cancelled));

    await storage.tryUpdateTask(
      'cancel-failed',
      (old) => old.copyWith(status: TaskStatusEnum.failed),
    );

    expect(storage.getTaskById('cancel-failed')!.status, TaskStatusEnum.failed);
  });

  test('cancelTask writes cancelled status', () async {
    final storage = TaskStorage();
    final task = clipTask('cancel-api', TaskStatusEnum.processing);
    await storage.addTask(task);

    await storage.cancelTask(task);

    expect(storage.getTaskById(task.id)!.status, TaskStatusEnum.cancelled);
  });
}
