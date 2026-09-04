import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/shell/workspace/workspace_tab_store.dart';

WorkspaceTab _playerTab(String tabId, String videoPath) => WorkspaceTab(
  tabId: tabId,
  kind: WorkspaceTabKind.videoPlayer,
  routePath: '/video/player',
  title: 'video',
  params: {'videoPath': videoPath, 'fileName': 'video'},
);

WorkspaceTab _clipTab(String tabId, String clipId) => WorkspaceTab(
  tabId: tabId,
  kind: WorkspaceTabKind.clipWorkflow,
  routePath: '/clip/$clipId/preview',
  title: clipId,
  params: {'clipId': clipId},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkspaceTabStore store;

  setUp(() {
    store = WorkspaceTabStore.instance;
    // Reset singleton state between tests.
    for (final tab in store.tabs.toList()) {
      store.close(tab.tabId);
    }
  });

  test('open activates an existing tab with the same instance key', () {
    final first = store.open(_playerTab('a', '/tmp/a.mp4'));
    store.open(_clipTab('b', 'clip-1'));

    final again = store.open(_playerTab('c', '/tmp/a.mp4'));

    expect(again.tabId, first.tabId, reason: 'same video reuses the tab');
    expect(store.tabs, hasLength(2), reason: 'no duplicate tab created');
    expect(store.activeTabId, first.tabId);
  });

  test('distinct instance keys open distinct tabs', () {
    store.open(_playerTab('a', '/tmp/a.mp4'));
    store.open(_playerTab('b', '/tmp/b.mp4'));

    expect(store.tabs, hasLength(2));
  });

  test('clipNew always opens a fresh instance', () {
    store.open(
      WorkspaceTab(
        tabId: 'a',
        kind: WorkspaceTabKind.clipNew,
        routePath: '/clip/new',
        title: 'new',
      ),
    );
    store.open(
      WorkspaceTab(
        tabId: 'b',
        kind: WorkspaceTabKind.clipNew,
        routePath: '/clip/new',
        title: 'new',
      ),
    );

    expect(store.tabs, hasLength(2));
  });

  test('updateTab patches display fields without changing identity', () {
    final tab = store.open(_clipTab('a', 'clip-1'));

    store.updateTab(
      tab.tabId,
      title: '名字',
      routePath: '/clip/clip-1/edit',
      thumbnailPath: '/tmp/thumb.jpg',
    );

    final updated = store.tabs.single;
    expect(updated.title, '名字');
    expect(updated.routePath, '/clip/clip-1/edit');
    expect(updated.thumbnailPath, '/tmp/thumb.jpg');
    expect(updated.tabId, tab.tabId);
    expect(updated.kind, WorkspaceTabKind.clipWorkflow);
  });

  test('close activates the neighbour tab and reports empty state', () {
    store.open(_playerTab('a', '/tmp/a.mp4'));
    final middle = store.open(_playerTab('b', '/tmp/b.mp4'));
    store.open(_playerTab('c', '/tmp/c.mp4'));

    final next = store.close(middle.tabId);

    expect(next?.tabId, 'c', reason: 'right neighbour takes over');
    expect(store.tabs, hasLength(2));

    store.close('c');
    store.close('a');
    expect(store.activeTab, isNull);
  });

  test('setActiveByRoute activates the tab with a matching virtual route', () {
    store.open(_playerTab('a', '/tmp/a.mp4'));
    final clip = store.open(_clipTab('b', 'clip-1'));

    store.setActiveByRoute('/clip/clip-1/preview');

    expect(store.activeTabId, clip.tabId);
    // No match → no change.
    store.setActiveByRoute('/nowhere');
    expect(store.activeTabId, clip.tabId);
  });

  test('noteNavRoute ignores workspace routes', () {
    store.noteNavRoute('/tasks');
    expect(store.lastNavRoute, '/tasks');

    store.noteNavRoute('/workspace');
    store.noteNavRoute('/video/player?videoUrl=x');
    store.noteNavRoute('/clip/new');
    store.noteNavRoute('/tools/video-compress');
    expect(store.lastNavRoute, '/tasks', reason: 'workspace routes are skipped');
  });
}
