import 'package:flutter/material.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';

enum _AppButtonVariant { custom, primary, outlined, text }

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
  final _AppButtonVariant _variant;

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
  }) : _variant = _AppButtonVariant.custom;

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
  })  : backgroundColor = null,
        foregroundColor = null,
        borderColor = null,
        _variant = _AppButtonVariant.primary;

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
  })  : backgroundColor = null,
        foregroundColor = null,
        borderColor = null,
        _variant = _AppButtonVariant.outlined;

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
        foregroundColor = null,
        borderColor = null,
        _variant = _AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final (variantBg, variantFg, variantBorder) = switch (_variant) {
      _AppButtonVariant.primary => (
          cs.primary,
          cs.onPrimary,
          cs.primary,
        ),
      _AppButtonVariant.outlined => (
          Colors.transparent,
          cs.onSurfaceVariant,
          context.desktopBorderMedium,
        ),
      _AppButtonVariant.text => (
          null as Color?,
          cs.onSurfaceVariant,
          Colors.transparent,
        ),
      _AppButtonVariant.custom => (
          backgroundColor,
          foregroundColor,
          borderColor,
        ),
    };

    final effectiveBg = variantBg ?? Colors.transparent;
    final effectiveFg = variantFg ?? cs.onSurfaceVariant;
    final effectiveBorder = variantBorder ?? Colors.transparent;
    final effectiveRadius = borderRadius ?? desktopRadiusMd;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final effectiveTextStyle =
        textStyle ?? TpTextStyles.of(context).sm;

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

    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(effectiveRadius),
      padding: effectivePadding,
      backgroundColor: effectiveBg,
      pressScale: 0.97,
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
