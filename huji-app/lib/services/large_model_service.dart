import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:huji_app/models/large_model.dart';
import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/inference/onnx_model_predictor.dart';

import '../models/autoclip_models.dart';

/// 模型预测器接口
abstract class ModelPredictor {
  /// 预测单个帧
  Future<ActionType> predict(
    String framePath,
    Map<String, ActionType> classMappings,
  );

  Future<ActionType> predictWithBytes(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  );

  /// 分类 FFmpeg 输出的 letterboxed RGB24 裸帧文件（width×height×3 字节），
  /// 跳过图片解码，供视频抽帧推理走快路径。
  Future<ActionType> predictRgb24FromFile(
    String rgbFilePath,
    int width,
    int height,
    Map<String, ActionType> classMappings,
  );

  /// 预测单个帧并返回结果
  Future<ClassifierResult> predictForResult(
    String framePath,
    Map<String, ActionType> classMappings,
  );

  Future<ClassifierResult> predictWithBytesForResult(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  );

  /// 释放资源
  Future<void> dispose();
}

/// 大模型服务类
class LargeModelService {
  static final Logger _logger = Logger();

  static LargeModelService? _instance;
  static LargeModelService get instance => _instance ??= LargeModelService._();
  factory LargeModelService() => instance;

  /// Active ONNX spec for the current inference scope.
  InferenceSpec? _inferenceSpec;

  LargeModelService._();

  /// Run [action] with a resolved ONNX model on disk.
  ///
  /// 三端统一入口：调用方先通过 [OnnxModelAssetResolver.resolve] 把模型
  /// 落盘，再在此作用域内构造检测器；检测器构造时经 [getPredictor] 取到
  /// 基于该模型的 ONNX 预测器。
  Future<T> runWithInferenceSpec<T>({
    required InferenceSpec spec,
    required Future<T> Function() action,
  }) async {
    _inferenceSpec = spec;
    try {
      return await action();
    } finally {
      _inferenceSpec = null;
    }
  }

  /// 三端统一 ONNX 后唯一实现即 [OnnxModelPredictor]（移动端主 isolate、
  /// 桌面 worker isolate / 批处理 pool 都基于它）。
  OnnxModelPredictor getPredictor(String modelName) {
    final spec = _inferenceSpec;
    if (spec == null) {
      throw StateError(
        'Inference requires runWithInferenceSpec() before getPredictor()',
      );
    }

    // Not cached: batch pipeline disposes the predictor after each video.
    return OnnxModelPredictor(
      modelFilePath: spec.modelFilePath,
      fallbackClassNames: spec.classNames,
    );
  }

  Future<void> dispose() async {
    try {
      _logger.i('大模型服务资源已释放');
    } catch (e) {
      _logger.e('释放大模型服务资源失败: ${e.toString()}');
    }
  }
}
