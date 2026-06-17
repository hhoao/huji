import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// PNG decode + YOLO letterbox + /255 CHW tensor for ONNX classify models.
class OnnxImagePreprocessor {
  OnnxImagePreprocessor._();

  static const inputSize = 640;
  /// ffmpeg `pad` default fill — matches [local_inference.py] preprocessing.
  /// Ultralytics YOLO classify uses 114 for letterbox padding.
  static const padValue = 114;

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

  /// Convert letterboxed RGB24 (HWC) to CHW float32 tensor with /255 scaling.
  static Float32List toTensor(Uint8List rgb, int width, int height) {
    final spatialSize = width * height;
    final expectedLen = 3 * spatialSize;
    if (rgb.length < expectedLen) {
      throw ArgumentError(
        'RGB buffer length ${rgb.length} is too small for ${width}x$height',
      );
    }

    final tensor = Float32List(expectedLen);
    for (var i = 0; i < spatialSize; i++) {
      tensor[i] = rgb[i * 3] / 255.0;
      tensor[spatialSize + i] = rgb[i * 3 + 1] / 255.0;
      tensor[2 * spatialSize + i] = rgb[i * 3 + 2] / 255.0;
    }
    return tensor;
  }
}
