import 'package:flutter/material.dart';

import 'package:shared_ui/shared_ui.dart';
import 'huji_sidebar_icon_collapse.dart';
import 'huji_sidebar_theme.dart';

/// Vertical list of [HujiSidebarMenuItem]s.
class HujiSidebarMenu extends StatelessWidget {
  const HujiSidebarMenu({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // shadcn menu uses a tight vertical gap (~2–4px) between items.
    const gap = 2.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}

/// Host for a menu row: button plus optional action, badge, and nested sub.
///
/// Children are split by type — [HujiSidebarMenuButton], [HujiSidebarMenuAction],
/// [HujiSidebarMenuBadge], [HujiSidebarMenuSub] — matching shadcn composition.
class HujiSidebarMenuItem extends StatelessWidget {
  const HujiSidebarMenuItem({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    HujiSidebarMenuButton? button;
    HujiSidebarMenuAction? action;
    HujiSidebarMenuBadge? badge;
    HujiSidebarMenuSub? sub;
    final extras = <Widget>[];

    for (final child in children) {
      if (child is HujiSidebarMenuButton) {
        button = child;
      } else if (child is HujiSidebarMenuAction) {
        action = child;
      } else if (child is HujiSidebarMenuBadge) {
        badge = child;
      } else if (child is HujiSidebarMenuSub) {
        sub = child;
      } else {
        extras.add(child);
      }
    }

    final iconCollapsed = hideInIconCollapse(context);
    final spacing = context.tpSpacing;

    Widget? badgeSlot;
    if (badge != null) {
      if (iconCollapsed) {
        badgeSlot = const _BadgeDot(key: Key('huji-sidebar-badge-dot'));
      } else {
        badgeSlot = badge;
      }
    }

    final Widget row;
    if (iconCollapsed) {
      row = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (button != null) button,
          if (badgeSlot != null)
            Positioned(
              right: spacing.xs,
              child: badgeSlot,
            ),
          ...extras,
        ],
      );
    } else {
      row = Row(
        children: [
          if (button != null) Expanded(child: button),
          if (action != null) action,
          if (action != null && badgeSlot != null) SizedBox(width: spacing.xs),
          if (badgeSlot != null) badgeSlot,
          ...extras,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        if (sub != null && !iconCollapsed) sub,
      ],
    );
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = HujiSidebarTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = theme.accentForegroundColor ?? cs.primary;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Primary menu row button with optional icon, label, and active styling.
class HujiSidebarMenuButton extends StatelessWidget {
  const HujiSidebarMenuButton({
    super.key,
    this.icon,
    this.label,
    this.isActive = false,
    this.onPressed,
    this.tooltip,
  });

  final Widget? icon;
  final String? label;
  final bool isActive;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final iconCollapsed = hideInIconCollapse(context);
    final spacing = context.tpSpacing;
    final sidebarTheme = HujiSidebarTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    final accent = sidebarTheme.accentColor ??
        cs.onSurface.withValues(
          alpha: cs.brightness == Brightness.dark ? 0.10 : 0.06,
        );
    final accentFg = sidebarTheme.accentForegroundColor ?? cs.onSurface;
    final fg = (sidebarTheme.foregroundColor ?? cs.onSurface)
        .withValues(alpha: isActive ? 1 : 0.82);
    final hover =
        isActive ? accent : TpHover.defaultHoverColor(context);

    final showLabel = !iconCollapsed && label != null && label!.isNotEmpty;
    final tipMessage = tooltip ?? (iconCollapsed ? (label ?? '') : '');
    final iconSize = context.tpIconSizes.sm;
    final railWidth = sidebarTheme.widthIcon;

    final iconWidget = icon == null
        ? null
        : IconTheme(
            data: IconThemeData(
              size: iconSize,
              color: isActive ? accentFg : fg,
            ),
            child: icon!,
          );

    // OverflowBox keeps expanded-width children while the panel clips to the
    // left [widthIcon] strip — center icons inside that strip, not the full width.
    // Align left so stretch constraints from Column don't expand the rail box.
    final Widget rowChild;
    if (iconCollapsed) {
      rowChild = Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: railWidth,
          height: 32,
          child: Center(child: iconWidget),
        ),
      );
    } else {
      rowChild = SizedBox(
        height: 32,
        child: Row(
          children: [
            if (iconWidget != null) iconWidget,
            if (showLabel) ...[
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.mdMediumColored(isActive ? accentFg : fg),
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: isActive ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TpHover(
        onTap: onPressed,
        hoverColor: hover,
        borderRadius: BorderRadius.circular(6),
        padding: iconCollapsed
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                horizontal: spacing.sm,
                vertical: spacing.xs,
              ),
        child: rowChild,
      ),
    );

    if (tipMessage.isNotEmpty) {
      content = TpTooltip(message: tipMessage, child: content);
    }

    return content;
  }
}

/// Trailing icon action for a [HujiSidebarMenuItem] row.
class HujiSidebarMenuAction extends StatelessWidget {
  const HujiSidebarMenuAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (hideInIconCollapse(context)) {
      return const SizedBox.shrink();
    }

    return TpIconButton(
      icon: icon,
      onTap: onPressed,
      tooltip: tooltip,
      compact: true,
      size: TpIconButton.kCompactSize,
    );
  }
}

/// Count / status badge for a [HujiSidebarMenuItem].
///
/// When icon-collapsed, [HujiSidebarMenuItem] replaces this with a indicator
/// dot (`Key('huji-sidebar-badge-dot')`) instead of rendering [label]/[child].
class HujiSidebarMenuBadge extends StatelessWidget {
  const HujiSidebarMenuBadge({
    super.key,
    this.label,
    this.child,
  }) : assert(label != null || child != null);

  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) return child!;

    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;
    final spacing = context.tpSpacing;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label!,
        style: styles.smColored(cs.onSurfaceVariant),
      ),
    );
  }
}

