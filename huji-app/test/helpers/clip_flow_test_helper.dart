import 'dart:async';
import 'dart:io';

import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/demo_video_service.dart';
import 'package:huji_app/services/local_detection_service.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:path/path.dart' as p;
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
  static Future<String> startLocalClipFromDemo(DemoVideo demo) async {
    final file = await DemoVideoService.materialize(demo);
    final sportType = _sportTypeForDemo(demo);
    final clipConfig = _clipConfigForDemo(demo);
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
      clipConfig: clipConfig,
      createdAt: now,
      status: TaskStatusEnum.pending,
    );

    await taskStorage.addTask(task);

    await LocalVideoStorage().add(ProcessVideoRecord(
      id: '${now}_$fileName',
      processStatus: LocalVideoProcessStatusEnum.processing,
      sportType: sportType,
      filePath: file.path,
      clipMode: ClipMode.existingVideo,
      videoClipConfigReqVo: clipConfig,
      taskId: task.id,
    ));

    await taskStorage.updateTask(task.id, (oldTask) {
      return oldTask.copyWith(
        status: TaskStatusEnum.processing,
        extraInfo: 'local detecting',
      );
    });

    final progressThrottler = Throttler(
      tag: 'local_progress_${task.id}',
      duration: const Duration(milliseconds: 500),
    );

    unawaited(
      LocalDetectionService.runInferenceAsync(
        videoPath: file.path,
        clipConfig: clipConfig,
        sportTypeKey: demo.sportTypeKey,
        matchType: demo.matchType,
        onProgress: (progress, message) {
          progressThrottler.call(() {
            taskStorage.updateTask(task.id, (oldTask) {
              return oldTask.copyWith(
                status: TaskStatusEnum.processing,
                progress: progress,
                extraInfo:
                    message.isNotEmpty ? message : 'local detecting',
              );
            });
          });
        },
      ).then((result) async {
        final output = result.clipOutput;
        final allSegments = output.allMatchSegments
            .map((segmentMap) => segmentMap.values.first)
            .toList();
        final greatSegments = output.greatMatchSegments
            .map((segmentMap) => segmentMap.values.first)
            .toList();

        String? thumbPath;
        try {
          thumbPath = await VideoUtils.generateVideoThumbnail(file.path);
        } catch (_) {
          // Thumbnail generation is optional in tests.
        }

        await taskStorage.updateTask(task.id, (oldTask) {
          return oldTask.copyWith(
            status: TaskStatusEnum.completed,
            progress: 1.0,
            image: thumbPath,
            extraInfo: 'segments=${allSegments.length}',
          );
        });

        await LocalVideoStorage().add(EdittingVideoRecord(
          id: '${now}_$fileName',
          processStatus: LocalVideoProcessStatusEnum.completed,
          sportType: sportType,
          filePath: file.path,
          thumbnailPath: thumbPath,
          clipMode: ClipMode.existingVideo,
          allMatchSegments: allSegments,
          favoritesMatchSegments:
              greatSegments.isNotEmpty ? greatSegments : allSegments,
        ));
      }).catchError((Object e) async {
        await taskStorage.updateTask(task.id, (oldTask) {
          return oldTask.copyWith(
            status: TaskStatusEnum.failed,
            extraInfo: e.toString(),
          );
        });
      }),
    );

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
