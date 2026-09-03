import 'package:flutter/material.dart';

/// Legacy 10px captions mapped from [TpTextStyles.xs] (labelSmall ≈ 11).
const TextScaler kLegacyCaptionTextScaler = TextScaler.linear(10 / 11);

/// Legacy 18px section titles mapped from [TpTextStyles.xl] (titleLarge = 20).
const TextScaler kLegacySectionTitleTextScaler = TextScaler.linear(18 / 20);

/// Theme-aware replacements for legacy hardcoded Material greys on mobile.
extension ThemedMobileContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}

extension ThemedMobileColors on ColorScheme {
  Color get cardFill => surfaceContainerLow;

  Color get subtleFill => surfaceContainerHighest;

  /// Legacy mobile home: grey[50] page behind white cards.
  Color get legacyPageBackground =>
      brightness == Brightness.light ? const Color(0xFFFAFAFA) : surface;

  /// Legacy mobile cards: white fill with border + shadow on light theme.
  Color get legacyCardFill =>
      brightness == Brightness.light ? Colors.white : surface;

  Color get mutedForeground => onSurfaceVariant;

  Color get softShadow =>
      shadow.withValues(alpha: brightness == Brightness.dark ? 0.28 : 0.10);
}
