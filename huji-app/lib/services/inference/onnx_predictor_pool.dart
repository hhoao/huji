import 'dart:async';
import 'dart:collection';

import 'package:huji_app/services/inference/onnx_model_predictor.dart';

/// Bounded pool of [OnnxModelPredictor] instances for parallel chunk inference.
///
/// Each predictor owns its own ORT session. Borrowing via [withPredictor]
/// keeps concurrent runs ≤ [size] without sharing a session across isolates.
class OnnxPredictorPool {
  final List<OnnxModelPredictor> _all;
  final List<OnnxModelPredictor> _idle;
  final Queue<Completer<OnnxModelPredictor>> _waiters = Queue();
  bool _disposed = false;

  OnnxPredictorPool._(this._all) : _idle = List<OnnxModelPredictor>.from(_all);

  /// Create [size] predictors that all load the same on-disk model.
  factory OnnxPredictorPool.create({
    required String modelFilePath,
    required List<String> fallbackClassNames,
    required int size,
  }) {
    if (size < 1) {
      throw ArgumentError.value(size, 'size', 'must be >= 1');
    }
    final predictors = List<OnnxModelPredictor>.generate(
      size,
      (_) => OnnxModelPredictor(
        modelFilePath: modelFilePath,
        fallbackClassNames: fallbackClassNames,
        // 并行度来自 worker 数；每个 session 单线程，避免 N×N 线程超订阅。
        cpuThreadCount: 1,
      ),
    );
    return OnnxPredictorPool._(predictors);
  }

  int get size => _all.length;

  Future<T> withPredictor<T>(
    Future<T> Function(OnnxModelPredictor predictor) action,
  ) async {
    final predictor = await _acquire();
    try {
      return await action(predictor);
    } finally {
      _release(predictor);
    }
  }

  Future<OnnxModelPredictor> _acquire() async {
    if (_disposed) {
      throw StateError('OnnxPredictorPool has been disposed');
    }
    if (_idle.isNotEmpty) {
      return _idle.removeLast();
    }
    final waiter = Completer<OnnxModelPredictor>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void _release(OnnxModelPredictor predictor) {
    if (_disposed) {
      return;
    }
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete(predictor);
    } else {
      _idle.add(predictor);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().completeError(
            StateError('OnnxPredictorPool disposed while waiting'),
          );
    }
    _idle.clear();
    for (final predictor in _all) {
      await predictor.dispose();
    }
    _all.clear();
  }
}
