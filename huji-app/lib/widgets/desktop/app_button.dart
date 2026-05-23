import 'package:flutter/material.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';

/// Desktop button with hover highlight and press scale.
///
/// Variants:
/// - [AppButton.primary] — filled primary color
/// - [AppButton.outlined] — bordered, transparent fill
/// - [AppButton.text] — no border, subtle hover
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final double iconSize;
  final MainAxisSize mainAxisSize;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  })  : backgroundColor = DesktopTheme.primaryColor,
        foregroundColor = Colors.white,
        borderColor = DesktopTheme.primaryColor;

  const AppButton.outlined({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  })  : backgroundColor = Colors.transparent,
        foregroundColor = DesktopTheme.textSecondary,
        borderColor = DesktopTheme.borderMedium;

  const AppButton.text({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  })  : backgroundColor = null,
        foregroundColor = DesktopTheme.textSecondary,
        borderColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? Colors.transparent;
    final effectiveFg = foregroundColor ?? DesktopTheme.textSecondary;
    final effectiveBorder = borderColor ?? Colors.transparent;
    final effectiveRadius = borderRadius ?? DesktopTheme.radiusMd;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final effectiveTextStyle =
        textStyle ?? const TextStyle(fontSize: 12);

    final child = Row(
      mainAxisSize: mainAxisSize,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: effectiveFg),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: effectiveTextStyle.copyWith(color: effectiveFg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return AppHoverBox(
      onTap: onTap,
      borderRadius: effectiveRadius,
      padding: effectivePadding,
      backgroundColor: effectiveBg,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: effectiveBorder),
          borderRadius: BorderRadius.circular(effectiveRadius),
        ),
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
