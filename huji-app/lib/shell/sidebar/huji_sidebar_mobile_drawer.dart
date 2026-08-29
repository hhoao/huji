import 'package:flutter/material.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

import 'huji_sidebar_theme.dart';
import 'huji_sidebar_config.dart';

/// Full-screen mobile overlay: edge-open strip, scrim, sliding panel, back dismiss.
class HujiSidebarMobileDrawer extends StatefulWidget {
  const HujiSidebarMobileDrawer({
    super.key,
    required this.side,
    required this.theme,
    required this.openMobile,
    required this.edgeOpenEnabled,
    required this.onOpenMobileChange,
    required this.child,
  });

  final HujiSidebarSide side;
  final HujiSidebarTheme theme;
  final bool openMobile;
  final bool edgeOpenEnabled;
  final ValueChanged<bool> onOpenMobileChange;
  final Widget child;

  @override
  State<HujiSidebarMobileDrawer> createState() => _HujiSidebarMobileDrawerState();
}

class _HujiSidebarMobileDrawerState extends State<HujiSidebarMobileDrawer> {
  static const double _edgeHitWidth = 20;

  double _dragExtent = 0;
  bool _isDragging = false;

  double _drawerWidth(BuildContext context) =>
      widget.theme.resolveMobileDrawerWidth(MediaQuery.sizeOf(context).width);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDragging) {
      _syncExtentFromOpen();
    }
  }

  @override
  void didUpdateWidget(covariant HujiSidebarMobileDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _syncExtentFromOpen();
    }
  }

  void _syncExtentFromOpen() {
    final target = widget.openMobile ? _drawerWidth(context) : 0.0;
    if (_dragExtent != target) {
      setState(() => _dragExtent = target);
    }
  }

  void _setOpenMobile(bool open) {
    widget.onOpenMobileChange(open);
    if (!_isDragging) {
      setState(() => _dragExtent = open ? _drawerWidth(context) : 0);
    }
  }

  double _signedDelta(double delta) {
    return widget.side == HujiSidebarSide.left ? delta : -delta;
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final width = _drawerWidth(context);
    final next = (_dragExtent + _signedDelta(details.delta.dx))
        .clamp(0.0, width);
    if (next != _dragExtent) {
      setState(() => _dragExtent = next);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    final width = _drawerWidth(context);
    final velocity = details.primaryVelocity ?? 0;
    final signedVelocity =
        widget.side == HujiSidebarSide.left ? velocity : -velocity;

    bool open;
    if (signedVelocity.abs() > 500) {
      open = signedVelocity > 0;
    } else {
      open = _dragExtent > width * 0.5;
    }

    widget.onOpenMobileChange(open);
    setState(() => _dragExtent = open ? width : 0);
  }

  double _panelOffset(BuildContext context) {
    final width = _drawerWidth(context);
    if (widget.side == HujiSidebarSide.left) {
      return _dragExtent - width;
    }
    return width - _dragExtent;
  }

  Widget _buildPanel(BuildContext overlayContext) {
    final scheme = Theme.of(overlayContext).colorScheme;
    final width = _drawerWidth(overlayContext);
    return Material(
      elevation: 8,
      color: widget.theme.backgroundColor ?? scheme.workspacePage,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showDrawer = _dragExtent > 0;
    final showEdgeStrip = widget.edgeOpenEnabled &&
        !widget.openMobile &&
        _dragExtent == 0 &&
        !_isDragging;

    Widget stack = Stack(
      fit: StackFit.expand,
      children: [
        if (showDrawer)
          ModalBarrier(
            dismissible: true,
            color: Colors.black54,
            onDismiss: () => _setOpenMobile(false),
          ),
        if (showDrawer)
          Positioned(
            left: widget.side == HujiSidebarSide.left ? _panelOffset(context) : null,
            right: widget.side == HujiSidebarSide.right ? _panelOffset(context) : null,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: _buildPanel(context),
            ),
          ),
        if (showEdgeStrip)
          Positioned(
            left: widget.side == HujiSidebarSide.left ? 0 : null,
            right: widget.side == HujiSidebarSide.right ? 0 : null,
            top: 0,
            bottom: 0,
            width: _edgeHitWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );

    if (widget.openMobile) {
      stack = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _setOpenMobile(false);
          }
        },
        child: stack,
      );
    }

    return stack;
  }
}
