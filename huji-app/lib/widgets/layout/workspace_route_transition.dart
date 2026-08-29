import 'package:flutter/material.dart';

/// Fade (+ optional slide) played when [routeKey] changes — route / tab swaps.
///
/// Replaces `child.animate(key: ValueKey(...))` chains: a persistent
/// controller replays from [didUpdateWidget] instead of swapping the Animate
/// element, so the child subtree is never remounted on navigation. A
/// RepaintBoundary under the transitions caches the content raster, making
/// the animation composite-only (opacity / offset layer updates per frame).
class WorkspaceRouteTransition extends StatefulWidget {
  const WorkspaceRouteTransition({
    required this.routeKey,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.slide = true,
    super.key,
  });

  /// Identity of the content — the transition replays whenever it changes.
  final Object routeKey;
  final Widget child;
  final Duration duration;

  /// Whether content slides in from the right alongside the fade.
  final bool slide;

  @override
  State<WorkspaceRouteTransition> createState() =>
      _WorkspaceRouteTransitionState();
}

class _WorkspaceRouteTransitionState extends State<WorkspaceRouteTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  // Fade finishes 180ms into the 220ms timeline; slide runs the full span.
  // Mirrors the previous .fadeIn(180ms).slideX(220ms) flutter_animate chain.
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Interval(0, 180 / widget.duration.inMilliseconds, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0.025, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(WorkspaceRouteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeKey != oldWidget.routeKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = RepaintBoundary(child: widget.child);
    if (widget.slide) {
      content = SlideTransition(position: _slide, child: content);
    }
    return FadeTransition(opacity: _fade, child: content);
  }
}
