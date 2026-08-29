import 'package:flutter/services.dart';

import 'command_definition.dart';
import 'key_chord.dart';
import 'shortcut_context.dart';

/// Merges user overrides onto the catalog defaults and matches key events
/// against the effective bindings.
abstract final class KeybindingResolver {
  /// Missing override → catalog defaults; an explicit empty list means the
  /// user unbound the command; a non-empty list replaces the defaults.
  static Map<String, List<KeyChord>> effectiveBindings({
    required List<CommandDefinition> catalog,
    required Map<String, List<KeyChord>> overrides,
  }) {
    final effective = <String, List<KeyChord>>{};
    for (final definition in catalog) {
      effective[definition.id] =
          overrides[definition.id] ?? definition.defaultChords;
    }
    return effective;
  }

  /// First command whose chord accepts [event], in catalog declaration order.
  /// Returns `null` when nothing matches.
  static String? match({
    required KeyEvent event,
    required List<CommandDefinition> catalog,
    required Map<String, List<KeyChord>> effectiveByCommand,
    required ShortcutContext context,
    required bool isMacOS,
  }) {
    for (final definition in catalog) {
      for (final chord in effectiveByCommand[definition.id] ?? const []) {
        if (context.inTextField && !chord.hasTextSafeModifier) continue;
        if (chord
            .toActivator(isMacOS: isMacOS)
            .accepts(event, HardwareKeyboard.instance)) {
          return definition.id;
        }
      }
    }
    return null;
  }

  /// Chords bound to more than one command among the effective bindings.
  static List<KeybindingConflict> findConflicts(
    Map<String, List<KeyChord>> effectiveByCommand,
  ) {
    final byChord = <KeyChord, List<String>>{};
    effectiveByCommand.forEach((commandId, chords) {
      for (final chord in chords) {
        byChord.putIfAbsent(chord, () => []).add(commandId);
      }
    });
    final conflicts = <KeybindingConflict>[];
    for (final entry in byChord.entries) {
      if (entry.value.length > 1) {
        conflicts.add(
          KeybindingConflict(chord: entry.key, commandIds: entry.value),
        );
      }
    }
    return conflicts;
  }
}

/// A chord claimed by more than one command.
class KeybindingConflict {
  const KeybindingConflict({required this.chord, required this.commandIds});

  final KeyChord chord;
  final List<String> commandIds;
}
