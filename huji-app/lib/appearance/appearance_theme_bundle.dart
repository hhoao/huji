import 'package:flutter/material.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:shared_ui/shared_ui.dart';

/// Resolved theme + zoom values for [MaterialApp].
class AppearanceThemeBundle {
  const AppearanceThemeBundle({
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
    required this.locale,
    required this.uiZoom,
    required this.textScaleMultiplier,
    required this.iconScaleMultiplier,
  });

  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;
  final Locale locale;
  final double uiZoom;

  /// Effective text multiplier (includes OS auto baseline).
  final double textScaleMultiplier;

  /// Damped icon multiplier for [TpThemeData.iconScale].
  final double iconScaleMultiplier;
}

AppearanceThemeBundle resolveAppearanceTheme(
  AppearancePreferences prefs,
  MediaQueryData systemMq,
) {
  final textBaseline = PlatformCapability.isDesktop
      ? autoTextScaleForSystem(
          systemMq.textScaler.scale(1.0),
          systemMq.devicePixelRatio,
        )
      : autoTextScaleForMobile();
  final effectiveTextMult = resolveRelativeScale(
    scaleId: prefs.typographyScale,
    customMultiplier: prefs.typographyScaleCustomMultiplier,
    baseline: textBaseline,
  );
  final textScale = AppTypographyScale(multiplier: effectiveTextMult);
  final iconMult = TpIconSizes.resolveIconMultiplier(
    effectiveTextMultiplier: effectiveTextMult,
    textBaseline: textBaseline,
  );
  final iconScale = AppTypographyScale(multiplier: iconMult);

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
    textScaleMultiplier: effectiveTextMult,
    iconScaleMultiplier: iconMult,
  );
}
