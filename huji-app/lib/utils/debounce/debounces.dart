import 'dart:async';

/// A void callback, i.e. (){}, so we don't need to import e.g. `dart.ui`
/// just for the VoidCallback type definition.
typedef DebounceCallback = void Function();

class _DebounceOperation {
  DebounceCallback callback;
  Timer timer;
  _DebounceOperation(this.callback, this.timer);
}

/// A static class for handling method call debouncing.
class Debounces {
  static final Map<String, _DebounceOperation> _operations = {};

  /// Will delay the execution of [onExecute] with the given [duration]. If another call to
  /// debounce() with the same [tag] happens within this duration, the first call will be
  /// cancelled and the debouncer will start waiting for another [duration] before executing
  /// [onExecute].
  ///
  /// [tag] is any arbitrary String, and is used to identify this particular debounce
  /// operation in subsequent calls to [debounce()] or [cancel()].
  ///
  /// If [duration] is `Duration.zero`, [onExecute] will be executed immediately, i.e.
  /// synchronously.
  static void debounce(
    String tag,
    Duration duration,
    DebounceCallback onExecute,
  ) {
    if (duration == Duration.zero) {
      _operations[tag]?.timer.cancel();
      _operations.remove(tag);
      onExecute();
    } else {
      _operations[tag]?.timer.cancel();

      _operations[tag] = _DebounceOperation(
        onExecute,
        Timer(duration, () {
          _operations[tag]?.timer.cancel();
          _operations.remove(tag);

          onExecute();
        }),
      );
    }
  }

  /// Fires the callback associated with [tag] immediately. This does not cancel the debounce timer,
  /// so if you want to invoke the callback and cancel the debounce timer, you must first call
  /// `fire(tag)` and then `cancel(tag)`.
  static void fire(String tag) {
    _operations[tag]?.callback();
  }

  /// Cancels any active debounce operation with the given [tag].
  static void cancel(String tag) {
    _operations[tag]?.timer.cancel();
    _operations.remove(tag);
  }

  /// Cancels all active debouncers.
  static void cancelAll() {
    for (final operation in _operations.values) {
      operation.timer.cancel();
    }
    _operations.clear();
  }

  /// Returns the number of active debouncers (debouncers that haven't yet called their
  /// [onExecute] methods).
  static int count() {
    return _operations.length;
  }
}

/// A single debouncer instance for managing one debounce operation.
/// This is useful when you want to create a dedicated debouncer for a specific widget or component.
class Debouncer {
  final String _tag;
  final Duration _duration;
  Timer? _timer;
  DebounceCallback? _callback;

  /// Creates a new debouncer instance.
  ///
  /// [tag] is a unique identifier for this debouncer.
  /// [duration] is the debounce delay duration.
  Debouncer({required String tag, required Duration duration})
    : _tag = tag,
      _duration = duration;

  /// Executes the callback with debouncing.
  /// If called multiple times within the duration, only the last call will be executed.
  void call(DebounceCallback callback) {
    _callback = callback;
    _timer?.cancel();

    if (_duration == Duration.zero) {
      callback();
    } else {
      _timer = Timer(_duration, () {
        _callback?.call();
        _timer = null;
      });
    }
  }

  /// Executes the callback with debouncing and parameter.
  void callWithParam<T>(void Function(T) callback, T parameter) {
    call(() => callback(parameter));
  }

  /// Fires the callback immediately without waiting for the debounce duration.
  void fire() {
    _callback?.call();
  }

  /// Cancels the current debounce operation.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _callback = null;
  }

  /// Returns true if there's an active debounce operation.
  bool get isActive => _timer != null;

  /// Returns the tag of this debouncer.
  String get tag => _tag;

  /// Returns the duration of this debouncer.
  Duration get duration => _duration;

  /// Disposes the debouncer and cancels any active operations.
  void dispose() {
    cancel();
  }
}
