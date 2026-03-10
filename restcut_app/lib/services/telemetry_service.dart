import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/autoclip/telemetry_models.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/utils/logger_utils.dart';

class TelemetryService {
  static final TelemetryService instance = TelemetryService._internal();
  TelemetryService._internal();

  DeviceInfoPlugin? _deviceInfo;
  String? _deviceInfoStr;
  String? _systemVersion;
  String? _appVersion;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _deviceInfo = DeviceInfoPlugin();
      _deviceInfoStr = await _getDeviceInfo();
      _systemVersion = await _getSystemVersion();
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _isInitialized = true;
    } catch (e, stackTrace) {
      AppLogger().e('Error initializing TelemetryService', stackTrace, e);
    }
  }

  Future<String?> _getDeviceInfo() async {
    if (_deviceInfo == null) return null;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo!.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo!.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo!.windowsInfo;
        return 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo!.linuxInfo;
        return '${linuxInfo.name} ${linuxInfo.version}';
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo!.macOsInfo;
        return 'macOS ${macOsInfo.osRelease}';
      }
    } catch (e, stackTrace) {
      AppLogger().e('Error getting device info', stackTrace, e);
    }
    return null;
  }

  Future<String?> _getSystemVersion() async {
    if (_deviceInfo == null) return null;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo!.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo!.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo!.windowsInfo;
        return 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo!.linuxInfo;
        return linuxInfo.version;
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo!.macOsInfo;
        return 'macOS ${macOsInfo.osRelease}';
      }
    } catch (e, stackTrace) {
      AppLogger().e('Error getting system version', stackTrace, e);
    }
    return null;
  }

  /// 获取任务类型对应的功能代码
  String _getFeatureCodeFromTaskType(TaskTypeEnum taskType) {
    switch (taskType) {
      case TaskTypeEnum.videoClip:
        return 'video_clip';
      case TaskTypeEnum.videoCompress:
        return 'video_compress';
      case TaskTypeEnum.imageCompress:
        return 'image_compress';
      case TaskTypeEnum.videoUpload:
        return 'video_upload';
      case TaskTypeEnum.download:
        return 'download';
      case TaskTypeEnum.videoSegmentDetect:
        return 'video_segment_detect';
    }
  }

  /// 记录任务使用统计
  Future<void> recordTaskTelemetry({
    required TaskTypeEnum taskType,
    required bool success,
    int? duration,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // 确保已初始化
      if (!_isInitialized) {
        await initialize();
      }

      final featureCode = _getFeatureCodeFromTaskType(taskType);
      final featureName = taskType.name;

      final reqVO = TelemetryCreateReqVO(
        featureCode: featureCode,
        featureName: featureName,
        success: success,
        duration: duration,
        extraData: extraData != null ? jsonEncode(extraData) : null, // JSON序列化
        appVersion: _appVersion,
        systemVersion: _systemVersion,
        deviceInfo: _deviceInfoStr,
      );

      await Api.telemetry.recordTelemetry(reqVO);
      AppLogger().i(
        'Telemetry recorded: featureCode=$featureCode, success=$success, duration=$duration',
      );
    } catch (e, stackTrace) {
      // 静默失败，不影响主流程
      AppLogger().w('Error recording telemetry', e, stackTrace);
    }
  }
}
