import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'command_catalog.dart';
import 'key_chord.dart';

const _kBindingsKey = 'shortcuts.bindings.v1';

/// Persists user keybinding overrides as one JSON blob, dropping chords/ids
/// the current catalog does not know (schema drift, removed commands).
class ShortcutsPreferencesStore {
  Future<Map<String, List<KeyChord>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBindingsKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final knownIds = appCommandCatalog.map((d) => d.id).toSet();
      final overrides = <String, List<KeyChord>>{};
      decoded.forEach((key, value) {
        if (key is! String || !knownIds.contains(key)) return;
        if (value is! List) return;
        final chords = value
            .map(KeyChord.tryFromJson)
            .whereType<KeyChord>()
            .where((c) => logicalKeyForChordKey(c.key) != null)
            .toList();
        // An empty persisted list means the user unbound the command; an
        // entry whose chords all failed to parse is garbage and must not
        // silently shadow the catalog defaults.
        if (chords.isEmpty && value.isNotEmpty) return;
        overrides[key] = chords;
      });
      return overrides;
    } on FormatException {
      return {};
    }
  }

  Future<void> save(Map<String, List<KeyChord>> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    if (overrides.isEmpty) {
      await prefs.remove(_kBindingsKey);
      return;
    }
    await prefs.setString(
      _kBindingsKey,
      jsonEncode({
        for (final entry in overrides.entries)
          entry.key: entry.value.map((c) => c.toJson()).toList(),
      }),
    );
  }
}
