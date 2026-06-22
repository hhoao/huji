import 'dart:async';

import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/core/batch/badminton_batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/pingpong_batch_action_segment_detector.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/inference/desktop_inference_spec.dart';
import 'package:huji_app/services/inference/onnx_model_asset_resolver.dart';
import 'package:huji_app/services/large_model_service.dart';
import 'package:huji_app/services/local_detection_isolate.dart';
import 'package:huji_app/services/platform_capability.dart';
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
    if (!PlatformCapability.isDesktop) {
      return LocalModelStatus.incompatible;
    }
    return LocalModelStatus.available;
  }

  /// Run full batch autoclip pipeline (frame extract → classify → segment filter).
  ///
  /// On desktop, [desktopInferenceSpec] must be provided (or resolvable via
  /// [sportTypeKey] + [matchType] on the UI isolate only).
  Future<LocalDetectionResult> runAutoclip({
    required String videoPath,
    required VideoClipConfigReqVo clipConfig,
    DesktopInferenceSpec? desktopInferenceSpec,
    String? sportTypeKey,
    String? matchType,
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
              completer.completeError(
                Exception('$error${details.isNotEmpty ? ': $details' : ''}'),
              );
            }
          },
        );

    Future<void> runPipeline() => detector.autoclipVideo(
          inputVideoPath: videoPath,
          progressHandler: handler,
        );

    if (PlatformCapability.isDesktop) {
      final spec = desktopInferenceSpec ??
          await OnnxModelAssetResolver.resolve(
            sportType: sportTypeKey!,
            matchType: matchType!,
          );
      await largeModelService.runWithDesktopSpec(
        spec: spec,
        action: runPipeline,
      );
    } else {
      await runPipeline();
    }

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
      if (PlatformCapability.isDesktop) {
        final inferenceSpec = await OnnxModelAssetResolver.resolve(
          sportType: sportTypeKey,
          matchType: matchType,
        );
        return LocalDetectionIsolateRunner.run(
          videoPath: videoPath,
          clipConfig: clipConfig,
          inferenceSpec: inferenceSpec,
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
