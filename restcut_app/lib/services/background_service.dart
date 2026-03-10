import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static BackgroundService get instance => _instance;

  final _service = FlutterBackgroundService();

  Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'background_service_channel',
        initialNotificationTitle: '后台服务',
        initialNotificationContent: '准备中...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// 启动前台服务
  Future<void> startService() async {
    if (!await _service.isRunning()) {
      await _service.startService();
      // 等待服务启动
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// 停止服务
  Future<void> stopService() async {
    if (await _service.isRunning()) {
      _service.invoke('stopService');
    }
  }
}

/// 后台服务入口点
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 设置前台服务
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // 只保留通知更新监听
  service.on('update_notification').listen((event) {
    if (event == null) return;

    final title = event['title'] as String?;
    final content = event['content'] as String?;

    if (title != null && content != null && service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(title: title, content: content);
    }
  });

  // 停止服务监听
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
