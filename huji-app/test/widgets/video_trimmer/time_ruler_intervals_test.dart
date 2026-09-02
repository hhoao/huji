import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';

void main() {
  group('resolveTimeRulerIntervals', () {
    test('keeps 1s labels when timeline is dense enough (desktop short clip)', () {
      // Desktop tile 88px / 1s thumbnail interval.
      final intervals = resolveTimeRulerIntervals(88);

      expect(intervals.labelInterval, 1.0);
      expect(intervals.shortInterval, 0.2);
      expect(intervals.textInterval, 5);
    });

    test('widens labels when compressed to ~44 px/s (15–30 min desktop)', () {
      final intervals = resolveTimeRulerIntervals(44);

      expect(intervals.labelInterval, greaterThanOrEqualTo(2.0));
      expect(intervals.labelInterval * 44, greaterThanOrEqualTo(48));
      expect(intervals.shortInterval * 44, greaterThanOrEqualTo(8));
    });

    test('widens labels when compressed to ~18 px/s (>60 min desktop)', () {
      final intervals = resolveTimeRulerIntervals(17.6);

      expect(intervals.labelInterval, greaterThanOrEqualTo(5.0));
      expect(intervals.labelInterval * 17.6, greaterThanOrEqualTo(48));
      expect(intervals.shortInterval * 17.6, greaterThanOrEqualTo(8));
    });

    test('label interval is an integer multiple of short interval', () {
      for (final pps in [88.0, 44.0, 29.3, 17.6, 8.0]) {
        final intervals = resolveTimeRulerIntervals(pps);
        expect(
          intervals.labelInterval / intervals.shortInterval,
          closeTo(intervals.textInterval.toDouble(), 1e-9),
        );
        expect(intervals.longInterval, intervals.labelInterval);
      }
    });
  });

  group('timeRulerTickOwnedByTile', () {
    test('assigns boundary tick to the next tile (half-open)', () {
      expect(
        timeRulerTickOwnedByTile(0, tileWidth: 88, isLastTile: false),
        isTrue,
      );
      expect(
        timeRulerTickOwnedByTile(88, tileWidth: 88, isLastTile: false),
        isFalse,
      );
      expect(
        timeRulerTickOwnedByTile(88, tileWidth: 88, isLastTile: true),
        isTrue,
      );
    });

    test('centers label on tick without clamping into the tile', () {
      expect(
        timeRulerLabelPaintX(tickX: 0, labelWidth: 32),
        -16,
      );
      expect(
        timeRulerLabelPaintX(tickX: 88, labelWidth: 32),
        72,
      );
    });

    test('each boundary label is drawn once across adjacent tiles', () {
      const tileWidth = 88.0;
      const labelWidth = 32.0;
      // Label interval == tile duration: tick at every tile boundary.
      final drawn = <double>[];
      for (var tile = 0; tile < 4; tile++) {
        final isLast = tile == 3;
        for (final tickX in [0.0, tileWidth]) {
          if (!timeRulerTickOwnedByTile(
            tickX,
            tileWidth: tileWidth,
            isLastTile: isLast,
          )) {
            continue;
          }
          drawn.add(
            tile * tileWidth +
                timeRulerLabelPaintX(tickX: tickX, labelWidth: labelWidth),
          );
        }
      }
      // Absolute text origins stay a full tile apart — no packed pairs.
      expect(drawn, [ -16, 72, 160, 248, 336 ]);
      for (var i = 1; i < drawn.length; i++) {
        expect(drawn[i] - drawn[i - 1], tileWidth);
      }
    });
  });
}
