import 'package:flutter/foundation.dart';

import 'font_catalog.dart';

/// Resolved UI and mono font families for theme / mono consumers.
@immutable
final class ResolvedFonts {
  const ResolvedFonts({
    required this.uiFamily,
    required this.uiFallback,
    required this.monoFamily,
    required this.monoFallback,
  });

  final String uiFamily;
  final List<String> uiFallback;
  final String monoFamily;
  final List<String> monoFallback;
}

/// Catalog-driven resolution for the UI + mono roles. Huji ships bundled
/// faces only (no system-font preference), so resolution is the bundled
/// family plus a platform fallback chain.
abstract final class AppFontResolver {
  /// Bundled JetBrains mono family (catalog id `jetbrainsMono`).
  static const String bundledMonoFamily = 'JetBrainsMono NFM';

  static ResolvedFonts resolve({
    String? uiFontId,
    String? monoFontId,
    TargetPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    final ui = FontCatalog.entry(
      FontRole.ui,
      uiFontId ?? FontCatalog.defaultUiId,
    );
    final mono = FontCatalog.entry(
      FontRole.mono,
      monoFontId ?? FontCatalog.defaultMonoId,
    );
    return ResolvedFonts(
      uiFamily: ui.bundledFamily!,
      uiFallback: _systemUiFallback(resolvedPlatform),
      monoFamily: mono.bundledFamily!,
      monoFallback: monoCjkFallback(resolvedPlatform),
    );
  }

  /// Platform mono fallback chain (primary excluded). Used by the bundled
  /// [bundledMonoFamily] and [AppFonts.monoFamilyFallback].
  ///
  /// A Simplified-Chinese CJK mono face is listed before the generic
  /// `monospace` alias: fontconfig often maps `monospace` (even under
  /// `lang=zh`) to *Noto Sans Mono CJK JP*, whose Japanese `locl` forms
  /// misplace Chinese punctuation — and once JP covers CJK, later SC
  /// fallbacks never run.
  static List<String> monoCjkFallback(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.macOS => [
        'Monaco',
        'Courier New',
        'Noto Sans Mono CJK SC',
        'monospace',
      ],
      TargetPlatform.windows => [
        'Cascadia Mono',
        'Courier New',
        'Courier',
        'Noto Sans Mono CJK SC',
        'monospace',
      ],
      TargetPlatform.linux => [
        // Bundled JetBrainsMono NFM covers Latin. Explicit fallbacks are
        // resolved eagerly via fontconfig on every new paragraph (one
        // ~140ms scan per family), and none of the system mono faces are
        // FontLoader-registered — so keep the chain empty and let missing
        // glyphs fall through to the engine's system font table instead of
        // paying a per-family scan.
      ],
      TargetPlatform.android => [
        'Noto Sans Mono CJK SC',
        'Noto Sans CJK SC',
        'monospace',
      ],
      _ => [
        'Noto Sans Mono CJK SC',
        'Noto Sans CJK SC',
        'WenQuanYi Zen Hei Mono',
        'monospace',
      ],
    };
  }

  static ({String family, List<String> fallback}) _systemUi(
    TargetPlatform platform,
  ) {
    return switch (platform) {
      TargetPlatform.macOS => (
        family: 'PingFang SC',
        fallback: ['.AppleSystemUIFont', 'Heiti SC', 'Helvetica Neue'],
      ),
      TargetPlatform.windows => (
        family: 'Segoe UI',
        fallback: ['Microsoft YaHei'],
      ),
      TargetPlatform.android => (
        family: 'sans-serif',
        fallback: ['Noto Sans CJK SC', 'Droid Sans Fallback'],
      ),
      _ => (
        // An explicit family keeps Skia on the named-font path; an empty
        // family falls to the engine default typeface, which on Linux still
        // scans fontconfig per paragraph. Note: only the bundled Noto Sans
        // SC (the default) avoids the scan entirely.
        family: 'Noto Sans',
        fallback: const [],
      ),
    };
  }

  /// Fallback chain behind the bundled UI primary.
  static List<String> _systemUiFallback(TargetPlatform platform) =>
      _systemUi(platform).fallback;
}
