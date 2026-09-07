import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/inference/inference_model_registry.dart';

/// Extracts bundled ncnn assets to stable on-disk paths on the UI isolate.
///
/// Worker isolates receive the resulting [InferenceSpec] and load models
/// via file path only — never through [rootBundle].
class NcnnModelAssetResolver {
  NcnnModelAssetResolver._();

  static Directory get _cacheDir => Directory(
        path.join(Directory.systemTemp.path, 'huji_ncnn_models'),
      );

  /// Resolve sport/match to cached ncnn files plus fallback class names.
  static Future<InferenceSpec> resolve({
    required String sportType,
    required String matchType,
  }) async {
    final assetKeys = InferenceModelRegistry.ncnnAssetKeysFor(
      sportType,
      matchType,
    );
    final classNames =
        InferenceModelRegistry.classNamesFor(sportType, matchType);

    await _cacheDir.create(recursive: true);
    final cacheSubDir = Directory(
      path.join(_cacheDir.path, '${sportType}_$matchType'),
    );
    await cacheSubDir.create(recursive: true);

    for (final entry in assetKeys.entries) {
      final file = File(path.join(cacheSubDir.path, entry.key));
      if (!await file.exists() || await file.length() == 0) {
        final data = await rootBundle.load(entry.value);
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
    }

    return InferenceSpec(
      paramFilePath: path.join(cacheSubDir.path, 'model.ncnn.param'),
      binFilePath: path.join(cacheSubDir.path, 'model.ncnn.bin'),
      classNames: classNames,
      sportType: sportType,
      matchType: matchType,
    );
  }
}
