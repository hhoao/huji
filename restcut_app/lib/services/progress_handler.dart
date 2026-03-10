import 'package:logger/logger.dart';
import 'package:restcut/models/task.dart';

/// 进度回调函数类型
typedef ProgressCallback = void Function(double progress, String message);

/// 状态回调函数类型
typedef StatusCallback = void Function(TaskStatusEnum status, String message);

/// 错误回调函数类型
typedef ErrorCallback = void Function(String error, String details);

/// 完成回调函数类型
typedef CompleteCallback = void Function(dynamic result);

/// 进度处理器类
class ProgressHandler {
  static final Logger _logger = Logger();

  /// 进度回调
  ProgressCallback? _progressCallback;

  /// 状态回调
  StatusCallback? _statusCallback;

  /// 错误回调
  ErrorCallback? _errorCallback;

  /// 完成回调
  CompleteCallback? _completeCallback;

  /// 当前进度
  double _currentProgress = 0.0;

  /// 当前状态
  TaskStatusEnum _currentStatus = TaskStatusEnum.pending;

  /// 当前消息
  String _currentMessage = '';

  /// 是否已取消
  bool _isCancelled = false;

  /// 总帧数
  int _totalFrames = 0;

  /// 构造函数
  ProgressHandler({
    ProgressCallback? onProgress,
    StatusCallback? onStatus,
    ErrorCallback? onError,
    CompleteCallback? onComplete,
  }) {
    _progressCallback = onProgress;
    _statusCallback = onStatus;
    _errorCallback = onError;
    _completeCallback = onComplete;
  }

  /// 获取当前进度
  double get currentProgress => _currentProgress;

  /// 获取当前状态
  TaskStatusEnum get currentStatus => _currentStatus;

  /// 获取当前消息
  String get currentMessage => _currentMessage;

  /// 是否已取消
  bool get isCancelled => _isCancelled;

  /// 当前帧数
  int _currentFrames = 0;

  void startProcess(double duration, int perSecondFrames) {
    _totalFrames = (duration * perSecondFrames).toInt();
    _currentFrames = 0;
    _currentProgress = 0.0;
    _currentMessage = '';
    _isCancelled = false;

    updateStatus(TaskStatusEnum.processing);
  }

  void forword() {
    if (_isCancelled) return;

    _currentFrames++;
    _currentProgress = _currentFrames / _totalFrames;

    _progressCallback?.call(_currentProgress, _currentMessage);
  }

  /// 更新状态
  void updateStatus(TaskStatusEnum status, {String? message}) {
    if (_isCancelled) return;

    _currentStatus = status;
    if (message != null) {
      _currentMessage = message;
    }

    _logger.i('状态更新: $status - $_currentMessage');
    _statusCallback?.call(status, _currentMessage);
  }

  /// 报告错误
  void reportError(String error, {String? details}) {
    if (_isCancelled) return;

    _currentStatus = TaskStatusEnum.failed;
    _currentMessage = error;

    _logger.e('错误报告: $error${details != null ? ' - $details' : ''}');
    _errorCallback?.call(error, details ?? '');
  }

  /// 完成任务
  void complete(result) {
    if (_isCancelled) return;

    _currentProgress = 1.0;
    _currentStatus = TaskStatusEnum.completed;
    _currentMessage = '任务完成';

    _logger.i('任务完成');
    _completeCallback?.call(result);
  }

  /// 取消任务
  void cancel() {
    _isCancelled = true;
    _currentStatus = TaskStatusEnum.cancelled;
    _currentMessage = '任务已取消';

    _logger.w('任务已取消');
    _statusCallback?.call(_currentStatus, _currentMessage);
  }
}
