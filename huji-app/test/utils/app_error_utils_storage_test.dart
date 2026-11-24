import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/utils/app_error_utils.dart';

void main() {
  group('AppErrorUtils.isStorageError', () {
    test('writeFrom failure on stdout (no path) is not a storage error', () {
      final error = FileSystemException(
        'writeFrom failed',
        '',
        const OSError('The handle is invalid.', 6),
      );

      expect(AppErrorUtils.isStorageError(error), isFalse);
    });

    test('writeFrom failure on a real file is a storage error', () {
      final error = FileSystemException(
        'writeFrom failed',
        '/tmp/export.mp4',
        const OSError('No space left on device', 28),
      );

      expect(AppErrorUtils.isStorageError(error), isTrue);
    });
  });
}
