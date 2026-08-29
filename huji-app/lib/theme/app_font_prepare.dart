import 'app_font_loader.dart';
import 'app_font_resolver.dart';

/// Registers the bundled UI / mono faces before first paint.
///
/// Call once from `main()` after binding initialization, on every platform:
/// [FontLoader] registration is what makes runtime font resolution hit the
/// registry directly instead of scanning fontconfig per paragraph, and on
/// Android it is the only way the applied family name resolves at all.
Future<void> prepareFontsForUse() async {
  await loadFontsFor(AppFontResolver.resolve());
}
