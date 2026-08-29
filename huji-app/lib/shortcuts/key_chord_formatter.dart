import 'package:huji_app/shortcuts/key_chord.dart';

/// Renders a [KeyChord] for UI: `⌘⇧K` on macOS, `Ctrl+Shift+K` elsewhere.
///
/// All shortcut surfaces (cheatsheet, settings, chips) must render chords
/// through this function so labels stay consistent.
String formatKeyChord(KeyChord chord, {required bool isMacOS}) {
  final mods = [...chord.mods]..sort();
  final keyLabel = _keyGlyph(chord.key, isMacOS: isMacOS);
  if (isMacOS) {
    final buffer = StringBuffer();
    for (final m in mods) {
      switch (m) {
        case KeyChordMod.mod:
        case KeyChordMod.meta:
          buffer.write('⌘');
        case KeyChordMod.ctrl:
          buffer.write('⌃');
        case KeyChordMod.alt:
          buffer.write('⌥');
        case KeyChordMod.shift:
          buffer.write('⇧');
      }
    }
    buffer.write(keyLabel);
    return buffer.toString();
  }

  final names = <String>[];
  for (final m in mods) {
    switch (m) {
      case KeyChordMod.mod:
        names.add('Ctrl');
      case KeyChordMod.ctrl:
        names.add('Ctrl');
      case KeyChordMod.meta:
        names.add('Win');
      case KeyChordMod.alt:
        names.add('Alt');
      case KeyChordMod.shift:
        names.add('Shift');
    }
  }
  names.add(keyLabel);
  return names.join('+');
}

String _keyGlyph(String key, {required bool isMacOS}) {
  switch (key) {
    case 'space':
      return 'Space';
    case 'enter':
      return isMacOS ? '↵' : 'Enter';
    case 'escape':
      return isMacOS ? '⎋' : 'Esc';
    case 'tab':
      return '⇥';
    case 'backspace':
      return isMacOS ? '⌫' : 'Backspace';
    case 'delete':
      return isMacOS ? '⌦' : 'Del';
    case 'comma':
      return ',';
    case 'period':
      return '.';
    case 'slash':
      return '/';
    case 'minus':
      return '-';
    case 'equal':
      return '=';
    case 'semicolon':
      return ';';
    case 'quote':
      return '\'';
    case 'backquote':
      return '`';
    case 'bracketLeft':
      return '[';
    case 'bracketRight':
      return ']';
    case 'backslash':
      return r'\';
    case 'arrowUp':
      return '↑';
    case 'arrowDown':
      return '↓';
    case 'arrowLeft':
      return '←';
    case 'arrowRight':
      return '→';
    default:
      if (key.length == 1) return key.toUpperCase();
      return key;
  }
}
