import 'package:flutter/material.dart';
import 'package:huji_app/constants/desktop_theme.dart';

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
        widget.hoverColor ?? DesktopTheme.hoverHighlight;
    final effectiveBg = widget.backgroundColor ?? Colors.transparent;
    final effectiveRadius =
        widget.borderRadius ?? DesktopTheme.radiusMd;

    return MouseRegion(
      cursor: widget.enabled && widget.onTap != null
          ? DesktopTheme.clickCursor
          : DesktopTheme.defaultCursor,
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
          duration: DesktopTheme.animationFast,
          curve: DesktopTheme.defaultCurve,
          child: AnimatedContainer(
            duration: DesktopTheme.animationFast,
            curve: DesktopTheme.defaultCurve,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.onTap != null
                      ? effectiveHoverColor
                      : effectiveBg)
                  : effectiveBg,
              borderRadius:
                  BorderRadius.circular(effectiveRadius),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
