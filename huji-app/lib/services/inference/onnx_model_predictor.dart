import 'dart:io';
import 'dart:typed_data';

import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/large_model.dart';
import 'package:huji_app/services/inference/onnx_image_preprocessor.dart';
import 'package:huji_app/services/inference/onnx_inference_engine.dart';
import 'package:huji_app/services/large_model_service.dart';

/// Desktop ONNX implementation of [ModelPredictor].
///
/// Loads models from on-disk paths only — asset resolution happens on the UI
/// isolate before inference workers are spawned.
class OnnxModelPredictor implements ModelPredictor {
  final String modelFilePath;
  final List<String> fallbackClassNames;

  OnnxInferenceEngine? _engine;
  Future<void>? _predictQueue;

  OnnxModelPredictor({
    required this.modelFilePath,
    required this.fallbackClassNames,
  });

  Future<OnnxInferenceEngine> _ensureLoaded() async {
    if (_engine != null) return _engine!;
    final engine = OnnxInferenceEngine();
    await engine.loadModelFromFile(
      modelFilePath,
      fallbackClassNames: fallbackClassNames,
    );
    _engine = engine;
    return engine;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final job = (_predictQueue ?? Future.value()).then((_) => operation());
    _predictQueue = job.then((_) {}, onError: (_) {});
    return job;
  }

  @override
  Future<ActionType> predict(
    String imagePath,
    Map<String, ActionType> classMappings,
  ) async {
    final imageBytes = await File(imagePath).readAsBytes();
    return predictWithBytes(imageBytes, classMappings);
  }

  @override
  Future<ActionType> predictWithBytes(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  ) async {
    final result = await predictWithBytesForResult(imageBytes, classMappings);
    return _mapClassName(result.classification.topClass, classMappings);
  }

  @override
  Future<ClassifierResult> predictForResult(
    String imagePath,
    Map<String, ActionType> classMappings,
  ) async {
    final imageBytes = await File(imagePath).readAsBytes();
    return predictWithBytesForResult(imageBytes, classMappings);
  }

  @override
  Future<ClassifierResult> predictWithBytesForResult(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  ) {
    return _enqueue(() async {
      final stopwatch = Stopwatch()..start();
      final engine = await _ensureLoaded();
      final classNames = engine.classNames;

      final rgb = OnnxImagePreprocessor.decodeAndLetterbox(imageBytes);
      const size = OnnxImagePreprocessor.inputSize;
      final tensor = OnnxImagePreprocessor.toTensor(rgb, size, size);
      final logits = await engine.predict(tensor, size, size);

      final (topIdx, topConfidence) = _topPrediction(logits, classNames.length);
      final topClass = classNames[topIdx];
      _mapClassName(topClass, classMappings);

      final topK = classNames.length < 5 ? classNames.length : 5;
      final top5 = _topK(logits, topK, classNames.length);
      stopwatch.stop();

      return ClassifierResult(
        imageSize: const ImageSize(width: size, height: size),
        classification: Classification(
          topClass: topClass,
          topConfidence: topConfidence,
          top5Classes: top5.map((e) => classNames[e.$1]).toList(),
          top5Confidences: top5.map((e) => e.$2).toList(),
        ),
        speed: stopwatch.elapsedMicroseconds / 1e6,
        detections: [
          Detection(
            classIndex: topIdx,
            className: topClass,
            confidence: topConfidence,
            boundingBox: const BoundingBox(left: 0, top: 0, right: 0, bottom: 0),
            normalizedBox: const BoundingBox(left: 0, top: 0, right: 0, bottom: 0),
          ),
        ],
      );
    });
  }

  ActionType _mapClassName(
    String className,
    Map<String, ActionType> classMappings,
  ) {
    final direct = classMappings[className];
    if (direct != null) return direct;

    final normalized = className.toLowerCase().replaceAll('_', '');
    for (final entry in classMappings.entries) {
      final key = entry.key.toLowerCase().replaceAll('_', '');
      if (key == normalized) return entry.value;
    }

    throw Exception('Unknown action type: $className');
  }

  (int, double) _topPrediction(Float32List logits, int numClasses) {
    final limit = numClasses.clamp(0, logits.length);
    if (limit == 0) return (0, 0.0);
    var bestIdx = 0;
    for (var i = 1; i < limit; i++) {
      if (logits[i] > logits[bestIdx]) bestIdx = i;
    }
    return (bestIdx, logits[bestIdx]);
  }

  List<(int, double)> _topK(Float32List logits, int k, int numClasses) {
    final limit = numClasses.clamp(0, logits.length);
    final indexed = List.generate(limit, (i) => (i, logits[i]));
    indexed.sort((a, b) => b.$2.compareTo(a.$2));
    return indexed.take(k.clamp(0, limit)).toList();
  }

  @override
  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _predictQueue = null;
  }
}
