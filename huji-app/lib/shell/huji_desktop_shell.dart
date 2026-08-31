import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/shortcut_route_scope.dart';
import 'package:huji_app/shell/huji_desktop_sidebar.dart';
import 'package:huji_app/shell/sidebar/sidebar.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/chrome/desktop_window_title_bar.dart';
import 'package:huji_app/widgets/message/message_bell_button.dart';
import 'package:huji_app/widgets/layout/workspace_right_pane.dart';
import 'package:panes/panes.dart';

/// Teampilot-style desktop chrome: custom title bar + inset sidebar + card body.
class HujiDesktopShell extends StatefulWidget {
  const HujiDesktopShell({
    required this.currentRoute,
    required this.child,
    super.key,
  });

  final String currentRoute;
  final Widget child;

  static const sidebarPaneId = 'sidebar';
  static const bodyPaneId = 'body';

  @override
  State<HujiDesktopShell> createState() => _HujiDesktopShellState();
}

class _HujiDesktopShellState extends State<HujiDesktopShell> {
  late final PaneController _panes;
  CommandHandler? _toggleSidebarHandler;

  @override
  void initState() {
    super.initState();
    _panes = PaneController(
      entries: const [
        PaneEntry(
          id: HujiDesktopShell.sidebarPaneId,
          initialSize: PaneSizePixel(280),
          minSize: PaneSizePixel(200),
          maxSize: PaneSizePixel(420),
        ),
        PaneEntry(
          id: HujiDesktopShell.bodyPaneId,
          initialSize: PaneSizeFraction(1),
        ),
      ],
    );
    _toggleSidebarHandler = _toggleSidebar;
    context.read<CommandBus>().register(
      CommandIds.toggleSidebar,
      _toggleSidebarHandler!,
    );
  }

  @override
  void dispose() {
    final handler = _toggleSidebarHandler;
    if (handler != null) {
      context.read<CommandBus>().unregister(CommandIds.toggleSidebar, handler);
    }
    _panes.dispose();
    super.dispose();
  }

  void _toggleSidebar() => _panes.toggle(HujiDesktopShell.sidebarPaneId);

  @override
  Widget build(BuildContext context) {
    ShortcutRouteScope.instance.update(widget.currentRoute);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.workspacePage,
      body: Focus(
        autofocus: true,
        child: Column(
          children: [
            ListenableBuilder(
              listenable: _panes,
              builder: (context, _) {
                final sidebarVisible = _panes.isVisible(
                  HujiDesktopShell.sidebarPaneId,
                );
                return DesktopWindowTitleBar(
                  title: context.hujiL10n.appTitle,
                  leading: HujiSidebarTrigger(
                    selected: !sidebarVisible,
                    onPressed: _toggleSidebar,
                  ),
                  trailing: const MessageBellButton(),
                );
              },
            ),
            Expanded(
              child: PaneTheme(
                data: PaneThemeData(
                  resizerColor: Colors.transparent,
                  resizerHoverColor: cs.outlineVariant.withValues(alpha: 0.55),
                  resizerFocusedColor: cs.primary.withValues(alpha: 0.4),
                  resizerThickness: 1,
                  resizerHitTestThickness: 8,
                ),
                child: MultiPane(
                  direction: Axis.horizontal,
                  controller: _panes,
                  paneBuilder: (context, id, _) => switch (id) {
                    HujiDesktopShell.sidebarPaneId => Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 6, 12),
                      child: HujiSidebarInset(
                        child: HujiDesktopSidebar(
                          currentRoute: widget.currentRoute,
                        ),
                      ),
                    ),
                    HujiDesktopShell.bodyPaneId => Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 12, 12),
                      child: HujiSidebarInset(
                        child: WorkspaceRightPane(
                          contentKey: widget.currentRoute,
                          child: widget.child,
                        ),
                      ),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
