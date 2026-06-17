import 'dart:io';
import 'dart:typed_data';

import 'package:huji_app/services/inference/action_segment_detector.dart';
import 'package:huji_app/services/inference/onnx_inference_engine.dart';

enum LocalModelStatus { available, notFound, incompatible }

/// Result from local inference.
class LocalInferenceResult {
  final List<Map<String, dynamic>> matchSegments;
  final int frameCount;
  final Duration processingTime;

  const LocalInferenceResult({
    required this.matchSegments,
    required this.frameCount,
    required this.processingTime,
  });
}

/// Per-model class-index → ActionType mapping.
///
/// Derived from the ONNX model metadata (ultralytics YOLO export).
/// Keys match the directory layout under assets/models/: `<sport>/<match_type>`.
const _classMaps = <String, Map<int, ActionType>>{
  'ping_pong/normal': {0: ActionType.fireBall, 1: ActionType.pickBall, 2: ActionType.playBall},
  'ping_pong/profession': {0: ActionType.fireBall, 1: ActionType.pickBall, 2: ActionType.playBall, 3: ActionType.transition},
  'badminton/singles': {0: ActionType.pickBall, 1: ActionType.playBall, 2: ActionType.transition},
  'badminton/doubles': {0: ActionType.pickBall, 1: ActionType.playBall, 2: ActionType.transition},
};

/// Inference frame rate and resolution.
const _fps = 6;
const _frameW = 640;
const _frameH = 640;

/// Local YOLO inference on desktop using flutter_onnxruntime.
///
/// Frame extraction uses the system `ffmpeg` binary (bundled with the app on
/// desktop). Preprocessing, ONNX inference, and sliding-window segment detection
/// run asynchronously without blocking the UI.
class LocalDetectionService {
  final ActionSegmentDetector _detector = ActionSegmentDetector();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether bundled ONNX models are available on this platform.
  Future<LocalModelStatus> checkModels() async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return LocalModelStatus.incompatible;
    }
    return LocalModelStatus.available;
  }

  /// Run local inference on a video file.
  ///
  /// [sportType] is the sport directory name (e.g. "ping_pong", "badminton").
  /// [matchType] is the match-type directory (e.g. "normal", "profession").
  Future<LocalInferenceResult> runInference({
    required String videoPath,
    required String sportType,
    required String matchType,
    void Function(double progress, String stage)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    final modelAsset = OnnxInferenceEngine.modelAssetFor(sportType, matchType);

    onProgress?.call(0.0, '正在抽帧…');
    final tmpdir = await _extractFrames(videoPath);
    try {
      final frameFiles = _listFrames(tmpdir);
      final frameCount = frameFiles.length;
      if (frameCount == 0) throw Exception('No frames extracted from video');

      onProgress?.call(0.05, '加载模型…');
      final classKey = '$sportType/$matchType';
      final classMap =
          _classMaps[classKey] ?? _classMaps['ping_pong/normal']!;
      final numClasses = classMap.length;

      final engine = OnnxInferenceEngine();
      await engine.loadModelFromAsset(modelAsset);

      try {
        onProgress?.call(0.1, '正在分析视频…');
        final predictions = <FramePrediction>[];

        for (var i = 0; i < frameCount; i++) {
          final raw = await File(frameFiles[i]).readAsBytes();
          final tensor = _preprocess(raw, _frameW, _frameH);
          final logits = await engine.predict(
            tensor,
            _frameW,
            _frameH,
            numClasses: numClasses,
          );
          final actionType = classMap[_argmax(logits)] ?? ActionType.transition;
          predictions.add(
            FramePrediction(actionType: actionType, seconds: i / _fps),
          );

          if (i % 50 == 0) {
            onProgress?.call(
              0.1 + 0.7 * (i / frameCount),
              '分析中… ${i + 1}/$frameCount',
            );
          }
        }

        onProgress?.call(0.8, '检测片段…');

        final segments = sportType == 'badminton'
            ? _detector.detectBadmintonSegments(predictions)
            : _detector.detectPingPongSegments(predictions);

        onProgress?.call(1.0, '完成');

        return LocalInferenceResult(
          matchSegments: segments
              .map((m) => m.entries
                  .map((e) => {
                        'start': e.value.startSeconds,
                        'end': e.value.endSeconds,
                        'action': e.key.name,
                      })
                  .first)
              .toList(),
          frameCount: frameCount,
          processingTime: stopwatch.elapsed,
        );
      } finally {
        await engine.dispose();
      }
    } finally {
      try {
        await Directory(tmpdir).delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Serialize concurrent local detection jobs (one ONNX session at a time).
  static Future<void>? _inferenceQueue;

  /// Run local detection asynchronously without blocking the UI thread.
  static Future<Map<String, dynamic>> runInferenceAsync(
    Map<String, String> params,
  ) {
    final job = (_inferenceQueue ?? Future.value()).then((_) async {
      final service = LocalDetectionService();
      final result = await service.runInference(
        videoPath: params['videoPath']!,
        sportType: params['sportType']!,
        matchType: params['matchType']!,
      );
      return {
        'matchSegments': result.matchSegments,
        'frameCount': result.frameCount,
        'processingTimeMs': result.processingTime.inMilliseconds,
      };
    });
    _inferenceQueue = job.then((_) {}, onError: (_) {});
    return job;
  }

  // ---------------------------------------------------------------------------
  // Frame extraction
  // ---------------------------------------------------------------------------

  /// ffmpeg binary: env var → AppDir (AppImage) → PATH.
  String _resolveFfmpeg() {
    final fromEnv = Platform.environment['HUJI_FFMPEG_PATH'];
    if (fromEnv != null && fromEnv.isNotEmpty && File(fromEnv).existsSync()) {
      return fromEnv;
    }
    final appDir = Platform.environment['APPDIR'];
    if (appDir != null && appDir.isNotEmpty) {
      final bundled = '$appDir/usr/bin/ffmpeg';
      if (File(bundled).existsSync()) return bundled;
    }
    return 'ffmpeg';
  }

  Future<String> _extractFrames(String videoPath) async {
    final tmpdir = Directory.systemTemp.createTempSync('huji_frames_').path;
    final ffmpeg = _resolveFfmpeg();

    final vf = 'fps=$_fps,'
        'scale=$_frameW:$_frameH:force_original_aspect_ratio=decrease,'
        'pad=$_frameW:$_frameH:(ow-iw)/2:(oh-ih)/2';

    final result = await Process.run(ffmpeg, [
      '-loglevel', 'error',
      '-i', videoPath,
      '-vf', vf,
      '-f', 'image2',
      '-vcodec', 'rawvideo',
      '-pix_fmt', 'rgb24',
      '$tmpdir/frame_%06d.rgb',
    ], stdoutEncoding: null, stderrEncoding: null);

    if (result.exitCode != 0) {
      final err = result.stderr?.toString() ?? 'unknown error';
      throw Exception('ffmpeg extract failed: $err');
    }

    return tmpdir;
  }

  List<String> _listFrames(String tmpdir) {
    final dir = Directory(tmpdir);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.rgb'))
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files.map((f) => f.path).toList();
  }

  Float32List _preprocess(Uint8List raw, int w, int h) {
    final chw = Float32List(3 * w * h);
    final pixels = w * h;
    for (var i = 0; i < pixels; i++) {
      final r = raw[i * 3] / 255.0;
      final g = raw[i * 3 + 1] / 255.0;
      final b = raw[i * 3 + 2] / 255.0;
      chw[i] = r;
      chw[pixels + i] = g;
      chw[2 * pixels + i] = b;
    }
    return chw;
  }

  int _argmax(Float32List values) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }
}
