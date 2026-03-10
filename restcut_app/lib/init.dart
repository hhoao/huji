// [FOSS_REMOVE_END]

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restcut/config/environment.dart';
import 'package:restcut/constants/theme_manager.dart';
import 'package:restcut/services/app_update_checker.dart';
import 'package:restcut/services/error_log_service.dart';
import 'package:restcut/services/notification/notification_manager.dart';
import 'package:restcut/services/permission_service.dart';
import 'package:restcut/services/storage_manager.dart';
import 'package:restcut/services/storage_service.dart';
import 'package:restcut/settings/settings_manager.dart';
import 'package:restcut/store/message.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/user.dart';
import 'package:restcut/store/user/user_bloc_instance.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Will be called before the MaterialApp started
Future<void> preInit() async {
  // 初始化存储服务（必须在其他服务之前初始化，因为它们可能需要路径）
  await StorageService.init();
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
  await PermissionService().initialize();

  AppLogger.instance.i('PermissionService initialized');
  NotificationManager.instance.initialize();

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
}
