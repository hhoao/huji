import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/command_scope.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/keybinding_resolver.dart';
import 'package:huji_app/shortcuts/shortcut_context.dart';

CommandDefinition _def(
  String id,
  List<KeyChord> chords, {
  CommandScope scope = CommandScope.global,
}) => CommandDefinition(
  id: id,
  category: CommandCategory.navigation,
  defaultChords: chords,
  scope: scope,
  title: (l10n) => id,
);

final _catalog = [
  _def('first', const [
    KeyChord('n', [KeyChordMod.mod]),
  ]),
  _def('second', const [
    KeyChord('b', [KeyChordMod.mod]),
  ]),
  _def('bare', const [KeyChord('f5')]),
];

Map<String, List<KeyChord>> _effective({
  Map<String, List<KeyChord>> overrides = const {},
}) => KeybindingResolver.effectiveBindings(
  catalog: _catalog,
  overrides: overrides,
);

KeyDownEvent _keyDown(LogicalKeyboardKey key) => KeyDownEvent(
  // SingleActivator.accepts matches on the logical key only; the physical
  // key is irrelevant here.
  logicalKey: key,
  physicalKey: const PhysicalKeyboardKey(0x00000000),
  timeStamp: Duration.zero,
);

ShortcutContext _ctx({bool inTextField = false, String? route}) =>
    ShortcutContext(inTextField: inTextField, route: route);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('effectiveBindings', () {
    test('missing override falls back to defaults', () {
      final effective = _effective();
      expect(effective['first'], [
        const KeyChord('n', [KeyChordMod.mod]),
      ]);
    });

    test('non-empty override replaces defaults', () {
      final effective = _effective(
        overrides: const {
          'first': [
            KeyChord('j', [KeyChordMod.mod]),
          ],
        },
      );
      expect(effective['first'], [
        const KeyChord('j', [KeyChordMod.mod]),
      ]);
    });

    test('empty override means intentionally unbound', () {
      final effective = _effective(overrides: const {'first': <KeyChord>[]});
      expect(effective['first'], isEmpty);
    });
  });

  group('match', () {
    // SingleActivator.accepts consults HardwareKeyboard for held modifiers,
    // so match() is exercised through simulated real key presses.
    testWidgets('matches Ctrl+N on Windows/Linux', (tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.keyN),
        catalog: _catalog,
        effectiveByCommand: _effective(),
        context: _ctx(),
        isMacOS: false,
      );
      expect(id, 'first');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });

    testWidgets('mod resolves to Meta on macOS', (tester) async {
      // Without Meta held, the macOS-resolved chord stays closed.
      var id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.keyN),
        catalog: _catalog,
        effectiveByCommand: _effective(),
        context: _ctx(),
        isMacOS: true,
      );
      expect(id, isNull);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.keyN),
        catalog: _catalog,
        effectiveByCommand: _effective(),
        context: _ctx(),
        isMacOS: true,
      );
      expect(id, 'first');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    });

    testWidgets('declaration order decides ties', (tester) async {
      final effective = _effective(
        overrides: const {
          'second': [
            KeyChord('n', [KeyChordMod.mod]),
          ],
        },
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.keyN),
        catalog: _catalog,
        effectiveByCommand: effective,
        context: _ctx(),
        isMacOS: false,
      );
      expect(id, 'first');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });

    testWidgets('modifier-less chord matches without qualifiers', (
      tester,
    ) async {
      final effective = _effective(
        overrides: const {
          'second': [KeyChord('f5')],
        },
      );
      final id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.f5),
        catalog: _catalog,
        effectiveByCommand: effective,
        context: _ctx(),
        isMacOS: false,
      );
      expect(id, 'second');
    });
  });

  test('inTextField skips chords without Ctrl/Meta/Mod', () {
    final effective = _effective(
      overrides: const {
        'bare': [KeyChord('n')],
      },
    );
    // 'bare' is bound to plain N: while a text field has focus the chord is
    // skipped even though the event would otherwise match.
    final id = KeybindingResolver.match(
      event: _keyDown(LogicalKeyboardKey.keyN),
      catalog: _catalog,
      effectiveByCommand: effective,
      context: const ShortcutContext(inTextField: true),
      isMacOS: false,
    );
    expect(id, isNull);
  });

  group('scope', () {
    final scopedCatalog = [
      _def('global_cmd', const [KeyChord('space')]),
      _def(
        'edit_cmd',
        const [KeyChord('space')],
        scope: CommandScope.precisionEdit,
      ),
    ];

    test('scoped command ignored off-route', () {
      final effective = KeybindingResolver.effectiveBindings(
        catalog: scopedCatalog,
        overrides: const {},
      );
      final id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.space),
        catalog: scopedCatalog,
        effectiveByCommand: effective,
        context: _ctx(route: '/'),
        isMacOS: false,
      );
      expect(id, 'global_cmd');
    });

    test('scoped command matches on precision-edit route', () {
      final catalog = [
        _def(
          'edit_only',
          const [KeyChord('s')],
          scope: CommandScope.precisionEdit,
        ),
      ];
      final effective = KeybindingResolver.effectiveBindings(
        catalog: catalog,
        overrides: const {},
      );
      final id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.keyS),
        catalog: catalog,
        effectiveByCommand: effective,
        context: _ctx(route: '/clip/test-id/edit'),
        isMacOS: false,
      );
      expect(id, 'edit_only');
    });

    test('scoped command does not match on other routes', () {
      final catalog = [
        _def(
          'edit_only',
          const [KeyChord('s')],
          scope: CommandScope.precisionEdit,
        ),
      ];
      final effective = KeybindingResolver.effectiveBindings(
        catalog: catalog,
        overrides: const {},
      );
      final id = KeybindingResolver.match(
        event: _keyDown(LogicalKeyboardKey.keyS),
        catalog: catalog,
        effectiveByCommand: effective,
        context: _ctx(route: '/settings'),
        isMacOS: false,
      );
      expect(id, isNull);
    });
  });

  group('findConflicts', () {
    test('flags chords bound to multiple commands', () {
      final conflicts = KeybindingResolver.findConflicts(const {
        'a': [
          KeyChord('n', [KeyChordMod.mod]),
        ],
        'b': [
          KeyChord('n', [KeyChordMod.mod]),
        ],
        'c': [
          KeyChord('j', [KeyChordMod.mod]),
        ],
      });
      expect(conflicts, hasLength(1));
      expect(conflicts.first.commandIds, ['a', 'b']);
    });

    test('unique bindings yield no conflicts', () {
      final conflicts = KeybindingResolver.findConflicts(const {
        'a': [
          KeyChord('n', [KeyChordMod.mod]),
        ],
        'b': [
          KeyChord('b', [KeyChordMod.mod]),
        ],
      });
      expect(conflicts, isEmpty);
    });
  });
}
