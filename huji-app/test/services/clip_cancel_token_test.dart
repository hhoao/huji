import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/clip_cancel_token.dart';

void main() {
  tearDown(() {
    ClipCancelToken.release('job-a');
    ClipCancelToken.release('job-b');
  });

  test('forJob returns a stable token per job id', () {
    final a = ClipCancelToken.forJob('job-a');
    expect(identical(a, ClipCancelToken.forJob('job-a')), isTrue);
    expect(identical(a, ClipCancelToken.forJob('job-b')), isFalse);
    expect(ClipCancelToken.find('job-a'), same(a));
  });

  test('listeners fire once; late listeners fire immediately', () {
    final token = ClipCancelToken.forJob('job-a');
    var count = 0;
    token.addListener(() => count++);

    token.cancel();
    token.cancel(); // terminal: second cancel is a no-op
    expect(count, 1);
    expect(token.isCancelled, isTrue);

    token.addListener(() => count++);
    expect(count, 2, reason: 'a listener added after cancel must run at once');
  });

  test('removeListener prevents the callback from firing', () {
    final token = ClipCancelToken.forJob('job-a');
    var count = 0;
    void listener() => count++;
    token.addListener(listener);
    token.removeListener(listener);
    token.cancel();
    expect(count, 0);
  });

  test('cancelJob cancels and unregisters; release only unregisters', () {
    final token = ClipCancelToken.forJob('job-a');
    ClipCancelToken.cancelJob('job-a');
    expect(token.isCancelled, isTrue);
    expect(ClipCancelToken.find('job-a'), isNull);

    final tokenB = ClipCancelToken.forJob('job-b');
    ClipCancelToken.release('job-b');
    expect(tokenB.isCancelled, isFalse);
    expect(ClipCancelToken.find('job-b'), isNull);
  });

  test('cancelJob without a running job is a no-op', () {
    expect(() => ClipCancelToken.cancelJob('missing'), returnsNormally);
  });

  test('throwIfCancelled throws only after cancel', () {
    final token = ClipCancelToken.forJob('job-a');
    expect(token.throwIfCancelled, returnsNormally);

    token.cancel();
    expect(token.throwIfCancelled, throwsA(isA<ClipCancelledException>()));
  });
}
