import 'package:flutter/material.dart';

import 'package:shared_ui/shared_ui.dart';
import 'huji_sidebar_icon_collapse.dart';

/// Padded section inside [HujiSidebarContent] for a label, optional action, and
/// menu block.
class HujiSidebarGroup extends StatelessWidget {
  const HujiSidebarGroup({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final collapsed = hideInIconCollapse(context);
    return Padding(
      padding: padding ??
          (collapsed
              ? EdgeInsets.symmetric(vertical: spacing.xs)
              : EdgeInsets.all(spacing.sm)),
      child: child,
    );
  }
}

/// Small section label above a [HujiSidebarGroupContent] block.
class HujiSidebarGroupLabel extends StatelessWidget {
  const HujiSidebarGroupLabel({
    super.key,
    required this.label,
    this.padding,
  });

  final String label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (hideInIconCollapse(context)) {
      return const SizedBox.shrink();
    }

    final spacing = context.tpSpacing;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(spacing.sm, spacing.xs, spacing.sm, spacing.xxs),
      child: SizedBox(
        height: 24,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: styles.smMediumColored(
              cs.onSurfaceVariant.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Trailing icon action for a [HujiSidebarGroup] header row.
class HujiSidebarGroupAction extends StatelessWidget {
  const HujiSidebarGroupAction({
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

/// Body slot under a group label (typically [HujiSidebarMenu]).
class HujiSidebarGroupContent extends StatelessWidget {
  const HujiSidebarGroupContent({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
