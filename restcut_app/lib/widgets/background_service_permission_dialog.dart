import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundServicePermissionDialog extends StatelessWidget {
  const BackgroundServicePermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Text('需要后台服务权限'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('为了让视频压缩任务能在后台继续执行，需要您授予以下权限：', style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.video_settings, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '后台媒体处理权限',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: 28),
            child: Text(
              '允许应用在后台处理视频压缩任务，即使您切换到其他应用或锁屏，压缩任务也会继续执行。',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          SizedBox(height: 16),
          Text(
            '如果拒绝授权，视频压缩将在前台进行，可能会影响您使用其他应用。',
            style: TextStyle(fontSize: 14, color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('稍后设置'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            // 打开应用设置页面
            await openAppSettings();
          },
          child: const Text('前往设置'),
        ),
      ],
    );
  }

  /// 显示权限对话框
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BackgroundServicePermissionDialog(),
    );
    return result ?? false;
  }
}
