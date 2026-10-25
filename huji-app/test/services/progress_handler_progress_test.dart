import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/progress_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressHandler progress is monotonic', () {
    test('extraction progress advances before any frame is predicted', () {
      final reported = <double>[];
      final handler = ProgressHandler(
        onProgress: (progress, _) => reported.add(progress),
      );
      // 10 s @ 6 fps → 60 frames.
      handler.startProcess(10, 6);

      handler.reportFrameProgress(15);
      expect(reported.last, closeTo(0.25, 1e-9));

      // A slower concurrent chunk must not rewind the bar.
      handler.reportFrameProgress(5);
      expect(reported.last, closeTo(0.25, 1e-9));

      handler.reportFrameProgress(45);
      expect(reported.last, closeTo(0.75, 1e-9));
    });

    test('frame predictions never rewind extraction progress', () {
      final reported = <double>[];
      final handler = ProgressHandler(
        onProgress: (progress, _) => reported.add(progress),
      );
      handler.startProcess(10, 6);

      // Extraction of the second chunk reports 75 % first.
      handler.reportFrameProgress(45);
      expect(reported.last, closeTo(0.75, 1e-9));

      // Predictions start from the first chunk: frames/total would be 1/60.
      handler.forword();
      expect(reported.last, closeTo(0.75, 1e-9));

      // Once predictions overtake the extraction mark, they drive the bar.
      while (reported.length < 100) {
        handler.forword();
        if (reported.last > 0.75) break;
      }
      expect(reported.last, greaterThan(0.75));
      expect(reported.last, closeTo(46 / 60, 1e-9));
    });

    test('clamps out-of-range extraction reports', () {
      final reported = <double>[];
      final handler = ProgressHandler(
        onProgress: (progress, _) => reported.add(progress),
      );
      handler.startProcess(10, 6);

      handler.reportFrameProgress(-5);
      expect(reported, isEmpty);

      handler.reportFrameProgress(999);
      expect(reported.last, 1.0);
    });

    test('does not report after cancellation', () {
      final reported = <double>[];
      final handler = ProgressHandler(
        onProgress: (progress, _) => reported.add(progress),
      );
      handler.startProcess(10, 6);
      handler.cancel();
      reported.clear();

      handler.reportFrameProgress(30);
      handler.forword();
      expect(reported, isEmpty);
    });
  });
}
