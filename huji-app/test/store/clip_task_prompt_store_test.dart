import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/store/task/clip_task_prompt_store.dart';

void main() {
  late ClipTaskPromptStore store;

  setUp(() {
    store = ClipTaskPromptStore.instance;
    store.reset();
  });

  tearDown(() {
    store.reset();
  });

  group('register', () {
    test('registered id is pending and promptable', () {
      store.register('task-1');
      expect(store.pendingIds, ['task-1']);
      expect(store.shouldPrompt('task-1'), isTrue);
    });

    test('null and empty ids are ignored', () {
      store.register(null);
      store.register('');
      expect(store.pendingIds, isEmpty);
    });

    test('duplicate register does not stack pending entries', () {
      // 路由 builder 可能重跑(主题切换等),注册必须幂等。
      store.register('task-1');
      store.register('task-1');
      store.register('task-1');
      expect(store.pendingIds, ['task-1']);
    });

    test('consumed id does not come back to life on re-register', () {
      store.register('task-1');
      store.consume('task-1');
      store.register('task-1');
      expect(store.shouldPrompt('task-1'), isFalse);
      expect(store.pendingIds, isEmpty);
    });

    test('pending ids keep registration order', () {
      store.register('a');
      store.register('b');
      store.register('c');
      expect(store.pendingIds, ['a', 'b', 'c']);
    });
  });

  group('consume', () {
    test('consume removes pending and marks consumed', () {
      store.register('task-1');
      store.consume('task-1');
      expect(store.shouldPrompt('task-1'), isFalse);
      expect(store.pendingIds, isEmpty);
    });

    test('consume keeps other pending ids intact', () {
      store.register('a');
      store.register('b');
      store.consume('a');
      expect(store.pendingIds, ['b']);
    });
  });

  group('pendingIds', () {
    test('returned list is unmodifiable', () {
      store.register('task-1');
      expect(() => store.pendingIds.add('task-2'), throwsUnsupportedError);
    });
  });

  group('reset', () {
    test('clears both pending and consumed history', () {
      store.register('task-1');
      store.consume('task-1');
      store.reset();
      store.register('task-1');
      expect(store.shouldPrompt('task-1'), isTrue);
    });
  });
}
