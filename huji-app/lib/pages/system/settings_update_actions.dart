import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/services/app_update_service.dart';
import 'package:huji_app/widgets/app_update_dialog.dart';
import 'package:shared_ui/shared_ui.dart';

abstract final class SettingsUpdateActions {
  static Future<void> checkUpdate(BuildContext context) async {
    final updateInfo = await AppUpdateService.instance.checkForUpdate();
    if (!context.mounted) return;
    if (updateInfo == null || !updateInfo.hasUpdate) {
      TpToast.show(
        context,
        message: context.hujiL10n.settingsAlreadyLatestVersion,
        variant: TpToastVariant.info,
      );
      return;
    }
    showTpDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      escapeDismissible: !updateInfo.forceUpdate,
      builder: (dialogContext) =>
          AppUpdateDialog(updateInfo: updateInfo),
    );
  }
}
