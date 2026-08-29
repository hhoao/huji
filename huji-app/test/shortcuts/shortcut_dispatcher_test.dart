import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/command_catalog.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/keybinding_resolver.dart';
import 'package:huji_app/shortcuts/shortcut_dispatcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommandBus bus;
  late ShortcutDispatcher dispatcher;

  setUp(() {
    bus = CommandBus();
    dispatcher = ShortcutDispatcher(
      bus: bus,
      effectiveChords: () => KeybindingResolver.effectiveBindings(
        catalog: appCommandCatalog,
        overrides: const {},
      ),
      isMacOS: () => false,
    );
    dispatcher.attach();
  });

  tearDown(() {
    dispatcher.detach();
  });

  // HardwareKeyboard dispatch calls every handler regardless of the previous
  // handler's result, so consumption is asserted via handle()'s own return
  // value with the real modifier state held down.
  testWidgets('matched chord invokes its handler and reports handled', (
    tester,
  ) async {
    var invoked = 0;
    bus.register(CommandIds.newClip, () => invoked++);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(invoked, 1);
  });

  testWidgets('matched chord with no handler is still reported handled', (
    tester,
  ) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final handled = dispatcher.handle(
      KeyDownEvent(
        logicalKey: LogicalKeyboardKey.keyN,
        physicalKey: const PhysicalKeyboardKey(0x00000000),
        timeStamp: Duration.zero,
      ),
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(handled, isTrue);
  });

  testWidgets('disabled dispatcher ignores matching chords', (tester) async {
    var invoked = 0;
    bus.register(CommandIds.newClip, () => invoked++);
    dispatcher.enabled = false;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(invoked, 0);
  });

  testWidgets('unmatched chords do not invoke commands', (tester) async {
    var invoked = 0;
    bus.register(CommandIds.newClip, () => invoked++);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);

    expect(invoked, 0);
  });

  testWidgets('plain keys never hijack typing in a text field', (tester) async {
    var invoked = 0;
    bus.register(CommandIds.newClip, () => invoked++);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TextField(autofocus: true))),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    expect(invoked, 0);
  });

  testWidgets('text-safe chords still fire while a text field has focus', (
    tester,
  ) async {
    var invoked = 0;
    bus.register(CommandIds.newClip, () => invoked++);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TextField(autofocus: true))),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(invoked, 1);
  });

  testWidgets('detach stops listening', (tester) async {
    var invoked = 0;
    bus.register(CommandIds.newClip, () => invoked++);
    dispatcher.detach();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(invoked, 0);
  });
}
