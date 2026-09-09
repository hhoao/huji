# Desktop App Icon Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One command (`dart run tool/sync_app_icons.dart`) regenerates all huji launcher icons (Android/iOS/Web/Windows/macOS + Linux bundle + AppImage/deb) from a single 1024×1024 master icon rendered from the vector logo — replacing the "弧" text-glyph AppImage placeholder.

**Architecture:** A Flutter widget test rasterizes `assets/svg/logo_no_font.svg` (via `flutter_svg`, already a dependency) onto a black square → 1024px master + 256px rounded AppImage icon. A plain Dart tool (teampilot's `sync_app_icons.dart` pattern) runs that test, runs `flutter_launcher_icons` (Android/iOS/Web/Windows/macOS — it has **no Linux support**), then copies the master to `linux/runner/resources/app_icon.png`. All generated files are committed.

**Tech Stack:** Flutter widget tests (`flutter_test`), `flutter_svg`, `flutter_launcher_icons` ^0.14.4 (already in dev_dependencies), plain `dart:io` script.

**Spec:** `docs/superpowers/specs/2026-09-09-desktop-app-icons-design.md`

## Global Constraints

- All commands run from `huji-app/` unless stated otherwise.
- Generated binaries (PNGs, app_icon.ico, linux app_icon.png) are **committed** — CI and developers who never run the tool must build correctly.
- `linux/runner/my_application.cc` (runtime window-icon resolution from `flutter_assets/assets/icons/logo_bg.png`) is NOT touched.
- `assets/icons/logo_bg.png` stays — still referenced by splash and window icon.
- `remove_alpha_ios: true` and `android: "launcher_icon_dark"` naming stay as-is.
- 1024 master is a full-bleed black square (platforms mask it); the 256px AppImage icon is rounded (rx = 48/256 ≈ 18.75%) with transparency outside the corners.
- Do not touch `huji-app/macos/Runner/Info.plist` (repo has a CI guard on the Impeller entry; unrelated to icons but in the blast radius of icon work).
- Repo commit convention: conventional-commit style, Chinese or English subject OK (see `git log`: `fix(ncnn): …`, `docs: …`).

---

### Task 1: SVG → PNG icon generator test

**Files:**
- Create: `test/tools/generate_app_icon_test.dart`
- Create (by running the test): `assets/icons/logo_bg_1024.png`, `scripts/appimage/huji.png`

**Interfaces:**
- Consumes: `assets/svg/logo_no_font.svg` (existing, declared in pubspec `assets:` as part of `assets/svg/`).
- Produces: `assets/icons/logo_bg_1024.png` (1024×1024 PNG, opaque black background, logo centered at ~78% width) and `scripts/appimage/huji.png` (256×256 PNG, rounded corners, transparent outside). Tasks 2–4 read these exact paths.

- [ ] **Step 1: Write the generator test**

```dart
// test/tools/generate_app_icon_test.dart
//
// Renders the vector logo into the committed app-icon PNGs. Run from
// `huji-app/`:
//
//   flutter test test/tools/generate_app_icon_test.dart
//
// Outputs (both committed):
//   - assets/icons/logo_bg_1024.png  master launcher icon (full-bleed square)
//   - scripts/appimage/huji.png     256px AppImage icon (rounded corners)
//
// Re-run via `dart run tool/sync_app_icons.dart` which also regenerates the
// platform icons.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _sourceSvg = 'assets/svg/logo_no_font.svg';
const _masterIcon = 'assets/icons/logo_bg_1024.png';
const _appimageIcon = 'scripts/appimage/huji.png';

/// Logo width as a fraction of the icon canvas. 0.78 calibrated against the
/// previous 418px logo_bg.png composition; adjust if the master looks off
/// next to assets/icons/logo_bg.png.
const _logoScale = 0.78;

/// Corner radius fraction for the rounded variant — same as the old
/// scripts/appimage/huji.svg placeholder (rx=48 of 256).
const _cornerRadiusFraction = 48 / 256;

Future<ui.Image> _renderIcon(
  WidgetTester tester, {
  required double logicalSize,
  required double pixelRatio,
  required bool rounded,
}) async {
  // Preload the SVG string so no async asset loading races the pump.
  final svg = await rootBundle.loadString(_sourceSvg);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: rounded
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(logicalSize * _cornerRadiusFraction),
                  child: _iconBody(logicalSize, svg),
                )
              : _iconBody(logicalSize, svg),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return boundary.toImage(pixelRatio: pixelRatio);
}

Widget _iconBody(double size, String svg) {
  return Container(
    width: size,
    height: size,
    color: Colors.black,
    alignment: Alignment.center,
    child: SvgPicture.string(
      svg,
      width: size * _logoScale,
      fit: BoxFit.contain,
    ),
  );
}

Future<void> _writePng(ui.Image image, String path) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
}

void main() {
  testWidgets('generate 1024px master icon', (tester) async {
    final image = await _renderIcon(
      tester,
      logicalSize: 256,
      pixelRatio: 4,
      rounded: false,
    );
    expect(image.width, 1024);
    expect(image.height, 1024);
    await _writePng(image, _masterIcon);
  });

  testWidgets('generate 256px rounded AppImage icon', (tester) async {
    final image = await _renderIcon(
      tester,
      logicalSize: 256,
      pixelRatio: 1,
      rounded: true,
    );
    expect(image.width, 256);
    expect(image.height, 256);
    await _writePng(image, _appimageIcon);
  });
}
```

- [ ] **Step 2: Run the test, expect it to pass and write the files**

Run: `flutter test test/tools/generate_app_icon_test.dart`
Expected: `All tests passed!` (2 tests). If `rootBundle.loadString` fails with
"unable to find asset", confirm `assets/svg/` is still listed under
`flutter: assets:` in `pubspec.yaml`.

- [ ] **Step 3: Verify the outputs are real icons**

Run: `file assets/icons/logo_bg_1024.png scripts/appimage/huji.png`
Expected: `PNG image data, 1024 x 1024` and `PNG image data, 256 x 256, 8-bit/color RGBA` (RGBA = the rounded transparent corners).

- [ ] **Step 4: Visual calibration**

Open `assets/icons/logo_bg_1024.png` side by side with `assets/icons/logo_bg.png` (e.g. in an image viewer, or `xdg-open` both). Acceptance: same artwork, black background, logo horizontally centered and occupying a similar share of the canvas as in `logo_bg.png` (within ~5 percentage points). If the composition is visibly different, adjust `_logoScale` in the test (the previous artwork sits around 0.75–0.85) and re-run Step 2.

- [ ] **Step 5: Commit**

```bash
git add test/tools/generate_app_icon_test.dart assets/icons/logo_bg_1024.png scripts/appimage/huji.png
git commit -m "feat(icons): render master + AppImage icons from vector logo"
```

(`scripts/appimage/huji.svg` is still referenced by build_appimage.sh until Task 4 — do not delete it yet.)

---

### Task 2: Point flutter_launcher_icons at the 1024 master

**Files:**
- Modify: `pubspec.yaml` (the `flutter_launcher_icons:` block, ~lines 136–156)
- Modify (by running the tool): `android/app/src/main/res/**` mipmaps, `ios/Runner/Assets.xcassets/AppIcon.appiconset/**`, `web/icons/**` + `web/favicon.png`, `windows/runner/resources/app_icon.ico`, `macos/Runner/Assets.xcassets/AppIcon.appiconset/**`

**Interfaces:**
- Consumes: `assets/icons/logo_bg_1024.png` from Task 1.
- Produces: regenerated platform icons; the pubspec config the sync tool (Task 3) relies on.

- [ ] **Step 1: Replace the flutter_launcher_icons block**

In `pubspec.yaml`, replace the whole block (currently android `launcher_icon_dark`, `image_path: "assets/icons/logo_bg.png"`, windows `icon_size: 48`, dead `linux:` section) with:

```yaml
flutter_launcher_icons:
  android: "launcher_icon_dark"
  ios: true
  image_path: "assets/icons/logo_bg_1024.png"
  min_sdk_android: 21
  remove_alpha_ios: true
  web:
    generate: true
    image_path: "assets/icons/logo_bg_1024.png"
    background_color: "#000000"
    theme_color: "#000000"
  windows:
    generate: true
    image_path: "assets/icons/logo_bg_1024.png"
    icon_size: 256
  macos:
    generate: true
    image_path: "assets/icons/logo_bg_1024.png"
```

(The `linux:` section is dropped — flutter_launcher_icons 0.14 has no Linux support and silently ignores it; Task 3's tool covers Linux.)

- [ ] **Step 2: Run the generator**

Run: `dart run flutter_launcher_icons`
Expected: exit 0, output listing generated icons for Android, iOS, Web, Windows, macOS. If it errors on the Android icon name, verify `android: "launcher_icon_dark"` was kept verbatim.

- [ ] **Step 3: Verify the regenerated outputs**

Run: `ls -la windows/runner/resources/app_icon.ico && ls macos/Runner/Assets.xcassets/AppIcon.appiconset/ | head -4`
Expected: `app_icon.ico` has a fresh mtime and is larger than before (256px icon vs the old 48px one); macOS appiconset PNGs regenerated.

Run: `git status --short | grep -E 'windows|macos|web|android|ios'`
Expected: icon files show as modified; nothing unrelated is touched.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml windows/runner/resources/app_icon.ico macos/ web/ android/ ios/
git commit -m "feat(icons): generate platform icons from 1024px master"
```

---

### Task 3: sync_app_icons tool + Linux bundle icon

**Files:**
- Create: `tool/sync_app_icons.dart`
- Create (by running the tool): `linux/runner/resources/app_icon.png`

**Interfaces:**
- Consumes: `test/tools/generate_app_icon_test.dart` (Task 1) and the pubspec config (Task 2).
- Produces: `dart run tool/sync_app_icons.dart` — the one command that regenerates everything; `linux/runner/resources/app_icon.png` (1024×1024 PNG) consumed by the Linux build.

- [ ] **Step 1: Write the tool**

```dart
// ignore_for_file: avoid_print
//
// Regenerates all launcher icons from the vector logo. Run from `huji-app/`:
//
//   dart run tool/sync_app_icons.dart
//
// 1. flutter test test/tools/generate_app_icon_test.dart
//    → assets/icons/logo_bg_1024.png + scripts/appimage/huji.png
// 2. dart run flutter_launcher_icons
//    → Android / iOS / Web / Windows / macOS icons
// 3. Copy the master icon to linux/runner/resources/app_icon.png
//    (flutter_launcher_icons has no Linux support — same workaround as
//    teampilot's client/tool/sync_app_icons.dart)

import 'dart:io';

const _masterIcon = 'assets/icons/logo_bg_1024.png';
const _linuxBundleIcon = 'linux/runner/resources/app_icon.png';
const _generatorTest = 'test/tools/generate_app_icon_test.dart';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run from the huji-app/ directory (pubspec.yaml not found).');
    exit(1);
  }
  if (!File('assets/svg/logo_no_font.svg').existsSync()) {
    stderr.writeln(
        'Missing assets/svg/logo_no_font.svg — the vector logo is the icon source.');
    exit(1);
  }

  print('Rendering master icon from SVG…');
  await _run('flutter', ['test', _generatorTest]);

  print('Running flutter_launcher_icons…');
  await _run('dart', ['run', 'flutter_launcher_icons']);

  final linuxDest = File(_linuxBundleIcon);
  await linuxDest.parent.create(recursive: true);
  await File(_masterIcon).copy(linuxDest.path);
  print('Synced $_masterIcon → $_linuxBundleIcon');
  print('Done.');
}

