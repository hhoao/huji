import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/config/environment.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/router/modules/tools.dart';
import 'package:huji_app/widgets/file_picker/file_selection.dart';
import 'package:shared_ui/shared_ui.dart';

/// Home-page utility shortcuts aligned with mobile [HomePage] tools section.
class DesktopHomeToolsSection extends StatelessWidget {
  const DesktopHomeToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeToolsSection,
          style: styles.mdSemibold.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ToolChip(
              icon: Icons.image_outlined,
              label: l10n.taskTypeImageCompress,
              onTap: () => _openImageCompress(context),
            ),
            _ToolChip(
              icon: Icons.video_file_outlined,
              label: l10n.taskTypeVideoCompress,
              onTap: () => _openVideoCompress(context),
            ),
            if (EnvironmentConfig.isDevelopment)
              _ToolChip(
                icon: Icons.science_outlined,
                label: l10n.testPageTitle,
                onTap: () => context.push(ToolsRoute.test),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _openImageCompress(BuildContext context) async {
    final result = await FileSelection.selectImages(
      context: context,
      allowMultiple: true,
    );
    if (!context.mounted || result == null || result.isEmpty) return;
    context.push(
      ToolsRoute.imageCompress,
      extra: result.map((e) => File(e.path)).toList(),
    );
  }

  Future<void> _openVideoCompress(BuildContext context) async {
    final files = await FileSelection.selectVideos(
      context: context,
      allowMultiple: false,
    );
    if (!context.mounted || files == null || files.isEmpty) return;
    context.push(ToolsRoute.videoCompress, extra: File(files.first.path));
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      backgroundColor: cs.surfaceContainer,
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(label, style: styles.sm.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}
