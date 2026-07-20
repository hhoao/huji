import 'package:flutter/material.dart';

/// Bridges legacy [DesktopTheme] call sites to Material 3 [ColorScheme].
extension DesktopColorScheme on BuildContext {
  ColorScheme get desktopColors => Theme.of(this).colorScheme;

  Color get desktopPrimary => desktopColors.primary;
  Color get desktopOnSurface => desktopColors.onSurface;
  Color get desktopOnSurfaceVariant => desktopColors.onSurfaceVariant;
  Color get desktopSurfaceContainer => desktopColors.surfaceContainer;
  Color get desktopOutlineVariant => desktopColors.outlineVariant;
  Color get desktopPrimaryContainer => desktopColors.primaryContainer;
  Color get desktopOnPrimaryContainer => desktopColors.onPrimaryContainer;

  Color get desktopBorderLight =>
      desktopColors.outlineVariant.withValues(alpha: 0.35);

  Color get desktopBorderMedium =>
      desktopColors.outlineVariant.withValues(alpha: 0.55);

  Color get desktopHoverHighlight => Theme.of(this).hoverColor;

  Color get desktopActiveBg =>
      desktopColors.primaryContainer.withValues(alpha: 0.35);

  Color get desktopActiveFg => desktopColors.primary;
}

const desktopAnimationNormal = Duration(milliseconds: 250);
const desktopAnimationFast = Duration(milliseconds: 150);
const desktopDefaultCurve = Curves.easeOut;
const desktopRadiusMd = 6.0;
const desktopRadiusLg = 8.0;


