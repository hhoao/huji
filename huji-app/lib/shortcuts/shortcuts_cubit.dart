import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'command_catalog.dart';
import 'key_chord.dart';
import 'keybinding_resolver.dart';
import 'shortcuts_preferences_store.dart';
import 'shortcuts_state.dart';

/// Result of [ShortcutsCubit.importOverrides]: whether the import applied,
/// and any conflicts discovered against the current bindings (returned for a
/// "replace all" confirm when not applied).
class ImportResult {
  const ImportResult({required this.applied, this.conflicts = const []});

  final bool applied;
  final List<KeybindingConflict> conflicts;
}

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

  /// Applies imported overrides.
  ///
  /// When the import would steal chords from commands outside
  /// [importedOverrides] and [replaceConflicts] is `false`, the state is left
  /// unchanged and the conflicts are returned for the caller to present a
  /// replace-all confirm. With `replaceConflicts`, the conflicting chords are
  /// cleared from the other commands and the import applies.
  Future<ImportResult> importOverrides(
    Map<String, List<KeyChord>> importedOverrides, {
    bool replaceConflicts = false,
  }) async {
    final importedIds = importedOverrides.keys.toSet();
    final tentativeOverrides = Map<String, List<KeyChord>>.of(state.overrides);
    tentativeOverrides.addAll({
      for (final entry in importedOverrides.entries)
        entry.key: List<KeyChord>.of(entry.value),
    });

    final tentativeEffective = KeybindingResolver.effectiveBindings(
      catalog: appCommandCatalog,
      overrides: tentativeOverrides,
    );
    final conflicts = KeybindingResolver.findConflicts(
      tentativeEffective,
    ).where((c) => c.commandIds.any(importedIds.contains)).toList();

    if (conflicts.isNotEmpty && !replaceConflicts) {
      return ImportResult(applied: false, conflicts: conflicts);
    }

    var finalOverrides = tentativeOverrides;
    if (conflicts.isNotEmpty) {
      finalOverrides = Map<String, List<KeyChord>>.of(tentativeOverrides);
      for (final conflict in conflicts) {
        for (final commandId in conflict.commandIds) {
          if (importedIds.contains(commandId)) continue;
          final currentChords =
              finalOverrides[commandId] ?? _defaultChordsFor(commandId);
          finalOverrides[commandId] = currentChords
              .where((chord) => chord != conflict.chord)
              .toList();
        }
      }
    }

    await _apply(finalOverrides);
    return ImportResult(applied: true, conflicts: conflicts);
  }

  List<KeyChord> _defaultChordsFor(String commandId) {
    for (final definition in appCommandCatalog) {
      if (definition.id == commandId) {
        return List<KeyChord>.of(definition.defaultChords);
      }
    }
    return const [];
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
