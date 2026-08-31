import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/pages/desktop/huji_shortcut_settings_section.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/key_chord_formatter.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
    supportedLocales: HujiLocalizationsSetup.supportedLocales,
    home: TpTheme(
      data: TpThemeData.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.orange),
        scale: 1.0,
      ),
      child: Scaffold(
        body: BlocProvider<ShortcutsCubit>(
          create: (_) => ShortcutsCubit(),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('search filters command rows by title', (tester) async {
    await tester.pumpWidget(_host(const HujiShortcutsSettingsSection()));
    await tester.pumpAndSettle();

    expect(find.text('New Clip'), findsOneWidget);
    expect(find.text('Open Tasks'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tasks');
    await tester.pumpAndSettle();

    expect(find.text('New Clip'), findsNothing);
    expect(find.text('Open Tasks'), findsOneWidget);
  });

  testWidgets('search matches formatted chord text', (tester) async {
    await tester.pumpWidget(_host(const HujiShortcutsSettingsSection()));
    await tester.pumpAndSettle();

    // Search text derives from the formatter so the expectation holds on any
    // host platform (macOS renders mod as ⌘, others as Ctrl). Match against
    // the host's own rendering, exactly as the section formats its chips.
    const tasksChord = KeyChord('t', [KeyChordMod.mod]);
    final tasksNeedle = formatKeyChord(
      tasksChord,
      isMacOS: Platform.isMacOS,
    ).toLowerCase();
    const newClipChord = KeyChord('n', [KeyChordMod.mod]);
    final newClipNeedle = formatKeyChord(
      newClipChord,
      isMacOS: Platform.isMacOS,
    ).toLowerCase();
    expect(newClipNeedle, isNot(tasksNeedle));

    await tester.enterText(find.byType(TextField), tasksNeedle);
    await tester.pumpAndSettle();

    expect(find.text('Open Tasks'), findsOneWidget);
    expect(find.text('New Clip'), findsNothing);
  });

  group('parseImportedBindings', () {
    test('parses version payload and drops unknown ids and chords', () {
      final parsed = parseImportedBindings(
        '{"version":1,"bindings":{'
        '"app.newClip":[{"key":"j","mods":["ctrl"]}],'
        '"legacy.cmd":[{"key":"x"}],'
        '"app.openTasks":[{"key":"bogus"}]}}',
      );

      expect(parsed, isNotNull);
      expect(parsed!.keys, ['app.newClip']);
      expect(parsed['app.newClip']!.single.key, 'j');
    });

    test('returns null for malformed payloads', () {
      expect(parseImportedBindings('not json'), isNull);
      expect(parseImportedBindings('{"other":1}'), isNull);
      expect(parseImportedBindings('{"bindings":"nope"}'), isNull);
    });
  });
}
