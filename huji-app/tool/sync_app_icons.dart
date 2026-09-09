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

  // On Windows the SDK launcher is flutter.bat — dart:io's Process.run does
  // not resolve .bat shims (CreateProcess behavior). dart.exe is a real
  // executable and needs no special-casing.
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';

  print('Rendering master icon from SVG…');
  await _run(flutter, ['test', _generatorTest]);

  print('Running flutter_launcher_icons…');
  await _run('dart', ['run', 'flutter_launcher_icons']);

  final linuxDest = File(_linuxBundleIcon);
  await linuxDest.parent.create(recursive: true);
  await File(_masterIcon).copy(linuxDest.path);
  print('Synced $_masterIcon → $_linuxBundleIcon');
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
