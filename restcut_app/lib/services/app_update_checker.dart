import 'dart:async';

import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/api/models/autoclip/app_models.dart';
import 'package:restcut/services/app_update_service.dart';
import 'package:restcut/widgets/app_update_dialog.dart';

class AppUpdateChecker {
  static final AppUpdateChecker _instance = AppUpdateChecker._internal();
  factory AppUpdateChecker() => _instance;
  AppUpdateChecker._internal();

  static AppUpdateChecker get instance => _instance;

  final AppLogger _logger = AppLogger();
  final AppUpdateService _updateService = AppUpdateService.instance;

  Timer? _checkTimer;
  bool _isChecking = false;
  DateTime? _lastCheckTime;
  static const Duration _checkInterval = Duration(hours: 24); // 24小时检查一次

  void startAutoCheck() {
    checkForUpdate(silent: false);
    _stopAutoCheck();
    _checkTimer = Timer.periodic(_checkInterval, (timer) {
      checkForUpdate(silent: false);
    });
    _logger.i('启动自动更新检查，间隔: $_checkInterval');
  }

  /// 停止自动更新检查
  void stopAutoCheck() {
    _stopAutoCheck();
    _logger.i('停止自动更新检查');
  }

  void _stopAutoCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> checkForUpdate({bool silent = false}) async {
    if (_isChecking) {
      _logger.i('更新检查正在进行中，跳过本次检查');
      return;
    }

    // 检查是否需要更新检查
    if (!silent && _lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck < const Duration(hours: 1)) {
        _logger.i('距离上次检查时间过短，跳过本次检查');
        return;
      }
    }

    _isChecking = true;
    _lastCheckTime = DateTime.now();

    try {
      final updateInfo = await _updateService.checkForUpdate();

      if (updateInfo != null && updateInfo.hasUpdate) {
        if (silent) {
          _showUpdateNotification(updateInfo);
        } else {
          _showUpdateDialog(updateInfo);
        }
      }
    } catch (e, stackTrace) {
      _logger.e('检查更新失败: $e', stackTrace, e);
    } finally {
      _isChecking = false;
    }
  }

  void _showUpdateNotification(AppUpdateInfo updateInfo) {
    _logger.i('发现新版本: ${updateInfo.latestApp?.version}');
  }

  /// 显示更新对话框
  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    AppUpdateDialogHelper.show(updateInfo: updateInfo);
  }

  void dispose() {
    _stopAutoCheck();
  }
}
