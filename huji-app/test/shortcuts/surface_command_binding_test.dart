import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/shortcut_route_scope.dart';
import 'package:huji_app/shortcuts/surface_command_binding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommandBus bus;
  late ShortcutRouteScope scope;

  setUp(() {
    bus = CommandBus();
    scope = ShortcutRouteScope.instance;
    scope.updateNavRoute('/');
  });

  tearDown(() {
    scope.updateNavRoute('/');
  });

  SurfaceCommandBinding buildBinding({
    required String tabId,
    String? routePath = '/clip/a/edit',
    void Function()? onDeactivated,
  }) {
    return SurfaceCommandBinding(
      bus: bus,
      tabId: tabId,
      routePath: routePath,
      onDeactivated: onDeactivated,
    );
  }

  test('registers handlers only while its tab and route are current', () {
    var invoked = 0;
    final binding = buildBinding(tabId: 'tab-1')
      ..register(CommandIds.playbackPlayPause, () => invoked++);
    binding.attach();

    // 未处于前台：命令不归它。
    scope.updateNavRoute('/library');
    expect(bus.invoke(CommandIds.playbackPlayPause), isFalse);
    expect(invoked, 0);

    // 本 tab、本页面：接管命令。
    scope.updateTabRoute('tab-1', '/clip/a/edit');
    expect(bus.invoke(CommandIds.playbackPlayPause), isTrue);
    expect(invoked, 1);

    binding.detach();
  });

  test('same tab but different page does not own the commands', () {
    var invoked = 0;
    final binding = buildBinding(tabId: 'tab-1')
      ..register(CommandIds.playbackPlayPause, () => invoked++);
    binding.attach();

    // 同一 tab 切到预览页：编辑页不该持有命令（预览↔精修切换场景）。
    scope.updateTabRoute('tab-1', '/clip/a/preview');
    expect(bus.invoke(CommandIds.playbackPlayPause), isFalse);

    binding.detach();
  });

  test('different tab with the same route does not own the commands', () {
    var invoked = 0;
    final binding = buildBinding(tabId: 'tab-1')
      ..register(CommandIds.playbackPlayPause, () => invoked++);
    binding.attach();

    // 另一个 tab 展示同一路径（如两个 /clip/new tab）。
    scope.updateTabRoute('tab-2', '/clip/a/edit');
    expect(bus.invoke(CommandIds.playbackPlayPause), isFalse);

    binding.detach();
  });

  test('null routePath matches by tab id only', () {
    var invoked = 0;
    final binding = buildBinding(tabId: 'tab-1', routePath: null)
      ..register(CommandIds.playbackPlayPause, () => invoked++);
    binding.attach();

    scope.updateTabRoute('tab-1', '/clip/new');
    expect(bus.invoke(CommandIds.playbackPlayPause), isTrue);
    expect(invoked, 1);

    binding.detach();
  });

  test('onDeactivated fires exactly on active→inactive transitions', () {
    var deactivated = 0;
    final binding = buildBinding(
      tabId: 'tab-1',
      onDeactivated: () => deactivated++,
    )..register(CommandIds.playbackPlayPause, () {});
    binding.attach();

    scope.updateTabRoute('tab-1', '/clip/a/edit');
    expect(deactivated, 0);

    scope.updateTabRoute('tab-1', '/clip/a/preview');
    expect(deactivated, 1);

    // 已经失活时再次路由变化不重复触发。
    scope.updateNavRoute('/library');
    expect(deactivated, 1);

    // 回到前台再离开：再次触发。
    scope.updateTabRoute('tab-1', '/clip/a/edit');
    expect(deactivated, 1);
    scope.updateTabRoute('tab-2', '/clip/b/edit');
    expect(deactivated, 2);

    binding.detach();
  });

  test('attach while frontmost registers immediately', () {
    scope.updateTabRoute('tab-1', '/clip/a/edit');
    var invoked = 0;
    final binding = buildBinding(tabId: 'tab-1')
      ..register(CommandIds.playbackPlayPause, () => invoked++);
    binding.attach();

    expect(bus.invoke(CommandIds.playbackPlayPause), isTrue);
    expect(invoked, 1);

    binding.detach();
  });

  test('detach drops registrations and stops following the scope', () {
    scope.updateTabRoute('tab-1', '/clip/a/edit');
    var invoked = 0;
    final binding = buildBinding(tabId: 'tab-1')
      ..register(CommandIds.playbackPlayPause, () => invoked++);
    binding.attach();
    binding.detach();

    scope.updateTabRoute('tab-1', '/clip/a/preview');
    scope.updateTabRoute('tab-1', '/clip/a/edit');
    expect(bus.invoke(CommandIds.playbackPlayPause), isFalse);
    expect(invoked, 0);
  });

  test('register replaces the previous handler for the same id', () {
    scope.updateTabRoute('tab-1', '/clip/a/edit');
    var first = 0;
    var second = 0;
    final binding = buildBinding(tabId: 'tab-1')
      ..register(CommandIds.playbackPlayPause, () => first++)
      ..register(CommandIds.playbackPlayPause, () => second++);
    binding.attach();

    expect(bus.invoke(CommandIds.playbackPlayPause), isTrue);
    expect(first, 0);
    expect(second, 1);

    binding.detach();
  });

  test('registerPlayback wires the shared playback command ids', () {
    scope.updateTabRoute('tab-1', '/clip/a/edit');
    var playPause = 0;
    final binding = buildBinding(tabId: 'tab-1')
      ..registerPlayback(
        playPause: () => playPause++,
        // 未提供的命令不应注册。
      );
    binding.attach();

    expect(bus.invoke(CommandIds.playbackPlayPause), isTrue);
    expect(bus.invoke(CommandIds.playbackSeekBackward), isFalse);
    expect(playPause, 1);

    binding.detach();
  });
}
