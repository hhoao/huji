import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/huji_l10n_helpers.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final AppLogger _logger = AppLogger();

  // 应用所需的所有权限列表
  final List<Permission> _requiredPermissions = [
    Permission.notification,
    Permission.storage,
    Permission.camera,
    Permission.microphone,
    Permission.photos,
    Permission.videos,
    Permission.audio,
  ];

  // 初始化权限服务
  Future<void> initialize() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      _logger.i('Skipping permission service on desktop');
      return;
    }
    _logger.i('Initializing permission service...');
    try {
      await checkAndRequestPermissions();
    } catch (e, stackTrace) {
      _logger.e('Permission service initialization failed: $e', stackTrace, e);
      // 如果权限服务初始化失败，不阻止应用启动
    }
  }

  // 检查并请求所有权限
  Future<void> checkAndRequestPermissions() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    _logger.i('Checking and requesting permissions...');

    try {
      final Map<Permission, PermissionStatus> permissionStatuses = {};

      // 首先检查所有权限状态
      for (final permission in _requiredPermissions) {
        final status = await permission.status;
        permissionStatuses[permission] = status;
      }

      // 找出需要请求的权限
      final permissionsToRequest = permissionStatuses.entries
          .where((entry) => !entry.value.isGranted)
          .map((entry) => entry.key)
          .toList();

      if (permissionsToRequest.isEmpty) {
        return;
      }

      // 请求权限
      for (final permission in permissionsToRequest) {
        try {
          final status = await permission.request();
          _logger.i('$permission request result: $status');

          // 如果权限被永久拒绝，记录日志但不显示对话框（避免阻塞启动流程）
          if (status.isPermanentlyDenied) {
            _logger.w('$permission is permanently denied');
          }
        } catch (e, stackTrace) {
          _logger.e(
            'Error requesting $permission: $e',
            stackTrace,
            e,
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error in checkAndRequestPermissions: $e', stackTrace, e);
      // 不抛出异常，避免阻止应用启动
    }
  }

  Future<PermissionStatus> checkPermission(Permission permission) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return PermissionStatus.granted;
    }
    if (permission == Permission.storage) {
      return await checkStoragePermission();
    }
    final status = await permission.status;
    return status;
  }

  Future<PermissionStatus> requestPermission(Permission permission) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return PermissionStatus.granted;
    }
    try {
      final currentStatus = await permission.status;

      if (currentStatus.isGranted) {
        return currentStatus;
      }

      if (currentStatus.isPermanentlyDenied) {
        return currentStatus;
      }

      if (permission == Permission.storage) {
        return await requestStoragePermission();
      }

      final status = await permission.request();

      return status;
    } catch (e, stackTrace) {
      _logger.e(
        'Error requesting $permission: $e',
        stackTrace,
        e,
      );
      return await permission.status;
    }
  }

  Future<PermissionStatus> checkStoragePermission() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return PermissionStatus.granted;
    }
    if (await Permission.storage.status == PermissionStatus.granted) {
      return PermissionStatus.granted;
    } else {
      final photosStatus = await Permission.photos.status;
      final videosStatus = await Permission.videos.status;
      final audioStatus = await Permission.audio.status;
      final manageExternalStorageStatus =
          await Permission.manageExternalStorage.status;
      if (photosStatus.isGranted &&
          videosStatus.isGranted &&
          audioStatus.isGranted &&
          manageExternalStorageStatus.isGranted) {
        return PermissionStatus.granted;
      } else {
        return PermissionStatus.denied;
      }
    }
  }

  /// 特殊处理存储权限（Android 13+）
  /// - On Android 13 (API 33) and above, this permission is deprecated and
  /// always returns `PermissionStatus.denied`. Instead use `Permission.photos`,
  /// `Permission.video`, `Permission.audio` or
  /// `Permission.manageExternalStorage`
  Future<PermissionStatus> requestStoragePermission() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return PermissionStatus.granted;
    }
    try {
      var status = await Permission.storage.request();

      if (!status.isGranted) {
        final photosStatus = await Permission.photos.request();

        final videosStatus = await Permission.videos.request();

        final audioStatus = await Permission.audio.request();

        if (photosStatus.isGranted &&
            videosStatus.isGranted &&
            audioStatus.isGranted) {
          status = PermissionStatus.granted;
        }
      }

      return status;
    } catch (e, stackTrace) {
      _logger.e('Error requesting storage permission: $e', stackTrace, e);
      return await Permission.storage.status;
    }
  }

  // 检查所有权限状态
  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return {
        for (final p in _requiredPermissions) p: PermissionStatus.granted,
      };
    }
    final Map<Permission, PermissionStatus> statuses = {};

    for (final permission in _requiredPermissions) {
      statuses[permission] = await permission.status;
    }

    return statuses;
  }

  // 获取权限状态文本
  String getPermissionStatusText(
    PermissionStatus status,
    HujiLocalizations l10n,
  ) {
    return l10n.permissionStatusLabel(status);
  }

  // 获取权限状态颜色
  Color getPermissionStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.restricted:
        return Colors.red;
      case PermissionStatus.limited:
        return Colors.yellow;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 打开应用设置页面
  Future<void> openAppSettingsPage() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    await openAppSettings();
  }

  // 检查是否所有必需权限都已授权
  Future<bool> areAllPermissionsGranted() async {
    final statuses = await checkAllPermissions();
    return statuses.values.every((status) => status.isGranted);
  }

  // 获取权限名称
  String getPermissionName(Permission permission, HujiLocalizations l10n) {
    return l10n.permissionNameLabel(permission);
  }

  // 获取权限详细说明
  String getPermissionDetail(Permission permission, HujiLocalizations l10n) {
    return l10n.permissionDetailLabel(permission);
  }

  // 检查权限是否对应用功能至关重要
  bool isPermissionCritical(Permission permission) {
    // 存储权限是最重要的，没有它应用基本无法工作
    return permission == Permission.storage;
  }

  // 获取权限建议操作
  String getPermissionSuggestion(
    Permission permission,
    PermissionStatus status,
    HujiLocalizations l10n,
  ) {
    return l10n.permissionSuggestionLabel(permission, status);
  }

  List<Permission> get requiredPermissions =>
      List.unmodifiable(_requiredPermissions);

  Future<Map<String, dynamic>> diagnosePermissionIssues(
    HujiLocalizations l10n,
  ) async {
    final Map<String, dynamic> diagnosis = {
      'timestamp': DateTime.now().toIso8601String(),
      'permissions': {},
      'summary': {},
    };

    final statuses = await checkAllPermissions();

    for (final entry in statuses.entries) {
      final permission = entry.key;
      final status = entry.value;

      diagnosis['permissions'][getPermissionName(permission, l10n)] = {
        'status': status.toString(),
        'isGranted': status.isGranted,
        'isDenied': status.isDenied,
        'isPermanentlyDenied': status.isPermanentlyDenied,
        'isRestricted': status.isRestricted,
        'isLimited': status.isLimited,
      };
    }

    final total = statuses.length;
    final granted = statuses.values.where((s) => s.isGranted).length;
    final denied = statuses.values.where((s) => s.isDenied).length;
    final permanentlyDenied = statuses.values
        .where((s) => s.isPermanentlyDenied)
        .length;

    diagnosis['summary'] = {
      'total': total,
      'granted': granted,
      'denied': denied,
      'permanentlyDenied': permanentlyDenied,
      'grantedPercentage': total > 0 ? (granted / total * 100).round() : 0,
    };

    return diagnosis;
  }
}
