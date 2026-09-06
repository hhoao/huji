import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/main.dart';
import 'package:huji_app/services/notification/task_notification_service.dart';
import 'package:huji_app/settings/settings_manager.dart';

abstract class NotificationService<T> {
  Future<void> showOrUpdateTaskNotification(T params);
  Future<void> cancelTaskNotification(T params);
  Future<void> cancelAllTaskNotifications();
}

class NotificationManager implements NotificationService<dynamic> {
  late final Map<Type, NotificationService> _services;
  late final FlutterLocalNotificationsPlugin _notifications;

  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() => _instance;
  NotificationManager._internal() {
    _notifications = FlutterLocalNotificationsPlugin();
    final taskNotificationService = TaskNotificationService(_notifications);
    _services = {
      DownloadTask: taskNotificationService,
      VideoUploadTask: taskNotificationService,
      VideoClipTask: taskNotificationService,
      VideoCompressTask: taskNotificationService,
      ImageCompressTask: taskNotificationService,
      VideoSegmentDetectTask: taskNotificationService,
      VideoExportTask: taskNotificationService,
    };
  }

  @override
  Future<void> showOrUpdateTaskNotification(dynamic params) async {
    if (!SettingsManager.to.notifications) {
      return;
    }
    if (!await checkNotificationPermission()) {
      AppLogger().e(
        'Notification permission not granted, cannot show notification',
        StackTrace.current,
      );
      return;
    }
    final service = _services[params.runtimeType];
    if (service == null) {
      AppLogger().w(
        'No notification service registered for ${params.runtimeType}',
        StackTrace.current,
      );
      return;
    }
    service.showOrUpdateTaskNotification(params);
  }

  Future<void> initialize() async {
    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon_dark');

    // iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // macOS settings
    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Linux settings
    final LinuxInitializationSettings? initializationSettingsLinux =
        Platform.isLinux
        ? LinuxInitializationSettings(
            defaultActionName: 'huji',
            defaultIcon: ThemeLinuxIcon('huji'),
          )
        : null;

    // Windows settings
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: '弧迹',
          appUserModelId: 'Com.Huji.HujiApp',
          guid: 'a3f8c2e1-9b4d-4a7e-8f6c-1d2e3b4a5c6d',
        );

    // Initialization settings
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
      linux: initializationSettingsLinux,
      windows: Platform.isWindows ? initializationSettingsWindows : null,
    );

    // Initialize plugin
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions (not needed on Linux - libnotify handles this)
    if (!Platform.isLinux) {
      await _requestPermissions();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    appRouter.go(MainRoute.main);
  }

  Future<void> _requestPermissions() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    await Permission.notification.request();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // 检查通知权限
  Future<bool> checkNotificationPermission() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return true;
    }
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // 获取通知服务实例
  static NotificationManager get instance => _instance;

  @override
  Future<void> cancelAllTaskNotifications() async {
    _services[Task]!.cancelAllTaskNotifications();
  }

  @override
  Future<void> cancelTaskNotification(params) async {
    _services[params.runtimeType]!.cancelTaskNotification(params);
  }
}
