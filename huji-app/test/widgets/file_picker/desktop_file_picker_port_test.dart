import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/file_picker/adapters/desktop_file_picker_port.dart';

void main() {
  group('omitIfUnsafeForLinuxFilePickerInitialDirectory', () {
    test('passes ASCII paths through', () {
      expect(
        DesktopFilePickerPort.omitIfUnsafeForLinuxFilePickerInitialDirectory(
          '/home/user/Videos/Huji',
        ),
        '/home/user/Videos/Huji',
      );
    });

    test('returns null for paths with BMP code units above 255 on Linux', () {
      final result =
          DesktopFilePickerPort.omitIfUnsafeForLinuxFilePickerInitialDirectory(
        '/home/user/Videos/弧迹',
      );
      if (Platform.isLinux) {
        expect(result, isNull);
      } else {
        expect(result, '/home/user/Videos/弧迹');
      }
    });

    test('returns null for empty path', () {
      expect(
        DesktopFilePickerPort.omitIfUnsafeForLinuxFilePickerInitialDirectory(''),
        isNull,
      );
    });
  });
}
