import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';

void main() {
  group('resolveTimeRulerIntervals', () {
    test('keeps 1s labels at desktop density (88 px/s, 1 tile = 1s)', () {
      // Desktop tile 88px / 1s thumbnail interval.
      final intervals = resolveTimeRulerIntervals(88);

      expect(intervals.labelInterval, 1.0);
      expect(intervals.shortInterval, 0.2);
      expect(intervals.textInterval, 5);
    });

    test('widens labels when compressed to ~44 px/s', () {
      final intervals = resolveTimeRulerIntervals(44);

      expect(intervals.labelInterval, greaterThanOrEqualTo(2.0));
      expect(intervals.labelInterval * 44, greaterThanOrEqualTo(48));
      expect(intervals.shortInterval * 44, greaterThanOrEqualTo(8));
    });

    test('widens labels when compressed to ~18 px/s', () {
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
      expect(drawn, [-16, 72, 160, 248, 336]);
      for (var i = 1; i < drawn.length; i++) {
        expect(drawn[i] - drawn[i - 1], tileWidth);
      }
    });
  });

  group('timeToTimelineX', () {
    test('integer-second ticks land on tile seams when width is duration-based', () {
      const durationS = 125.3;
      const tile = 88.0;
      const interval = 1.0;
      final totalWidth = timelineTotalWidth(
        durationSeconds: durationS,
        tileSize: tile,
        timeIntervalSeconds: interval,
      );

      for (final t in [0.0, 30.0, 60.0, 100.0, 125.0]) {
        final tickX = timeToTimelineX(
          timeSeconds: t,
          totalDurationSeconds: durationS,
          totalWidth: totalWidth,
        );
        expect(tickX, closeTo(t / interval * tile, 1e-9), reason: 't=$t');
      }
      expect(
        timeToTimelineX(
          timeSeconds: durationS,
          totalDurationSeconds: durationS,
          totalWidth: totalWidth,
        ),
        closeTo(totalWidth, 1e-9),
      );
    });

    test('ceil-based width drifts from tile seams (regression guard)', () {
      const durationS = 125.3;
      const tile = 88.0;
      final ceilWidth = (durationS / 1.0).ceil() * tile;
      final tickAt100 = timeToTimelineX(
        timeSeconds: 100,
        totalDurationSeconds: durationS,
        totalWidth: ceilWidth,
      );
      // This is the old bug: integer second ≠ tile boundary.
      expect((tickAt100 - 100 * tile).abs(), greaterThan(1));
    });

    test('last tile width is the fractional remainder', () {
      const durationS = 125.3;
      const tile = 88.0;
      const interval = 1.0;
      final count = timelineThumbnailCount(
        durationSeconds: durationS,
        timeIntervalSeconds: interval,
      );
      expect(count, 126);
      expect(
        timelineTileWidth(
          index: 0,
          thumbnailCount: count,
          durationSeconds: durationS,
          tileSize: tile,
          timeIntervalSeconds: interval,
        ),
        tile,
      );
      expect(
        timelineTileWidth(
          index: 125,
          thumbnailCount: count,
          durationSeconds: durationS,
          tileSize: tile,
          timeIntervalSeconds: interval,
        ),
        closeTo(0.3 * tile, 1e-9),
      );
    });

    test('is linear so later times do not accumulate extra drift', () {
      const durationS = 90.3;
      final totalWidth = timelineTotalWidth(
        durationSeconds: durationS,
        tileSize: 88,
        timeIntervalSeconds: 1,
      );
      final x30 = timeToTimelineX(
        timeSeconds: 30,
        totalDurationSeconds: durationS,
        totalWidth: totalWidth,
      );
      final x60 = timeToTimelineX(
        timeSeconds: 60,
        totalDurationSeconds: durationS,
        totalWidth: totalWidth,
      );
      expect(x60, closeTo(x30 * 2, 1e-9));
    });
  });
}
