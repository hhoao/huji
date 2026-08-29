import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/keybinding_resolver.dart';

/// Immutable shortcuts state: what the user changed, what is in effect, and
/// the conflicts the settings UI should surface.
class ShortcutsState {
  const ShortcutsState({
    this.overrides = const {},
    this.effectiveBindings = const {},
    this.conflicts = const [],
  });

  /// User-changed bindings only; an empty list means intentionally unbound.
  final Map<String, List<KeyChord>> overrides;

  /// Catalog defaults merged with [overrides].
  final Map<String, List<KeyChord>> effectiveBindings;

  final List<KeybindingConflict> conflicts;

  /// Effective chords for [commandId]; empty when unbound.
  List<KeyChord> chordsFor(String commandId) =>
      effectiveBindings[commandId] ?? const [];

  ShortcutsState copyWith({
    Map<String, List<KeyChord>>? overrides,
    Map<String, List<KeyChord>>? effectiveBindings,
    List<KeybindingConflict>? conflicts,
  }) {
    return ShortcutsState(
      overrides: overrides ?? this.overrides,
      effectiveBindings: effectiveBindings ?? this.effectiveBindings,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}
