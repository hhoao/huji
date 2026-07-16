import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';
export 'huji_l10n_helpers.dart';

extension HujiL10n on BuildContext {
  HujiLocalizations get hujiL10n => HujiLocalizations.of(this);
}

/// Preset display names for [ThemeColorPresetPicker] (ported from shared_ui).
extension HujiL10nTheme on HujiLocalizations {
  String themeColorPresetName(String id) {
    return switch (id) {
      'ocean' => themePresetOcean,
      'violet' => themePresetViolet,
      'amber' => themePresetAmber,
      'forest' => themePresetForest,
      'graphite' => themePresetGraphite,
      _ => themePresetGraphite,
    };
  }
}
