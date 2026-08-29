import 'package:flutter/services.dart';

import 'package:huji_app/utils/logger_utils.dart';

import 'app_font_resolver.dart';
import 'font_catalog.dart';

/// Families already registered this process — skip re-[FontLoader.load], which
/// can invalidate every [RenderParagraph] and cause multi-second layouts.
final Set<String> _loadedFamilies = <String>{};

/// Loads the bundled faces required by [fonts] before first paint.
///
/// Faces are registered under the catalog family name (NOT GoogleFonts'
/// `*_regular` key) so the `fontFamily` values applied by the theme resolve
/// directly against the [FontLoader] registry — see [FontCatalog] for why the
/// GoogleFonts key breaks Android word gaps and leaves the mono face unloaded.
Future<void> loadFontsFor(ResolvedFonts fonts) async {
  for (final entry in FontCatalog.all) {
    if (entry.bundledFamily != fonts.uiFamily &&
        entry.bundledFamily != fonts.monoFamily) {
      continue;
    }
    final family = entry.bundledFamily;
    if (family == null || _loadedFamilies.contains(family)) continue;
    await _registerFontAssets(
      loader: FontLoader(family),
      family: family,
      assets: entry.assetPaths,
    );
  }
}

/// Adds every [assets] to [loader], loads the family, and records it as
/// registered. Per-asset and registration failures are logged; the family name
/// stays in play so Flutter falls through the [ResolvedFonts] fallbacks.
Future<void> _registerFontAssets({
  required FontLoader loader,
  required String family,
  required List<String> assets,
}) async {
  var addedAny = false;
  for (final asset in assets) {
    try {
      loader.addFont(rootBundle.load(asset));
      addedAny = true;
    } on Object catch (error, stackTrace) {
      AppLogger.instance.w(
        'Failed to load font asset: $asset',
        error,
        stackTrace,
      );
    }
  }
  if (!addedAny) return;
  try {
    await loader.load();
    _loadedFamilies.add(family);
  } on Object catch (error, stackTrace) {
    AppLogger.instance.w(
      'Failed to register font family: $family',
      error,
      stackTrace,
    );
  }
}
