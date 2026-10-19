import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/settings/log_viewer_panel.dart';
import 'package:shared_ui/shared_ui.dart';

const double _kLogViewerDialogWidth = 920;
const double _kLogViewerDialogHeight = 640;

/// Modal log viewer used from settings / about.
Future<void> showLogViewerDialog(BuildContext context) {
  final l10n = context.hujiL10n;

  return showTpDialog<void>(
    context: context,
    builder: (dialogContext) {
      final media = MediaQuery.of(dialogContext);
      final width = _kLogViewerDialogWidth.clamp(
        0.0,
        media.size.width - kTpDialogInsetExtent,
      );
      final height = _kLogViewerDialogHeight.clamp(
        0.0,
        media.size.height - kTpDialogInsetExtent,
      );
      final cs = Theme.of(dialogContext).colorScheme;

      return TpDialog(
        maxWidth: width,
        maxHeight: height,
        contentPadding: EdgeInsets.zero,
        backgroundColor: cs.workspacePage,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LogViewerDialogHeader(
                title: l10n.logViewerTitle,
                subtitle: l10n.logViewerSubtitle,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: const LogViewerPanel(useSurfaceCard: false),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Header with its own padding so the title and close button stay clear of the
/// dialog's rounded corners (the shell itself uses zero content padding).
class _LogViewerDialogHeader extends StatelessWidget {
  const _LogViewerDialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.lgBoldSnugColored(cs.onSurface),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: styles.mutedMd,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          TpIconButton(
            icon: Icons.close_rounded,
            iconSize: context.tpIconSizes.md,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            color: cs.onSurfaceVariant,
            compact: true,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}
