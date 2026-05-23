import 'package:restcut/services/inference/action_classifier.dart';
import 'package:restcut/services/inference/action_segment_detector.dart';
import 'package:restcut/services/inference/frame_extractor.dart';
import 'package:restcut/utils/logger_utils.dart';

/// Result of the local inference pipeline.
class LocalInferenceResult {
  final List<Map<ActionType, ActionSegment>> matchSegments;
  final List<FramePrediction> framePredictions;
  final Duration processingTime;

  const LocalInferenceResult({
    required this.matchSegments,
    required this.framePredictions,
    required this.processingTime,
  });
}

/// Inference parameters for the pipeline.
class InferenceConfig {
  final String modelPath;
  final ClassMapping classMapping;
  final int fps;
  final int frameWidth;
  final int frameHeight;
  final double segmentIntervalSeconds;
  final int segmentWindowCount;
  final bool mergeFireBallAndPlayBall;

  const InferenceConfig({
    required this.modelPath,
    required this.classMapping,
    this.fps = 6,
    this.frameWidth = 640,
    this.frameHeight = 640,
    this.segmentIntervalSeconds = 2.0,
    this.segmentWindowCount = 5,
    this.mergeFireBallAndPlayBall = true,
  });
}

/// Progress callback during inference.
typedef ProgressCallback = void Function(double progress, String stage);

/// Full local inference pipeline: video → frames → classify → segments.
///
/// Equivalent to Python `AutoClipper._predict_video_action_points` +
/// `_convert_action_point_to_match_segments`.
class LocalInferencePipeline {
  final AppLogger _logger = AppLogger();
  final FrameExtractor _frameExtractor;

  LocalInferencePipeline({FrameExtractor? frameExtractor})
      : _frameExtractor = frameExtractor ?? FrameExtractor();

  /// Run the full inference pipeline on [videoPath].
  ///
  /// Steps:
  /// 1. Extract frames at [config.fps] fps, resized to [config.frameWidth]x[config.frameHeight]
  /// 2. Classify each frame using the ONNX model
  /// 3. Detect continuous play_ball segments
  /// 4. Return match segments
  Future<LocalInferenceResult> run({
    required String videoPath,
    required InferenceConfig config,
    ProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Extract frames
    onProgress?.call(0.0, 'Extracting frames...');
    final frames = await _frameExtractor.extractFramesRaw(
      videoPath: videoPath,
      fps: config.fps,
      width: config.frameWidth,
      height: config.frameHeight,
    );

    if (frames.isEmpty) {
      throw Exception('No frames extracted from video');
    }

    _logger.i('Extracted ${frames.length} frames');

    // Step 2: Classify each frame
    onProgress?.call(0.1, 'Loading model...');
    final classifier = ActionClassifier(
      modelPath: config.modelPath,
      classMapping: config.classMapping,
    );

    try {
      final predictions = <FramePrediction>[];
      final totalFrames = frames.length;

      for (var i = 0; i < totalFrames; i++) {
        final action = classifier.classifyFrame(
          frames[i],
          config.frameWidth,
          config.frameHeight,
        );

        final seconds = i / config.fps;
        predictions.add(FramePrediction(
          actionType: action,
          seconds: seconds,
        ));

        // Progress: 10% to 80% during classification
        final progress = 0.1 + (0.7 * (i + 1) / totalFrames);
        if (i % 50 == 0 || i == totalFrames - 1) {
          onProgress?.call(progress, 'Classifying... ${i + 1}/$totalFrames');
        }
      }

      // Step 3: Detect segments
      onProgress?.call(0.85, 'Detecting segments...');
      final detector = ActionSegmentDetector();

      final isPingPong = config.classMapping == pingPongClassMapping;
      final matchSegments = isPingPong
          ? detector.detectPingPongSegments(
              predictions,
              mergeFireBallAndPlayBall: config.mergeFireBallAndPlayBall,
              intervalSeconds: config.segmentIntervalSeconds,
              windowCount: config.segmentWindowCount,
            )
          : detector.detectBadmintonSegments(
              predictions,
              intervalSeconds: config.segmentIntervalSeconds,
              windowCount: config.segmentWindowCount,
            );

      stopwatch.stop();
      onProgress?.call(1.0, 'Done');

      _logger.i(
        'Inference complete: ${predictions.length} frames, '
        '${matchSegments.length} segments, '
        '${stopwatch.elapsed.inSeconds}s',
      );

      return LocalInferenceResult(
        matchSegments: matchSegments,
        framePredictions: predictions,
        processingTime: stopwatch.elapsed,
      );
    } finally {
      classifier.dispose();
    }
  }
}
