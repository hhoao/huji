import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/file_picker/adapters/io_filesystem_port.dart';
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
      final nestedDir = Directory('${tempDir.path}/nested');
      await nestedDir.create();
      final file = File('${tempDir.path}/readme.txt');
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
