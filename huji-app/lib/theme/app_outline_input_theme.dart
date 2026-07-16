import 'package:flutter/material.dart';

import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

/// Fills null [TextStyle.fontSize] from [AppTypographyScale]; keeps explicit
/// sizes (e.g. from Google Fonts).
TextTheme materializeM3TextThemeSizes(
  TextTheme textTheme, {
  AppTypographyScale scale = AppTypographyScale.standard,
}) {
  final sizes = AppTypographyTheme.fromScale(scale);
  TextStyle resolve(TextStyle? style, double fallback) {
    final base = style ?? const TextStyle();
    if (base.fontSize != null) {
      return base.inherit
          ? base.copyWith(
              inherit: false,
              textBaseline: base.textBaseline ?? TextBaseline.alphabetic,
            )
          : base;
    }
    return base.copyWith(
      fontSize: fallback,
      inherit: false,
      textBaseline: base.textBaseline ?? TextBaseline.alphabetic,
    );
  }

  return textTheme.copyWith(
    titleLarge: resolve(textTheme.titleLarge, sizes.titleLarge),
    titleMedium: resolve(textTheme.titleMedium, sizes.titleMedium),
    titleSmall: resolve(textTheme.titleSmall, sizes.titleSmall),
    bodyLarge: resolve(textTheme.bodyLarge, sizes.bodyLarge),
    bodyMedium: resolve(textTheme.bodyMedium, sizes.bodyMedium),
    bodySmall: resolve(textTheme.bodySmall, sizes.bodySmall),
    // labelLarge: M3 button labels (TextButton/OutlinedButton/FilledButton).
    labelLarge: resolve(textTheme.labelLarge, scale.labelLarge),
    labelMedium: resolve(textTheme.labelMedium, sizes.labelMedium),
    labelSmall: resolve(textTheme.labelSmall, sizes.labelSmall),
  );
}

/// Ensures [style] has [TextStyle.fontSize] so M3 hint merge can override
/// [TextTheme.bodyLarge] (color-only theme hints keep the large size).
TextStyle withResolvedFontSize(
  TextStyle style, {
  TextStyle? sizeFrom,
  double? fallback,
  AppTypographyScale scale = AppTypographyScale.standard,
}) {
  final resolvedFallback =
      fallback ?? AppTypographyTheme.fromScale(scale).bodySmall;
  final size = style.fontSize ?? sizeFrom?.fontSize ?? resolvedFallback;
  return style.copyWith(
    fontSize: size,
    inherit: false,
    textBaseline:
        style.textBaseline ?? sizeFrom?.textBaseline ?? TextBaseline.alphabetic,
  );
}

/// M3 [TextField] typed text uses [TextTheme.bodyLarge]. Remap to [bodyMedium]
/// (or pass [inputTextStyle]) so size follows the text scale, not a literal.
TextTheme applyAppInputTextStyles(
  TextTheme textTheme, {
  TextStyle? inputTextStyle,
}) {
  final inputText =
      inputTextStyle ??
      textTheme.bodyMedium ??
      textTheme.bodySmall ??
      textTheme.bodyLarge!;
  return textTheme.copyWith(bodyLarge: inputText.copyWith(height: 1.25));
}

/// Typed text style for a [TextField] when a widget needs an explicit [TextField.style].
TextStyle appTextFieldStyle(TextTheme textTheme) {
  return textTheme.bodyLarge ?? textTheme.bodyMedium ?? const TextStyle();
}

/// Global [InputDecorationTheme] for workspace text fields and dropdowns.
InputDecorationTheme buildAppOutlineInputDecorationTheme({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  double borderRadius = 8,
}) {
  final outline = colorScheme.outlineVariant;
  final radius = BorderRadius.circular(borderRadius);

  OutlineInputBorder outlineBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  final hintColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.72);
  final labelColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.9);
  final hintBase = textTheme.bodyMedium ?? textTheme.bodyLarge!;
  final hintStyle = withResolvedFontSize(
    hintBase.copyWith(
      color: hintColor,
      height: 1.25,
      fontWeight: FontWeight.w400,
    ),
    sizeFrom: textTheme.bodySmall ?? textTheme.bodyMedium,
    fallback: AppTypographyScale.standard.bodySmall,
  );

  return InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.workspaceCard,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    constraints: const BoxConstraints(minHeight: 40),
    hintStyle: hintStyle,
    labelStyle: textTheme.bodyMedium?.copyWith(color: labelColor),
    floatingLabelStyle: textTheme.bodyMedium?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w500,
    ),
    border: outlineBorder(outline),
    enabledBorder: outlineBorder(outline),
    focusedBorder: outlineBorder(colorScheme.primary, 1.5),
    errorBorder: outlineBorder(colorScheme.error),
    focusedErrorBorder: outlineBorder(colorScheme.error, 1.5),
    disabledBorder: outlineBorder(outline.withValues(alpha: 0.38)),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
  );
}
