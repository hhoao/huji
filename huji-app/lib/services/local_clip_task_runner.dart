import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/l10n/l10n_resolve.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/local_detection_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/utils/video_utils.dart';

/// Runs the desktop local-detection pipeline for a [VideoClipTask].
///
/// This is the single source of truth for local detection task orchestration
/// (progress updates + library records). It is invoked both when the task is
/// first created (see `DesktopClipConfigPage`) and when a failed local task is
/// retried (`VideoClipTaskManager`).
///
/// A local detection task is identified by a null `uploadTaskId`: it never
/// goes through the multipart upload path used by cloud clip tasks.
class LocalClipTaskRunner {
  LocalClipTaskRunner._();

  /// `ping_pong` / `badminton` — the model asset folder key.
  static String sportTypeKeyFor(SportType sportType) {
    switch (sportType) {
      case SportType.pingpong:
        return 'ping_pong';
      case SportType.badminton:
        return 'badminton';
    }
  }

  /// Model match-type folder key for a sport.
  static String matchTypeFor(SportType sportType) {
    switch (sportType) {
      case SportType.pingpong:
        return 'profession';
      case SportType.badminton:
        return 'singles';
    }
  }

  static Future<void> run({
    required VideoClipTask task,
    required TaskStorage taskStorage,
  }) async {
    final l10n = resolveHujiL10n();
    final taskId = task.id;
    final sportType = task.sportType ?? SportType.pingpong;

    final clipConfig = task.clipConfig ?? await _configFromLibrary(taskId);
    if (clipConfig == null) {
      await _markFailed(
        taskStorage,
        taskId,
        l10n.localDetectionFailed('missing clip config'),
      );
      return;
    }

    final videoPath = task.videoPath;

    final started = await taskStorage.tryUpdateTask(
      taskId,
      (oldTask) => (oldTask as VideoClipTask).copyWith(
        status: TaskStatusEnum.processing,
        progress: 0,
        supportsPause: false,
        extraInfo: l10n.localDetecting,
      ),
    );
    if (started == null) {
      return; // Task was removed before we started.
    }

    // Keep the library entry in sync (idempotent: id == taskId).
    await LocalVideoStorage().add(
      ProcessVideoRecord(
        id: taskId,
        processStatus: LocalVideoProcessStatusEnum.processing,
        sportType: sportType,
        filePath: videoPath,
        clipMode: ClipMode.existingVideo,
        videoClipConfigReqVo: clipConfig,
        taskId: taskId,
      ),
    );

    final progressThrottler = Throttler(
      tag: 'local_progress_$taskId',
      duration: const Duration(milliseconds: 500),
    );

    try {
      final result = await LocalDetectionService.runInferenceAsync(
        videoPath: videoPath,
        clipConfig: clipConfig,
        sportTypeKey: sportTypeKeyFor(sportType),
        matchType: matchTypeFor(sportType),
        onProgress: (progress, message) {
          progressThrottler.call(() {
            // Fire-and-forget: the task may already be deleted, so ignore a
            // missing task instead of throwing an uncaught StateError.
            taskStorage.tryUpdateTask(taskId, (oldTask) {
              return (oldTask as VideoClipTask).copyWith(
                status: TaskStatusEnum.processing,
                progress: progress,
                extraInfo: message.isNotEmpty ? message : l10n.localDetecting,
              );
            });
          });
        },
      );

      final output = result.clipOutput;
      final allSegments = output.allMatchSegments
          .map((segmentMap) => segmentMap.values.first)
          .toList();
      final greatSegments = output.greatMatchSegments
          .map((segmentMap) => segmentMap.values.first)
          .toList();
      final processingTimeMs = result.processingTime.inMilliseconds;

      String? thumbPath;
      try {
        thumbPath = await VideoUtils.generateVideoThumbnail(videoPath);
      } catch (e) {
        AppLogger().w('Failed to generate detection thumbnail: $e');
      }

      final completed = await taskStorage.tryUpdateTask(
        taskId,
        (oldTask) => (oldTask as VideoClipTask).copyWith(
          status: TaskStatusEnum.completed,
          progress: 1.0,
          image: thumbPath,
          extraInfo: l10n.segmentsDetectedResult(
            allSegments.length,
            (processingTimeMs / 1000).round(),
          ),
        ),
      );
      if (completed == null) {
        return; // Task was removed while detecting — don't add an orphan record.
      }

      await LocalVideoStorage().add(
        EdittingVideoRecord(
          id: taskId,
          processStatus: LocalVideoProcessStatusEnum.completed,
          sportType: sportType,
          filePath: videoPath,
          thumbnailPath: thumbPath,
          clipMode: ClipMode.existingVideo,
          allMatchSegments: allSegments,
          favoritesMatchSegments: greatSegments.isNotEmpty
              ? greatSegments
              : allSegments,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger().e('Local detection failed: $e', stackTrace, e);
      await _markFailed(taskStorage, taskId, l10n.localDetectionFailed('$e'));
    }
  }

  /// Fallback for tasks persisted before `clipConfig` was stored on the task:
  /// recover it from the library's `ProcessVideoRecord` (id == taskId).
  static Future<VideoClipConfigReqVo?> _configFromLibrary(String taskId) async {
    try {
      final record = await LocalVideoStorage().findById(taskId);
      if (record is ProcessVideoRecord) {
        return record.videoClipConfigReqVo;
      }
    } catch (e) {
      AppLogger().w('Failed to recover clip config for $taskId: $e');
    }
    return null;
  }

  static Future<void> _markFailed(
    TaskStorage taskStorage,
    String taskId,
    String message,
  ) async {
    await taskStorage.tryUpdateTask(
      taskId,
      (oldTask) => (oldTask as VideoClipTask).copyWith(
        status: TaskStatusEnum.failed,
        supportsPause: false,
        extraInfo: message,
      ),
    );
  }
}
