import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/appearance/appearance_preferences_store.dart';
import 'package:huji_app/theme/app_theme.dart';

class AppearanceCubit extends Cubit<AppearancePreferences> {
  AppearanceCubit({
    AppearancePreferencesStore? store,
    AppearancePreferences? initial,
  })  : _store = store ?? AppearancePreferencesStore(),
        super(initial ?? const AppearancePreferences()) {
    if (initial == null) {
      unawaited(_load());
    }
  }

  final AppearancePreferencesStore _store;

  /// Loads persisted preferences before [runApp] so the first frame uses the
  /// saved theme instead of [AppearancePreferences] defaults.
  static Future<AppearanceCubit> load({
    AppearancePreferencesStore? store,
  }) async {
    final resolvedStore = store ?? AppearancePreferencesStore();
    try {
      final prefs = await resolvedStore.load();
      return AppearanceCubit(store: resolvedStore, initial: prefs);
    } catch (_) {
      return AppearanceCubit(store: resolvedStore);
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await _store.load();
      emit(prefs);
    } catch (_) {
      emit(const AppearancePreferences());
    }
  }

  Future<void> setThemeMode(String mode) async {
    final next = state.copyWith(themeMode: mode);
    emit(next);
    await _store.save(next);
  }

  Future<void> setThemeColorPreset(String preset) async {
    final next = state.copyWith(
      themeColorPreset: normalizeThemeColorPreset(preset),
    );
    emit(next);
    await _store.save(next);
  }

  Future<void> setLocale(String locale) async {
    final next = state.copyWith(locale: locale);
    emit(next);
    await _store.save(next);
  }

  Future<void> setTypographyScale(String scale, {double? custom}) async {
    final next = state.copyWith(
      typographyScale: scale,
      typographyScaleCustomMultiplier:
          custom ?? state.typographyScaleCustomMultiplier,
    );
    emit(next);
    await _store.save(next);
  }

  Future<void> setUiZoomScale(String scale, {double? custom}) async {
    final next = state.copyWith(
      uiZoomScale: scale,
      uiZoomCustomMultiplier: custom ?? state.uiZoomCustomMultiplier,
    );
    emit(next);
    await _store.save(next);
  }
}
