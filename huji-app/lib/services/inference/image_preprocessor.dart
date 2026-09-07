import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// PNG decode + YOLO letterbox for ncnn classify models.
///
/// Normalization (/255) happens natively inside the ncnn shim
/// (`Mat::substract_mean_normalize`), so no Dart-side tensor conversion
/// is needed — the engine consumes RGB24 bytes directly.
class ImagePreprocessor {
  ImagePreprocessor._();

  static const inputSize = 640;
  /// Ultralytics YOLO classify letterbox pad (also used by ffmpeg RGB extract).
  static const padValue = 114;

  /// Expected byte length of a letterboxed RGB24 frame.
  static int rgb24ByteLength(int width, int height) => width * height * 3;

  /// Hex color string for ffmpeg `pad=...:color=` (RRGGBB).
  static String get padColorHex {
    final v = padValue.toRadixString(16).padLeft(2, '0');
    return '0x$v$v$v';
  }

  /// Decode PNG/JPEG bytes, letterbox to [size]×[size], return RGB HWC bytes.
  static Uint8List decodeAndLetterbox(Uint8List imageBytes, {int size = inputSize}) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Unable to decode image (${imageBytes.length} bytes)');
    }

    final rgb = _ensureRgb(decoded);

    final scale = math.min(size / rgb.width, size / rgb.height);
    final newW = (rgb.width * scale).round().clamp(1, size);
    final newH = (rgb.height * scale).round().clamp(1, size);
    final resized = img.copyResize(
      rgb,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.cubic,
    );

    final canvas = img.Image(width: size, height: size);
    img.fill(canvas, color: img.ColorRgb8(padValue, padValue, padValue));
    img.compositeImage(
      canvas,
      resized,
      dstX: (size - newW) ~/ 2,
      dstY: (size - newH) ~/ 2,
    );

    return canvas.getBytes(order: img.ChannelOrder.rgb);
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
