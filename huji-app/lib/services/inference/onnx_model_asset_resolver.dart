import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'package:huji_app/services/inference/desktop_inference_spec.dart';
import 'package:huji_app/services/inference/inference_model_registry.dart';

/// Extracts bundled ONNX assets to stable on-disk paths on the UI isolate.
///
/// Worker isolates receive the resulting [DesktopInferenceSpec] and load models
/// via file path only — never through [rootBundle].
class OnnxModelAssetResolver {
  OnnxModelAssetResolver._();

  static Directory get _cacheDir => Directory(
        path.join(Directory.systemTemp.path, 'huji_onnx_models'),
      );

  /// Resolve sport/match to a cached ONNX file plus fallback class names.
  static Future<DesktopInferenceSpec> resolve({
    required String sportType,
    required String matchType,
  }) async {
    final assetKey = InferenceModelRegistry.onnxAssetFor(sportType, matchType);
    final classNames =
        InferenceModelRegistry.classNamesFor(sportType, matchType);

    await _cacheDir.create(recursive: true);
    final cacheFileName = assetKey.replaceAll('/', '_');
    final modelFile = File(path.join(_cacheDir.path, cacheFileName));

    if (!await modelFile.exists() || await modelFile.length() == 0) {
      final data = await rootBundle.load(assetKey);
      await modelFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

    return DesktopInferenceSpec(
      modelFilePath: modelFile.path,
      classNames: classNames,
      sportType: sportType,
      matchType: matchType,
    );
  }
}
