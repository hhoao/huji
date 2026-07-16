import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/platform/desktop_window_actions.dart';
import 'package:huji_app/platform/platform_utils.dart';
import 'package:shared_ui/shared_ui.dart';

/// Wraps [child] in the window-move area and restores the interactions a native
/// title bar would provide on a frameless window:
///
/// * drag to move and double-click to maximize/restore — already provided by
///   [DragToMoveArea];
/// * a right-click window menu (minimize / maximize / restore / always-on-top /
///   close) — added here, since a frameless GTK window has no native one.
///
/// The window operations themselves are delegated to window_manager; this
/// widget only supplies the menu UI and the secondary-tap gesture. On Android
/// (no custom title bar) it returns [child] unchanged.
class WindowDragArea extends StatelessWidget {
  const WindowDragArea({required this.child, super.key});

  final Widget child;

  Future<void> _showWindowMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    // Resolve the menu anchor synchronously, before any async gap, so the
    // BuildContext is only used while it is guaranteed mounted.
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      overlay.size.width - globalPosition.dx,
      overlay.size.height - globalPosition.dy,
    );

    final expanded = await isDesktopWindowExpanded();
    final onTop =
        await windowManagerCall(windowManager.isAlwaysOnTop) ?? false;
    if (!context.mounted) return;

    final l10n = context.hujiL10n;
    final selected = await showMenu<_WindowMenuAction>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: _WindowMenuAction.minimize,
          child: _MenuRow(
            icon: Icons.remove,
            label: l10n.windowControlMinimize,
          ),
        ),
        PopupMenuItem(
          value: expanded
              ? _WindowMenuAction.restore
              : _WindowMenuAction.maximize,
          child: _MenuRow(
            icon: expanded ? Icons.filter_none : Icons.crop_square_outlined,
            label: expanded
                ? l10n.windowControlRestore
                : l10n.windowControlMaximize,
          ),
        ),
        CheckedPopupMenuItem(
          value: _WindowMenuAction.toggleAlwaysOnTop,
          checked: onTop,
          child: Text(l10n.windowControlAlwaysOnTop),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _WindowMenuAction.close,
          child: _MenuRow(icon: Icons.close, label: l10n.windowControlClose),
        ),
      ],
    );

    switch (selected) {
      case _WindowMenuAction.minimize:
        await windowManagerCall(windowManager.minimize);
      case _WindowMenuAction.maximize:
      case _WindowMenuAction.restore:
        await toggleDesktopWindowExpand();
      case _WindowMenuAction.toggleAlwaysOnTop:
        await windowManagerCall(() => windowManager.setAlwaysOnTop(!onTop));
      case _WindowMenuAction.close:
        await windowManagerCall(windowManager.close);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!useCustomDesktopWindowTitleBar) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) =>
          _showWindowMenu(context, details.globalPosition),
      child: DragToMoveArea(child: child),
    );
  }
}

enum _WindowMenuAction { minimize, maximize, restore, toggleAlwaysOnTop, close }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.tpIconSizes.md),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
