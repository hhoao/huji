import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/file_picker/adapters/io_filesystem_port.dart';
import 'package:path/path.dart' as path;
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('IoFilesystemPort', () {
    late Directory tempDir;
    late IoFilesystemPort port;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('io_filesystem_port_test_');
      port = IoFilesystemPort();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('listDir returns files and directories in a temp folder', () async {
      // Build child paths with the host separator: dart:io returns entity
      // paths in platform style, so hardcoding '/' breaks on Windows.
      final nestedDir = Directory(path.join(tempDir.path, 'nested'));
      await nestedDir.create();
      final file = File(path.join(tempDir.path, 'readme.txt'));
      await file.writeAsString('hello');

      final entries = await port.listDir(tempDir.path);
      final paths = entries.map((entry) => entry.path).toSet();

      expect(paths, contains(file.path));
      expect(paths, contains(nestedDir.path));
      expect(
        entries.firstWhere((entry) => entry.path == file.path).kind,
        TpFsEntryKind.file,
      );
      expect(
        entries.firstWhere((entry) => entry.path == nestedDir.path).kind,
        TpFsEntryKind.directory,
      );
    });
  });
}
