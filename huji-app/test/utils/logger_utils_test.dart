import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/utils/logger_utils.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('huji_logs_');
    AppLogger.instance.resetForTesting();
  });

  tearDown(() async {
    AppLogger.instance.resetForTesting();
    try {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    } on Object {
      // The log file may still be open on Windows.
    }
  });

  test('ensureFileLogging writes one parseable line per record', () async {
    await AppLogger.instance.ensureFileLogging(temp.path);

    AppLogger.instance.i('hello from test');

    final path = AppLogger.instance.currentLogFilePath;
    expect(path, isNotNull);

    final contents = await File(path!).readAsString();
    expect(contents, contains('hello from test'));
    expect(
      contents,
      matches(
        RegExp(
          r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} \|  INFO \d+ \| [^|]+ \| hello from test$',
          multiLine: true,
        ),
      ),
    );
  });

  test(
    'readLogFileLines reads only the tail without a partial first line',
    () async {
      final dir = Directory('${temp.path}/logs');
      await dir.create(recursive: true);
      final file = File('${dir.path}/app_2026-10-19.log');
      await file.writeAsString('keep-this-line\nDROP\nlast-line\n');

      final lines = await AppLogger.instance.readLogFileLines(
        file.path,
        maxBytes: 12,
      );

      expect(lines, ['last-line']);
    },
  );

  test(
    'getLogFiles lists newest first without file logging initialized',
    () async {
      final dir = Directory('${temp.path}/logs');
      await dir.create(recursive: true);
      final older = File('${dir.path}/app_2026-10-18.log');
      final newer = File('${dir.path}/app_2026-10-19.log');
      await older.writeAsString('older\n');
      await newer.writeAsString('newer\n');
      await older.setLastModified(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      final files = await AppLogger.instance.getLogFiles(
        appDataRoot: temp.path,
      );

      expect(files, [newer.path, older.path]);
    },
  );

  test('clearOldLogs removes expired files and keeps recent ones', () async {
    final dir = Directory('${temp.path}/logs');
    await dir.create(recursive: true);
    final oldFile = File('${dir.path}/app_2026-10-01.log');
    final recentFile = File('${dir.path}/app_2026-10-19.log');
    await oldFile.writeAsString('old\n');
    await recentFile.writeAsString('recent\n');
    await oldFile.setLastModified(
      DateTime.now().subtract(const Duration(days: 10)),
    );

    await AppLogger.instance.clearOldLogs(keepDays: 7, appDataRoot: temp.path);

    expect(await oldFile.exists(), isFalse);
    expect(await recentFile.exists(), isTrue);
  });
}
