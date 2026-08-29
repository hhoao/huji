import 'package:flutter/material.dart';

import 'package:shared_ui/shared_ui.dart';
import 'huji_sidebar_icon_collapse.dart';

/// Sticky bottom slot inside [HujiSidebar] (non-scrolling).
class HujiSidebarFooter extends StatelessWidget {
  const HujiSidebarFooter({
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
