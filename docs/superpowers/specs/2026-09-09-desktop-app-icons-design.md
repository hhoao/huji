# Desktop App Icon Unification Design

Date: 2026-09-09
Status: Approved (approach A — full teampilot parity with self-contained rasterization)

## Problem

The Linux AppImage ships a placeholder icon: `huji-app/scripts/appimage/huji.svg`
is a rounded rectangle with a text glyph "弧" that renders as plain text in most
desktop environments. The `flutter_launcher_icons` config in `pubspec.yaml`
exists but was never fully wired: `linux/runner/resources/` does not exist
(flutter_launcher_icons 0.14 has **no Linux support** — the `linux:` section in
the config is dead config, silently ignored), and the Windows icon is
generated at only 48px. The only source artwork, `assets/icons/logo_bg.png`,
is 418×418.

TeamPilot solves this with a one-command icon regeneration tool
(`client/tool/sync_app_icons.dart`): run `flutter_launcher_icons`, then copy a
committed 1024×1024 master PNG to `linux/runner/resources/app_icon.png`.

## Goal

One command regenerates all launcher icons (Android/iOS/Web/Windows/macOS plus
Linux bundle + AppImage/deb) from a single 1024×1024 master icon rendered from
the vector logo. Works on any machine that can run Flutter — no system
rasterizer (rsvg-convert/inkscape) required.

## Source artwork

- Vector logo: `assets/svg/logo_no_font.svg` (real brand artwork, viewBox
  394×368).
- Background: solid black `#000000` (matches existing `logo_bg.png` corners).
- Composition: black square canvas, logo centered; logo proportions calibrated
  against the existing 418px `logo_bg.png` so the new icons are visually
  identical to the old ones, only sharper.

## Components

| File | Action | Purpose |
|---|---|---|
| `test/tools/generate_app_icon_test.dart` | add | Flutter widget test: loads the SVG via `flutter_svg`, paints it centered on a black canvas inside a `RepaintBoundary`, exports via `toImage()` two PNGs (see Outputs). Runs under plain `flutter test` — cross-platform, no system deps. |
| `assets/icons/logo_bg_1024.png` | add (generated, committed) | 1024×1024 master icon, full-bleed black square. Single source for flutter_launcher_icons, Linux bundle icon, and deb icon. |
| `scripts/appimage/huji.png` | add (generated, committed) | 256×256, rounded corners (rx ≈ 48/256), transparent outside the corners. Replaces the placeholder. |
| `scripts/appimage/huji.svg` | delete | The placeholder being replaced. |
| `tool/sync_app_icons.dart` | add | One-command sync tool (teampilot pattern). |
| `pubspec.yaml` | edit | `flutter_launcher_icons`: every `image_path` → `assets/icons/logo_bg_1024.png`; Windows `icon_size` 48 → 256; drop the dead `linux:` section. |
| `scripts/build_appimage.sh` | edit | Copy `huji.png` (not the svg) into `$APPDIR` and `usr/share/icons/hicolor/256x256/apps/`; `--icon-file` → `huji.png`. |
| `linux/packaging/deb/make_config.yaml` | edit | `icon:` → `assets/icons/logo_bg_1024.png`. |
| `CLAUDE.md` | edit | Document `dart run tool/sync_app_icons.dart`. |

## Tool flow (`dart run tool/sync_app_icons.dart`, run from `huji-app/`)

1. `flutter test test/tools/generate_app_icon_test.dart` — renders
   `assets/icons/logo_bg_1024.png` and `scripts/appimage/huji.png`.
2. `dart run flutter_launcher_icons` — regenerates Android/iOS/Web/Windows/macOS
   icons from the master.
3. Copy `assets/icons/logo_bg_1024.png` → `linux/runner/resources/app_icon.png`
   (the Linux gap flutter_launcher_icons does not cover — teampilot's approach).

Each step's exit code is checked; the tool stops on first failure with a clear
message. All generated files are committed (teampilot's policy), so CI and
developers who never run the tool still build correctly.

## Shape policy

- 1024 master: full-bleed black square. Android applies its own mask; macOS
  applies its squircle; iOS strips alpha (`remove_alpha_ios: true` stays).
- Linux 256px AppImage icon: rounded corners with transparency outside — most
  Linux app icons are rounded; a hard black square reads as unfinished on the
  desktop.

## Unchanged

- `linux/runner/my_application.cc` runtime window-icon resolution (reads
  `flutter_assets/assets/icons/logo_bg.png`) — 418px is plenty for a window
  icon and the file stays.
- `assets/icons/logo_bg.png` itself — still referenced by splash and the
  runtime window icon.

## Error handling

- Sync tool: fails fast if `pubspec.yaml` is missing (wrong cwd), if the
  generator test fails, or if `flutter_launcher_icons` fails; prints each
  step's output.
- Generator test: fails if `assets/svg/logo_no_font.svg` is missing from the
  asset bundle.

## Verification

1. Run `dart run tool/sync_app_icons.dart`; confirm the master PNG, AppImage
   PNG, `linux/runner/resources/app_icon.png`, and regenerated
   Android/Windows/macOS/Web icons all exist and look right.
2. Run `scripts/build_appimage.sh`; extract the AppImage and check `.DirIcon`,
   `huji.png`, and the hicolor 256x256 entry are the new icon.
3. Re-run the tool — idempotent.
