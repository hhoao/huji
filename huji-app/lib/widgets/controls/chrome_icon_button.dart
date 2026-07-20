import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Compact icon control for toolbars and list rows: square hit target, rounded
/// ink splash (AppFlowy-style).
///
/// Named [ChromeIconButton] (not [AppIconButton]) to avoid clashing with
/// huji's local desktop [AppIconButton].
class ChromeIconButton extends StatelessWidget {
  static const double kDefaultSize = 32;
  static const double kDefaultBorderRadius = 6;

  /// Dense toolbar preset (file tree header, terminal tabs, etc.).
  static const double kCompactSize = 28;

  const ChromeIconButton({
    super.key,
    this.icon,
    this.iconWidget,
    required this.onTap,
    this.tooltip,
    this.size = kDefaultSize,
    this.iconSize,
    this.compact = false,
    this.borderRadius = kDefaultBorderRadius,
    this.color,
    this.backgroundColor,
    this.enabled = true,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double? iconSize;
  final bool compact;
  final double borderRadius;
  final Color? color;
  final Color? backgroundColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final sizes = context.tpIconSizes;
    final resolvedIconSize =
        iconSize ?? (compact ? sizes.sm : sizes.md);
    final effectiveColor = color ?? Theme.of(context).colorScheme.tpIcon;
    final radius = BorderRadius.circular(borderRadius);

    Widget iconChild = iconWidget ??
        Icon(icon, size: resolvedIconSize, color: effectiveColor);
    if (!enabled) {
      iconChild = IconTheme(
        data: IconThemeData(color: effectiveColor.withValues(alpha: 0.38)),
        child: iconChild,
      );
    }

    Widget button = TpHover(
      onTap: enabled ? onTap : null,
      enabled: enabled,
      borderRadius: radius,
      backgroundColor: backgroundColor,
      width: size,
      height: size,
      pressScale: 0.97,
      child: Center(child: iconChild),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
