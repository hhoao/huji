import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/inference/inference_model_registry.dart';

/// Extracts bundled ONNX assets to stable on-disk paths on the UI isolate.
///
/// Worker isolates receive the resulting [InferenceSpec] and load models
/// via file path only — never through [rootBundle].
class OnnxModelAssetResolver {
  OnnxModelAssetResolver._();

  static Directory get _cacheDir => Directory(
        path.join(Directory.systemTemp.path, 'huji_onnx_models'),
      );

  /// Resolve sport/match to a cached ONNX file plus fallback class names.
  ///
  /// 移动端优先选 fp16 混合精度导出（`best_fp16.onnx`，内部 fp16 权重 +
  /// fp32 边界 Cast）：XNNPACK 的 fp16 卷积在小分类模型上明显更快；
  /// 缺失时回退 fp32 的 `best.onnx`（桌面/极端情况）。
  static Future<InferenceSpec> resolve({
    required String sportType,
    required String matchType,
  }) async {
    // fp16 回退中：Android XNNPACK + fp16 首次 session.run 不返回（实测
    // 2026-09，任务卡死在第一帧）。fp16 资产和 preferFp16 开关保留，
    // 待 XNNPACK fp16 验证通过后再按平台开启。
    final assetKey = InferenceModelRegistry.onnxAssetFor(
      sportType,
      matchType,
      preferFp16: false,
    );
    final classNames =
        InferenceModelRegistry.classNamesFor(sportType, matchType);

    await _cacheDir.create(recursive: true);
    final cacheFileName = assetKey.replaceAll('/', '_');
    final modelFile = File(path.join(_cacheDir.path, cacheFileName));

    if (!await modelFile.exists() || await modelFile.length() == 0) {
      try {
        final data = await rootBundle.load(assetKey);
        await modelFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      } on FlutterError {
        // fp16 变体不存在（或加载失败）→ 回退 fp32
        if (!assetKey.endsWith('_fp16.onnx')) rethrow;
        return resolveFallbackFp32(sportType: sportType, matchType: matchType);
      }
    }

    return InferenceSpec(
      modelFilePath: modelFile.path,
      classNames: classNames,
      sportType: sportType,
      matchType: matchType,
    );
  }

  static Future<InferenceSpec> resolveFallbackFp32({
    required String sportType,
    required String matchType,
  }) async {
    final assetKey = InferenceModelRegistry.onnxAssetFor(
      sportType,
      matchType,
      preferFp16: false,
    );
    final classNames =
        InferenceModelRegistry.classNamesFor(sportType, matchType);

    final cacheFileName = assetKey.replaceAll('/', '_');
    final modelFile = File(path.join(_cacheDir.path, cacheFileName));
    if (!await modelFile.exists() || await modelFile.length() == 0) {
      final data = await rootBundle.load(assetKey);
      await modelFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return InferenceSpec(
      modelFilePath: modelFile.path,
      classNames: classNames,
      sportType: sportType,
      matchType: matchType,
    );
  }
}
