import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'command_catalog.dart';
import 'key_chord.dart';
import 'keybinding_resolver.dart';
import 'shortcuts_preferences_store.dart';
import 'shortcuts_state.dart';

class ShortcutsCubit extends Cubit<ShortcutsState> {
  ShortcutsCubit({ShortcutsPreferencesStore? store, ShortcutsState? initial})
    : _store = store ?? ShortcutsPreferencesStore(),
      super(initial ?? _resolve(const ShortcutsState(overrides: {})));

  final ShortcutsPreferencesStore _store;

  /// Loads persisted overrides before [runApp] so the first key press already
  /// honors user bindings, mirroring [AppearanceCubit.load].
  static Future<ShortcutsCubit> load({ShortcutsPreferencesStore? store}) async {
    final resolvedStore = store ?? ShortcutsPreferencesStore();
    try {
      final overrides = await resolvedStore.load();
      return ShortcutsCubit(
        store: resolvedStore,
        initial: _resolve(ShortcutsState(overrides: overrides)),
      );
    } catch (_) {
      return ShortcutsCubit(store: resolvedStore);
    }
  }

  static ShortcutsState _resolve(ShortcutsState state) {
    final effective = KeybindingResolver.effectiveBindings(
      catalog: appCommandCatalog,
      overrides: state.overrides,
    );
    return state.copyWith(
      effectiveBindings: effective,
      conflicts: KeybindingResolver.findConflicts(effective),
    );
  }

  /// Binds [chord] to [commandId], replacing that command's other chords.
  Future<void> rebind(String commandId, KeyChord chord) async {
    final next = Map<String, List<KeyChord>>.of(state.overrides);
    next[commandId] = [chord];
    await _apply(next);
  }

  /// Clears all chords of [commandId] (explicitly unbound).
  Future<void> unbind(String commandId) async {
    final next = Map<String, List<KeyChord>>.of(state.overrides);
    next[commandId] = const [];
    await _apply(next);
  }

  Future<void> reset(String commandId) async {
    final next = Map<String, List<KeyChord>>.of(state.overrides);
    next.remove(commandId);
    await _apply(next);
  }

  Future<void> resetAll() async {
    await _apply(const {});
  }

  Future<void> _apply(Map<String, List<KeyChord>> overrides) async {
    final next = _resolve(ShortcutsState(overrides: overrides));
    emit(next);
    try {
      await _store.save(overrides);
    } catch (_) {
      // Persistence failures keep the in-memory binding; retried on next
      // change.
    }
  }
}
