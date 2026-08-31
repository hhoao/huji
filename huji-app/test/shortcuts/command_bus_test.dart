import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shortcuts/command_bus.dart';

void main() {
  test('invoke runs the registered handler', () {
    final bus = CommandBus();
    var calls = 0;
    bus.register('cmd', () => calls++);

    expect(bus.invoke('cmd'), isTrue);
    expect(calls, 1);
  });

  test('invoke on unregistered command is a no-op', () {
    final bus = CommandBus();
    expect(bus.invoke('missing'), isFalse);
  });

  test('re-register replaces the previous handler', () {
    final bus = CommandBus();
    var first = 0;
    var second = 0;
    bus.register('cmd', () => first++);
    bus.register('cmd', () => second++);

    bus.invoke('cmd');
    expect(first, 0);
    expect(second, 1);
  });

  test('unregister removes only when handler is still current', () {
    final bus = CommandBus();
    var calls = 0;
    void handler() => calls++;
    void stale() => calls += 100;

    bus.register('cmd', handler);
    bus.unregister('cmd', stale);
    expect(bus.invoke('cmd'), isTrue);

    bus.unregister('cmd', handler);
    expect(bus.invoke('cmd'), isFalse);
    expect(calls, 1);
  });

  test('invoke exposes isRepeat via CommandInvocationScope', () {
    final bus = CommandBus();
    var sawRepeat = false;
    bus.register('cmd', () {
      sawRepeat = CommandInvocationScope.instance.isRepeat;
    });

    bus.invoke('cmd');
    expect(sawRepeat, isFalse);

    bus.invoke('cmd', isRepeat: true);
    expect(sawRepeat, isTrue);
  });
}
