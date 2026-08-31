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

/// Layout metrics from autoclip-web-front [LoginForm.vue], uniformly scaled for
/// desktop so proportions match the web dialog but read at a similar visual size.
abstract final class LoginDialogLayout {
  /// Uniform scale over the web modal (Tailwind / Element Plus baseline).
  static const scale = 4 / 3;

  static const maxWidth = 597.0; // web max-w-md 448 × scale
  static const contentPadding = 32.0; // web p-6 24 × scale
  static const noticeTopGap = 21.0;

  /// Target height for inputs and the login button (web h-12 48 × scale).
  static const controlHeight = 72.0;

  static const controlPaddingH = 16.0;
  static EdgeInsets get controlPadding => const EdgeInsets.symmetric(
        horizontal: controlPaddingH,
      );

  /// Vertical padding inside login inputs — tune to adjust field feel.
  static const inputPaddingV = 24.0;

  /// Passed to [TpInputFormField.metrics] / [TpInput.metrics].
  static TpControlSizeMetrics get inputMetrics => TpControlSizeMetrics(
        height: controlHeight,
        minWidth: 64,
        horizontalPadding: controlPaddingH,
        verticalPadding: inputPaddingV,
      );

  static const controlRadius = 11.0; // web rounded-lg 8 × scale
  static const prefixIconSize = 22.0;

  static const socialButtonSize = 53.0; // web h-10 40 × scale
  static const socialIconSize = 22.0;
  static const socialIconPadding = 12.0;
  static const socialButtonGap = 11.0; // web gap-2 8 × scale

  static const fieldGap = 21.0; // web space-y-4 16 × scale
  static const sectionGap = 32.0; // web space-y-6 / my-6 24 × scale
  static const tabGap = 32.0;
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
      hintStyle: TpTextStyles(base).mutedMd.copyWith(
        color: LoginDialogColors.mutedText,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LoginDialogLayout.controlRadius),
        borderSide: const BorderSide(color: LoginDialogColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LoginDialogLayout.controlRadius),
        borderSide: const BorderSide(color: LoginDialogColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LoginDialogLayout.controlRadius),
        borderSide: const BorderSide(color: LoginDialogColors.primary, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LoginDialogLayout.controlRadius),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),
  );
}
