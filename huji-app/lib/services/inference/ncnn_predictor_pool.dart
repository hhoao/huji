import 'dart:async';
import 'dart:collection';

import 'package:huji_app/services/inference/ncnn_model_predictor.dart';

/// Bounded pool of [NcnnModelPredictor] instances for parallel chunk inference.
///
/// Each predictor owns its own ncnn network. Borrowing via [withPredictor]
/// keeps concurrent runs ≤ [size] without sharing a net across calls.
class NcnnPredictorPool {
  final List<NcnnModelPredictor> _all;
  final List<NcnnModelPredictor> _idle;
  final Queue<Completer<NcnnModelPredictor>> _waiters = Queue();
  bool _disposed = false;

  NcnnPredictorPool._(this._all) : _idle = List<NcnnModelPredictor>.from(_all);

  /// True when every predictor's model is loaded and ready.
  bool get allLoaded => _all.every((p) => p.isLoaded);

  /// Create [size] predictors that all load the same on-disk model.
  ///
  /// All models load CONCURRENTLY; the returned future completes only
  /// after every predictor is ready — borrowers never hit a lazy load.
  static Future<NcnnPredictorPool> create({
    required String paramFilePath,
    required String binFilePath,
    required List<String> fallbackClassNames,
    required int size,
  }) async {
    if (size < 1) {
      throw ArgumentError.value(size, 'size', 'must be >= 1');
    }
    final predictors = List<NcnnModelPredictor>.generate(
      size,
      (_) => NcnnModelPredictor(
        paramFilePath: paramFilePath,
        binFilePath: binFilePath,
        fallbackClassNames: fallbackClassNames,
      ),
    );
    // Parallel load — each predictor owns its own engine/net.
    await Future.wait(predictors.map((p) => p.warmUp()));
    return NcnnPredictorPool._(predictors);
  }

  int get size => _all.length;

  Future<T> withPredictor<T>(
    Future<T> Function(NcnnModelPredictor predictor) action,
  ) async {
    final predictor = await _acquire();
    try {
      return await action(predictor);
    } finally {
      _release(predictor);
    }
  }

  Future<NcnnModelPredictor> _acquire() async {
    if (_disposed) {
      throw StateError('NcnnPredictorPool has been disposed');
    }
    if (_idle.isNotEmpty) {
      return _idle.removeLast();
    }
    final waiter = Completer<NcnnModelPredictor>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void _release(NcnnModelPredictor predictor) {
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
            StateError('NcnnPredictorPool disposed while waiting'),
          );
    }
    _idle.clear();
    for (final predictor in _all) {
      await predictor.dispose();
    }
    _all.clear();
  }
}
