import 'dart:async';
import 'dart:io';

import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/demo_video_service.dart';
import 'package:huji_app/services/local_clip_task_runner.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:path/path.dart' as p;
import 'package:get/get.dart';
import 'package:huji_app/settings/settings_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'autoclip_fixtures.dart';
import 'fake_path_provider.dart';

/// Test harness for the desktop clip flow:
/// demo video → local detection task → task storage updates.
class ClipFlowTestHelper {
  ClipFlowTestHelper._();

  static Directory? _tempRoot;

  static Future<void> setUp() async {
    _tempRoot ??= Directory.systemTemp.createTempSync('huji_clip_flow_test');
    PathProviderPlatform.instance = FakePathProvider(root: _tempRoot!.path);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Task notifications resolve SettingsManager via GetX — register it so
    // task status updates don't throw in the test VM.
    if (!Get.isRegistered<SettingsManager>()) {
      Get.put(SettingsManager(), permanent: true);
    }

    if (!StorageService.isInitialized) {
      await StorageService.init();
    }

    await TaskStorage().resetDatabase();
    await LocalVideoStorage().resetDatabase();
    await TaskStorage().init();
    await LocalVideoStorage().init();
  }

  static SportType _sportTypeForDemo(DemoVideo demo) {
    return demo.sportTypeKey == 'badminton'
        ? SportType.badminton
        : SportType.pingpong;
  }

  static VideoClipConfigReqVo _clipConfigForDemo(DemoVideo demo) {
    return demo.sportTypeKey == 'badminton'
        ? algorithmBadmintonConfig()
        : algorithmPingPongConfig();
  }

  /// Mirrors [DesktopClipConfigPage._startLocalDetection] without UI dependencies.
  ///
  /// [clipConfig] overrides the demo's default config — used to force
  /// pipeline outcomes (e.g. an impossible minimum segment duration to
  /// trigger the "no valid segments" failure path).
  static Future<String> startLocalClipFromDemo(
    DemoVideo demo, {
    VideoClipConfigReqVo? clipConfig,
  }) async {
    final file = await DemoVideoService.materialize(demo);
    final sportType = _sportTypeForDemo(demo);
    final effectiveClipConfig = clipConfig ?? _clipConfigForDemo(demo);
    final taskStorage = TaskStorage();
    final now = DateTime.now().millisecondsSinceEpoch;
    final fileName = p.basename(file.path);

    final task = VideoClipTask(
      id: '${now}_$fileName',
      name: 'integration-$fileName',
      videoPath: file.path,
      outputPath: '',
      autoDownload: false,
      sportType: sportType,
      clipConfig: effectiveClipConfig,
      createdAt: now,
      status: TaskStatusEnum.pending,
    );

    await taskStorage.addTask(task);

    // Same orchestration the app uses (progress + library records).
    unawaited(LocalClipTaskRunner.run(task: task, taskStorage: taskStorage));

    return task.id;
  }

  static Future<Task> waitForTerminalStatus(
    String taskId, {
    Duration timeout = const Duration(minutes: 15),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    final taskStorage = TaskStorage();

    while (DateTime.now().isBefore(deadline)) {
      final task = taskStorage.getTaskById(taskId);
      if (task == null) {
        throw StateError('Task disappeared: $taskId');
      }
      if (task.status == TaskStatusEnum.completed ||
          task.status == TaskStatusEnum.failed ||
          task.status == TaskStatusEnum.cancelled) {
        return task;
      }
      await Future<void>.delayed(pollInterval);
    }

    final last = taskStorage.getTaskById(taskId);
    throw TimeoutException(
      'Task $taskId did not finish within $timeout (last=${last?.status})',
      timeout,
    );
  }
}
