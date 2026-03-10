import 'dart:async';

typedef ThrottleCallback = void Function();

class _ThrottleOperation {
  ThrottleCallback callback;
  ThrottleCallback? onAfter;
  Timer timer;

  _ThrottleOperation(this.callback, this.timer, {this.onAfter});
}

class Throttles {
  static final Map<String, _ThrottleOperation> _operations = {};

  /// Will execute [onExecute] immediately and ignore additional attempts to
  /// call throttle with the same [tag] happens for the given [duration].
  ///
  /// [tag] is any arbitrary String, and is used to identify this particular throttle
  /// operation in subsequent calls to [throttle()] or [cancel()].
  ///
  /// [duration] is the amount of time subsequent attempts will be ignored.
  ///
  /// Returns whether the operation was throttled
  static bool throttle(
    String tag,
    Duration duration,
    ThrottleCallback onExecute, {
    ThrottleCallback? onAfter,
  }) {
    var throttled = _operations.containsKey(tag);
    if (throttled) {
      return true;
    }

    _operations[tag] = _ThrottleOperation(
      onExecute,
      Timer(duration, () {
        _operations[tag]?.timer.cancel();
        _ThrottleOperation? removed = _operations.remove(tag);

        removed?.onAfter?.call();
      }),
      onAfter: onAfter,
    );

    onExecute();

    return false;
  }

  /// Cancels any active throttle with the given [tag].
  static void cancel(String tag) {
    _operations[tag]?.timer.cancel();
    _operations.remove(tag);
  }

  /// Cancels all active throttles.
  static void cancelAll() {
    for (final operation in _operations.values) {
      operation.timer.cancel();
    }
    _operations.clear();
  }

  /// Returns the number of active throttles
  static int count() {
    return _operations.length;
  }
}

/// A single throttler instance for managing one throttle operation.
/// This is useful when you want to create a dedicated throttler for a specific widget or component.
class Throttler {
  final String _tag;
  final Duration _duration;
  Timer? _timer;
  ThrottleCallback? _onAfter;

  /// Creates a new throttler instance.
  ///
  /// [tag] is a unique identifier for this throttler.
  /// [duration] is the throttle duration.
  Throttler({required String tag, required Duration duration})
    : _tag = tag,
      _duration = duration;

  /// Executes the callback with throttling.
  /// If called multiple times within the duration, only the first call will be executed.
  ///
  /// Returns true if the operation was throttled (ignored).
  bool call(ThrottleCallback callback, {ThrottleCallback? onAfter}) {
    if (_timer != null) {
      return true; // Already throttled
    }

    _onAfter = onAfter;
    _timer = Timer(_duration, () {
      _timer?.cancel();
      _timer = null;
      _onAfter?.call();
      _onAfter = null;
    });

    callback();
    return false; // Not throttled
  }

  /// Executes the callback with throttling and parameter.
  ///
  /// Returns true if the operation was throttled (ignored).
  bool callWithParam<T>(
    void Function(T) callback,
    T parameter, {
    ThrottleCallback? onAfter,
  }) {
    return call(() => callback(parameter), onAfter: onAfter);
  }

  /// Cancels the current throttle operation.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _onAfter = null;
  }

  /// Returns true if there's an active throttle operation.
  bool get isActive => _timer != null;

  /// Returns the tag of this throttler.
  String get tag => _tag;

  /// Returns the duration of this throttler.
  Duration get duration => _duration;

  /// Disposes the throttler and cancels any active operations.
  void dispose() {
    cancel();
  }
}
