import 'package:flutter/material.dart';

import 'huji_sidebar_config.dart';
import 'huji_sidebar_scope.dart';

/// Inner-edge hit strip: drag to resize when expanded; tap to toggle.
///
/// Place inside a [Stack] over the sidebar panel so it receives a bounded height.
class HujiSidebarRail extends StatefulWidget {
  const HujiSidebarRail({super.key});

  static const double _width = 12;
  static const double _tapSlop = 4;

  @override
  State<HujiSidebarRail> createState() => _HujiSidebarRailState();
}

class _HujiSidebarRailState extends State<HujiSidebarRail> {
  double _dragDistance = 0;

  Alignment get _alignment {
    final side = HujiSidebarConfig.maybeOf(context)?.side ?? HujiSidebarSide.left;
    return side == HujiSidebarSide.left
        ? Alignment.centerRight
        : Alignment.centerLeft;
  }

  void _onDragStart(DragStartDetails _) {
    _dragDistance = 0;
    final scope = HujiSidebarScope.of(context);
    if (scope.open && !scope.isMobile) {
      scope.beginResize();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final scope = HujiSidebarScope.of(context);
    if (!scope.open || scope.isMobile) return;

    final side = HujiSidebarConfig.maybeOf(context)?.side ?? HujiSidebarSide.left;
    final delta = details.delta.dx;
    _dragDistance += delta.abs();
    final signed = side == HujiSidebarSide.left ? delta : -delta;
    scope.setWidth(scope.width + signed);
  }

  void _onDragEnd(DragEndDetails _) {
    final scope = HujiSidebarScope.of(context);
    final wasTap = _dragDistance < HujiSidebarRail._tapSlop;
    scope.endResize();
    _dragDistance = 0;
    if (wasTap) {
      scope.toggleSidebar();
    }
  }

  void _onDragCancel() {
    HujiSidebarScope.of(context).endResize();
    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    final scope = HujiSidebarScope.of(context);
    final canResize = scope.open && !scope.isMobile;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : double.infinity;
        return Align(
          alignment: _alignment,
          child: MouseRegion(
            cursor: canResize
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.click,
            child: GestureDetector(
              key: const Key('huji-sidebar-rail'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: _onDragCancel,
              // Tap without drag still toggles when collapsed (no drag gestures).
              onTap: canResize ? null : scope.toggleSidebar,
              child: SizedBox(
                width: HujiSidebarRail._width,
                height: height,
              ),
            ),
          ),
        );
      },
    );
  }
}
