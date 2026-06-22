import 'package:flutter/material.dart';
import 'package:huji_app/utils/desktop_style.dart';

/// Universal hover/press wrapper for all desktop interactive widgets.
///
/// Provides:
/// - MouseRegion with click cursor
/// - Animated background color on hover (150ms)
/// - Animated scale on press (0.97x)
class AppHoverBox extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? hoverColor;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double pressScale;
  final bool enabled;

  const AppHoverBox({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.hoverColor,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.pressScale = 0.97,
    this.enabled = true,
  });

  @override
  State<AppHoverBox> createState() => _AppHoverBoxState();
}

class _AppHoverBoxState extends State<AppHoverBox> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHoverColor =
        widget.hoverColor ?? context.desktopHoverHighlight;
    final effectiveBg = widget.backgroundColor ?? Colors.transparent;
    final effectiveRadius = widget.borderRadius ?? desktopRadiusMd;

    return MouseRegion(
      cursor: widget.enabled && widget.onTap != null
          ? desktopClickCursor
          : desktopDefaultCursor,
      onEnter: (_) {
        if (widget.enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
      },
      child: GestureDetector(
        onTapDown: widget.enabled && widget.onTap != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled && widget.onTap != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressScale : 1.0,
          duration: desktopAnimationFast,
          curve: desktopDefaultCurve,
          child: AnimatedContainer(
            duration: desktopAnimationFast,
            curve: desktopDefaultCurve,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.onTap != null
                      ? effectiveHoverColor
                      : effectiveBg)
                  : effectiveBg,
              borderRadius: BorderRadius.circular(effectiveRadius),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
