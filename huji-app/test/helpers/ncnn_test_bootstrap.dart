import 'dart:io';

import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:path/path.dart' as p;

import 'autoclip_fixtures.dart';

/// Library file name per platform (Linux + Windows are the platforms
/// with a dynamically resolved plugin; macOS links statically into the
/// app binary and is opened from the built app bundle instead).
const _pluginFileNames = <String>[
  'libhuji_ncnn_plugin.so',
  'huji_ncnn_plugin.dll',
];

bool _bootstrapped = false;

/// Locates the built huji_ncnn plugin and pins it via
/// [NcnnRuntime.overrideLibraryDirectory].
///
/// - Linux:   build/linux/x64/{debug,release}/plugins/huji_ncnn/
/// - Windows: build/windows/x64/Debug/plugins/huji_ncnn/
/// - macOS:   build/macos/Build/Products/{Debug,Release}/<app>.app/
///            Contents/MacOS/ (the app's .debug.dylib carries the symbols;
///            the product name varies, so the .app bundle is discovered)
///
/// Call from setUpAll of every ncnn integration test.
///
/// Fail-fast: no artifact → StateError with the build command. Never
/// silently skip — a skipped ncnn test is a silently broken pipeline.
Future<void> bootstrapNcnnLibrary() async {
  if (_bootstrapped) return;

  final appRoot = findAppRoot();
  // Layout differs by platform:
  //   Linux:   build/linux/x64/<config>/plugins/huji_ncnn/ (config in path)
  //   Windows: build/windows/x64/plugins/huji_ncnn/<Config>/ (config last)
  final candidates = <String>[
    p.join(appRoot.path, 'build', 'linux', 'x64', 'debug',
        'plugins', 'huji_ncnn'),
    p.join(appRoot.path, 'build', 'linux', 'x64', 'release',
        'plugins', 'huji_ncnn'),
    p.join(appRoot.path, 'build', 'windows', 'x64', 'plugins',
        'huji_ncnn', 'Debug'),
    p.join(appRoot.path, 'build', 'windows', 'x64', 'plugins',
        'huji_ncnn', 'Release'),
    ..._macosCandidates(appRoot.path),
  ];

  for (final dir in candidates) {
    if (_pluginExistsIn(dir)) {
      NcnnRuntime.overrideLibraryDirectory(dir);
      _bootstrapped = true;
      return;
    }
  }

  throw StateError(
    'huji_ncnn plugin not found under any build directory of '
    '${appRoot.path}.\n'
    'Build first:  cd huji-app && flutter build linux --debug\n'
    '(flutter build windows --debug on Windows, '
    'flutter build macos --debug on macOS)',
  );
}

/// `Contents/MacOS` dirs of every built .app bundle, newest build
/// configuration first (Debug carries a separate .debug.dylib; Release
/// embeds the symbols in the executable, which is not dlopen-able).
Iterable<String> _macosCandidates(String appRootPath) {  final products = p.join(appRootPath, 'build', 'macos', 'Build', 'Products');
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
  if (_pluginFileNames.any((name) =>
      File(p.join(dir, name)).existsSync())) {
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
