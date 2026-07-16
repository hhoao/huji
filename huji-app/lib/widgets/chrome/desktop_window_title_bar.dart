import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:huji_app/platform/desktop_window_actions.dart';
import 'package:huji_app/platform/platform_utils.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:shared_ui/theme/app_text_styles.dart';
import 'package:huji_app/widgets/chrome/window_chrome_controls.dart';
import 'package:huji_app/widgets/chrome/window_drag_area.dart';

/// Height of the in-app replacement for the native window title bar.
const double kDesktopWindowTitleBarHeight = 40;

/// Desktop-only custom title bar (minimize / maximize / close).
///
/// Requires [TitleBarStyle.hidden] and [windowButtonVisibility] false at startup
/// — see [main.dart]. On macOS the controls are left-aligned traffic lights;
/// on Linux and Windows they stay on the right in Windows style.
class DesktopWindowTitleBar extends StatefulWidget {
  const DesktopWindowTitleBar({
    this.title = 'TeamPilot',
    super.key,
  });

  final String title;

  @override
  State<DesktopWindowTitleBar> createState() => _DesktopWindowTitleBarState();
}

class _DesktopWindowTitleBarState extends State<DesktopWindowTitleBar>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!useCustomDesktopWindowTitleBar) return;
    windowManager.addListener(this);
    _syncExpanded();
  }

  @override
  void dispose() {
    if (useCustomDesktopWindowTitleBar) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _syncExpanded() async {
    final expanded = await isDesktopWindowExpanded();
    if (!mounted) return;
    setState(() => _isMaximized = expanded);
  }

  Future<void> _toggleMaximize({bool optionPressed = false}) async {
    if (Platform.isMacOS) {
      await handleMacGreenButton(optionPressed: optionPressed);
    } else {
      await toggleDesktopWindowExpand();
    }
    await _syncExpanded();
  }

  @override
  void onWindowMaximize() => unawaited(_syncExpanded());

  @override
  void onWindowUnmaximize() => unawaited(_syncExpanded());

  @override
  void onWindowEnterFullScreen() => unawaited(_syncExpanded());

  @override
  void onWindowLeaveFullScreen() => unawaited(_syncExpanded());

  Widget _buildWindowControls() {
    return WindowChromeControls(
      height: kDesktopWindowTitleBarHeight,
      isMaximized: _isMaximized,
      onMinimize: () => windowManagerCall(windowManager.minimize),
      onToggleMaximize: _toggleMaximize,
      onClose: () => windowManagerCall(windowManager.close),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!useCustomDesktopWindowTitleBar) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);

    final title = Padding(
      padding: EdgeInsets.only(left: useMacWindowChromeStyle ? 8 : 16),
      child: Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.of(context).bodyStrong.copyWith(
          color: titleColor.withValues(alpha: 0.9),
        ),
      ),
    );

    return Material(
      color: cs.workspacePage,
      child: SizedBox(
        height: kDesktopWindowTitleBarHeight,
        child: Row(
          children: [
            if (useMacWindowChromeStyle) _buildWindowControls(),
            Expanded(
              child: WindowDragArea(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: title,
                ),
              ),
            ),
            if (!useMacWindowChromeStyle) _buildWindowControls(),
          ],
        ),
      ),
    );
  }
}

/// Wraps [child] with [DesktopWindowTitleBar] on desktop targets.
class DesktopWindowChrome extends StatelessWidget {
  const DesktopWindowChrome({
    required this.child,
    this.title = 'TeamPilot',
    super.key,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (!useCustomDesktopWindowTitleBar) {
      return child;
    }

    return Column(
      children: [
        DesktopWindowTitleBar(title: title),
        Expanded(child: child),
      ],
    );
  }
}
