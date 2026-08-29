import 'package:flutter/material.dart';

/// Which edge the sidebar docks to.
enum HujiSidebarSide { left, right }

/// Visual treatment of the sidebar panel.
enum HujiSidebarVariant { sidebar, floating, inset }

/// How the sidebar collapses on desktop.
enum HujiSidebarCollapsible { none, icon, offcanvas }

/// Inherited layout config published by [HujiSidebar] for descendants.
class HujiSidebarConfig extends InheritedWidget {
  const HujiSidebarConfig({
    super.key,
    required this.side,
    required this.variant,
    required this.collapsible,
    required super.child,
  });

  final HujiSidebarSide side;
  final HujiSidebarVariant variant;
  final HujiSidebarCollapsible collapsible;

  static HujiSidebarConfig of(BuildContext context) {
    final config = maybeOf(context);
    if (config == null) {
      throw FlutterError(
        'HujiSidebarConfig.of() called with a context that does not contain a '
        'HujiSidebarConfig.\n'
        'No HujiSidebarConfig ancestor could be found starting from the context '
        'that was passed to HujiSidebarConfig.of().\n'
        'The context used was:\n'
        '  $context',
      );
    }
    return config;
  }

  static HujiSidebarConfig? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HujiSidebarConfig>();

  @override
  bool updateShouldNotify(HujiSidebarConfig oldWidget) =>
      side != oldWidget.side ||
      variant != oldWidget.variant ||
      collapsible != oldWidget.collapsible;
}
