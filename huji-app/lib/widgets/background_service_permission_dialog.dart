import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundServicePermissionDialog extends StatelessWidget {
  const BackgroundServicePermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.backgroundServicePermissionTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backgroundServicePermissionIntro,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.video_settings, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.backgroundMediaProcessingPermission,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              l10n.backgroundMediaProcessingDescription,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.backgroundServicePermissionDeniedHint,
            style: const TextStyle(fontSize: 14, color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.setupLater),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            if (Platform.isAndroid || Platform.isIOS) {
              await openAppSettings();
            }
          },
          child: Text(l10n.goToSettings),
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
