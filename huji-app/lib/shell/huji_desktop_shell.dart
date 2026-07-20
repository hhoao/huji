import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shell/huji_desktop_sidebar.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/chrome/desktop_window_title_bar.dart';
import 'package:huji_app/widgets/layout/workspace_right_pane.dart';
import 'package:shared_ui/shared_ui.dart';

/// Teampilot-style desktop chrome: custom title bar + inset sidebar + card body.
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
      body: TpSidebarProvider(
        defaultOpen: true,
        child: Column(
          children: [
            DesktopWindowTitleBar(
              title: context.hujiL10n.appTitle,
              leading: const TpSidebarTrigger(),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HujiDesktopSidebar(currentRoute: currentRoute),
                  Expanded(
                    child: Padding(
                      // Keep a small gap so inset card breathes against the rail.
                      padding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                      child: TpSidebarInset(
                        child: WorkspaceRightPane(
                          contentKey: currentRoute,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
