import 'package:flutter/material.dart';

/// Tooltip label style. Flutter's default [Tooltip] hardcodes 12px on desktop;
/// we use the scaled [TextTheme.bodyMedium] so tooltips follow the app's
/// text-size setting.
TextStyle appTooltipTextStyle({
  required TextTheme textTheme,
  required Brightness brightness,
}) {
  final base = textTheme.bodyMedium ?? const TextStyle();
  final color = brightness == Brightness.dark ? Colors.black : Colors.white;
  return base.copyWith(color: color, height: 1.4);
}

TooltipThemeData buildAppTooltipTheme({
  required TextTheme textTheme,
  required Brightness brightness,
}) {
  return TooltipThemeData(
    textStyle: appTooltipTextStyle(
      textTheme: textTheme,
      brightness: brightness,
    ),
    decoration: BoxDecoration(
      color: brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.9)
          : Colors.grey.shade700.withValues(alpha: 0.9),
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}
