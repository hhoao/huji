import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/router/app_router.dart';
import 'package:restcut/router/modules/main.dart';
import 'package:restcut/services/notification/task_notification_service.dart';
import 'package:restcut/settings/settings_manager.dart';

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
    _services[params.runtimeType]!.showOrUpdateTaskNotification(params);
  }

  Future<void> initialize() async {
    // Android 设置
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon_dark');

    // iOS 设置
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // 初始化设置
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // 初始化插件
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 请求权限
    await _requestPermissions();
  }

  void _onNotificationTapped(NotificationResponse response) {
    appRouter.go(MainRoute.main);
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // 检查通知权限
  Future<bool> checkNotificationPermission() async {
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
