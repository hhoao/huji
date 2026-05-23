import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:logger/logger.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/core/action_segment_detector.dart';
import 'package:restcut/utils/time_utils.dart' as time_utils;
import 'package:synchronized/synchronized.dart';

import '../../models/autoclip_models.dart';
import '../../services/large_model_service.dart';

/// 实时动作片段检测结果监听器
typedef RealtimeSegmentListener =
    Future<void> Function(double? currentTime, SegmentInfo? segment);

/// 待预测任务
class _PendingPredictionTask {
  final String imagePath;
  final double timestamp;

  _PendingPredictionTask({required this.imagePath, required this.timestamp});
}

/// 实时动作片段检测器
abstract class RealtimeActionSegmentDetector<C extends VideoClipConfigReqVo>
    extends ActionSegmentDetector<C> {
  static final Logger _logger = Logger();

  /// 监听器列表
  final List<RealtimeSegmentListener> _listeners = [];

  /// 滑动窗口 - 按动作类型分组，用于判断动作持续状态
  final Map<ActionType, Queue<PredictedFrameInfo>> _actionWindows = {};

  /// 动作开始时间 - 记录每个动作类型的开始时间
  final Map<ActionType, double> _actionStartTimes = {};

  /// 是否正在运行
  bool _isRunning = false;

  /// 已检测到的片段
  final List<SegmentInfo> _detectedSegments = [];

  /// 模型预测器
  late ModelPredictor _modelPredictor;

  /// 类别映射
  late Map<String, ActionType> _classMappings;

  /// 窗口操作锁
  final Lock _queueLock = Lock(reentrant: true);

  /// 待预测任务队列
  final Queue<_PendingPredictionTask> _pendingPredictionQueue =
      Queue<_PendingPredictionTask>();

  /// 队列处理任务是否正在运行
  bool _isProcessingQueue = false;

  RealtimeActionSegmentDetector({
    required super.config,
    required super.largeModelService,
    required super.segmentDetectConfig,
  }) {
    _modelPredictor = largeModelService.getPredictor(
      getCurrentPredictModel(config),
    );
    _classMappings = getClassesMapping(config);
  }

  /// 添加监听器
  void addListener(RealtimeSegmentListener listener) {
    _listeners.add(listener);
  }

  /// 移除监听器
  void removeListener(RealtimeSegmentListener listener) {
    _listeners.remove(listener);
  }

  /// 获取已检测到的片段
  List<SegmentInfo> get detectedSegments =>
      List.unmodifiable(_detectedSegments);

  /// 开始实时检测
  Future<void> start() async {
    if (_isRunning) {
      _logger.w('实时检测器已在运行中');
      return;
    }

    _isRunning = true;
    _detectedSegments.clear();
    _clearAllWindows();

    _logger.i('开始实时动作检测');
  }

  /// 停止实时检测
  Future<void> stop({bool force = false}) async {
    if (!_isRunning) {
      _logger.w('实时检测器未在运行');
      return;
    }

    _isRunning = false;

    // 处理剩余的窗口数据
    if (!force) {
      await _processRemainingWindows();
    }
  }

  /// 添加预测结果（使用文件路径）
  Future<void> addPrediction(String imagePath, double timestamp) async {
    if (!_isRunning) {
      _logger.w('实时检测器未运行，无法添加预测');
      return;
    }
    _pendingPredictionQueue.add(
      _PendingPredictionTask(imagePath: imagePath, timestamp: timestamp),
    );
    _processPendingPredictionQueue();
  }

  Future<void> _processPendingPredictionQueue() async {
    if (!_isProcessingQueue && _pendingPredictionQueue.isNotEmpty) {
      await _queueLock.synchronized(() async {
        if (!_isProcessingQueue) {
          _isProcessingQueue = true;
          while (_pendingPredictionQueue.isNotEmpty) {
            final task = _pendingPredictionQueue.removeFirst();
            try {
              // 使用文件路径进行预测
              final actionType = await _modelPredictor.predict(
                task.imagePath,
                _classMappings,
              );
              final frameInfo = PredictedFrameInfo(
                actionType: actionType,
                seconds: task.timestamp,
              );
              await _addToWindow(frameInfo);
            } catch (e, stackTrace) {
              _logger.e('处理预测任务失败: $e', error: e, stackTrace: stackTrace);
              // 继续处理下一个任务
            }
          }
          _isProcessingQueue = false;
        }
      });
    }
  }

  /// 添加预测结果到滑动窗口
  Future<void> _addToWindow(PredictedFrameInfo frameInfo) async {
    log(
      "addToWindow: ${frameInfo.actionType}, ${time_utils.formatMillisecondsToHHMMSSS((frameInfo.seconds * 1000).toInt())}",
    );
    final actionType = frameInfo.actionType;

    // 初始化窗口（如果不存在）
    _actionWindows.putIfAbsent(actionType, () => Queue<PredictedFrameInfo>());

    // 添加到窗口
    _actionWindows[actionType]!.add(frameInfo);

    // 清理超出时间窗口的数据
    var cleanUpLatestAction = _cleanupWindow(actionType);

    // 检查动作状态变化
    await _checkActionStateChange(
      actionType,
      frameInfo.seconds,
      cleanUpLatestAction,
    );
  }

  /// 清理指定动作类型的窗口
  PredictedFrameInfo? _cleanupWindow(
    ActionType actionType, {
    bool forceClean = false,
  }) {
    final window = _actionWindows[actionType];
    if (window == null) {
      return null;
    }

    final segmentConfig = segmentDetectConfig[actionType];
    if (segmentConfig == null) {
      return null;
    }

    // 移除超出时间窗口的数据
    PredictedFrameInfo? latestAction;
    while (window.isNotEmpty &&
        (window.last.seconds - window.first.seconds >
                segmentConfig.intervalSeconds ||
            forceClean)) {
      latestAction = window.removeFirst();
    }
    return latestAction;
  }

  /// 检查动作状态变化
  /// 前一步会移除超出时间窗口的数据，这里需要检查是否需要继续移除
  /// 当前时间到窗口最后一个动作的时间的间隔大于intervalSeconds，则认为动作结束
  Future<void> _checkActionStateChange(
    ActionType actionType,
    double? currentActionSeconds,
    PredictedFrameInfo? cleanUpLatestAction,
  ) async {
    // 动作片段开始, 当窗口长度达到windowCount时，认为动作开始
    SegmentInfo? segment;
    if (!_actionStartTimes.containsKey(actionType)) {
      if (_actionWindows[actionType]!.length >=
          segmentDetectConfig[actionType]!.windowCount) {
        log(
          "Action start: $actionType, currTime: ${currentActionSeconds != null ? time_utils.formatMillisecondsToHHMMSSS((currentActionSeconds * 1000).toInt()) : 'null'}",
        );
        _actionStartTimes[actionType] =
            _actionWindows[actionType]!.first.seconds;
      }
    } else {
      // 判断动作是否结束
      final window = _actionWindows[actionType]!;

      final segmentConfig = segmentDetectConfig[actionType]!;

      final isCurrentlyOngoing = window.length >= segmentConfig.windowCount;

      if (!isCurrentlyOngoing) {
        // 动作结束
        final startSeconds = _actionStartTimes[actionType]!;
        final endSeconds = cleanUpLatestAction!.seconds;

        segment = SegmentInfo(
          actionType: actionType,
          startSeconds: startSeconds,
          endSeconds: endSeconds,
        );

        log(
          "Action end: ${segment.actionType} from ${time_utils.formatMillisecondsToHHMMSSS((startSeconds * 1000).toInt())} to ${time_utils.formatMillisecondsToHHMMSSS((endSeconds * 1000).toInt())}, duration: ${time_utils.formatMillisecondsToHHMMSSS((endSeconds * 1000).toInt() - (startSeconds * 1000).toInt())}",
        );

        _detectedSegments.add(segment);

        _actionStartTimes.remove(actionType);
      }
    }
    await _notifyListeners(currentActionSeconds, segment);
  }

  /// 处理剩余的窗口数据
  Future<void> _processRemainingWindows() async {
    await _processPendingPredictionQueue();
    await _queueLock.synchronized(() async {
      for (final entry in _actionWindows.entries) {
        final actionType = entry.key;
        final cleanUpLatestAction = _cleanupWindow(
          actionType,
          forceClean: true,
        );
        await _checkActionStateChange(actionType, null, cleanUpLatestAction);
      }
    });

    _clearAllWindows();
  }

  /// 通知所有监听器
  Future<void> _notifyListeners(
    double? currentTime,
    SegmentInfo? segment,
  ) async {
    for (final listener in _listeners) {
      try {
        await listener(currentTime, segment);
      } catch (e) {
        _logger.e('监听器回调异常: $e');
      }
    }
  }

  /// 清空所有窗口
  void _clearAllWindows() {
    _actionWindows.clear();
    _actionStartTimes.clear();
  }

  /// 获取当前窗口状态
  Map<ActionType, int> get windowStatus {
    return _actionWindows.map((key, value) => MapEntry(key, value.length));
  }

  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 获取检测到的片段数量
  int get detectedSegmentCount => _detectedSegments.length;

  /// 检查指定动作类型是否正在持续
  bool isActionOngoing(ActionType actionType) {
    return _actionStartTimes.containsKey(actionType);
  }

  /// 获取当前正在进行的动作类型列表
  List<ActionType> get ongoingActions {
    return _actionStartTimes.keys.toList();
  }

  /// 获取指定动作类型的持续时间
  double getActionDuration(ActionType actionType) {
    if (!_actionStartTimes.containsKey(actionType) ||
        _actionWindows[actionType] == null ||
        _actionWindows[actionType]!.isEmpty) {
      return 0.0;
    }

    final startTime = _actionStartTimes[actionType]!;
    return _actionWindows[actionType]!.last.seconds - startTime;
  }

  /// 获取指定动作类型的开始时间
  double? getActionStartTime(ActionType actionType) {
    return _actionStartTimes[actionType];
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    _listeners.clear();
    _detectedSegments.clear();
    _clearAllWindows();
  }
}
