import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Modifier slots of a [KeyChord].
///
/// [KeyChordMod.mod] is the platform-primary modifier: Meta on macOS and
/// Control elsewhere, resolved at activation time — so one chord covers
/// Ctrl+N on Windows/Linux and Cmd+N on macOS.
enum KeyChordMod { mod, ctrl, meta, alt, shift }

/// A portable, serializable keyboard chord bound to a command.
///
/// Chords are deliberately not [SingleActivator]s: they canonicalize the key
/// name and modifier order for equality, round-trip through JSON for
/// persistence, and resolve `mod` per platform on demand.
class KeyChord {
  const KeyChord(this.key, [this.mods = const <KeyChordMod>[]]);

  /// Canonical key name: single letters/digits lowercase (`a`, `3`) or one of
  /// the [chordKeyForLogicalKey] names (`comma`, `slash`, `escape`, ...).
  final String key;

  final List<KeyChordMod> mods;

  /// Whether the chord still works while a text field has focus — chords
  /// without a Ctrl/Meta/Mod qualifier would hijack plain typing.
  bool get hasTextSafeModifier => mods.any(
    (m) =>
        m == KeyChordMod.mod || m == KeyChordMod.ctrl || m == KeyChordMod.meta,
  );

  List<KeyChordMod> get sortedMods =>
      [...mods]..sort((a, b) => a.index.compareTo(b.index));

  SingleActivator toActivator({required bool isMacOS}) {
    var control = false;
    var meta = false;
    var alt = false;
    var shift = false;
    for (final m in mods) {
      switch (m) {
        case KeyChordMod.mod:
          if (isMacOS) {
            meta = true;
          } else {
            control = true;
          }
        case KeyChordMod.ctrl:
          control = true;
        case KeyChordMod.meta:
          meta = true;
        case KeyChordMod.alt:
          alt = true;
        case KeyChordMod.shift:
          shift = true;
      }
    }
    return SingleActivator(
      logicalKeyForChordKey(key)!,
      control: control,
      meta: meta,
      alt: alt,
      shift: shift,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'mods': mods.map((m) => m.name).toList(),
  };

  static KeyChord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final key = json['key'];
    if (key is! String) return null;
    final rawMods = json['mods'];
    final mods = <KeyChordMod>[];
    if (rawMods is List) {
      for (final m in rawMods) {
        for (final value in KeyChordMod.values) {
          if (value.name == m) {
            mods.add(value);
            break;
          }
        }
      }
    }
    return KeyChord(key, mods);
  }

  @override
  bool operator ==(Object other) =>
      other is KeyChord &&
      other.key == key &&
      _listEquals(other.sortedMods, sortedMods);

  @override
  int get hashCode => Object.hash(key, Object.hashAll(sortedMods));

  @override
  String toString() =>
      'KeyChord(${[...mods.map((m) => m.name), key].join('+')})';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

const _letters = 'abcdefghijklmnopqrstuvwxyz';

final Map<String, LogicalKeyboardKey> _chordKeyByLogicalKey = () {
  final map = <String, LogicalKeyboardKey>{
    'space': LogicalKeyboardKey.space,
    'enter': LogicalKeyboardKey.enter,
    'escape': LogicalKeyboardKey.escape,
    'tab': LogicalKeyboardKey.tab,
    'backspace': LogicalKeyboardKey.backspace,
    'delete': LogicalKeyboardKey.delete,
    'comma': LogicalKeyboardKey.comma,
    'period': LogicalKeyboardKey.period,
    'slash': LogicalKeyboardKey.slash,
    'minus': LogicalKeyboardKey.minus,
    'equal': LogicalKeyboardKey.equal,
    'semicolon': LogicalKeyboardKey.semicolon,
    'quote': LogicalKeyboardKey.quote,
    'backquote': LogicalKeyboardKey.backquote,
    'bracketLeft': LogicalKeyboardKey.bracketLeft,
    'bracketRight': LogicalKeyboardKey.bracketRight,
    'backslash': LogicalKeyboardKey.backslash,
    'arrowUp': LogicalKeyboardKey.arrowUp,
    'arrowDown': LogicalKeyboardKey.arrowDown,
    'arrowLeft': LogicalKeyboardKey.arrowLeft,
    'arrowRight': LogicalKeyboardKey.arrowRight,
    'home': LogicalKeyboardKey.home,
    'end': LogicalKeyboardKey.end,
    'pageUp': LogicalKeyboardKey.pageUp,
    'pageDown': LogicalKeyboardKey.pageDown,
    'f1': LogicalKeyboardKey.f1,
    'f2': LogicalKeyboardKey.f2,
    'f3': LogicalKeyboardKey.f3,
    'f4': LogicalKeyboardKey.f4,
    'f5': LogicalKeyboardKey.f5,
    'f6': LogicalKeyboardKey.f6,
    'f7': LogicalKeyboardKey.f7,
    'f8': LogicalKeyboardKey.f8,
    'f9': LogicalKeyboardKey.f9,
    'f10': LogicalKeyboardKey.f10,
    'f11': LogicalKeyboardKey.f11,
    'f12': LogicalKeyboardKey.f12,
  };
  for (var i = 0; i < _letters.length; i++) {
    map[_letters[i]] = [
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyB,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyG,
      LogicalKeyboardKey.keyH,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyP,
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyU,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.keyY,
      LogicalKeyboardKey.keyZ,
    ][i];
  }
  for (var i = 0; i <= 9; i++) {
    map['$i'] = [
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ][i];
  }
  return map;
}();

/// Maps a canonical chord key name to its [LogicalKeyboardKey]; `null` when
/// unknown (e.g. a persisted binding from another keyboard layout).
LogicalKeyboardKey? logicalKeyForChordKey(String key) =>
    _chordKeyByLogicalKey[key] ??
    (key.length == 1 ? _chordKeyByLogicalKey[key.toLowerCase()] : null);

/// Inverse of [logicalKeyForChordKey] used when capturing chords in the
/// rebind dialog; `null` for keys we do not offer as bindings.
String? chordKeyForLogicalKey(LogicalKeyboardKey logicalKey) {
  for (final entry in _chordKeyByLogicalKey.entries) {
    if (entry.value == logicalKey) return entry.key;
  }
  return null;
}
