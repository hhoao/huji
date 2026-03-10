import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:restcut/config/environment.dart';
import 'package:restcut/models/large_model.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:ultralytics_yolo/yolo.dart';

import '../constants/autoclip_constants.dart';
import '../models/autoclip_models.dart';

class FastModelPredictor implements ModelPredictor {
  final String _modelPath;
  YOLO? _modelCache;

  FastModelPredictor(this._modelPath);

  @override
  Future<ActionType> predictWithBytes(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  ) async {
    final model = _getModel();
    final result = await model.predict(imageBytes);
    final top1 = result["detections"][0]["className"];
    final actionType = classMappings[top1];

    if (actionType == null) {
      throw Exception('Unknown action type: $top1');
    }
    return actionType;
  }

  @override
  Future<ClassifierResult> predictWithBytesForResult(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  ) async {
    final model = _getModel();
    final result = await model.predict(imageBytes);

    final classifierResult = ClassifierResult.fromJson(result);

    if (EnvironmentConfig.isDevelopment) {
      final speed = classifierResult.speed;
      final classificationName = classifierResult.classification.topClass;
      final classificationConfidence =
          classifierResult.classification.topConfidence;
      AppLogger().d(
        "speed: ${speed * 1000}ms, classificationName: $classificationName, classificationConfidence: $classificationConfidence",
      );
    }

    return classifierResult;
  }

  @override
  Future<ActionType> predict(
    String imagePath,
    Map<String, ActionType> classMappings,
  ) async {
    final imageBytes = File(imagePath).readAsBytesSync();

    final actionType = await predictWithBytes(imageBytes, classMappings);

    return actionType;
  }

  @override
  Future<ClassifierResult> predictForResult(
    String imagePath,
    Map<String, ActionType> classMappings,
  ) async {
    final imageBytes = File(imagePath).readAsBytesSync();
    final classifierResult = await predictWithBytesForResult(
      imageBytes,
      classMappings,
    );
    return classifierResult;
  }

  YOLO _getModel() {
    if (_modelCache != null) {
      return _modelCache!;
    }
    _modelCache = YOLO(modelPath: _modelPath, task: YOLOTask.classify);
    _modelCache!.loadModel();
    return _modelCache!;
  }

  @override
  Future<void> dispose() async {
    await _modelCache?.dispose();
    _modelCache = null;
    return;
  }
}

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

  final Map<String, ModelPredictor> _predictorCache = {};

  LargeModelService._();

  final Map<String, String> _modelNamePathMapping =
      AutoclipConstants.modelNamePathMapping;

  ModelPredictor getPredictor(String modelName) {
    if (_predictorCache.containsKey(modelName)) {
      return _predictorCache[modelName]!;
    }
    final predictor = FastModelPredictor(getModelPath(modelName));
    _predictorCache[modelName] = predictor;
    return predictor;
  }

  String getModelPath(String modelName) {
    if (!_modelNamePathMapping.containsKey(modelName)) {
      throw Exception('模型不存在: $modelName');
    }
    return _modelNamePathMapping[modelName]!;
  }

  Future<void> dispose() async {
    try {
      _logger.i('大模型服务资源已释放');
    } catch (e) {
      _logger.e('释放大模型服务资源失败: ${e.toString()}');
    }
  }
}
