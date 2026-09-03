import 'package:flutter/material.dart';
import 'package:huji_app/services/platform_capability.dart';
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

/// Layout metrics from autoclip-web-front [LoginForm.vue].
///
/// Desktop keeps the web modal's proportions uniformly scaled (×4/3 over the
/// Tailwind / Element Plus baseline) so it reads at a similar visual size;
/// mobile renders the web baseline directly — phone screens are dense enough
/// without the upscale.
abstract final class LoginDialogLayout {
  static bool get _isDesktop => PlatformCapability.isDesktop;

  static double get maxWidth => _isDesktop ? 597.0 : 448.0; // web max-w-md
  static double get contentPadding => _isDesktop ? 32.0 : 24.0; // web p-6
  static double get noticeTopGap => _isDesktop ? 21.0 : 16.0; // web pt-4

  /// Target height for inputs and the login button (web h-12 48).
  static double get controlHeight => _isDesktop ? 72.0 : 48.0;

  static double get controlPaddingH => _isDesktop ? 16.0 : 12.0;
  static EdgeInsets get controlPadding => EdgeInsets.symmetric(
        horizontal: controlPaddingH,
      );

  /// Vertical padding inside login inputs — tune to adjust field feel.
  static double get inputPaddingV => _isDesktop ? 24.0 : 14.0;

  /// Passed to [TpInputFormField.metrics] / [TpInput.metrics].
  static TpControlSizeMetrics get inputMetrics => TpControlSizeMetrics(
        height: controlHeight,
        minWidth: 64,
        horizontalPadding: controlPaddingH,
        verticalPadding: inputPaddingV,
      );

  static double get controlRadius => _isDesktop ? 11.0 : 8.0; // web rounded-lg

  /// Prefix icon edge length as a multiple of the input's body text size.
  /// Icons carry less ink than glyphs, so ~1.3× the font size reads as "about
  /// the same size" while tracking the text-size setting.
  static const double prefixIconTextRatio = 1.3;

  /// Inset from the input's left border to the prefix icon. The web modal's
  /// el-input wrapper padding is 12px; desktop keeps the ×4/3 proportion.
  static double get prefixIconInset => _isDesktop ? 16.0 : 12.0;

  /// Gap between the prefix icon and the input text (M3 adds its own 4px on
  /// top of this).
  static double get prefixIconGap => _isDesktop ? 8.0 : 6.0;

  static double get socialButtonSize => _isDesktop ? 53.0 : 40.0; // web h-10
  /// Social-login icon edge length as a multiple of body text size — slightly
  /// larger than prefix icons since the buttons have no text beside them.
  static const double socialIconTextRatio = 1.5;
  static double get socialIconPadding => _isDesktop ? 12.0 : 9.0;
  static double get socialButtonGap => _isDesktop ? 11.0 : 8.0; // web gap-2

  static double get fieldGap => _isDesktop ? 21.0 : 16.0; // web space-y-4
  static double get sectionGap =>
      _isDesktop ? 32.0 : 24.0; // web space-y-6 / my-6
  static double get tabGap => _isDesktop ? 32.0 : 24.0; // web space-x-6

  /// Gap between the login-type tab label and its underline — the web modal
  /// uses 4px padding-bottom on the checked radio label.
  static double get tabUnderlineGap => _isDesktop ? 6.0 : 4.0;
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
