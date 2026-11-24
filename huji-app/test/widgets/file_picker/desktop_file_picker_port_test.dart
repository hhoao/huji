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

  group('normalizeInitialDirectory', () {
    test('returns null for empty and relative paths', () {
      expect(DesktopFilePickerPort.normalizeInitialDirectory(''), isNull);
      expect(
        DesktopFilePickerPort.normalizeInitialDirectory('Videos/弧迹'),
        isNull,
      );
    });

    test('normalizes separators and drops the trailing separator', () {
      if (Platform.isWindows) {
        expect(
          DesktopFilePickerPort.normalizeInitialDirectory('C:/Users/me/Videos/'),
          r'C:\Users\me\Videos',
        );
      } else {
        expect(
          DesktopFilePickerPort.normalizeInitialDirectory('/home/me//Videos/'),
          '/home/me/Videos',
        );
      }
    });

    test('returns null for paths without a drive or share root', () {
      expect(
        DesktopFilePickerPort.normalizeInitialDirectory(r'\tmp\Videos'),
        isNull,
      );
    });
  });
}
