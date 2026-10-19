import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/settings/log_viewer_panel.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
    supportedLocales: HujiLocalizationsSetup.supportedLocales,
    home: TpTheme(
      data: TpThemeData.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.orange),
        scale: 1.0,
      ),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  // Live binding: the panel reads real files from disk.
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('huji_log_viewer_');
    AppLogger.instance.resetForTesting();
    final dir = Directory('${temp.path}/logs');
    await dir.create(recursive: true);
    await File('${dir.path}/app_2026-10-19.log').writeAsString(
      '2026-10-19 12:00:00.000 |  INFO 1 | package:huji_app/a.dart:1:1 | started\n'
      '2026-10-19 12:00:01.000 | ERROR 1 | package:huji_app/b.dart:2:2 | failed\n',
    );
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

  testWidgets('panel loads log files and filters by search text', (
    tester,
  ) async {
    await AppLogger.instance.ensureFileLogging(temp.path);

    await tester.pumpWidget(_host(LogViewerPanel(appDataRoot: temp.path)));
    for (
      var i = 0;
      i < 40 && find.textContaining('started').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.textContaining('a.dart:1:1'), findsOneWidget);
    expect(find.textContaining('b.dart:2:2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'failed');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.textContaining('b.dart:2:2'), findsOneWidget);
    expect(find.textContaining('a.dart:1:1'), findsNothing);
  });
}
