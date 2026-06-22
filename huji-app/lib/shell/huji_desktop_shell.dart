import 'package:flutter/material.dart';
import 'package:huji_app/shell/huji_desktop_sidebar.dart';
import 'package:shared_ui/shell/workspace_surface_layers.dart';
import 'package:shared_ui/widgets/chrome/desktop_window_title_bar.dart';
import 'package:shared_ui/widgets/layout/workspace_right_pane.dart';

/// Teampilot-style desktop chrome: custom title bar + wide sidebar + card body.
class HujiDesktopShell extends StatelessWidget {
  const HujiDesktopShell({
    required this.currentRoute,
    required this.child,
    super.key,
  });

  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.workspacePage,
      body: Column(
        children: [
          const DesktopWindowTitleBar(title: '弧迹'),
          Expanded(
            child: WorkspacePageCardShell(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HujiDesktopSidebar(currentRoute: currentRoute),
                  Expanded(
                    child: WorkspaceRightPane(
                      contentKey: currentRoute,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
