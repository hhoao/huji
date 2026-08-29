import 'package:flutter/material.dart';

import 'package:shared_ui/shared_ui.dart';
import 'huji_sidebar_scope.dart';

/// Toolbar control that toggles the sidebar.
class HujiSidebarTrigger extends StatelessWidget {
  const HujiSidebarTrigger({
    super.key,
    this.icon,
    this.tooltip,
    this.size = TpIconButton.kDefaultSize,
    this.selected = false,
    this.onPressed,
  });

  final Widget? icon;
  final String? tooltip;
  final double size;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final onTap = onPressed ?? HujiSidebarScope.of(context).toggleSidebar;
    if (icon != null) {
      return TpIconButton(
        iconWidget: icon,
        onTap: onTap,
        tooltip: tooltip,
        size: size,
        selected: selected,
      );
    }
    return TpIconButton(
      icon: selected ? Icons.menu_open : Icons.menu,
      onTap: onTap,
      tooltip: tooltip,
      size: size,
      selected: selected,
    );
  }
}
