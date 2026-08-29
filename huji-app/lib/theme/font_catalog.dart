enum FontRole { ui, mono }

enum FontSourceKind { bundled }

class FontCatalogEntry {
  const FontCatalogEntry({
    required this.id,
    required this.role,
    required this.source,
    this.bundledFamily,
    this.assetPaths = const [],
  });

  final String id;
  final FontRole role;
  final FontSourceKind source;
  final String? bundledFamily;
  final List<String> assetPaths;
}

abstract final class FontCatalog {
  /// Defaults — bundled faces, registered by [loadFontsFor] before first paint.
  static const defaultUiId = 'notoSansSc';
  static const defaultMonoId = 'jetbrainsMono';

  static const List<FontCatalogEntry> all = [
    FontCatalogEntry(
      id: defaultUiId,
      role: FontRole.ui,
      source: FontSourceKind.bundled,
      // Must match [FontLoader] family exactly. GoogleFonts registers
      // `Noto Sans SC_regular` instead; using that mismatch on Android makes
      // U+0020 resolve to a ~1em-wide face and blows out English word gaps.
      bundledFamily: 'Noto Sans SC',
      assetPaths: [
        'assets/google_fonts/NotoSansSC-Regular.ttf',
        'assets/google_fonts/NotoSansSC-Medium.ttf',
        'assets/google_fonts/NotoSansSC-SemiBold.ttf',
        'assets/google_fonts/NotoSansSC-Bold.ttf',
        'assets/google_fonts/NotoSansSC-ExtraBold.ttf',
      ],
    ),
    FontCatalogEntry(
      id: defaultMonoId,
      role: FontRole.mono,
      source: FontSourceKind.bundled,
      bundledFamily: 'JetBrainsMono NFM',
      assetPaths: [
        'assets/fonts/terminal/JetBrainsMonoNerdFontMono-Regular.ttf',
      ],
    ),
  ];

  static FontCatalogEntry entry(FontRole role, String id) {
    for (final e in all) {
      if (e.role == role && e.id == id) return e;
    }
    return all.firstWhere((e) => e.role == role);
  }
}
