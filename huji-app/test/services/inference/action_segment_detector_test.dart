import 'package:flutter_test/flutter_test.dart';
import 'package:restcut/services/inference/action_segment_detector.dart';

void main() {
  group('ActionSegmentDetector', () {
    test('detects continuous play_ball segments', () {
      // Simulate 10 seconds of frames at 6fps (60 predictions)
      // Seconds 2-7 are play_ball, rest are pick_ball
      final predictions = <FramePrediction>[];
      for (var s = 0.0; s < 10.0; s += 1.0 / 6.0) {
        final action = (s >= 2.0 && s <= 7.0)
            ? ActionType.playBall
            : ActionType.pickBall;
        predictions.add(FramePrediction(actionType: action, seconds: s));
      }

      final detector = ActionSegmentDetector();
      final segments = detector.detectSegments(
        predictions,
        actionType: ActionType.playBall,
        intervalSeconds: 2.0,
        windowCount: 4,
      );

      expect(segments.length, 1);
      expect(segments[0].startSeconds, closeTo(2.0, 0.2));
      expect(segments[0].endSeconds, closeTo(7.0, 0.2));
      expect(segments[0].actionType, ActionType.playBall);
    });

    test('returns empty for no matching action', () {
      final predictions = List.generate(60, (i) => FramePrediction(
        actionType: ActionType.pickBall,
        seconds: i / 6.0,
      ));

      final detector = ActionSegmentDetector();
      final segments = detector.detectSegments(
        predictions,
        actionType: ActionType.playBall,
        intervalSeconds: 2.0,
        windowCount: 4,
      );

      expect(segments, isEmpty);
    });

    test('detects multiple separated segments', () {
      final predictions = <FramePrediction>[];
      for (var s = 0.0; s < 20.0; s += 1.0 / 6.0) {
        final action = ((s >= 2.0 && s <= 4.0) || (s >= 10.0 && s <= 14.0))
            ? ActionType.playBall
            : ActionType.pickBall;
        predictions.add(FramePrediction(actionType: action, seconds: s));
      }

      final detector = ActionSegmentDetector();
      final segments = detector.detectSegments(
        predictions,
        actionType: ActionType.playBall,
        intervalSeconds: 2.0,
        windowCount: 4,
      );

      expect(segments.length, 2);
    });

    test('ping pong segment detection merges fire_ball into play_ball', () {
      final predictions = <FramePrediction>[];
      for (var s = 0.0; s < 10.0; s += 1.0 / 6.0) {
        final action = (s >= 2.0 && s <= 7.0)
            ? ActionType.playBall
            : ActionType.fireBall;
        predictions.add(FramePrediction(actionType: action, seconds: s));
      }

      final detector = ActionSegmentDetector();
      final segments = detector.detectPingPongSegments(
        predictions,
        mergeFireBallAndPlayBall: true,
      );

      expect(segments.length, 1);
    });
  });
}
