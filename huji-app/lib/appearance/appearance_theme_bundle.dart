import 'package:flutter/material.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:shared_ui/theme/app_icon_sizes.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:shared_ui/theme/app_typography_scale.dart';

/// Resolved theme + zoom values for [MaterialApp].
class AppearanceThemeBundle {
  const AppearanceThemeBundle({
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
    required this.locale,
    required this.uiZoom,
  });

  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;
  final Locale locale;
  final double uiZoom;
}

AppearanceThemeBundle resolveAppearanceTheme(
  AppearancePreferences prefs,
  MediaQueryData systemMq,
) {
  final textBaseline = autoTextScaleForSystem(
    systemMq.textScaler.scale(1.0),
    systemMq.devicePixelRatio,
  );
  final effectiveTextMult = resolveRelativeScale(
    scaleId: prefs.typographyScale,
    customMultiplier: prefs.typographyScaleCustomMultiplier,
    baseline: textBaseline,
  );
  final textScale = AppTypographyScale(multiplier: effectiveTextMult);
  final iconScale = AppTypographyScale(
    multiplier: AppIconSizes.resolveIconMultiplier(
      effectiveTextMultiplier: effectiveTextMult,
      textBaseline: textBaseline,
    ),
  );

  final themeMode = switch (prefs.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  final locale = switch (prefs.locale) {
    'en' => const Locale('en'),
    'zh' => const Locale('zh'),
    _ => const Locale('zh'),
  };

  final effectiveZoom = clampUiZoom(
    resolveRelativeScale(
      scaleId: prefs.uiZoomScale,
      customMultiplier: prefs.uiZoomCustomMultiplier,
      baseline: autoUiZoomForDevicePixelRatio(systemMq.devicePixelRatio),
    ),
  );

  return AppearanceThemeBundle(
    lightTheme: buildLightTheme(prefs.themeColorPreset, textScale, iconScale),
    darkTheme: buildDarkTheme(prefs.themeColorPreset, textScale, iconScale),
    themeMode: themeMode,
    locale: locale,
    uiZoom: effectiveZoom,
  );
}
