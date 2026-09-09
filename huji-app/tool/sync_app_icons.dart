// ignore_for_file: avoid_print
//
// Regenerates all launcher icons. Run from `huji-app/`:
//
//   dart run tool/sync_app_icons.dart
//
// 1. flutter test test/tools/generate_app_icon_test.dart
//    → assets/icons/logo_bg_1024.png (mobile / web master from SVG)
// 2. dart run flutter_launcher_icons
//    → Android / iOS / Web from logo_bg_1024.png
//    → Windows / macOS from icon_bg_1024.png (desktop black-plate icon)
// 3. Copy desktop icons for Linux packaging:
//    icon_bg_1024.png → linux/runner/resources/app_icon.png
//    icon_bg.png      → scripts/appimage/huji.png

import 'dart:io';

const _mobileMasterIcon = 'assets/icons/logo_bg_1024.png';
const _desktopMasterIcon = 'assets/icons/icon_bg_1024.png';
const _desktopAppImageIcon = 'assets/icons/icon_bg.png';
const _linuxBundleIcon = 'linux/runner/resources/app_icon.png';
const _appImageIcon = 'scripts/appimage/huji.png';
const _generatorTest = 'test/tools/generate_app_icon_test.dart';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run from the huji-app/ directory (pubspec.yaml not found).');
    exit(1);
  }
  if (!File('assets/svg/logo_no_font.svg').existsSync()) {
    stderr.writeln(
        'Missing assets/svg/logo_no_font.svg — the vector logo is the mobile icon source.');
    exit(1);
  }
  for (final path in [_desktopMasterIcon, _desktopAppImageIcon]) {
    if (!File(path).existsSync()) {
      stderr.writeln('Missing $path — desktop black-plate icons are required.');
      exit(1);
    }
  }

  // On Windows the SDK launcher is flutter.bat — dart:io's Process.run does
  // not resolve .bat shims (CreateProcess behavior). dart.exe is a real
  // executable and needs no special-casing.
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';

  print('Rendering mobile master icon from SVG…');
  await _run(flutter, ['test', _generatorTest]);

  print('Running flutter_launcher_icons…');
  await _run('dart', ['run', 'flutter_launcher_icons']);

  final linuxDest = File(_linuxBundleIcon);
  await linuxDest.parent.create(recursive: true);
  await File(_desktopMasterIcon).copy(linuxDest.path);
  print('Synced $_desktopMasterIcon → $_linuxBundleIcon');

  final appImageDest = File(_appImageIcon);
  await appImageDest.parent.create(recursive: true);
  await File(_desktopAppImageIcon).copy(appImageDest.path);
  print('Synced $_desktopAppImageIcon → $_appImageIcon');

  print('Mobile master: $_mobileMasterIcon');
  print('Done.');
}

Future<void> _run(String executable, List<String> args) async {
  final ProcessResult result;
  try {
    result = await Process.run(executable, args);
  } on ProcessException catch (e) {
    stderr.writeln(
        "'$executable' not found on PATH — install Flutter and ensure "
        'flutter/dart are on PATH. ($e)');
    exit(1);
  }
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
