// [FOSS_REMOVE_END]

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:huji_app/config/environment.dart';
import 'package:huji_app/constants/theme_manager.dart';
import 'package:huji_app/services/app_update_checker.dart';
import 'package:huji_app/services/error_log_service.dart';
import 'package:huji_app/services/feature_visibility.dart';
import 'package:huji_app/services/notification/notification_manager.dart';
import 'package:huji_app/services/permission_service.dart';
import 'package:huji_app/services/storage_manager.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/settings/settings_manager.dart';
import 'package:huji_app/store/message.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Will be called before the MaterialApp started
Future<void> preInit() async {
  // 初始化存储服务（必须在其他服务之前初始化，因为它们可能需要路径）
  await StorageService.init();
  // 后台清理持久缩略图缓存（源视频已删 + 容量 LRU），不阻塞启动
  unawaited(StorageService.instance.evictVideoThumbnailCache());
  await AppLogger.instance.initializeFileLogger();
  AppLogger.instance.i('StorageService initialized');

  // 初始化错误日志服务
  ErrorLogService.instance.initialize();

  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorLogService.instance.recordError(
      details.exception,
      details.stack ?? StackTrace.empty,
      module: details.library,
      context: details.context.toString(),
    );
  };
  AppLogger.instance.i('ErrorLogService initialized');

  // 设置异步错误处理
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogService.instance.recordError(error, stack, module: 'Async Error');
    return true;
  };

  AppLogger.instance.i('ErrorLogService initialized');

  // VideoProxy.init(logPrint: true);
  final bool inProduction = bool.fromEnvironment("dart.vm.product");

  if (inProduction) {
    EnvironmentConfig.setEnvironment(Environment.production);
  } else {
    EnvironmentConfig.setEnvironment(Environment.development);
  }

  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
    // this step, it will use the sqlite version available on the system.
    databaseFactory = databaseFactoryFfi;
  }

  AppLogger.instance.i('FVP initialized');
}

/// Will be called when home page has been initialized
Future<void> postInit() async {
  if (Platform.isAndroid || Platform.isIOS) {
    await PermissionService().initialize();
  }

  AppLogger.instance.i('PermissionService initialized');
  if (Platform.isAndroid || Platform.isIOS) {
    NotificationManager.instance.initialize();
  }

  AppLogger.instance.i('NotificationManager initialized');

  // 初始化认证服务
  await UserStore.initialize();

  AppLogger.instance.i('UserStore initialized');

  // 初始化用户 Bloc（在 UserStore 初始化后）
  // UserBloc 会在创建时自动加载初始状态
  UserBlocInstance.instance; // 触发实例创建

  AppLogger.instance.i('UserBloc initialized');

  // 初始化数据库
  // await LocalVideoStorage().resetDatabase();
  // await TaskStorage().resetDatabase();
  await LocalVideoStorage().init();
  await TaskStorage().init();

  AppLogger.instance.i('LocalVideoStorage initialized');

  // 历史版本把缩略图写入系统临时目录会被 OS 清理，启动后异步补生成
  unawaited(LocalVideoStorage().repairMissingThumbnails());

  // 初始化消息状态管理器
  Get.put(MessageStore(), permanent: true);

  AppLogger.instance.i('MessageStore initialized');

  // 初始化主题管理器
  Get.put(ThemeManager(), permanent: true);

  AppLogger.instance.i('ThemeManager initialized');

  // 初始化设置管理器
  Get.put(SettingsManager(), permanent: true);

  AppLogger.instance.i('SettingsManager initialized');

  // 初始化存储管理器
  Get.put(StorageManager(), permanent: true);

  AppLogger.instance.i('StorageManager initialized');

  // 启动应用更新检查
  AppUpdateChecker.instance.startAutoCheck();

  AppLogger.instance.i('AppUpdateChecker initialized');

  await FeatureVisibility.instance.load();

  AppLogger.instance.i('FeatureVisibility initialized');
}
