import 'package:equatable/equatable.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';

class AppearancePreferences extends Equatable {
  const AppearancePreferences({
    this.themeMode = 'dark',
    this.themeColorPreset = kDefaultThemeColorPreset,
    this.typographyScale = kDefaultTypographyScaleId,
    this.typographyScaleCustomMultiplier = kDefaultTypographyCustomMultiplier,
    this.uiZoomScale = kDefaultTypographyScaleId,
    this.uiZoomCustomMultiplier = kDefaultTypographyCustomMultiplier,
    this.locale = 'zh',
  });

  final String themeMode;
  final String themeColorPreset;
  final String typographyScale;
  final double typographyScaleCustomMultiplier;
  final String uiZoomScale;
  final double uiZoomCustomMultiplier;
  final String locale;

  AppearancePreferences copyWith({
    String? themeMode,
    String? themeColorPreset,
    String? typographyScale,
    double? typographyScaleCustomMultiplier,
    String? uiZoomScale,
    double? uiZoomCustomMultiplier,
    String? locale,
  }) {
    return AppearancePreferences(
      themeMode: themeMode ?? this.themeMode,
      themeColorPreset: themeColorPreset ?? this.themeColorPreset,
      typographyScale: typographyScale ?? this.typographyScale,
      typographyScaleCustomMultiplier: typographyScaleCustomMultiplier ??
          this.typographyScaleCustomMultiplier,
      uiZoomScale: uiZoomScale ?? this.uiZoomScale,
      uiZoomCustomMultiplier:
          uiZoomCustomMultiplier ?? this.uiZoomCustomMultiplier,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        themeColorPreset,
        typographyScale,
        typographyScaleCustomMultiplier,
        uiZoomScale,
        uiZoomCustomMultiplier,
        locale,
      ];
}
