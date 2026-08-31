import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Web login modal palette (Element Plus + Tailwind tokens from autoclip-web-front).
abstract final class LoginDialogColors {
  static const cardBackground = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFF3F4F6); // gray-100
  static const titleText = Color(0xFF1F2937); // gray-800
  static const bodyText = Color(0xFF4B5563); // gray-600
  static const mutedText = Color(0xFF6B7280); // gray-500
  static const inputBorder = Color(0xFFE5E7EB); // gray-200
  static const inputBorderHover = Color(0xFF9CA3AF); // gray-400
  static const primary = Color(0xFF409EFF); // Element Plus default
  static const iconMuted = Color(0xFF9CA3AF); // gray-400
  static const buttonBorder = Color(0xFFDCDFE6);
  static const buttonText = Color(0xFF606266);
  static const orangeNotice = Color(0xFFFB923C); // orange-400
  static const socialBorder = Color(0xFFD1D5DB); // gray-300
  static const socialHover = Color(0xFFF3F4F6); // gray-100
}

/// Forces the login modal subtree onto a light card theme regardless of app mode.
ThemeData loginDialogTheme(BuildContext context) {
  final base = Theme.of(context);
  final scheme = ColorScheme.light(
    primary: LoginDialogColors.primary,
    onPrimary: Colors.white,
    surface: LoginDialogColors.cardBackground,
    onSurface: LoginDialogColors.titleText,
    onSurfaceVariant: LoginDialogColors.mutedText,
    outline: LoginDialogColors.inputBorder,
    outlineVariant: LoginDialogColors.inputBorder,
  );

  return base.copyWith(
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: LoginDialogColors.cardBackground,
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return LoginDialogColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: const BorderSide(color: LoginDialogColors.inputBorder, width: 1.5),
      visualDensity: VisualDensity.compact,
    ),
    dividerColor: LoginDialogColors.inputBorder,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LoginDialogColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: TpTextStyles(base).mutedMd.copyWith(
        color: LoginDialogColors.mutedText,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LoginDialogColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LoginDialogColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LoginDialogColors.primary, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),
  );
}
