import 'app_font_loader.dart';
import 'app_font_resolver.dart';

/// Registers the bundled UI / mono faces before first paint, on desktop.
///
/// Call once from `main()` after binding initialization. Mobile skips this:
/// awaiting the ~42MB Noto asset load would drag the cold start, and mobile
/// keeps google_fonts' lazy per-variant asset loading instead. [FontLoader]
/// registration is what makes runtime font resolution hit the registry
/// directly instead of scanning fontconfig per paragraph.
Future<void> prepareFontsForUse() async {
  await loadFontsFor(AppFontResolver.resolve());
}
