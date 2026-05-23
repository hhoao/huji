import 'dart:collection';

/// Action types for sports video classification (matches Python ActionType enum).
enum ActionType {
  fireBall,
  playBall,
  pickBall,
  transition,
  playback,
}

/// A single frame prediction at a specific time.
class FramePrediction {
  final ActionType actionType;
  final double seconds;

  const FramePrediction({required this.actionType, required this.seconds});
}

/// A detected segment of continuous action.
class ActionSegment {
  final ActionType actionType;
  final double startSeconds;
  final double endSeconds;

  const ActionSegment({
    required this.actionType,
    required this.startSeconds,
    required this.endSeconds,
  });

  double get duration => endSeconds - startSeconds;
}

/// Converts per-frame ActionType predictions to continuous game segments.
///
/// Ported from Python `action_segment_detector.py:_detect_continuous_classifier`
/// and the ping pong / badminton action segment detectors.
class ActionSegmentDetector {
  /// Detect continuous segments of [actionType] using sliding window.
  ///
  /// A segment is formed when at least [windowCount] frames of [actionType]
  /// appear within [intervalSeconds]. Segments are greedily extended.
  List<ActionSegment> detectSegments(
    List<FramePrediction> predictions, {
    required ActionType actionType,
    required double intervalSeconds,
    required int windowCount,
  }) {
    final filtered = predictions
        .where((p) => p.actionType == actionType)
        .toList();
    if (filtered.length < windowCount) return [];

    final segments = <ActionSegment>[];
    final n = filtered.length;
    final window = Queue<FramePrediction>();
    var start = 0;
    var end = 0;

    while (end < n) {
      window.addLast(filtered[end]);

      while (window.isNotEmpty &&
          window.last.seconds - window.first.seconds > intervalSeconds) {
        window.removeFirst();
        start++;
      }

      if (window.length >= windowCount) {
        var maxEnd = end;
        while (maxEnd + 1 < n) {
          final nextAction = filtered[maxEnd + 1];
          window.addLast(nextAction);

          while (window.isNotEmpty &&
              window.last.seconds - window.first.seconds > intervalSeconds) {
            window.removeFirst();
          }

          if (window.length >= windowCount) {
            maxEnd++;
          } else {
            break;
          }
        }

        segments.add(ActionSegment(
          actionType: actionType,
          startSeconds: filtered[start].seconds,
          endSeconds: filtered[maxEnd].seconds,
        ));

        end = maxEnd + 1;
        start = end;
        window.clear();
      } else {
        end++;
      }
    }

    return segments;
  }

  /// Filter segments to only those containing play_ball.
  List<Map<ActionType, ActionSegment>> filterMatchSegments(
      List<ActionSegment> segments) {
    final result = <Map<ActionType, ActionSegment>>[];
    for (final segment in segments) {
      if (segment.actionType == ActionType.playBall) {
        result.add({ActionType.playBall: segment});
      }
    }
    return result;
  }

  /// Ping pong segment detection pipeline.
  List<Map<ActionType, ActionSegment>> detectPingPongSegments(
    List<FramePrediction> predictions, {
    bool mergeFireBallAndPlayBall = true,
    double intervalSeconds = 2.0,
    int windowCount = 5,
  }) {
    final effective = mergeFireBallAndPlayBall
        ? predictions.map((p) => p.actionType == ActionType.fireBall
            ? FramePrediction(actionType: ActionType.playBall, seconds: p.seconds)
            : p).toList()
        : predictions;

    final playSegments = detectSegments(
      effective,
      actionType: ActionType.playBall,
      intervalSeconds: intervalSeconds,
      windowCount: windowCount,
    );

    return filterMatchSegments(playSegments);
  }

  /// Badminton segment detection pipeline.
  List<Map<ActionType, ActionSegment>> detectBadmintonSegments(
    List<FramePrediction> predictions, {
    double intervalSeconds = 2.0,
    int windowCount = 6,
  }) {
    final playSegments = detectSegments(
      predictions,
      actionType: ActionType.playBall,
      intervalSeconds: intervalSeconds,
      windowCount: windowCount,
    );

    return filterMatchSegments(playSegments);
  }
}
