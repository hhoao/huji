import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/pages/desktop/precision_edit_round_nav.dart';

SegmentInfo _segment(double start, double end) => SegmentInfo(
      actionType: ActionType.playBall,
      startSeconds: start,
      endSeconds: end,
    );

void main() {
  group('resolvePrecisionEditRoundIndex', () {
    test('prefers tracked index over stale segment value', () {
      final segments = [_segment(0, 1), _segment(2, 3), _segment(4, 5)];
      final staleSelection = _segment(2, 3);

      expect(
        resolvePrecisionEditRoundIndex(
          segments: segments,
          activeRoundIndex: 2,
          activeSegment: staleSelection,
        ),
        2,
      );
    });

    test('falls back to segment value when index is unset', () {
      final segments = [_segment(0, 1), _segment(2, 3)];

      expect(
        resolvePrecisionEditRoundIndex(
          segments: segments,
          activeSegment: segments[1],
        ),
        1,
      );
    });

    test('keeps index when segment times change after editing', () {
      final segments = [_segment(0, 1.2), _segment(2, 3.4)];
      final staleSelection = _segment(2, 3);

      expect(
        resolvePrecisionEditRoundIndex(
          segments: segments,
          activeRoundIndex: 1,
          activeSegment: staleSelection,
        ),
        1,
      );
    });
  });

  group('shiftPrecisionEditRoundIndex', () {
    test('clamps at list bounds', () {
      expect(shiftPrecisionEditRoundIndex(0, -1, 3), 0);
      expect(shiftPrecisionEditRoundIndex(2, 1, 3), 2);
      expect(shiftPrecisionEditRoundIndex(1, 1, 3), 2);
    });
  });
}
