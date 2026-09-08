import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_ncnn/huji_ncnn.dart';

/// Stale-marker regression: a marker file left behind by a previous build
/// (they survive `flutter clean`) must not shadow the bare-name fallback.
///
/// Lives in its own file on purpose — exercising the marker requires a VM
/// where no [NcnnRuntime.overrideLibraryDirectory] call has happened, since
/// the in-isolate pin outranks the marker.
void main() {
  final abi = Abi.current();
  final usesDirResolution = abi == Abi.linuxX64 ||
      abi == Abi.linuxArm64 ||
      abi == Abi.windowsX64 ||
      abi == Abi.windowsArm64;
  if (!usesDirResolution) return;
  // With the env var set the marker is never consulted.
  if (Platform.environment.containsKey('HUJI_NCNN_LIB_DIR')) return;

  test('stale marker dir is ignored — resolution falls back to bare name',
      () {
    final marker = File('${Directory.systemTemp.path}/huji_ncnn_lib_dir.txt');
    final staleDir =
        '${Directory.systemTemp.path}/huji_ncnn_stale_${pid}_does_not_exist';
    expect(Directory(staleDir).existsSync(), isFalse);
    marker.writeAsStringSync(staleDir);

    // Left stale on purpose (not restored/deleted): a stale marker is
    // harmless by design now, and deleting could race a concurrent test
    // VM that owns a valid pin in the same file.
    try {
      NcnnRuntime.instance;
      // Bare name resolved on this machine (plugin on the loader path).
      // Had the stale marker been honored, the open above would have
      // failed with the stale path instead.
    } on Object catch (e) {
      expect(
        e.toString().contains(staleDir),
        isFalse,
        reason: 'stale marker dir must not reach DynamicLibrary.open',
      );
    }
  });
}