Future<void> _run(String executable, List<String> args) async {
  final result = await Process.run(executable, args);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
```

- [ ] **Step 2: Run the tool end-to-end**

Run: `dart run tool/sync_app_icons.dart`
Expected: the generator test passes, flutter_launcher_icons runs, final line `Done.`.

- [ ] **Step 3: Verify the Linux bundle icon**

Run: `cmp assets/icons/logo_bg_1024.png linux/runner/resources/app_icon.png && echo identical`
Expected: `identical`. Also `file linux/runner/resources/app_icon.png` shows 1024×1024.

- [ ] **Step 4: Verify idempotency**

Run: `dart run tool/sync_app_icons.dart` again, then
`git status --short | grep -v '^??'`
Expected: second run exits 0; no diffs beyond the files Task 2 already regenerated (byte-stable PNG encoding).

- [ ] **Step 5: Commit**

```bash
git add tool/sync_app_icons.dart linux/runner/resources/app_icon.png
git commit -m "feat(icons): one-command launcher icon sync tool"
```

---

### Task 4: AppImage + deb wiring

**Files:**
- Modify: `scripts/build_appimage.sh` (lines ~97–98 and ~205)
- Modify: `linux/packaging/deb/make_config.yaml:11`
- Delete: `scripts/appimage/huji.svg`

**Interfaces:**
- Consumes: `scripts/appimage/huji.png` (Task 1) and `assets/icons/logo_bg_1024.png`.
- Produces: AppImage and deb packages carrying the new icon.

- [ ] **Step 1: Switch build_appimage.sh from the SVG placeholder to the PNG**

Replace these two lines (~97–98):

```bash
cp "$APPIMAGE_RES/huji.svg" "$APPDIR/huji.svg"
cp "$APPIMAGE_RES/huji.svg" "$APPDIR/usr/share/icons/hicolor/256x256/apps/huji.svg"
```

with:

```bash
cp "$APPIMAGE_RES/huji.png" "$APPDIR/huji.png"
cp "$APPIMAGE_RES/huji.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/huji.png"
```

And in the linuxdeploy invocation (~line 205), change:

```bash
  --icon-file "$APPIMAGE_RES/huji.svg" \
```

to:

```bash
  --icon-file "$APPIMAGE_RES/huji.png" \
```

- [ ] **Step 2: Point the deb config at the master icon**

In `linux/packaging/deb/make_config.yaml`, change line 11:

```yaml
icon: assets/icons/logo_bg.png
```

to:

```yaml
icon: assets/icons/logo_bg_1024.png
```

- [ ] **Step 3: Delete the placeholder**

Run: `git rm scripts/appimage/huji.svg`
Then confirm no other references remain:
Run: `grep -rn 'huji.svg' scripts/ linux/ .github/ 2>/dev/null`
Expected: no output.

- [ ] **Step 4: Verify by building the AppImage**

Run: `./scripts/build_appimage.sh` (slow — full Flutter build + tool downloads; no GPU/env setup needed per CLAUDE.md).
Then inspect the result:

```bash
./huji-*-x86_64.AppImage --appimage-extract >/dev/null 2>&1 || true
file squashfs-root/huji.png squashfs-root/usr/share/icons/hicolor/256x256/apps/huji.png squashfs-root/.DirIcon
cmp scripts/appimage/huji.png squashfs-root/usr/share/icons/hicolor/256x256/apps/huji.png && echo "hicolor icon OK"
rm -rf squashfs-root
```

Expected: all three are the 256px PNG; `hicolor icon OK` printed. (`.DirIcon` may be a different-size PNG or symlink generated by linuxdeploy — it must be the huji logo, not the old "弧" glyph. Check visually if in doubt: `xdg-open squashfs-root/.DirIcon`.)

- [ ] **Step 5: Commit**

```bash
git add scripts/build_appimage.sh linux/packaging/deb/make_config.yaml
git commit -m "fix(appimage): use real logo icon instead of text-glyph placeholder"
```

---

### Task 5: Docs + final verification

**Files:**
- Modify: `CLAUDE.md` (repo root)

**Interfaces:**
- Consumes: everything above.
- Produces: documentation of the one command.

- [ ] **Step 1: Document the command in CLAUDE.md**

Add this section to `CLAUDE.md` after the "AppImage / local runs" block (inside "Local Inference…" is wrong — put it right after that section ends, before "## Architecture"):

```markdown
## App Icons

All launcher icons (Android/iOS/Web/Windows/macOS + Linux bundle + AppImage)
are generated from `assets/svg/logo_no_font.svg` via a single command:

```bash
cd huji-app
dart run tool/sync_app_icons.dart
```

Outputs are committed (1024px master `assets/icons/logo_bg_1024.png`,
`scripts/appimage/huji.png`, `linux/runner/resources/app_icon.png`, and the
platform icon sets). Re-run it after changing the vector logo, then commit
the regenerated files. Composition lives in
`test/tools/generate_app_icon_test.dart` (`_logoScale`).
```

- [ ] **Step 2: Final full verification**

```bash
dart run tool/sync_app_icons.dart && flutter analyze --no-pub 2>&1 | tail -3
```

Expected: tool exits 0; analyze reports no new issues in `tool/` or `test/tools/`. Also skim `git status --short` — only expected icon/config/doc files changed.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: app icon regeneration command"
```
