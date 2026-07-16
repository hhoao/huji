import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

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
      child: child
          .animate(key: ValueKey(contentKey))
          .fadeIn(duration: 180.ms, curve: Curves.easeOut)
          .slideX(
            begin: 0.025,
            end: 0,
            duration: 220.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
