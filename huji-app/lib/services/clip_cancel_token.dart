import 'package:huji_app/utils/logger_utils.dart';

/// Thrown inside the local clip pipeline when its [ClipCancelToken] fires.
///
/// Callers treat it as "the user cancelled", not as a failure — the task must
/// stay in `TaskStatusEnum.cancelled` instead of being flipped to failed.
class ClipCancelledException implements Exception {
  const ClipCancelledException();

  @override
  String toString() => 'ClipCancelledException';
}

/// Cancellation signal for a single local clip/detection job.
///
/// A job is identified by its [jobId] (the clip task id). Tokens live in a
/// static registry so `VideoClipTaskManager.cancelTask` can reach a pipeline
/// that is currently running — including the desktop worker isolate, which has
/// its own copy of every static (see `LocalDetectionIsolateRunner`, which
/// bridges the signal over a `SendPort`).
///
/// A token can only be cancelled once; cancellation is terminal.
class ClipCancelToken {
  ClipCancelToken._(this.jobId);

  final String jobId;

  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  static final Map<String, ClipCancelToken> _registry = {};

  /// Returns the token registered for [jobId], creating one if needed.
  static ClipCancelToken forJob(String jobId) {
    return _registry.putIfAbsent(jobId, () => ClipCancelToken._(jobId));
  }

  /// Returns the token registered for [jobId], if any.
  static ClipCancelToken? find(String jobId) => _registry[jobId];

  /// Cancels the token registered for [jobId] and drops it from the registry.
  ///
  /// Safe to call when no job is running.
  static void cancelJob(String jobId) {
    _registry.remove(jobId)?.cancel();
  }

  /// Drops a finished job's token from the registry.
  static void release(String jobId) {
    _registry.remove(jobId);
  }

  bool get isCancelled => _cancelled;

  /// Registers [listener]; runs it immediately when already cancelled.
  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Fires the cancellation signal exactly once.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;

    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      try {
        listener();
      } catch (e, stackTrace) {
        AppLogger().e('Clip cancel listener failed: $e', stackTrace, e);
      }
    }
  }

  /// Aborts the current step when the job was cancelled.
  ///
  /// Call at pipeline checkpoints so a cancelled job stops instead of running
  /// to completion in the background.
  void throwIfCancelled() {
    if (_cancelled) {
      throw const ClipCancelledException();
    }
  }
}
