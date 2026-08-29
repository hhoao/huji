import 'package:flutter/material.dart';

import 'huji_sidebar_config.dart';
import 'huji_sidebar_scope.dart';

/// Whether chrome should hide for desktop icon-rail collapse.
bool hideInIconCollapse(BuildContext context) {
  final config = HujiSidebarConfig.maybeOf(context);
  final scope = HujiSidebarScope.maybeOf(context);
  if (config == null || scope == null) return false;
  return config.collapsible == HujiSidebarCollapsible.icon &&
      scope.state == HujiSidebarDesktopState.collapsed &&
      !scope.isMobile;
}