/// Static nested list under a parent [HujiSidebarMenuItem] (no accordion).
class HujiSidebarMenuSub extends StatelessWidget {
  const HujiSidebarMenuSub({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final cs = Theme.of(context).colorScheme;
    final border = cs.outlineVariant.withValues(alpha: 0.55);
    return Padding(
      padding: EdgeInsets.only(
        left: spacing.md,
        top: spacing.xxs,
        bottom: spacing.xxs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: border, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: spacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 2),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper for one entry inside [HujiSidebarMenuSub].
class HujiSidebarMenuSubItem extends StatelessWidget {
  const HujiSidebarMenuSubItem({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Nested menu button under [HujiSidebarMenuSub].
class HujiSidebarMenuSubButton extends StatelessWidget {
  const HujiSidebarMenuSubButton({
    super.key,
    this.icon,
    this.label,
    this.isActive = false,
    this.onPressed,
  });

  final Widget? icon;
  final String? label;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final sidebarTheme = HujiSidebarTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    final accent = sidebarTheme.accentColor ??
        cs.onSurface.withValues(
          alpha: cs.brightness == Brightness.dark ? 0.10 : 0.06,
        );
    final accentFg = sidebarTheme.accentForegroundColor ?? cs.onSurface;
    final fg = (sidebarTheme.foregroundColor ?? cs.onSurface)
        .withValues(alpha: isActive ? 1 : 0.75);
    final hover =
        isActive ? accent : TpHover.defaultHoverColor(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isActive ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TpHover(
        onTap: onPressed,
        hoverColor: hover,
        borderRadius: BorderRadius.circular(6),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: SizedBox(
          height: 28,
          child: Row(
            children: [
              if (icon != null)
                IconTheme(
                  data: IconThemeData(
                    size: context.tpIconSizes.sm,
                    color: isActive ? accentFg : fg,
                  ),
                  child: icon!,
                ),
              if (label != null && label!.isNotEmpty) ...[
                if (icon != null) SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.mdColored(isActive ? accentFg : fg),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
