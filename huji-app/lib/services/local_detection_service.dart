import 'dart:async';

import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/core/batch/badminton_batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/batch_action_segment_detector.dart';
import 'package:huji_app/core/batch/pingpong_batch_action_segment_detector.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/inference/inference_spec.dart';
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

    final spec =
        desktopInferenceSpec ??
        await OnnxModelAssetResolver.resolve(
          sportType: sportTypeKey!,
          matchType: matchType!,
        );
    await largeModelService.runWithInferenceSpec(
      spec: spec,
      action: runPipeline,
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
      // macOS 走 FFmpegKit（worker isolate 里插件的 EventChannel 订阅
      // 会崩），与 Android 一样在主 isolate 跑：ffmpeg 在 native 线程执行，
      // ONNX 推理经 flutter_onnxruntime 的后台 taskQueue 也不阻塞 UI。
      // Linux/Windows 桌面保留 worker isolate（外部 ffmpeg 子进程 + 推理
      // 读帧是重 CPU，需要离开主 isolate）。
      if (PlatformCapability.isDesktop &&
          !PlatformCapability.supportsFFmpegKit) {
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
