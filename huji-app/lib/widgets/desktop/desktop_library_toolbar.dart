import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';

/// Toolbar row for the video library — Teampilot [WorkspacesToolbar] pattern.
class DesktopLibraryToolbar extends StatelessWidget {
  const DesktopLibraryToolbar({
    required this.gridView,
    required this.onToggleView,
    required this.onNewClip,
    this.itemCount,
    this.selectionMode = false,
    this.selectedCount = 0,
    this.onEnterSelectionMode,
    this.onExitSelectionMode,
    this.onSelectAll,
    this.onDeselectAll,
    this.onBatchDelete,
    super.key,
  });

  final bool gridView;
  final ValueChanged<bool> onToggleView;
  final VoidCallback onNewClip;
  final int? itemCount;

  final bool selectionMode;
  final int selectedCount;
  final VoidCallback? onEnterSelectionMode;
  final VoidCallback? onExitSelectionMode;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final VoidCallback? onBatchDelete;

  @override
  Widget build(BuildContext context) {
    if (selectionMode && itemCount != null && itemCount! > 0) {
      return _SelectionBar(
        totalCount: itemCount!,
        selectedCount: selectedCount,
        onSelectAll: onSelectAll!,
        onDeselectAll: onDeselectAll!,
        onBatchDelete: onBatchDelete!,
        onExitSelectionMode: onExitSelectionMode!,
      );
    }

    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final canSelect = itemCount != null && itemCount! > 0;

    return Row(
      children: [
        _ViewToggle(gridView: gridView, onToggleView: onToggleView),
        if (itemCount != null) ...[
          SizedBox(width: 12),
          Text(
            l10n.desktopLibraryItemCount(itemCount!),
            style: styles.xs.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const Spacer(),
        if (canSelect) ...[
          TpButton(
            variant: TpButtonVariant.outline,
            onPressed: onEnterSelectionMode,
            child: Text(l10n.batchSelect),
          ),
          SizedBox(width: 8),
        ],
        _PrimaryAction(
          icon: Icons.add_rounded,
          label: l10n.desktopNewClip,
          onTap: onNewClip,
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.totalCount,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onBatchDelete,
    required this.onExitSelectionMode,
  });

  final int totalCount;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onBatchDelete;
  final VoidCallback onExitSelectionMode;

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final allSelected = selectedCount == totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(20),
        border: Border.all(color: cs.primary.withAlpha(60)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            context.hujiL10n.selectedItemsCount(selectedCount),
            style: TpTextStyles.of(context).md.copyWith(color: cs.primary),
          ),
          const Spacer(),
          TpButton(
            variant: TpButtonVariant.ghost,
            onPressed: allSelected ? onDeselectAll : onSelectAll,
            child: Text(
              allSelected
                  ? context.hujiL10n.deselectAll
                  : context.hujiL10n.selectAll,
            ),
          ),
          SizedBox(width: 8),
          TpButton(
            variant: TpButtonVariant.destructive,
            onPressed: selectedCount == 0 ? null : onBatchDelete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete, size: 16),
                const SizedBox(width: 6),
                Text(context.hujiL10n.actionDelete),
              ],
            ),
          ),
          SizedBox(width: 8),
          TpIconButton(
            onTap: onExitSelectionMode,
            icon: Icons.close,
            iconSize: 18,
          ),
        ],
      ),
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
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      backgroundColor:
          active ? cs.primary.withValues(alpha: 0.16) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Icon(
        icon,
        size: context.tpIconSizes.md,
        color: active ? cs.primary : cs.onSurfaceVariant,
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
    final styles = TpTextStyles.of(context);
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      backgroundColor: cs.primary,
      pressScale: 0.97,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.tpIconSizes.md, color: cs.onPrimary),
          SizedBox(width: 7),
          Text(label, style: styles.md.copyWith(color: cs.onPrimary)),
        ],
      ),
    );
  }
}
