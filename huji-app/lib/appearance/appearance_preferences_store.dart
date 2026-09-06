import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';

const _kPrefix = 'shared_ui.appearance.';

class AppearancePreferencesStore {
  Future<AppearancePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppearancePreferences(
      themeMode: prefs.getString('${_kPrefix}themeMode') ?? 'light',
      themeColorPreset: normalizeThemeColorPreset(
        prefs.getString('${_kPrefix}themeColorPreset'),
      ),
      typographyScale: normalizeTypographyScale(
        prefs.getString('${_kPrefix}typographyScale'),
      ),
      typographyScaleCustomMultiplier: clampTypographyCustomMultiplier(
        prefs.getDouble('${_kPrefix}typographyCustom') ??
            kDefaultTypographyCustomMultiplier,
      ),
      uiZoomScale: normalizeTypographyScale(
        prefs.getString('${_kPrefix}uiZoomScale'),
      ),
      uiZoomCustomMultiplier: clampTypographyCustomMultiplier(
        prefs.getDouble('${_kPrefix}uiZoomCustom') ??
            kDefaultTypographyCustomMultiplier,
      ),
      locale: prefs.getString('${_kPrefix}locale') ?? 'zh',
    );
  }

  Future<void> save(AppearancePreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_kPrefix}themeMode', preferences.themeMode);
    await prefs.setString(
      '${_kPrefix}themeColorPreset',
      preferences.themeColorPreset,
    );
    await prefs.setString(
      '${_kPrefix}typographyScale',
      preferences.typographyScale,
    );
    await prefs.setDouble(
      '${_kPrefix}typographyCustom',
      preferences.typographyScaleCustomMultiplier,
    );
    await prefs.setString('${_kPrefix}uiZoomScale', preferences.uiZoomScale);
    await prefs.setDouble(
      '${_kPrefix}uiZoomCustom',
      preferences.uiZoomCustomMultiplier,
    );
    await prefs.setString('${_kPrefix}locale', preferences.locale);
  }

  /// Debug helper.
  String encode(AppearancePreferences p) => jsonEncode({
        'themeMode': p.themeMode,
        'themeColorPreset': p.themeColorPreset,
        'locale': p.locale,
      });
}
