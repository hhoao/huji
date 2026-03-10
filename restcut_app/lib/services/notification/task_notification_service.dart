import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/services/notification/notification_manager.dart';

class TaskNotificationService implements NotificationService<Task> {
  final FlutterLocalNotificationsPlugin _notifications;

  static TaskNotificationService? _instance;

  factory TaskNotificationService(
    FlutterLocalNotificationsPlugin notifications,
  ) => _instance ??= TaskNotificationService._internal(notifications);

  TaskNotificationService._internal(this._notifications);

  // 通知ID常量 - 每个任务使用唯一的ID
  static const int _taskNotificationBaseId = 1000;

  // 获取任务的通知ID
  int _getTaskNotificationId(Task task) {
    return _taskNotificationBaseId + task.id.hashCode;
  }

  // 创建通知详情
  NotificationDetails _createNotificationDetails(
    TaskStatusEnum status, {
    bool showProgress = false,
    int currentProgress = 0,
    int maxProgress = 100,
    bool enableVibration = false,
    bool playSound = false,
    Color? color,
  }) {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'task_progress',
          '任务进度',
          channelDescription: '显示任务处理进度和状态',
          importance: status == TaskStatusEnum.processing
              ? Importance.defaultImportance
              : Importance.high,
          priority: status == TaskStatusEnum.processing
              ? Priority.defaultPriority
              : Priority.high,
          // ongoing: true 表示持续通知，用户不能清除；false 表示可以被用户清除
          ongoing: false,
          // autoCancel: true 表示点击通知后自动取消；false 表示不自动取消
          autoCancel: true,
          showProgress: showProgress,
          maxProgress: maxProgress,
          progress: currentProgress,
          indeterminate: false,
          enableVibration: enableVibration,
          playSound: playSound,
          channelShowBadge: true,
          icon: '@mipmap/launcher_icon_dark',
          color: color,
          // 允许用户清除通知
          onlyAlertOnce: true,
          // 设置通知可以被用户手动清除
          enableLights: true,
          // 对于正在进行的任务，ongoing设置为true表示不可清除；false表示可清除
          // ongoing: status == TaskStatusEnum.processing, // 已经在上面设置了
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // iOS 通知默认是可以被用户清除的
        );

    return NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }

  @override
  Future<void> showOrUpdateTaskNotification(Task task) async {
    final notificationId = _getTaskNotificationId(task);
    final progressPercent = (task.progress * 100).toInt();
    final currentStatus = task.status;

    String title;
    String body;
    bool showProgress;
    int currentProgress;
    int maxProgress;
    bool enableVibration;
    bool playSound;
    Color? color;

    switch (currentStatus) {
      case TaskStatusEnum.processing:
        title = '任务${task.name}处理中';
        body = '${task.name} - $progressPercent%';
        showProgress = true;
        currentProgress = progressPercent;
        maxProgress = 100;
        enableVibration = false;
        playSound = false;
        color = null;
        break;

      case TaskStatusEnum.completed:
        title = '任务完成';
        body = '${task.name} 处理完成';
        showProgress = false;
        currentProgress = 0;
        maxProgress = 0;
        enableVibration = true;
        playSound = false;
        color = const Color(0xFF4CAF50);
        break;

      case TaskStatusEnum.failed:
        title = '任务失败';
        body = '${task.name} 处理失败';
        showProgress = false;
        currentProgress = 0;
        maxProgress = 0;
        enableVibration = true;
        playSound = false;
        color = const Color(0xFFF44336);
        break;

      default:
        title = '任务状态';
        body = '${task.name} - $progressPercent%';
        showProgress = true;
        currentProgress = progressPercent;
        maxProgress = 100;
        enableVibration = false;
        playSound = false;
        color = null;
        break;
    }

    // 创建通知详情
    NotificationDetails notificationDetails = _createNotificationDetails(
      currentStatus,
      showProgress: showProgress,
      currentProgress: currentProgress,
      maxProgress: maxProgress,
      enableVibration: enableVibration,
      playSound: playSound,
      color: color,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: task.id,
    );
  }

  @override
  Future<void> cancelTaskNotification(Task task) async {
    final notificationId = _getTaskNotificationId(task);
    await _notifications.cancel(notificationId);
  }

  @override
  Future<void> cancelAllTaskNotifications() async {
    await _notifications.cancelAll();
  }
}
