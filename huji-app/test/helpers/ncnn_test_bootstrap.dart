import 'dart:io';

import 'package:ncnn/ncnn.dart';
import 'package:path/path.dart' as p;

import 'autoclip_fixtures.dart';

/// Library file name per platform (Linux + Windows are the platforms
/// with a dynamically resolved plugin; macOS links statically into the
/// app binary and is opened from the built app bundle instead).
const _pluginFileNames = <String>[
  'libncnn_plugin.so',
  'ncnn_plugin.dll',
];

bool _bootstrapped = false;

/// Locates the built ncnn plugin and pins it via
/// [NcnnRuntime.overrideLibraryDirectory].
///
/// Search order (first hit wins):
/// - the app build: `build/linux/<arch>/{debug,release}/plugins/ncnn/`
///   and `.../bundle/lib/`, `build/windows/x64/plugins/ncnn/<Config>/`,
///   `build/macos/Build/Products/<Config>/<app>.app/Contents/MacOS/`
/// - the package example build (`packages/ncnn/example/build/…`), same
///   layouts — handy when only the example was built.
///
/// Call from setUpAll of every ncnn integration test.
///
/// Returns true when a build artifact was found and pinned, false when
/// no build exists yet — native-dependent tests then skip via
/// `markTestSkipped` (build first: `flutter build linux --debug`).
Future<bool> bootstrapNcnnLibrary() async {
  if (_bootstrapped) return true;

  final appRoot = findAppRoot();
  for (final dir in _candidateDirs(appRoot.path)) {
    if (_pluginExistsIn(dir)) {
      NcnnRuntime.overrideLibraryDirectory(dir);
      _bootstrapped = true;
      return true;
    }
  }
  return false;
}

List<String> _candidateDirs(String appRootPath) => [
      // Linux: build/linux/<arch>/<config>/plugins/ncnn/ (the plugin's
      // RUNPATH points at the downloaded ncnn lib dir, so pinning the
      // plugin dir also resolves libncnn.so.1), plus the bundle's lib/.
      ..._linuxDirs(p.join(appRootPath, 'build')),
      // Windows: build/windows/x64/plugins/ncnn/<Config>/ (config last).
      p.join(appRootPath, 'build', 'windows', 'x64', 'plugins', 'ncnn',
          'Debug'),
      p.join(appRootPath, 'build', 'windows', 'x64', 'plugins', 'ncnn',
          'Release'),
      // macOS: .app bundles (the product name varies; the app's
      // .debug.dylib carries the symbols).
      ..._macosCandidates(appRootPath),
      // The package example's build, when present.
      ..._linuxDirs(p.join(appRootPath, 'packages', 'ncnn', 'example',
          'build')),
      p.join(appRootPath, 'packages', 'ncnn', 'example', 'build', 'windows',
          'x64', 'plugins', 'ncnn', 'Debug'),
      p.join(appRootPath, 'packages', 'ncnn', 'example', 'build', 'windows',
          'x64', 'plugins', 'ncnn', 'Release'),
      ..._macosCandidates(
          p.join(appRootPath, 'packages', 'ncnn', 'example')),
    ];

/// Plugin dirs of every arch/config under `<root>/build/linux/…`.
List<String> _linuxDirs(String buildRoot) {
  final out = <String>[];
  for (final arch in _subDirs(p.join(buildRoot, 'linux'))) {
    for (final config in ['debug', 'release']) {
      out.add(p.join(arch, config, 'plugins', 'ncnn'));
      out.add(p.join(arch, config, 'bundle', 'lib'));
    }
  }
  return out;
}

List<String> _subDirs(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const <String>[];
  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path)
      .toList();
}

/// `Contents/MacOS` dirs of every built .app bundle, newest build
/// configuration first (Debug carries a separate .debug.dylib; Release
/// embeds the symbols in the executable, which is not dlopen-able).
Iterable<String> _macosCandidates(String appRootPath) {
  final products = p.join(appRootPath, 'build', 'macos', 'Build', 'Products');
  return ['Debug', 'Release'].expand((config) {
    final dir = Directory(p.join(products, config));
    if (!dir.existsSync()) return const <String>[];
    return dir
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.endsWith('.app'))
        .map((d) => p.join(d.path, 'Contents', 'MacOS'));
  });
}

bool _pluginExistsIn(String dir) {
  if (_pluginFileNames
      .any((name) => File(p.join(dir, name)).existsSync())) {
    return true;
  }
  // macOS: the app's debug dylib (name varies with the product name).
  try {
    return Directory(dir)
        .listSync()
        .whereType<File>()
        .any((f) => f.path.endsWith('.debug.dylib'));
  } catch (_) {
    return false;
  }
}
