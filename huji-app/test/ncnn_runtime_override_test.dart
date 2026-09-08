import 'package:flutter_test/flutter_test.dart';
import 'package:huji_ncnn/huji_ncnn.dart';

/// overrideLibraryDirectory state machine checks that don't need the
/// native plugin. The "already open" rejection is exercised in
/// test/integration/ncnn_plugin_test.dart after bootstrap + library use.
void main() {
  test('pinning a different directory before first use re-pins silently',
      () {
    NcnnRuntime.overrideLibraryDirectory('/tmp/a');
    NcnnRuntime.overrideLibraryDirectory('/tmp/b');
  });

  test('pinning the same directory twice is a no-op', () {
    NcnnRuntime.overrideLibraryDirectory('/tmp/b');
    NcnnRuntime.overrideLibraryDirectory('/tmp/b');
  });
}
