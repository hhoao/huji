import 'dart:async';
import 'dart:io';

import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/core/batch/badminton_batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/pingpong_batch_action_segment_detector.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/large_model_service.dart';
import 'package:huji_app/services/local_detection_isolate.dart';
import 'package:huji_app/services/progress_handler.dart';

enum LocalModelStatus { available, notFound, incompatible }

/// Result from local batch autoclip (same shape as mobile pipeline output).
class LocalDetectionResult {
  final VideoClipOutputInfo clipOutput;
  final Duration processingTime;

  const LocalDetectionResult({
    required this.clipOutput,
    required this.processingTime,
  });
}

/// Desktop local detection — reuses the mobile batch autoclip pipeline with ONNX.
class LocalDetectionService {
  static Future<void>? _inferenceQueue;

  Future<LocalModelStatus> checkModels() async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return LocalModelStatus.incompatible;
    }
    return LocalModelStatus.available;
  }

  /// Run full batch autoclip pipeline (frame extract → classify → segment filter).
  Future<LocalDetectionResult> runAutoclip({
    required String videoPath,
    required VideoClipConfigReqVo clipConfig,
    required String sportTypeKey,
    required String matchType,
    ProgressHandler? progressHandler,
    ProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final largeModelService = LargeModelService.instance;
    final detector = _createDetector(clipConfig, largeModelService);
    final completer = Completer<VideoClipOutputInfo>();

    final handler = progressHandler ??
        ProgressHandler(
          onProgress: onProgress,
          onComplete: (result) {
            if (!completer.isCompleted) {
              completer.complete(result as VideoClipOutputInfo);
            }
          },
          onError: (error, details) {
            if (!completer.isCompleted) {
              completer.completeError(Exception('$error${details.isNotEmpty ? ': $details' : ''}'));
            }
          },
        );

    await largeModelService.runWithDesktopScope(
      sportType: sportTypeKey,
      matchType: matchType,
      action: () => detector.autoclipVideo(
        inputVideoPath: videoPath,
        progressHandler: handler,
      ),
    );

    stopwatch.stop();
    final output = await completer.future;
    return LocalDetectionResult(
      clipOutput: output,
      processingTime: stopwatch.elapsed,
    );
  }

  BatchActionSegmentDetector<VideoClipConfigReqVo> _createDetector(
    VideoClipConfigReqVo clipConfig,
    LargeModelService largeModelService,
  ) {
    if (clipConfig is PingPongVideoClipConfigReqVo) {
      return PingPongBatchActionSegmentDetector(
        config: clipConfig,
        largeModelService: largeModelService,
      );
    }
    if (clipConfig is BadmintonVideoClipConfigReqVo) {
      return BadmintonBatchActionSegmentDetector(
        config: clipConfig,
        largeModelService: largeModelService,
      );
    }
    throw ArgumentError('Unsupported clip config: ${clipConfig.runtimeType}');
  }

  /// Serialize concurrent local detection jobs (one ONNX session at a time).
  static Future<LocalDetectionResult> runInferenceAsync({
    required String videoPath,
    required VideoClipConfigReqVo clipConfig,
    required String sportTypeKey,
    required String matchType,
    ProgressCallback? onProgress,
  }) {
    final job = (_inferenceQueue ?? Future.value()).then((_) async {
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        return LocalDetectionIsolateRunner.run(
          videoPath: videoPath,
          clipConfig: clipConfig,
          sportTypeKey: sportTypeKey,
          matchType: matchType,
          onProgress: onProgress,
        );
      }
      final service = LocalDetectionService();
      return service.runAutoclip(
        videoPath: videoPath,
        clipConfig: clipConfig,
        sportTypeKey: sportTypeKey,
        matchType: matchType,
        onProgress: onProgress,
      );
    });
    _inferenceQueue = job.then((_) {}, onError: (_) {});
    return job;
  }
}
