import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shortcuts/command_catalog.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:huji_app/shortcuts/shortcuts_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('starts with catalog defaults and no conflicts', () {
    final cubit = ShortcutsCubit();
    expect(cubit.state.overrides, isEmpty);
    expect(cubit.state.conflicts, isEmpty);
    expect(
      cubit.state.chordsFor(CommandIds.newClip),
      appCommandCatalog
          .firstWhere((d) => d.id == CommandIds.newClip)
          .defaultChords,
    );
  });

  test('rebind replaces the effective chords and persists', () async {
    final store = ShortcutsPreferencesStore();
    final cubit = ShortcutsCubit(store: store);
    const chord = KeyChord('j', [KeyChordMod.ctrl]);

    await cubit.rebind(CommandIds.newClip, chord);

    expect(cubit.state.chordsFor(CommandIds.newClip), [chord]);

    // A fresh cubit over the same persisted store keeps the binding.
    final reloaded = await ShortcutsCubit.load(store: store);
    expect(reloaded.state.chordsFor(CommandIds.newClip), [chord]);
  });

  test('unbind empties the command, reset restores defaults', () async {
    final cubit = ShortcutsCubit();

    await cubit.unbind(CommandIds.newClip);
    expect(cubit.state.chordsFor(CommandIds.newClip), isEmpty);

    await cubit.reset(CommandIds.newClip);
    expect(cubit.state.chordsFor(CommandIds.newClip), isNotEmpty);
  });

  test('rebinding onto a taken chord reports a conflict', () async {
    final cubit = ShortcutsCubit();
    expect(cubit.state.conflicts, isEmpty);

    await cubit.rebind(
      CommandIds.openTasks,
      const KeyChord('n', [KeyChordMod.mod]),
    );

    expect(cubit.state.conflicts, hasLength(1));
    expect(
      cubit.state.conflicts.first.commandIds,
      contains(CommandIds.openTasks),
    );

    await cubit.reset(CommandIds.openTasks);
    expect(cubit.state.conflicts, isEmpty);
  });

  test('resetAll clears overrides and persisted state', () async {
    final store = ShortcutsPreferencesStore();
    final cubit = ShortcutsCubit(store: store);
    await cubit.unbind(CommandIds.newClip);
    await cubit.rebind(
      CommandIds.openTasks,
      const KeyChord('y', [KeyChordMod.ctrl]),
    );

    await cubit.resetAll();

    expect(cubit.state.overrides, isEmpty);
    expect(await store.load(), isEmpty);
  });

  test('load drops persisted bindings for unknown commands and keys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortcuts.bindings.v1':
          '{"app.newClip":[{"key":"j","mods":["ctrl"]}],"legacy.cmd":[{"key":"x","mods":[]}],"app.openTasks":[{"key":"bogus"}]}',
    });
    final store = ShortcutsPreferencesStore();
    final cubit = await ShortcutsCubit.load(store: store);

    expect(cubit.state.chordsFor(CommandIds.newClip), [
      const KeyChord('j', [KeyChordMod.ctrl]),
    ]);
    expect(cubit.state.effectiveBindings.containsKey('legacy.cmd'), isFalse);
    expect(
      cubit.state.chordsFor(CommandIds.openTasks),
      appCommandCatalog
          .firstWhere((d) => d.id == CommandIds.openTasks)
          .defaultChords,
    );
  });
}
