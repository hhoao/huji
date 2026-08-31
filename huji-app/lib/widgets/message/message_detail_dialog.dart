import 'package:flutter/material.dart';
import 'package:huji_app/api/models/member/notify_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:shared_ui/shared_ui.dart';

void showMessageDetailDialog(
  BuildContext context,
  NotifyMessageVO message,
) {
  showTpDialog(
    context: context,
    builder: (dialogContext) {
      return TpDialog(
        maxWidth: 480,
        maxHeight: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: message.templateNickname),
            SizedBox(height: dialogContext.tpSpacing.lg),
            Text(
              context.hujiL10n.messageTimeLabel(
                timeStampToTimeAgo(message.createTime),
              ),
              style: TpTextStyles.of(context).mutedXs,
            ),
            SizedBox(height: dialogContext.tpSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  message.templateContent,
                  style: TpTextStyles.of(context).md.copyWith(height: 1.5),
                ),
              ),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.hujiL10n.actionClose),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
