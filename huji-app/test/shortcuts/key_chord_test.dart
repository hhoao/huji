import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shortcuts/key_chord.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyChord', () {
    test('mod resolves to Ctrl off macOS and Meta on macOS', () {
      final chord = KeyChord('n', [KeyChordMod.mod]);

      final linux = chord.toActivator(isMacOS: false);
      expect(linux.control, isTrue);
      expect(linux.meta, isFalse);
      expect(linux.triggers.single, LogicalKeyboardKey.keyN);

      final mac = chord.toActivator(isMacOS: true);
      expect(mac.meta, isTrue);
      expect(mac.control, isFalse);
    });

    test('explicit ctrl and meta modifiers map directly', () {
      final ctrl = KeyChord('k', [
        KeyChordMod.ctrl,
      ]).toActivator(isMacOS: false);
      expect(ctrl.control, isTrue);
      expect(ctrl.meta, isFalse);

      final meta = KeyChord('k', [
        KeyChordMod.meta,
      ]).toActivator(isMacOS: false);
      expect(meta.meta, isTrue);
    });

    test('equality is canonical across modifier order', () {
      final a = KeyChord('k', [KeyChordMod.shift, KeyChordMod.mod]);
      final b = KeyChord('k', [KeyChordMod.mod, KeyChordMod.shift]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different keys or modifiers are not equal', () {
      expect(
        KeyChord('n', [KeyChordMod.mod]),
        isNot(KeyChord('m', [KeyChordMod.mod])),
      );
      expect(
        KeyChord('n', [KeyChordMod.mod]),
        isNot(KeyChord('n', [KeyChordMod.mod, KeyChordMod.shift])),
      );
    });

    test('JSON round-trips', () {
      final chord = KeyChord('slash', [KeyChordMod.mod, KeyChordMod.shift]);
      final restored = KeyChord.tryFromJson(chord.toJson());
      expect(restored, equals(chord));
    });

    test('tryFromJson tolerates garbage', () {
      expect(KeyChord.tryFromJson(null), isNull);
      expect(KeyChord.tryFromJson('nope'), isNull);
      expect(KeyChord.tryFromJson({'mods': []}), isNull);
      expect(
        KeyChord.tryFromJson({
          'key': 'x',
          'mods': ['bogus'],
        }),
        equals(const KeyChord('x')),
      );
    });

    test('letters, digits and named keys resolve to logical keys', () {
      expect(logicalKeyForChordKey('n'), LogicalKeyboardKey.keyN);
      expect(logicalKeyForChordKey('5'), LogicalKeyboardKey.digit5);
      expect(logicalKeyForChordKey('comma'), LogicalKeyboardKey.comma);
      expect(logicalKeyForChordKey('escape'), LogicalKeyboardKey.escape);
      expect(logicalKeyForChordKey('f10'), LogicalKeyboardKey.f10);
      expect(logicalKeyForChordKey('bogus'), isNull);
    });

    test('chordKeyForLogicalKey inverts logicalKeyForChordKey', () {
      for (final name in ['n', '5', 'comma', 'escape', 'arrowLeft']) {
        final logical = logicalKeyForChordKey(name)!;
        expect(chordKeyForLogicalKey(logical), name);
      }
      expect(chordKeyForLogicalKey(LogicalKeyboardKey.mediaPlay), isNull);
    });

    test('hasTextSafeModifier requires ctrl/meta/mod', () {
      expect(KeyChord('a', [KeyChordMod.mod]).hasTextSafeModifier, isTrue);
      expect(KeyChord('a', [KeyChordMod.ctrl]).hasTextSafeModifier, isTrue);
      expect(KeyChord('a', [KeyChordMod.meta]).hasTextSafeModifier, isTrue);
      expect(KeyChord('a', [KeyChordMod.alt]).hasTextSafeModifier, isFalse);
      expect(KeyChord('a', [KeyChordMod.shift]).hasTextSafeModifier, isFalse);
      expect(const KeyChord('a').hasTextSafeModifier, isFalse);
    });
  });
}
