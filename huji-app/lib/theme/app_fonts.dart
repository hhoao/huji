import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:shared_ui/shared_ui.dart';

import 'app_font_resolver.dart';
import 'font_catalog.dart';

export 'app_font_resolver.dart' show AppFontResolver, ResolvedFonts;

/// Central **font family** names for Huji UI.
///
/// **Font sizes** are configured in [AppTypographyScale] (`app_typography_scale.dart`)
/// — edit `*Base` constants or `standard` / `compact` / `comfortable` multipliers.
///
/// Bundled mono catalog family name; active faces come from [ResolvedFonts]
/// via [loadFontsFor]. Platform CJK mono fallbacks are owned by
/// [AppFontResolver]. Families are published on [ThemeData] as [TpFontTheme].
abstract final class AppFonts {
  /// Primary UI sans (CJK + Latin), bundled per [FontCatalog].
  static const String uiGoogleFontName = 'Noto Sans SC';

  /// Bundled JetBrains catalog family (id `jetbrainsMono`), used by
  /// [TpTextStyles.mono] (terminal / code editor / log viewer).
  static const String monoFamily = AppFontResolver.bundledMonoFamily;

  /// Mono fallback chain for the bundled [monoFamily]. Delegates to
  /// [AppFontResolver.monoCjkFallback] (Latin faces, then SC before `monospace`).
  static List<String> get monoFamilyFallback =>
      AppFontResolver.monoCjkFallback(defaultTargetPlatform);
}

/// Monospace [TextStyle] using theme body size unless [fontSize] is set.
TextStyle appMonoTextStyle(
  BuildContext context, {
  TextStyle? base,
  double? fontSize,
  double height = 1.35,
  Color? color,
}) {
  final fonts = context.tpFonts;
  final typography = context.appTypography;
  final resolvedBase =
      base ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  return resolvedBase.copyWith(
    fontFamily: fonts.monoFontFamily,
    fontFamilyFallback: fonts.monoFontFamilyFallback,
    fontSize: fontSize ?? resolvedBase.fontSize ?? typography.mono,
    height: height,
    color: color,
  );
}

ResolvedFonts _defaultResolvedFonts() => AppFontResolver.resolve();

/// Builds [TextTheme] with the bundled UI sans.
///
/// Bundled Noto Sans SC keeps the [GoogleFonts.notoSansScTextTheme] pipeline,
/// then applies [ResolvedFonts] family/fallback so every style points at the
/// exact family [loadFontsFor] registered.
TextTheme buildAppUiTextTheme(TextTheme base, [ResolvedFonts? fonts]) {
  final resolved = fonts ?? _defaultResolvedFonts();
  final themed = GoogleFonts.notoSansScTextTheme(base);
  return themed.apply(
    fontFamily: resolved.uiFamily,
    fontFamilyFallback: resolved.uiFallback,
  );
}

TextTheme buildAppUiPrimaryTextTheme(TextTheme base, [ResolvedFonts? fonts]) {
  final resolved = fonts ?? _defaultResolvedFonts();
  return GoogleFonts.notoSansScTextTheme(base).apply(
    fontFamily: resolved.uiFamily,
    fontFamilyFallback: resolved.uiFallback,
  );
}

/// Publishes the resolved faces on [TpFontTheme] for [TpTextStyles.mono] and
/// the glyph warmup helpers.
TpFontTheme buildTpFontTheme(ResolvedFonts fonts) {
  return TpFontTheme(
    uiFontFamily: fonts.uiFamily,
    uiFontFamilyFallback: fonts.uiFallback,
    monoFontFamily: fonts.monoFamily,
    monoFontFamilyFallback: fonts.monoFallback,
  );
}
