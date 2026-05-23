import 'package:flutter/material.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/large_model_service.dart';

abstract class ActionSegmentDetector<C extends VideoClipConfigReqVo> {
  /// 配置参数
  final C config;

  /// 片段检测配置
  final Map<ActionType, SegmentDetectorConfig> segmentDetectConfig;

  /// 大模型服务
  final LargeModelService largeModelService;

  ActionSegmentDetector({
    required this.config,
    required this.segmentDetectConfig,
    required this.largeModelService,
  });

  /// 获取当前预测模型（抽象方法）
  @protected
  String getCurrentPredictModel(C clipConfig);

  /// 获取类映射（抽象方法）
  @protected
  Map<String, ActionType> getClassesMapping(C clipConfig);
}
