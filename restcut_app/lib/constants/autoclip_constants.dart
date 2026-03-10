import 'package:restcut/constants/file_extensions.dart';

/// 自动剪辑相关常量定义
class AutoclipConstants {
  // 错误代码
  static const int success = 0;
  static const int unknownError = 1000;
  static const int invalidParameter = 1001;
  static const int fileNotFound = 1002;
  static const int videoProcessError = 1003;
  static const int modelLoadError = 1004;
  static const int insufficientMemory = 1005;
  static const int timeoutError = 1006;
  static const int networkError = 1007;
  static const int permissionDenied = 1008;
  static const int invalidVideoFormat = 1009;
  static const int videoTooLarge = 1010;
  static const int modelPredictionError = 1011;
  static const int clipGenerationError = 1012;
  static const int fileSystemError = 1013;
  static const int configurationError = 1014;
  static const int unsupportedOperation = 1015;
  static const int resourceUnavailable = 1016;
  static const int invalidState = 1017;
  static const int dataCorruption = 1018;
  static const int serviceUnavailable = 1019;
  static const int rateLimitExceeded = 1020;
  static const int quotaExceeded = 1021;
  static const int maintenanceMode = 1022;
  static const int versionMismatch = 1023;

  // 视频处理状态
  static const String videoProcessingState = 'processing';
  static const String videoCompletedState = 'completed';
  static const String videoFailedState = 'failed';
  static const String videoPendingState = 'pending';
  static const String videoCancelledState = 'cancelled';

  // 默认配置值
  static const double defaultFrameInterval = 0.5;
  static const double defaultReserveTimeBeforeSingleRound = 2.0;
  static const double defaultReserveTimeAfterSingleRound = 2.0;
  static const double defaultMinimumDurationSingleRound = 5.0;
  static const double defaultMinimumDurationGreatBall = 3.0;
  static const double defaultFireballMaxSeconds = 10.0;
  static const bool defaultMergeFireBallAndPlayBall = true;
  static const bool defaultGreatBallEditing = true;
  static const bool defaultRemoveReplay = true;

  // 文件路径常量
  static const String clippedDirName = 'clipped';
  static const String resizedDirName = 'resized';
  static const String debugFrameOutputDirName = 'debug_frames';

  // 模型相关常量
  static const String pingPongModelName = '乒乓球单打模型';
  static const String badmintonModelName = '羽毛球单打模型';

  static const List<String> modelNames = [
    pingPongModelName,
    badmintonModelName,
  ];

  // static const String modelDirName = 'assets/models';
  static const String modelDirName = 'models';

  static const Map<String, String> modelNamePathMapping = {
    pingPongModelName: '$modelDirName/ping_pong_singles.tflite',
    badmintonModelName: '$modelDirName/badminton_singles.tflite',
  };

  // 视频格式常量
  static final List<String> supportedVideoFormats =
      FileExtensions.videoExtensionsList;

  // 时间格式常量
  static const String timeFormat = 'HH:mm:ss.SSS';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // 缓存相关常量
  static const int maxCacheSize = 1024 * 1024 * 1024; // 1GB
  static const Duration cacheExpiration = Duration(days: 7);
  static const String cacheFileExtension = '.cache';

  // 网络相关常量
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 10);
  static const Duration downloadTimeout = Duration(minutes: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // 日志相关常量
  static const String logTag = 'Autoclip';
  static const String logPrefix = '[Autoclip]';

  // 性能相关常量
  static const int maxConcurrentTasks = 4;
  static const Duration taskTimeout = Duration(minutes: 30);
  static const int maxMemoryUsage = 1024 * 1024 * 1024; // 1GB

  // 质量相关常量
  static const int defaultVideoQuality = 80;
  static const int highVideoQuality = 90;
  static const int lowVideoQuality = 60;
  static const double defaultVideoScale = 1.0;
  static const double highVideoScale = 1.5;
  static const double lowVideoScale = 0.5;
}

/// 错误代码类
class ErrorCodes {
  static const int success = AutoclipConstants.success;
  static const int unknownError = AutoclipConstants.unknownError;
  static const int invalidParameter = AutoclipConstants.invalidParameter;
  static const int fileNotFound = AutoclipConstants.fileNotFound;
  static const int videoProcessError = AutoclipConstants.videoProcessError;
  static const int modelLoadError = AutoclipConstants.modelLoadError;
  static const int insufficientMemory = AutoclipConstants.insufficientMemory;
  static const int timeoutError = AutoclipConstants.timeoutError;
  static const int networkError = AutoclipConstants.networkError;
  static const int permissionDenied = AutoclipConstants.permissionDenied;
  static const int invalidVideoFormat = AutoclipConstants.invalidVideoFormat;
  static const int videoTooLarge = AutoclipConstants.videoTooLarge;
  static const int modelPredictionError =
      AutoclipConstants.modelPredictionError;
  static const int clipGenerationError = AutoclipConstants.clipGenerationError;
  static const int fileSystemError = AutoclipConstants.fileSystemError;
  static const int configurationError = AutoclipConstants.configurationError;
  static const int unsupportedOperation =
      AutoclipConstants.unsupportedOperation;
  static const int resourceUnavailable = AutoclipConstants.resourceUnavailable;
  static const int invalidState = AutoclipConstants.invalidState;
  static const int dataCorruption = AutoclipConstants.dataCorruption;
  static const int serviceUnavailable = AutoclipConstants.serviceUnavailable;
  static const int rateLimitExceeded = AutoclipConstants.rateLimitExceeded;
  static const int quotaExceeded = AutoclipConstants.quotaExceeded;
  static const int maintenanceMode = AutoclipConstants.maintenanceMode;
  static const int versionMismatch = AutoclipConstants.versionMismatch;
}
