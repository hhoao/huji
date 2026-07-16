import 'package:flutter/material.dart';
import 'package:shared_ui/theme/app_icon_sizes.dart';

/// Compact icon control for toolbars and list rows: square hit target, rounded
/// ink splash (AppFlowy-style).
class AppIconButton extends StatelessWidget {
  static const double kDefaultSize = 32;
  static const double kDefaultBorderRadius = 6;

  /// Dense toolbar preset (file tree header, terminal tabs, etc.).
  static const double kCompactSize = 28;

  const AppIconButton({
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
    final sizes = context.appIconSizes;
    final resolvedIconSize =
        iconSize ?? (compact ? sizes.sm : sizes.md);
    final effectiveColor = color ?? context.appIconColor;
    final radius = BorderRadius.circular(borderRadius);

    Widget iconChild = iconWidget ??
        Icon(icon, size: resolvedIconSize, color: effectiveColor);
    if (!enabled) {
      iconChild = IconTheme(
        data: IconThemeData(color: effectiveColor.withValues(alpha: 0.38)),
        child: iconChild,
      );
    }

    Widget ink = Ink(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: backgroundColor,
      ),
      child: InkWell(
        borderRadius: radius,
        hoverColor: effectiveColor.withValues(alpha: 0.12),
        splashColor: effectiveColor.withValues(alpha: 0.2),
        onTap: enabled ? onTap : null,
        child: Center(child: iconChild),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      ink = Tooltip(message: tooltip!, child: ink);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: ink,
    );
  }
}
