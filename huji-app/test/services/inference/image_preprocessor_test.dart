import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/inference/image_preprocessor.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:image/image.dart' as img;

Uint8List _pngBars({required int width, required int height, int bar = 20}) {
  final src = img.Image(width: width, height: height);
  img.fill(src, color: img.ColorRgb8(0, 255, 0));
  if (width >= height) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < bar; x++) {
        src.setPixelRgb(x, y, 255, 0, 0);
        src.setPixelRgb(width - 1 - x, y, 0, 0, 255);
      }
    }
  } else {
    for (var x = 0; x < width; x++) {
      for (var y = 0; y < bar; y++) {
        src.setPixelRgb(x, y, 255, 0, 0);
        src.setPixelRgb(x, height - 1 - y, 0, 0, 255);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(src));
}

int _pixel(int size, int x, int y) => (y * size + x) * 3;

bool _isGreen(Uint8List out, int i) =>
    out[i] < 40 && out[i + 1] > 200 && out[i + 2] < 40;

int _edgeMatchCount(
  Uint8List out,
  int size, {
  required bool left,
  required bool top,
  required int Function(Uint8List out, int i) score,
}) {
  var n = 0;
  if (left) {
    for (var y = 0; y < size; y++) {
      if (score(out, _pixel(size, 0, y)) > 0) n++;
    }
  }
  if (top) {
    for (var x = 0; x < size; x++) {
      if (score(out, _pixel(size, x, 0)) > 0) n++;
    }
  }
  return n;
}

void main() {
  group('ImagePreprocessor.decodeAndLetterbox', () {
    test('16:9 classify preprocess is center-crop, not letterbox pad 114', () {
      const size = 64;
      final out = ImagePreprocessor.decodeAndLetterbox(
        _pngBars(width: 320, height: 180),
        size: size,
      );
      expect(out.length, ImagePreprocessor.rgb24ByteLength(size, size));

      final cx = _pixel(size, size ~/ 2, size ~/ 2);
      expect(
        _isGreen(out, cx),
        isTrue,
        reason: 'center should stay green court',
      );

      final leftRed = _edgeMatchCount(
        out,
        size,
        left: true,
        top: false,
        score: (buf, i) => buf[i] > 200 && buf[i + 1] < 40 ? 1 : 0,
      );
      expect(
        leftRed,
        0,
        reason: 'left edge is red — letterbox kept the side bars',
      );

      var topSum = 0;
      for (var x = 0; x < size; x++) {
        final i = _pixel(size, x, 0);
        topSum += out[i] + out[i + 1] + out[i + 2];
      }
      final topMean = topSum / (size * 3);
      expect(
        (topMean - 114).abs(),
        greaterThan(20),
        reason: 'top row looks like letterbox pad 114',
      );
    });

    test('9:16 classify preprocess crops top/bottom bars, not sides', () {
      const size = 64;
      final out = ImagePreprocessor.decodeAndLetterbox(
        _pngBars(width: 180, height: 320),
        size: size,
      );
      expect(out.length, ImagePreprocessor.rgb24ByteLength(size, size));
      expect(
        _isGreen(out, _pixel(size, size ~/ 2, size ~/ 2)),
        isTrue,
        reason: 'center should stay green court',
      );

      final topRed = _edgeMatchCount(
        out,
        size,
        left: false,
        top: true,
        score: (buf, i) => buf[i] > 200 && buf[i + 1] < 40 ? 1 : 0,
      );
      expect(
        topRed,
        0,
        reason: 'top edge is red — letterbox kept the portrait bars',
      );
    });

    test('square source fills the crop without pad 114', () {
      const size = 64;
      final out = ImagePreprocessor.decodeAndLetterbox(
        _pngBars(width: 80, height: 80, bar: 8),
        size: size,
      );
      expect(out.length, ImagePreprocessor.rgb24ByteLength(size, size));
      expect(_isGreen(out, _pixel(size, size ~/ 2, size ~/ 2)), isTrue);

      var leftRed = 0;
      for (var y = 0; y < size; y++) {
        final i = _pixel(size, 0, y);
        if (out[i] > 200 && out[i + 1] < 40) leftRed++;
      }
      expect(
        leftRed,
        greaterThan(size ~/ 2),
        reason: 'side bars should remain',
      );
    });

    test('undecodable bytes throw ArgumentError', () {
      expect(
        () =>
            ImagePreprocessor.decodeAndLetterbox(Uint8List.fromList([0, 1, 2])),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ImagePreprocessor.ffmpegClassifyVf', () {
    test('covers then crops, does not pad', () {
      final vf = ImagePreprocessor.ffmpegClassifyVf(fps: 6);
      expect(vf, contains('fps=6'));
      expect(
        vf,
        contains('scale=640:640:force_original_aspect_ratio=increase'),
      );
      expect(vf, contains('crop=640:640'));
      expect(vf, isNot(contains('decrease')));
      expect(vf, isNot(contains('pad=')));
    });

    test('honors custom size', () {
      final vf = ImagePreprocessor.ffmpegClassifyVf(fps: 3, size: 224);
      expect(
        vf,
        contains('scale=224:224:force_original_aspect_ratio=increase'),
      );
      expect(vf, contains('crop=224:224'));
    });

    test('appends the transpose after crop for rotated sources', () {
      final vf = ImagePreprocessor.ffmpegClassifyVf(fps: 6, rotation: -90);
      expect(vf.endsWith(',transpose=1'), isTrue, reason: vf);
      // crop must come before the transpose: only the 640×640 output is
      // rotated, never the full-resolution frame (autorotate is disabled).
      expect(
        vf.indexOf('crop=640:640'),
        lessThan(vf.indexOf('transpose=1')),
      );
      expect(vf, isNot(contains('autorotate')));
    });

    test('no rotation filters for an unrotated source', () {
      final vf = ImagePreprocessor.ffmpegClassifyVf(fps: 6);
      expect(vf, isNot(contains('transpose')));
      expect(vf, isNot(contains('hflip')));
    });
  });

  group('ImagePreprocessor.ffmpegRotationFilters', () {
    test('maps ffprobe rotation to ffmpeg autorotate transposes', () {
      // ffprobe reports the display matrix angle; ffmpeg autorotate applies
      // the opposite angle (measured against the real DJI file: -90 →
      // transpose=1).
      expect(ImagePreprocessor.ffmpegRotationFilters(0), isEmpty);
      expect(ImagePreprocessor.ffmpegRotationFilters(-90), ['transpose=1']);
      expect(ImagePreprocessor.ffmpegRotationFilters(270), ['transpose=1']);
      expect(ImagePreprocessor.ffmpegRotationFilters(90), ['transpose=2']);
      expect(ImagePreprocessor.ffmpegRotationFilters(-270), ['transpose=2']);
      expect(
        ImagePreprocessor.ffmpegRotationFilters(180),
        ['hflip', 'vflip'],
      );
      expect(
        ImagePreprocessor.ffmpegRotationFilters(-180),
        ['hflip', 'vflip'],
      );
      // Near-square / unknown angles are treated as unrotated.
      expect(ImagePreprocessor.ffmpegRotationFilters(30), isEmpty);
      expect(ImagePreprocessor.ffmpegRotationFilters(360), isEmpty);
    });
  });

  group('VideoUtils classify extract', () {
    test('intervalExtractRawRgbFrames rejects non-square crop', () async {
      await expectLater(
        VideoUtils.intervalExtractRawRgbFrames(
          videoPath: 'missing.mp4',
          frameInterval: 1,
          tempDir: '/tmp',
          width: 640,
          height: 480,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('streamIntervalRawRgbFrames rejects non-square crop', () async {
      await expectLater(
        VideoUtils.streamIntervalRawRgbFrames(
          videoPath: 'missing.mp4',
          frameInterval: 1,
          width: 320,
          height: 240,
        ).first,
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
