import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('absolute segment edges match timeToTimelineX (no cumulative drift)', () {
    const totalDurationMs = 125300;
    const tile = 88.0;
    final totalWidth = timelineTotalWidth(
      durationSeconds: totalDurationMs / 1000.0,
      tileSize: tile,
      timeIntervalSeconds: 1.0,
    );
    final totalDurationSeconds = totalDurationMs / 1000.0;

    // Contiguous filled ranges like ClipSegmentBloc produces.
    final ranges = <(int, int)>[
      (0, 5200),
      (5200, 9100),
      (9100, 15000),
      (15000, 28000),
      (28000, 45000),
      (45000, 70000),
      (70000, 100000),
      (100000, 125300),
    ];

    for (final (startMs, endMs) in ranges) {
      final left = timeToTimelineX(
        timeSeconds: startMs / 1000.0,
        totalDurationSeconds: totalDurationSeconds,
        totalWidth: totalWidth,
      );
      final right = timeToTimelineX(
        timeSeconds: endMs / 1000.0,
        totalDurationSeconds: totalDurationSeconds,
        totalWidth: totalWidth,
      );

      // Integer-second starts land on tile seams under 1s/tile density.
      if (startMs % 1000 == 0) {
        expect(left, closeTo((startMs / 1000.0) * tile, 1e-9));
      }
      expect(right - left, greaterThan(0));
    }

    // A late segment (e.g. 37:00 style) must not pick up cumulative offset.
    const lateStartMs = 37 * 60 * 1000;
    const lateEndMs = lateStartMs + 7000;
    // Use a longer timeline so 37:00 is in range.
    const longDurationMs = 40 * 60 * 1000;
    final longWidth = timelineTotalWidth(
      durationSeconds: longDurationMs / 1000.0,
      tileSize: tile,
      timeIntervalSeconds: 1.0,
    );
    final lateLeft = timeToTimelineX(
      timeSeconds: lateStartMs / 1000.0,
      totalDurationSeconds: longDurationMs / 1000.0,
      totalWidth: longWidth,
    );
    expect(lateLeft, closeTo(37 * 60 * tile, 1e-9));
    final lateRight = timeToTimelineX(
      timeSeconds: lateEndMs / 1000.0,
      totalDurationSeconds: longDurationMs / 1000.0,
      totalWidth: longWidth,
    );
    expect(lateRight - lateLeft, closeTo(7 * tile, 1e-9));
  });
}
