import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// PNG/JPEG decode + YOLO classify preprocess for ncnn models.
///
/// Matches ultralytics classify / torchvision:
/// Resize(short side = size, long side int-truncated, bilinear) →
/// CenterCrop(size). Normalization (/255) happens natively inside the ncnn
/// shim (`Mat::substract_mean_normalize`), so the engine consumes RGB24
/// bytes directly.
class ImagePreprocessor {
  ImagePreprocessor._();

  static const inputSize = 640;

  /// Expected byte length of a classified RGB24 frame.
  static int rgb24ByteLength(int width, int height) => width * height * 3;

  /// FFmpeg vf that covers then center-crops to [size]×[size] (no pad 114).
  ///
  /// `force_original_aspect_ratio=increase` is the same geometry as
  /// ultralytics Resize(short side = size); default `crop` is centered.
  ///
  /// [rotation] is ffprobe's `side_data_list.rotation` in degrees. When set,
  /// the matching transpose runs *after* the crop instead of relying on
  /// ffmpeg's autorotate (which transposes every decoded frame at source
  /// resolution — ~2.8× slower on a 4K 10-bit stream, identical pixels for a
  /// centered square crop). Callers must pass `-noautorotate` when they pass
  /// a non-zero [rotation].
  static String ffmpegClassifyVf({
    required num fps,
    int size = inputSize,
    double rotation = 0,
  }) {
    final filters = <String>[
      'fps=$fps',
      'scale=$size:$size:force_original_aspect_ratio=increase:flags=bilinear',
      'crop=$size:$size',
      ...ffmpegRotationFilters(rotation),
    ];
    return filters.join(',');
  }

  /// Transpose filters reproducing ffmpeg's autorotate for [rotation].
  ///
  /// ffprobe reports the display-matrix rotation; ffmpeg's autorotate applies
  /// the opposite angle (`theta = -rotation`) with the same mapping as
  /// `ffmpeg_filter.c` (`90 → transpose=clock`, `180 → hflip+vflip`,
  /// `270 → transpose=cclock`).
  static List<String> ffmpegRotationFilters(double rotation) {
    final theta = ((-rotation) % 360 + 360) % 360;
    if (theta >= 45 && theta < 135) return const ['transpose=1'];
    if (theta >= 135 && theta < 225) return const ['hflip', 'vflip'];
    if (theta >= 225 && theta < 315) return const ['transpose=2'];
    return const [];
  }

  /// Decode PNG/JPEG bytes, classify-crop to [size]×[size], return RGB HWC bytes.
  static Uint8List decodeAndLetterbox(
    Uint8List imageBytes, {
    int size = inputSize,
  }) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError(
        'Unable to decode image (${imageBytes.length} bytes)',
      );
    }

    final rgb = _ensureRgb(decoded);
    final w = rgb.width;
    final h = rgb.height;
    late final int newW;
    late final int newH;
    if (w < h) {
      newW = size;
      newH = (size * h / w).toInt().clamp(1, 1 << 20);
    } else {
      newW = (size * w / h).toInt().clamp(1, 1 << 20);
      newH = size;
    }

    final resized = img.copyResize(
      rgb,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );
    final cropped = img.copyCrop(
      resized,
      x: (newW - size) ~/ 2,
      y: (newH - size) ~/ 2,
      width: size,
      height: size,
    );

    return cropped.getBytes(order: img.ChannelOrder.rgb);
  }

  static img.Image _ensureRgb(img.Image src) {
    if (src.numChannels == 3) return src;

    final out = img.Image(width: src.width, height: src.height, numChannels: 3);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        out.setPixelRgb(x, y, pixel.r, pixel.g, pixel.b);
      }
    }
    return out;
  }
}
