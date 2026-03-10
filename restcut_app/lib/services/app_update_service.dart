import 'dart:io';

import 'package:flutter/services.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/autoclip/app_models.dart';
import 'package:restcut/config/environment.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/utils/file_utils.dart' as path_utils;
import 'package:uuid/uuid.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static AppUpdateService get instance => _instance;

  final AppLogger _logger = AppLogger();

  Future<AppUpdateInfo?> checkForUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appName = packageInfo.appName;
    _logger.i('开始检查应用更新: $appName');

    // 获取平台信息
    final platform = await _getPlatform();
    if (platform == null) {
      _logger.e('无法获取平台信息', StackTrace.current);
      return null;
    }

    // 调用API获取最新版本信息
    final latestApps = await Api.app.getLatestAppInfo(appName, platform.value);

    if (latestApps.isEmpty ||
        _compareVersions(latestApps.first.version, packageInfo.version)) {
      _logger.i('当前已是最新版本: ${latestApps.first.version}');
      return AppUpdateInfo(hasUpdate: false);
    }

    final currentApp = await getCurrentApp();

    if (latestApps.isEmpty) {
      _logger.i('未找到应用更新信息');
      return AppUpdateInfo(hasUpdate: false);
    }

    // 找到当前平台的最新版本
    final latestApp = latestApps.firstWhere(
      (app) => app.platform == platform,
      orElse: () => latestApps.first,
    );

    // 比较版本
    final hasUpdate = _compareVersions(currentApp.version, latestApp.version);

    if (!hasUpdate) {
      _logger.i('当前已是最新版本: ${currentApp.version}');
      return AppUpdateInfo(hasUpdate: false);
    }

    _logger.i('发现新版本: ${latestApp.version}');

    // 获取版本详情
    final latestVersions = await Api.app.getLatestVersionsAppInfo(
      appName,
      platform.value,
    );

    final latestVersion = latestVersions.isNotEmpty
        ? latestVersions.first
        : null;

    return AppUpdateInfo(
      hasUpdate: true,
      currentApp: currentApp,
      latestApp: latestApp,
      latestVersion: latestVersion,
      forceUpdate: latestApp.forceUpdate ?? false,
      downloadUrl: latestVersion?.downloadUrl,
      downloadType: latestApp.downloadType, // 从 latestApp 中获取下载类型
      changelogs: await getUpdateInfoChangeLogs(
        AppUpdateInfo(
          hasUpdate: true,
          latestApp: latestApp,
          currentApp: currentApp,
          forceUpdate: latestApp.forceUpdate ?? false,
          downloadUrl: latestVersion?.downloadUrl,
          downloadType: latestApp.downloadType,
        ),
      ),
    );
  }

  /// 获取所有应用的最新版本信息
  Future<List<AppApplicationRespVO>> getAllLatestApps() async {
    try {
      return await Api.app.getAllLatestAppInfo();
    } catch (e, stackTrace) {
      _logger.e('获取所有应用最新版本失败: $e', stackTrace, e);
      return [];
    }
  }

  String getCacheKey(AppApplicationRespVO latestApp) {
    return '${latestApp.name}-${latestApp.version}-${latestApp.platform}';
  }

  /// 获取下载 URL
  String getDownloadUrl(AppApplicationRespVO latestApp) {
    return '${EnvironmentConfig.apiBaseUrl}/autoclip/app/download/${latestApp.id}';
  }

  String downloadUpdate(AppApplicationRespVO latestApp) {
    final token = RootIsolateToken.instance;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    final id = Uuid().v4();

    path_utils.getDownloadsDirectory().then((downloadsDirectory) async {
      String savePath = '${downloadsDirectory.path}/app-release.apk';
      String url =
          '${EnvironmentConfig.apiBaseUrl}/autoclip/app/download/${latestApp.id}';
      final downloadTask = DownloadTask(
        id: id,
        name: '下载更新',
        url: url,
        savePath: savePath,
        isInstall: true,
        cacheKey: getCacheKey(latestApp),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await TaskStorage().addAndAsyncProcessTask(downloadTask);
    });
    return id;
  }

  /// 获取应用更新日志
  Future<List<AppChangelogRespVO>> getAppChangelog({
    String? name,
    AppPlatformEnum? platform,
    String? version,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    final pageReqVO = AppChangelogPageReqVO(
      pageNo: pageNo,
      pageSize: pageSize,
      name: name,
      platform: platform,
      startVersion: version,
      endVersion: version,
    );

    final result = await Api.app.getAppChangelogPage(pageReqVO);
    return result.list;
  }

  /// 获取当前应用信息
  Future<PackageInfo?> _getCurrentAppInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e, stackTrace) {
      _logger.e('获取当前应用信息失败: $e', stackTrace, e);
      return null;
    }
  }

  /// 获取平台信息
  Future<AppPlatformEnum?> _getPlatform() async {
    try {
      if (Platform.isAndroid) {
        return AppPlatformEnum.android;
      } else if (Platform.isIOS) {
        return AppPlatformEnum.ios;
      } else if (Platform.isWindows) {
        return AppPlatformEnum.windows;
      } else if (Platform.isMacOS) {
        return AppPlatformEnum.macos;
      } else if (Platform.isLinux) {
        return AppPlatformEnum.linux;
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('获取平台信息失败: $e', stackTrace, e);
      return null;
    }
  }

  /// 比较版本号
  /// 返回 true 表示有新版本
  bool _compareVersions(String currentVersion, String latestVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) {
          return true;
        } else if (latest[i] < current[i]) {
          return false;
        }
      }
      return false; // 版本相同
    } catch (e, stackTrace) {
      _logger.e('版本比较失败: $e', stackTrace, e);
      return false;
    }
  }

  /// 解析版本号
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    final result = <int>[];

    for (int i = 0; i < 3; i++) {
      if (i < parts.length) {
        result.add(int.tryParse(parts[i]) ?? 0);
      } else {
        result.add(0);
      }
    }

    return result;
  }

  /// 检查是否满足最低版本要求
  Future<bool> checkMinVersionRequirement(String minVersion) async {
    try {
      final currentAppInfo = await _getCurrentAppInfo();
      if (currentAppInfo == null) return false;

      return !_compareVersions(currentAppInfo.version, minVersion);
    } catch (e, stackTrace) {
      _logger.e('检查最低版本要求失败: $e', stackTrace, e);
      return false;
    }
  }

  Future<AppApplicationRespVO> getCurrentApp() async {
    final currentAppInfo = await _getCurrentAppInfo();
    final platform = await _getPlatform();
    final pageReqVO = AppPageReqVO(
      pageNo: 1,
      pageSize: 1,
      name: currentAppInfo?.appName,
      version: currentAppInfo?.version,
      platform: platform,
    );
    final appList = await Api.app.getAppPage(pageReqVO);
    return appList.list.first;
  }

  Future<List<String>> getUpdateInfoChangeLogs(AppUpdateInfo updateInfo) async {
    final pageReqVO = AppChangelogPageReqVO(
      pageNo: 1,
      pageSize: 100,
      name: updateInfo.latestApp?.name,
      platform: updateInfo.latestApp?.platform,
      startVersion: updateInfo.currentApp?.version,
      endVersion: updateInfo.latestApp?.version,
    );
    final changelogs = await Api.app.getAppChangelogPage(pageReqVO);
    return changelogs.list.map((e) => e.changelog ?? '').toList();
  }

  /// 获取应用详细信息
  Future<List<AppApplicationRespVO>> getAppList({
    String? name,
    AppPlatformEnum? platform,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    try {
      final pageReqVO = AppPageReqVO(
        pageNo: pageNo,
        pageSize: pageSize,
        name: name,
        platform: platform,
      );

      final result = await Api.app.getAppPage(pageReqVO);

      return result.list;
    } catch (e, stackTrace) {
      _logger.e('获取应用列表失败: $e', stackTrace, e);
      return [];
    }
  }
}
