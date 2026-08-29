import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:shared_ui/shared_ui.dart';

enum WorkspaceHubNavDensity { standard, relaxed, subItem }

/// One row in a hub list or desktop section nav.
class WorkspaceHubEntry {
  const WorkspaceHubEntry({
    required this.title,
    required this.icon,
    required this.onTap,
    this.key,
    this.selected = false,
    this.trailingIcon,
    this.trailing,
    this.showLeaderBadge = false,
    this.density = WorkspaceHubNavDensity.standard,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Key? key;
  final bool selected;
  final IconData? trailingIcon;
  final Widget? trailing;
  final bool showLeaderBadge;
  final WorkspaceHubNavDensity density;
}

class WorkspaceHubNavItem extends StatelessWidget {
  const WorkspaceHubNavItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.hubStyle = false,
    this.trailingIcon,
    this.trailing,
    this.showLeaderBadge = false,
    this.density = WorkspaceHubNavDensity.standard,
    super.key,
  });

  static const teamLeadNavIcon = Icons.workspace_premium_outlined;

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool hubStyle;
  final IconData? trailingIcon;
  final Widget? trailing;
  final bool showLeaderBadge;
  final WorkspaceHubNavDensity density;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedFg = cs.onPrimaryContainer;
    final normalFg = cs.onSurface.withValues(alpha: hubStyle ? 0.92 : 0.88);
    final muted = cs.onSurfaceVariant;
    final selectedColor = cs.primaryContainer;
    final resolvedTrailingIcon =
        trailingIcon ?? (hubStyle ? Icons.chevron_right : null);

    final (height, iconSize, horizontalPadding, leftIndent) = switch (density) {
      WorkspaceHubNavDensity.standard => (
        hubStyle ? 56.0 : 48.0,
        context.tpIconSizes.md,
        hubStyle ? 16.0 : 18.0,
        0.0,
      ),
      WorkspaceHubNavDensity.relaxed => (
        54.0,
        context.tpIconSizes.md,
        18.0,
        0.0,
      ),
      WorkspaceHubNavDensity.subItem => (
        44.0,
        context.tpIconSizes.md,
        14.0,
        14.0,
      ),
    };

    final borderRadius = density == WorkspaceHubNavDensity.subItem
        ? BorderRadius.circular(10)
        : BorderRadius.circular(12);
    final leadingIcon = showLeaderBadge ? teamLeadNavIcon : icon;

    return Padding(
      padding: EdgeInsets.only(left: leftIndent, bottom: 8),
      child: TpHover(
        onTap: onTap,
        borderRadius: borderRadius,
        backgroundColor: selected
            ? selectedColor
            : hubStyle
            ? cs.workspaceSubtleSurface
            : Colors.transparent,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                Icon(
                  leadingIcon,
                  color: selected ? selectedFg : muted,
                  size: iconSize,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (hubStyle
                                ? TpTextStyles.of(context).lgSemibold
                                : TpTextStyles.of(context).md)
                            .copyWith(
                              fontWeight: hubStyle
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected ? selectedFg : normalFg,
                            ),
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (resolvedTrailingIcon != null)
                  Icon(
                    resolvedTrailingIcon,
                    size: hubStyle ? 22 : 18,
                    color: selected ? selectedFg : muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkspaceHubNavList extends StatelessWidget {
  const WorkspaceHubNavList({
    required this.entries,
    this.hubStyle = false,
    this.sidebarStyle = false,
    this.animateEntries = false,
    this.shrinkWrap = false,
    this.trailingChildren = const [],
    super.key,
  });

  final List<WorkspaceHubEntry> entries;
  final bool hubStyle;
  final bool sidebarStyle;
  final bool animateEntries;
  final bool shrinkWrap;
  final List<Widget> trailingChildren;

  @override
  Widget build(BuildContext context) {
    final items = entries.indexed.map((indexedEntry) {
      final (index, entry) = indexedEntry;
      final item = WorkspaceHubNavItem(
        key: entry.key,
        title: entry.title,
        icon: entry.icon,
        selected: entry.selected,
        hubStyle: hubStyle,
        trailingIcon: entry.trailingIcon,
        trailing: entry.trailing,
        showLeaderBadge: entry.showLeaderBadge,
        density: entry.density,
        onTap: entry.onTap,
      );

      if (!animateEntries) return item;

      return item
          .animate(delay: (index * 35).ms)
          .fadeIn(duration: 180.ms, curve: Curves.easeOut)
          .slideX(
            begin: -0.06,
            end: 0,
            duration: 220.ms,
            curve: Curves.easeOutCubic,
          );
    }).toList();

    final scrollPhysics =
        shrinkWrap ? const NeverScrollableScrollPhysics() : null;
    final children = [...items, ...trailingChildren];

    if (hubStyle) {
      return ListView(
        shrinkWrap: shrinkWrap,
        physics: scrollPhysics,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: children,
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: scrollPhysics,
      padding: sidebarStyle
          ? const EdgeInsets.fromLTRB(24, 28, 18, 24)
          : EdgeInsets.zero,
      children: children,
    );
  }
}
