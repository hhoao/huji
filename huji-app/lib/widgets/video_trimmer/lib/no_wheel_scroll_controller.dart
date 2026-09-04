import 'package:flutter/widgets.dart';

/// 时间轴专用的 ScrollController：禁用滚轮 / 触摸板滚动。
///
/// 精修页里 hover 到片段边界手柄时，触摸板横向滚动会平移时间轴，
/// 误触率高；时间轴平移应只由拖拽和播放跟随（jumpTo）驱动。
/// 覆写 [ScrollPositionWithSingleContext.pointerScroll] 后，
/// wheel/trackpad 事件被直接丢弃，拖拽、惯性滚动与 jumpTo 均不受影响。
class NoWheelScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _NoWheelScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _NoWheelScrollPosition extends ScrollPositionWithSingleContext {
  _NoWheelScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  @override
  void pointerScroll(double delta) {
    // 丢弃滚轮/触摸板增量：不改变 pixels，只复位 ballistic 状态，
    // 与基类 delta == 0 的处理保持一致。
    goBallistic(0.0);
  }
}
