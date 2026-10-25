import 'package:logger/logger.dart';
import 'package:huji_app/l10n/l10n_resolve.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/clip_cancel_token.dart';

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
    // NOTE: `_isCancelled` is intentionally NOT reset here. A handler instance
    // belongs to exactly one pipeline run (constructed in
    // `LocalDetectionService.runAutoclip`), and a cancel that lands before
    // frame extraction starts would otherwise be silently undone — the
    // pipeline would keep running after the user pressed 取消.

    updateStatus(TaskStatusEnum.processing);
  }

  void forword() {
    if (_isCancelled) return;

    _currentFrames++;
    final value = _totalFrames > 0 ? _currentFrames / _totalFrames : 0.0;
    // 抽帧阶段（reportFrameProgress）可能已经报过更靠前的进度：进度条只
    // 前进不回退。
    if (value > _currentProgress) _currentProgress = value;

    _progressCallback?.call(_currentProgress, _currentMessage);
  }

  /// 抽帧阶段的上报：按"已处理到的视频帧数"（全局时间轴）折算。
  ///
  /// 走 ffmpeg-kit 的平台是先把整段抽到临时文件再逐帧推理，抽帧期间若不
  /// 上报，4K 长视频会出现十几分钟停在 0% 的假死现象。
  void reportFrameProgress(double frames) {
    if (_isCancelled || _totalFrames <= 0) return;
    final value = (frames / _totalFrames).clamp(0.0, 1.0);
    if (value <= _currentProgress) return;
    _currentProgress = value;
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
    _currentMessage = resolveHujiL10n().progressTaskCompleted;

    _logger.i('任务完成');
    _completeCallback?.call(result);
  }

  /// 取消任务
  void cancel() {
    _isCancelled = true;
    _currentStatus = TaskStatusEnum.cancelled;
    _currentMessage = resolveHujiL10n().progressTaskCancelled;

    _logger.w('任务已取消');
    _statusCallback?.call(_currentStatus, _currentMessage);
  }

  /// 已取消时抛出 [ClipCancelledException]，用于在流水线检查点中断执行。
  void throwIfCancelled() {
    if (_isCancelled) {
      throw const ClipCancelledException();
    }
  }
}
