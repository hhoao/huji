import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huji_app/platform/desktop_window_actions.dart';
import 'package:window_manager/window_manager.dart';

/// Re-adds resize grips when the native title bar is hidden.
class DragToResizeWrapper extends StatefulWidget {
  const DragToResizeWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<DragToResizeWrapper> createState() => _DragToResizeWrapperState();
}

class _DragToResizeWrapperState extends State<DragToResizeWrapper>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncExpanded());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncExpanded() async {
    final expanded = await isDesktopWindowExpanded();
    if (!mounted) return;
    setState(() => _isMaximized = expanded);
  }

  @override
  void onWindowMaximize() => unawaited(_syncExpanded());

  @override
  void onWindowUnmaximize() => unawaited(_syncExpanded());

  @override
  void onWindowEnterFullScreen() => unawaited(_syncExpanded());

  @override
  void onWindowLeaveFullScreen() => unawaited(_syncExpanded());

  @override
  Widget build(BuildContext context) {
    if (_isMaximized) return widget.child;
    return DragToResizeArea(child: widget.child);
  }
}
