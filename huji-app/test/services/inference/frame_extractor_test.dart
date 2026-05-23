import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:restcut/services/inference/frame_extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FrameExtractor', () {
    test('extractFramesRaw returns correct number of raw RGB frames', () async {
      // Create a 1-second test video at 640x480 using ffmpeg (testsrc filter)
      final testVideo =
          '${Directory.systemTemp.path}/test_input_frame_extract.mp4';
      final createResult = await Process.run('ffmpeg', [
        '-y',
        '-f',
        'lavfi',
        '-i',
        'testsrc=duration=1:size=640x480:rate=6',
        '-c:v',
        'libx264',
        '-pix_fmt',
        'yuv420p',
        testVideo,
      ]);
      if (createResult.exitCode != 0) {
        throw Exception(
            'Failed to create test video: ${createResult.stderr}');
      }

      try {
        final frames = await FrameExtractor().extractFramesRaw(
          videoPath: testVideo,
          fps: 6,
          width: 640,
          height: 640,
          workDirectory: Directory.systemTemp,
        );

        // 1 second at 6fps ≈ 6 frames (may be 5-7 due to VFR)
        expect(frames.length, greaterThanOrEqualTo(5));
        expect(frames.length, lessThanOrEqualTo(7));

        // Each frame is 640*640*3 bytes of raw RGB24
        final expectedFrameSize = 640 * 640 * 3;
        for (final frame in frames) {
          expect(frame.length, expectedFrameSize);
        }
      } finally {
        await File(testVideo).delete();
      }
    });
  });
}
