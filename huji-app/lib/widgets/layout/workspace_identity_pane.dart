import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:shared_ui/shared_ui.dart';

/// Title row for identity / team right panes (Teampilot [HomeTeamHeader]).
class WorkspaceIdentityTitle extends StatelessWidget {
  const WorkspaceIdentityTitle({
    required this.title,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(color: cs.onSurface);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

/// Horizontal underline tabs (Teampilot [HomeContentTabBar]).
class WorkspaceContentTabBar extends StatelessWidget {
  const WorkspaceContentTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    this.trailing,
    super.key,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  WorkspaceContentTabItem(
                    label: tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class WorkspaceContentTabItem extends StatefulWidget {
  const WorkspaceContentTabItem({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<WorkspaceContentTabItem> createState() =>
      _WorkspaceContentTabItemState();
}

class _WorkspaceContentTabItemState extends State<WorkspaceContentTabItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected || !_hovered
                  ? Colors.transparent
                  : cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.lg.copyWith(
                color: selected
                    ? cs.primary
                    : _hovered
                    ? cs.onSurface
                    : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Identity / team content shell: title + tabs + divider + animated body.
class WorkspaceIdentityPane extends StatelessWidget {
  const WorkspaceIdentityPane({
    required this.header,
    required this.tabs,
    required this.selectedTabIndex,
    required this.onSelectTab,
    required this.contentKey,
    required this.child,
    this.tabBarTrailing,
    super.key,
  });

  final Widget header;
  final List<String> tabs;
  final int selectedTabIndex;
  final ValueChanged<int> onSelectTab;
  final Object contentKey;
  final Widget child;
  final Widget? tabBarTrailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ColoredBox(
      color: cs.workspaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 14),
          WorkspaceContentTabBar(
            tabs: tabs,
            selectedIndex: selectedTabIndex,
            onSelect: onSelectTab,
            trailing: tabBarTrailing,
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Expanded(
            child: child
                .animate(key: ValueKey(contentKey))
                .fadeIn(duration: 180.ms, curve: Curves.easeOut)
                .slideX(
                  begin: 0.025,
                  end: 0,
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
        ],
      ),
    );
  }
}
