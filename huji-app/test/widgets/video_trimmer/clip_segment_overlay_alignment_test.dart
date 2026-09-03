import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';
import 'package:multi_split_view/multi_split_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'overlay segment edges stay on timeToTimelineX with thickness 0',
    (tester) async {
      const totalDurationMs = 125300;
      const tile = 88.0;
      final totalWidth = timelineTotalWidth(
        durationSeconds: totalDurationMs / 1000.0,
        tileSize: tile,
        timeIntervalSeconds: 1.0,
      );

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

      final controller = MultiSplitViewController(
        areas: [
          for (final (start, end) in ranges)
            Area(
              size: timeToTimelineX(
                timeSeconds: (end - start) / 1000.0,
                totalDurationSeconds: totalDurationMs / 1000.0,
                totalWidth: totalWidth,
              ),
              builder: (context, area) => const ColoredBox(color: Colors.white),
            ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                height: 88,
                child: MultiSplitViewTheme(
                  data: MultiSplitViewThemeData(
                    dividerThickness: 0,
                    dividerHandleBuffer: 22,
                  ),
                  child: MultiSplitView(
                    controller: controller,
                    axis: Axis.horizontal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var cum = 0.0;
      var maxAbsDrift = 0.0;
      for (var i = 0; i < ranges.length; i++) {
        cum += controller.getArea(i).size!;
        final expected = timeToTimelineX(
          timeSeconds: ranges[i].$2 / 1000.0,
          totalDurationSeconds: totalDurationMs / 1000.0,
          totalWidth: totalWidth,
        );
        maxAbsDrift = (cum - expected).abs() > maxAbsDrift
            ? (cum - expected).abs()
            : maxAbsDrift;
      }

      expect(maxAbsDrift, lessThan(0.5));
    },
  );
}
