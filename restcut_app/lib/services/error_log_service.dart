import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/internal/member/error_log_api.dart';
import 'package:restcut/config/environment.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErrorLogService {
  static final ErrorLogService instance = ErrorLogService._internal();
  ErrorLogService._internal();

  DeviceInfoPlugin? _deviceInfo;
  String? _deviceInfoStr;
  bool _isInitialized = false;

  // 存储键名
  static const String _lastRecordedDateKey = 'error_log_last_recorded_date';
  static const String _recordedErrorsKey = 'error_log_recorded_errors';

  Future<PackageInfo?> getPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e, stackTrace) {
      AppLogger.instance.e('Error getting package info', stackTrace, e, false);
    }
    return null;
  }

  Future<void> initialize() async {
    while (!_isInitialized) {
      try {
        _deviceInfo = DeviceInfoPlugin();
        _deviceInfoStr = await _getDeviceInfo();
        _isInitialized = true;
      } catch (e, stackTrace) {
        AppLogger.instance.e(
          'Error initializing ErrorLogService',
          stackTrace,
          e,
        );
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<String?> _getDeviceInfo() async {
    if (_deviceInfo == null) return null;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo!.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}, Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo!.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}, iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo!.windowsInfo;
        return 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}.${windowsInfo.buildNumber}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo!.linuxInfo;
        return '${linuxInfo.name} ${linuxInfo.version}';
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo!.macOsInfo;
        return 'macOS ${macOsInfo.osRelease}';
      }
    } catch (e, stackTrace) {
      AppLogger.instance.e('Error getting device info', stackTrace, e, false);
    }
    return null;
  }

  String _extractErrorDetails(Object error, StackTrace stackTrace) {
    String errorMessage = error.toString();

    // 处理布局错误的详细信息
    if (error is FlutterError) {
      // 获取错误信息和相关的widget信息
      final List<String> lines = error.diagnostics
          .map((d) => d.toString())
          .toList();
      errorMessage = lines.join('\n');

      // 尝试从错误信息中提取文件路径和行号
      for (final line in lines) {
        if (line.contains('file://')) {
          final match = RegExp(r'file://([^:]+):(\d+):(\d+)').firstMatch(line);
          if (match != null) {
            break;
          }
        }
      }
    }

    return errorMessage;
  }

  /// 生成错误的唯一标识符
  String _generateErrorKey(Object error, String? module, String? action) {
    final errorType = error.runtimeType.toString();
    final errorMessage = _extractErrorDetails(error, StackTrace.empty);

    // 创建一个简化的错误标识符，包含错误类型、模块、动作和消息的前100个字符
    final messageHash = errorMessage.length > 100
        ? errorMessage.substring(0, 100).hashCode
        : errorMessage.hashCode;

    return '${errorType}_${module ?? 'unknown'}_${action ?? 'unknown'}_$messageHash';
  }

  /// 检查今天是否已经记录过这个错误
  Future<bool> _hasRecordedToday(String errorKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 获取上次记录的日期
      final lastRecordedDate = prefs.getString(_lastRecordedDateKey);
      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD格式

      // 如果日期不是今天，清除所有记录
      if (lastRecordedDate != today) {
        await prefs.remove(_recordedErrorsKey);
        await prefs.setString(_lastRecordedDateKey, today);
        return false;
      }

      // 获取今天已记录的错误列表
      final recordedErrors = prefs.getStringList(_recordedErrorsKey) ?? [];
      return recordedErrors.contains(errorKey);
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully - platform may not be ready
      if (e.code == 'channel-error') {
        // Silently return false to allow recording when channel is not ready
        return false;
      }
      AppLogger.instance.e(
        'Error checking recorded errors',
        stackTrace,
        e,
        false,
      );
      return false; // 出错时允许记录
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Error checking recorded errors',
        stackTrace,
        e,
        false,
      );
      return false; // 出错时允许记录
    }
  }

  /// 标记错误为已记录
  Future<void> _markAsRecorded(String errorKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordedErrors = prefs.getStringList(_recordedErrorsKey) ?? [];

      if (!recordedErrors.contains(errorKey)) {
        recordedErrors.add(errorKey);
        await prefs.setStringList(_recordedErrorsKey, recordedErrors);
      }
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully - platform may not be ready
      if (e.code == 'channel-error') {
        // Silently ignore when channel is not ready
        return;
      }
      AppLogger.instance.e(
        'Error marking error as recorded',
        stackTrace,
        e,
        false,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Error marking error as recorded',
        stackTrace,
        e,
        false,
      );
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? module,
    String? action,
    String? filePath,
    int? lineNumber,
    int? columnNumber,
    int? videoId,
    String? videoName,
    String? context,
    String? sessionId,
    String? requestId,
    String? userActions,
    String? previousActions,
  }) async {
    AppLogger.instance.e(error.toString(), stackTrace, error, false);

    if (EnvironmentConfig.isProduction) {
      try {
        final packageInfo = await getPackageInfo();
        // 确保已初始化，如果没有则尝试初始化
        if (!_isInitialized) {
          await initialize();
          // 如果初始化仍然失败，跳过记录
          if (!_isInitialized || packageInfo == null) {
            AppLogger.instance.w(
              'ErrorLogService not initialized, skipping error record',
            );
            return;
          }
        }

        // 生成错误标识符
        final errorKey = _generateErrorKey(error, module, action);

        // 检查今天是否已经记录过这个错误
        if (await _hasRecordedToday(errorKey)) {
          AppLogger.instance.i('Error already recorded today: $errorKey');
          return;
        }

        final String errorMessage = _extractErrorDetails(error, stackTrace);

        final errorLog = ErrorLogCreateReqVO(
          message: errorMessage,
          errorType: error.runtimeType.toString(),
          stackTrace: stackTrace.toString(),
          module: module,
          action: action,
          filePath: filePath,
          lineNumber: lineNumber,
          columnNumber: columnNumber,
          deviceInfo: _deviceInfoStr,
          appVersion: packageInfo?.version,
          systemVersion: packageInfo?.buildNumber,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          videoId: videoId,
          videoName: videoName,
          context: context,
          sessionId: sessionId,
          requestId: requestId,
          userActions: userActions,
          previousActions: previousActions,
        );

        await Api.errorLog.recordError(errorLog);

        // 标记为已记录
        await _markAsRecorded(errorKey);

        AppLogger.instance.i('Error logged successfully: $errorKey');
      } catch (e, stackTrace) {
        AppLogger.instance.e('Error recording error log', stackTrace, e, false);
      }
    }
  }

  Future<void> batchRecordErrors(List<ErrorLogCreateReqVO> errors) async {
    try {
      await Api.errorLog.batchRecordErrors(errors);
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Error batch recording error logs',
        stackTrace,
        e,
        false,
      );
    }
  }

  /// 清除所有已记录的错误（用于测试或重置）
  Future<void> clearRecordedErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastRecordedDateKey);
      await prefs.remove(_recordedErrorsKey);
      AppLogger.instance.i('Cleared all recorded errors');
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully
      if (e.code == 'channel-error') {
        return;
      }
      AppLogger.instance.e(
        'Error clearing recorded errors',
        stackTrace,
        e,
        false,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Error clearing recorded errors',
        stackTrace,
        e,
        false,
      );
    }
  }

  /// 获取今天已记录的错误数量
  Future<int> getTodayRecordedErrorCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordedErrors = prefs.getStringList(_recordedErrorsKey) ?? [];
      return recordedErrors.length;
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully
      if (e.code == 'channel-error') {
        return 0;
      }
      AppLogger.instance.e(
        'Error getting recorded error count',
        stackTrace,
        e,
        false,
      );
      return 0;
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Error getting recorded error count',
        stackTrace,
        e,
        false,
      );
      return 0;
    }
  }
}
