import 'dart:async';

typedef RateLimitCallback = void Function();

class _RateLimitOperation {
  RateLimitCallback? callback;
  RateLimitCallback? onAfter;

  Timer timer;

  _RateLimitOperation(this.timer);
}

class RateLimits {
  static final Map<String, _RateLimitOperation> _operations = {};

  /// Will execute [onExecute] immediately and record additional attempts to
  /// call rateLimit with the same [tag] happens until the given [duration] has passed
  /// when it will execute with the last attempt.
  ///
  /// [tag] is any arbitrary String, and is used to identify this particular rate limited
  /// operation in subsequent calls to [rateLimit()] or [cancel()].
  ///
  /// [duration] is the amount of time until the subsequent attempts will be sent.
  ///
  /// [onAfter] is executed after the [duration] has passed in which there were no rate limited calls.
  ///
  /// Returns whether the operation was rate limited
  static bool rateLimit(
    String tag,
    Duration duration,
    RateLimitCallback onExecute, {
    RateLimitCallback? onAfter,
  }) {
    final rateLimited = _operations.containsKey(tag);
    if (rateLimited) {
      _operations[tag]?.callback = onExecute;
      _operations[tag]?.onAfter = onAfter;
      return true;
    }

    final operation = _RateLimitOperation(
      Timer.periodic(duration, (Timer timer) {
        final operation = _operations[tag];

        if (operation != null) {
          if (operation.callback == null) {
            operation.timer.cancel();
            _operations.remove(tag);
            onAfter?.call();
          } else {
            operation.callback?.call();
            operation.onAfter?.call();
            operation.callback = null;
            operation.onAfter = null;
          }
        }
      }),
    );

    _operations[tag] = operation;

    onExecute();

    return false;
  }

  /// Cancels any active rate limiter with the given [tag].
  static void cancel(String tag) {
    _operations[tag]?.timer.cancel();
    _operations.remove(tag);
  }

  /// Cancels all active rate limiters.
  static void cancelAll() {
    for (final operation in _operations.values) {
      operation.timer.cancel();
    }
    _operations.clear();
  }

  /// Returns the number of active rate limiters
  static int count() {
    return _operations.length;
  }
}

/// A single rate limiter instance for managing one rate limit operation.
/// This is useful when you want to create a dedicated rate limiter for a specific widget or component.
class RateLimiter {
  final String _tag;
  final Duration _duration;
  Timer? _timer;
  RateLimitCallback? _callback;
  RateLimitCallback? _onAfter;

  /// Creates a new rate limiter instance.
  ///
  /// [tag] is a unique identifier for this rate limiter.
  /// [duration] is the rate limit duration.
  RateLimiter({required String tag, required Duration duration})
    : _tag = tag,
      _duration = duration;

  /// Executes the callback with rate limiting.
  /// If called multiple times within the duration, only the last call will be executed after the duration.
  ///
  /// Returns true if the operation was rate limited (queued for later execution).
  bool call(RateLimitCallback callback, {RateLimitCallback? onAfter}) {
    final rateLimited = _timer != null;

    if (rateLimited) {
      _callback = callback;
      _onAfter = onAfter;
      return true;
    }

    _callback = callback;
    _onAfter = onAfter;
    _timer = Timer.periodic(_duration, (Timer timer) {
      if (_callback == null) {
        timer.cancel();
        _timer = null;
        onAfter?.call();
      } else {
        _callback?.call();
        _onAfter?.call();
        _callback = null;
        _onAfter = null;
      }
    });

    callback();
    return false;
  }

  /// Executes the callback with rate limiting and parameter.
  ///
  /// Returns true if the operation was rate limited (queued for later execution).
  bool callWithParam<T>(
    void Function(T) callback,
    T parameter, {
    RateLimitCallback? onAfter,
  }) {
    return call(() => callback(parameter), onAfter: onAfter);
  }

  /// Cancels the current rate limit operation.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _callback = null;
    _onAfter = null;
  }

  /// Returns true if there's an active rate limit operation.
  bool get isActive => _timer != null;

  /// Returns the tag of this rate limiter.
  String get tag => _tag;

  /// Returns the duration of this rate limiter.
  Duration get duration => _duration;

  /// Disposes the rate limiter and cancels any active operations.
  void dispose() {
    cancel();
  }
}
