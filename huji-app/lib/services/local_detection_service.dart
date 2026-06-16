import 'dart:io';
import 'dart:typed_data';

import 'package:huji_app/services/inference/action_segment_detector.dart';
import 'package:huji_app/services/inference/onnx_inference_engine.dart';
import 'package:huji_app/utils/logger_utils.dart';

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
/// Keys match the directory layout under assets/models/: <sport>/<match_type>.
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

/// Pure-Dart local YOLO inference engine using ONNX Runtime FFI.
///
/// Frame extraction uses the system `ffmpeg` binary (bundled with the app on
/// desktop).  Preprocessing, ONNX inference, and sliding-window segment
/// detection all run in Dart — no Python dependency.
class LocalDetectionService {
  final AppLogger _logger = AppLogger();
  final OnnxInferenceEngine _engine = OnnxInferenceEngine();
  final ActionSegmentDetector _detector = ActionSegmentDetector();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Check whether ONNX models are available on disk.
  Future<LocalModelStatus> checkModels() async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return LocalModelStatus.incompatible;
    }
    final modelsDir = _resolveModelsDir();
    if (modelsDir == null) return LocalModelStatus.notFound;

    final dir = Directory(modelsDir);
    if (!await dir.exists()) return LocalModelStatus.notFound;

    final entries =
        await dir.list(recursive: true).where((e) => e.path.endsWith('.onnx')).toList();
    if (entries.isEmpty) return LocalModelStatus.notFound;

    _logger.i('Found ${entries.length} local ONNX models');
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

    // 1. Resolve model
    final modelsDir = _resolveModelsDir();
    if (modelsDir == null) throw Exception('Models directory not found');

    final modelPath = '$modelsDir/$sportType/$matchType/best.onnx';
    if (!File(modelPath).existsSync()) {
      throw Exception('Model not found: $modelPath');
    }

    // 2. Extract frames via ffmpeg
    onProgress?.call(0.0, '正在抽帧…');
    final tmpdir = await _extractFrames(videoPath);
    try {
      final frameFiles = _listFrames(tmpdir);
      final frameCount = frameFiles.length;
      if (frameCount == 0) throw Exception('No frames extracted from video');

      // 3. Load ONNX model
      onProgress?.call(0.05, '加载模型…');
      final classKey = '$sportType/$matchType';
      final classMap =
          _classMaps[classKey] ?? _classMaps['ping_pong/normal']!;
      _engine.loadModel(modelPath);

      try {
        // 4. Classify every frame
        onProgress?.call(0.1, '正在分析视频…');
        final predictions = <FramePrediction>[];

        for (var i = 0; i < frameCount; i++) {
          final raw = await File(frameFiles[i]).readAsBytes();
          final tensor = _preprocess(raw, _frameW, _frameH);
          final logits = _engine.predict(tensor, _frameW, _frameH);
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

        // 5. Detect segments using the existing pipeline
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
        _engine.dispose();
      }
    } finally {
      // Clean up temp frames
      try {
        await Directory(tmpdir).delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Run inference in a separate isolate. Parameters are sendable so this
  /// can be passed to Isolate.run.
  static Future<Map<String, dynamic>> runInferenceInIsolate(
    Map<String, String> params,
  ) async {
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
  }

  // ---------------------------------------------------------------------------
  // Path resolution
  // ---------------------------------------------------------------------------

  /// Models directory: env var → Flutter asset bundle.
  String? _resolveModelsDir() {
    final fromEnv = Platform.environment['HUJI_MODELS_DIR'];
    if (fromEnv != null && fromEnv.isNotEmpty && Directory(fromEnv).existsSync()) {
      return fromEnv;
    }
    final execDir = File(Platform.resolvedExecutable).parent.path;
    final bundled = '$execDir/data/flutter_assets/assets/models';
    if (Directory(bundled).existsSync()) return bundled;
    return null;
  }

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

  // ---------------------------------------------------------------------------
  // Frame extraction
  // ---------------------------------------------------------------------------

  /// Extract raw RGB24 frames from [videoPath] into a temp directory.
  ///
  /// Returns the temp directory path.  Caller is responsible for cleanup.
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

  /// List extracted frame files in order.
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

  // ---------------------------------------------------------------------------
  // Preprocessing
  // ---------------------------------------------------------------------------

  /// Convert raw RGB24 bytes → Float32List in CHW layout, normalized to [0,1].
  ///
  /// YOLO11n-cls models use identity normalization (mean=0, std=1), so the
  /// only preprocessing required is uint8→float32 scaling.
  Float32List _preprocess(Uint8List raw, int w, int h) {
    final chw = Float32List(3 * w * h);
    final pixels = w * h;
    for (var i = 0; i < pixels; i++) {
      final r = raw[i * 3] / 255.0;
      final g = raw[i * 3 + 1] / 255.0;
      final b = raw[i * 3 + 2] / 255.0;
      chw[i] = r;              // R channel
      chw[pixels + i] = g;     // G channel
      chw[2 * pixels + i] = b; // B channel
    }
    return chw;
  }

  /// Argmax over a Float32List.
  int _argmax(Float32List values) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }
}
