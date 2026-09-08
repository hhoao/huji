import 'dart:io';

import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:path/path.dart' as p;

import 'autoclip_fixtures.dart';

/// Library file name per platform (Linux + Windows are the platforms
/// with a dynamically resolved plugin; macOS/iOS link statically).
const _pluginFileNames = <String>[
  'libhuji_ncnn_plugin.so',
  'huji_ncnn_plugin.dll',
];

bool _bootstrapped = false;

/// True after [bootstrapNcnnLibrary] succeeded.
bool get ncnnLibraryBootstrapped => _bootstrapped;

/// Locates the built huji_ncnn plugin under
/// build/linux/x64/{debug,release}/plugins/huji_ncnn/ and pins the
/// directory via NcnnRuntime.overrideLibraryDirectory.
///
/// Call from setUpAll of every ncnn integration test.
///
/// Fail-fast: no artifact → StateError with the build command. Never
/// silently skip — a skipped ncnn test is a silently broken pipeline.
Future<void> bootstrapNcnnLibrary() async {
  if (_bootstrapped) return;

  final appRoot = findAppRoot();
  final candidates = <String>[
    p.join(appRoot.path, 'build', 'linux', 'x64', 'debug',
        'plugins', 'huji_ncnn'),
    p.join(appRoot.path, 'build', 'linux', 'x64', 'release',
        'plugins', 'huji_ncnn'),
    p.join(appRoot.path, 'build', 'windows', 'x64', 'Debug',
        'plugins', 'huji_ncnn'),
  ];

  for (final dir in candidates) {
    final plugin = _findPluginIn(dir);
    if (plugin != null) {
      NcnnRuntime.overrideLibraryDirectory(dir);
      _bootstrapped = true;
      return;
    }
  }

  throw StateError(
    'huji_ncnn plugin not found under any build directory of '
    '${appRoot.path}.\n'
    'Build first:  cd huji-app && flutter build linux --debug\n'
    '(or flutter build windows --debug on Windows)',
  );
}

String? _findPluginIn(String dir) {
  for (final name in _pluginFileNames) {
    final file = File(p.join(dir, name));
    if (file.existsSync()) return file.path;
  }
  return null;
}
