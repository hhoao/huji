import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/core/batch/badminton_batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/pingpong_batch_action_segment_detector.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
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

/// Desktop local detection — reuses the mobile batch autoclip pipeline with ncnn.
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
  /// [desktopInferenceSpec] may be provided to skip asset resolution; otherwise
  /// the model is resolved via [sportTypeKey] + [matchType] on the UI isolate.
  Future<LocalDetectionResult> runAutoclip({
    required String videoPath,
    required VideoClipConfigReqVo clipConfig,
    InferenceSpec? desktopInferenceSpec,
    String? sportTypeKey,
    String? matchType,
    ProgressHandler? progressHandler,
    ProgressCallback? onProgress,
    @visibleForTesting
    BatchActionSegmentDetector<VideoClipConfigReqVo>? detectorOverride,
  }) async {
    final stopwatch = Stopwatch()..start();
    final largeModelService = LargeModelService.instance;
    final detector =
        detectorOverride ?? _createDetector(clipConfig, largeModelService);
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

    final spec =
        desktopInferenceSpec ??
        await NcnnModelAssetResolver.resolve(
          sportType: sportTypeKey!,
          matchType: matchType!,
        );

    // Attach the result listener BEFORE the pipeline runs. The pipeline
    // rethrows every failure after the detector already routed it through
    // ProgressHandler.reportError into [completer]; if nothing listens on
    // completer.future at propagation time, that error surfaces as an
    // unhandled async error — which kills the worker isolate before its
    // 'error' reply reaches the UI, leaving the task stuck at "detecting"
    // forever.
    final resultFuture = completer.future.then<LocalDetectionResult>((output) {
      stopwatch.stop();
      return LocalDetectionResult(
        clipOutput: output,
        processingTime: stopwatch.elapsed,
      );
    });

    // The pipeline rethrows every failure after the detector already routed
    // it through ProgressHandler.reportError into [completer]. Supervise it
    // without gating [resultFuture] on it: every outcome must funnel into
    // the completer, and the listener chain completer.future → resultFuture
    // → the caller's await has to be fully attached before the pipeline
    // starts — an error propagating across a gap (e.g. while this function
    // is still awaiting the pipeline) surfaces as an unhandled async error,
    // which kills the worker isolate before its 'error' reply reaches the
    // UI and leaves the task stuck at "detecting" forever.
    unawaited(
      largeModelService
          .runWithInferenceSpec(spec: spec, action: runPipeline)
          .then<void>(
            (_) {
              // Finished without any handler report (e.g. an externally
              // supplied progressHandler) — fail instead of hanging.
              if (!completer.isCompleted) {
                completer.completeError(
                  StateError('Local detection finished without reporting a result'),
                );
              }
            },
            onError: (Object e, StackTrace st) {
              // Only forward errors the handler never reported (e.g.
              // VideoUtils.getVideoInfo failing before handleVideo runs).
              if (!completer.isCompleted) {
                completer.completeError(
                  e is Exception ? e : Exception(e.toString()),
                  st,
                );
              }
            },
          ),
    );

    return resultFuture;
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

  /// Serialize concurrent local detection jobs (one ncnn net at a time).
  static Future<LocalDetectionResult> runInferenceAsync({
    required String videoPath,
    required VideoClipConfigReqVo clipConfig,
    required String sportTypeKey,
    required String matchType,
    ProgressCallback? onProgress,
  }) {
    final job = (_inferenceQueue ?? Future.value()).then((_) async {
      // macOS 走 FFmpegKit（worker isolate 里插件的 EventChannel 订阅
      // 会崩），与 Android 一样在主 isolate 跑：ffmpeg 在 native 线程执行，
      // ncnn 推理经 FFI 在 native 线程池执行也不阻塞 UI。
      // Linux/Windows 桌面保留 worker isolate（外部 ffmpeg 子进程 + 推理
      // 读帧是重 CPU，需要离开主 isolate）。
      if (PlatformCapability.isDesktop &&
          !PlatformCapability.supportsFFmpegKit) {
        final inferenceSpec = await NcnnModelAssetResolver.resolve(
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
