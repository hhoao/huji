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

  /// CPU-only sessions: ORT op threads (see [OnnxInferenceEngine.cpuThreadCount]).
  final int? cpuThreadCount;

  OnnxInferenceEngine? _engine;
  Future<void>? _predictQueue;

  /// 复用的输入张量缓冲区（尺寸变化时重建）。
  /// 所有预测经 [_enqueue] 串行执行，复用安全。
  Float32List? _tensorBuffer;
  int _tensorWidth = 0;
  int _tensorHeight = 0;

  OnnxModelPredictor({
    required this.modelFilePath,
    required this.fallbackClassNames,
    this.cpuThreadCount,
  });

  Future<OnnxInferenceEngine> _ensureLoaded() async {
    if (_engine != null) return _engine!;
    final engine = OnnxInferenceEngine(cpuThreadCount: cpuThreadCount);
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
      final rgb = OnnxImagePreprocessor.decodeAndLetterbox(imageBytes);
      const size = OnnxImagePreprocessor.inputSize;
      return _classifyRgb24(rgb, size, size, classMappings);
    });
  }

  /// Classify a pre-letterboxed RGB24 frame (skips PNG decode / Dart resize).
  Future<ActionType> predictRgb24(
    Uint8List rgb,
    int width,
    int height,
    Map<String, ActionType> classMappings,
  ) async {
    final result = await predictRgb24ForResult(rgb, width, height, classMappings);
    return _mapClassName(result.classification.topClass, classMappings);
  }

  /// Classify a pre-letterboxed RGB24 frame file written by FFmpeg
  /// (exactly [width]*[height]*3 bytes per file).
  @override
  Future<ActionType> predictRgb24FromFile(
    String rgbFilePath,
    int width,
    int height,
    Map<String, ActionType> classMappings,
  ) async {
    final rgb = await File(rgbFilePath).readAsBytes();
    return predictRgb24(rgb, width, height, classMappings);
  }

  Future<ClassifierResult> predictRgb24ForResult(
    Uint8List rgb,
    int width,
    int height,
    Map<String, ActionType> classMappings,
  ) {
    final expected = OnnxImagePreprocessor.rgb24ByteLength(width, height);
    if (rgb.length < expected) {
      throw ArgumentError(
        'RGB24 buffer length ${rgb.length} < expected $expected for ${width}x$height',
      );
    }
    return _enqueue(() => _classifyRgb24(rgb, width, height, classMappings));
  }

  Future<ClassifierResult> _classifyRgb24(
    Uint8List rgb,
    int width,
    int height,
    Map<String, ActionType> classMappings,
  ) async {
    final stopwatch = Stopwatch()..start();
    final engine = await _ensureLoaded();
    final classNames = engine.classNames;

    final tensor = OnnxImagePreprocessor.toTensor(
      rgb,
      width,
      height,
      _tensorBufferFor(width, height),
    );
    final logits = await engine.predict(tensor, width, height);

    final (topIdx, topConfidence) = _topPrediction(logits, classNames.length);
    final topClass = classNames[topIdx];
    _mapClassName(topClass, classMappings);

    final topK = classNames.length < 5 ? classNames.length : 5;
    final top5 = _topK(logits, topK, classNames.length);
    stopwatch.stop();

    return ClassifierResult(
      imageSize: ImageSize(width: width, height: height),
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
  }

  /// 取（或按尺寸重建）复用的输入张量缓冲区，消除每帧 4.9MB 分配。
  Float32List _tensorBufferFor(int width, int height) {
    if (_tensorBuffer == null ||
        _tensorWidth != width ||
        _tensorHeight != height) {
      _tensorBuffer = Float32List(3 * width * height);
      _tensorWidth = width;
      _tensorHeight = height;
    }
    return _tensorBuffer!;
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
    _tensorBuffer = null;
  }
}
