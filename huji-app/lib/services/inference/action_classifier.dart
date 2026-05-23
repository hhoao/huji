import 'dart:typed_data';

import 'package:restcut/services/inference/action_segment_detector.dart';
import 'package:restcut/services/inference/image_preprocessor.dart';
import 'package:restcut/services/inference/onnx_inference_engine.dart';
import 'package:restcut/utils/logger_utils.dart';

/// Maps model output class index → ActionType.
class ClassMapping {
  final List<String> classNames;

  const ClassMapping(this.classNames);

  ActionType classify(int classIndex) {
    final name = classNames[classIndex].toLowerCase();
    if (name.contains('fire')) return ActionType.fireBall;
    if (name.contains('play')) return ActionType.playBall;
    if (name.contains('pick')) return ActionType.pickBall;
    if (name.contains('transition')) return ActionType.transition;
    throw ArgumentError('Unknown class: $name (index $classIndex)');
  }

  int get numClasses => classNames.length;
}

/// Ping pong normal: 3 classes (fire_ball, pick_ball, play_ball)
const pingPongNormalClassMapping = ClassMapping([
  'fire_ball',
  'pick_ball',
  'play_ball',
]);

/// Ping pong profession: 4 classes (fireball, pickball, playball, transition)
const pingPongClassMapping = ClassMapping([
  'fireball',
  'pickball',
  'playball',
  'transition',
]);

/// Badminton: 3 classes (pickball, playball, transition)
const badmintonClassMapping = ClassMapping([
  'pickball',
  'playball',
  'transition',
]);

/// Runs per-frame action classification using the ONNX model.
class ActionClassifier {
  final AppLogger _logger = AppLogger();
  final OnnxInferenceEngine _engine;
  final ClassMapping _classMapping;
  bool _loaded = false;

  ActionClassifier({
    required String modelPath,
    required ClassMapping classMapping,
    OnnxInferenceEngine? engine,
  })  : _engine = engine ?? OnnxInferenceEngine(),
        _classMapping = classMapping {
    _engine.loadModel(modelPath);
    _loaded = true;
    _logger.i('ActionClassifier loaded with ${classMapping.numClasses} classes');
  }

  /// Classify a single raw RGB24 frame (HWC, already 640x640).
  ActionType classifyFrame(Uint8List rgb, int width, int height) {
    if (!_loaded) throw StateError('Classifier not loaded');

    // Preprocess: RGB HWC → CHW float32 normalized
    final tensor = ImagePreprocessor.preprocess(rgb, width, height);

    // Run inference
    final logits = _engine.predict(tensor, width, height);

    // Argmax
    var maxIdx = 0;
    var maxVal = logits[0];
    for (var i = 1; i < _classMapping.numClasses; i++) {
      if (logits[i] > maxVal) {
        maxVal = logits[i];
        maxIdx = i;
      }
    }

    return _classMapping.classify(maxIdx);
  }

  bool get isLoaded => _loaded;

  void dispose() {
    _loaded = false;
    _engine.dispose();
  }
}
