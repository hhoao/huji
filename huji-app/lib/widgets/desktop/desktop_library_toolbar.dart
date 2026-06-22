import 'package:flutter/material.dart';
import 'package:shared_ui/theme/app_icon_sizes.dart';
import 'package:shared_ui/theme/app_text_styles.dart';

/// Toolbar row for the video library — Teampilot [WorkspacesToolbar] pattern.
class DesktopLibraryToolbar extends StatelessWidget {
  const DesktopLibraryToolbar({
    required this.gridView,
    required this.onToggleView,
    required this.onNewClip,
    this.itemCount,
    super.key,
  });

  final bool gridView;
  final ValueChanged<bool> onToggleView;
  final VoidCallback onNewClip;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);

    return Row(
      children: [
        _ViewToggle(gridView: gridView, onToggleView: onToggleView),
        if (itemCount != null) ...[
          const SizedBox(width: 12),
          Text(
            '共 $itemCount 个',
            style: styles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const Spacer(),
        _PrimaryAction(
          icon: Icons.add_rounded,
          label: '新建剪辑',
          onTap: onNewClip,
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.gridView,
    required this.onToggleView,
  });

  final bool gridView;
  final ValueChanged<bool> onToggleView;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleCell(
            icon: Icons.grid_view_rounded,
            active: gridView,
            onTap: () => onToggleView(true),
          ),
          _ToggleCell(
            icon: Icons.format_list_bulleted_rounded,
            active: !gridView,
            onTap: () => onToggleView(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleCell extends StatelessWidget {
  const _ToggleCell({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? cs.primary.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: context.appIconSizes.md,
          color: active ? cs.primary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
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
    final styles = AppTextStyles.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.appIconSizes.md, color: cs.onPrimary),
            const SizedBox(width: 7),
            Text(label, style: styles.body.copyWith(color: cs.onPrimary)),
          ],
        ),
      ),
    );
  }
}
