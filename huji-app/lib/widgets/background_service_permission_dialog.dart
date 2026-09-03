import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

class BackgroundServicePermissionDialog extends StatelessWidget {
  const BackgroundServicePermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = context.cs;
    return TpDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogHeader(title: l10n.backgroundServicePermissionTitle),
          SizedBox(height: context.tpSpacing.lg),
          Text(
            l10n.backgroundServicePermissionIntro,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.video_settings, color: cs.primary, size: 20),
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
              style: TextStyle(fontSize: 14, color: cs.mutedForeground),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.backgroundServicePermissionDeniedHint,
            style: const TextStyle(fontSize: 14, color: Colors.orange),
          ),
          TpDialogActions(
            children: [
              TpButton(
                variant: TpButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.setupLater),
              ),
              TpButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  if (Platform.isAndroid || Platform.isIOS) {
                    await openAppSettings();
                  }
                },
                child: Text(l10n.goToSettings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 显示权限对话框
  static Future<bool> show(BuildContext context) async {
    final result = await showTpDialog<bool>(
      context: context,
      barrierDismissible: false,
      escapeDismissible: true,
      builder: (context) => const BackgroundServicePermissionDialog(),
    );
    return result ?? false;
  }
}
