import 'package:flutter/material.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/layout/workspace_route_transition.dart';

/// Teampilot workspace-home right pane chrome: uniform inset + route transition.
class WorkspaceRightPane extends StatelessWidget {
  const WorkspaceRightPane({
    required this.contentKey,
    required this.child,
    this.padding = WorkspacePageCardShell.rightPanePadding,
    super.key,
  });

  final Object contentKey;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: WorkspaceRouteTransition(routeKey: contentKey, child: child),
    );
  }
}
