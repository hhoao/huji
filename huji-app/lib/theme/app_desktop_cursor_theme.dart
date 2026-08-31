import 'package:flutter/material.dart';
import 'package:huji_app/services/platform_capability.dart';

/// Desktop-only interaction defaults: pointer cursor on clickable controls.
ThemeData withDesktopClickCursors(ThemeData theme) {
  if (!PlatformCapability.isDesktop) return theme;

  ButtonStyle clickCursorStyle(ButtonStyle? base) {
    return (base ?? const ButtonStyle()).copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      }),
    );
  }

  return theme.copyWith(
    textButtonTheme: TextButtonThemeData(
      style: clickCursorStyle(theme.textButtonTheme.style),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: clickCursorStyle(theme.elevatedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: clickCursorStyle(theme.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: clickCursorStyle(theme.outlinedButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: clickCursorStyle(theme.iconButtonTheme.style),
    ),
    checkboxTheme: theme.checkboxTheme.copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      }),
    ),
    radioTheme: theme.radioTheme.copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      }),
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      }),
    ),
  );
}
