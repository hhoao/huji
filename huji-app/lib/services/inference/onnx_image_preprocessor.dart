import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// PNG decode + YOLO letterbox + /255 CHW tensor for ONNX classify models.
class OnnxImagePreprocessor {
  OnnxImagePreprocessor._();

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

  /// /255 查找表：把逐像素的 int→double 除法换成一次数组读，
  /// 对 640×640 帧能省掉 ~120 万次除法。
  static final Float32List _inv255Lut = Float32List.fromList(
    List.generate(256, (v) => v / 255.0),
  );

  /// Convert letterboxed RGB24 (HWC) to CHW float32 tensor with /255 scaling.
  ///
  /// 传入 [output] 可跨调用复用缓冲区（模型输入固定尺寸时避免每帧
  /// 分配 4.9MB 的 Float32List 造成 GC 抖动）；[OrtValue.fromList] 会
  /// 把数据拷贝进原生内存，复用是安全的。
  static Float32List toTensor(
    Uint8List rgb,
    int width,
    int height, [
    Float32List? output,
  ]) {
    final spatialSize = width * height;
    final expectedLen = 3 * spatialSize;
    if (rgb.length < expectedLen) {
      throw ArgumentError(
        'RGB buffer length ${rgb.length} is too small for ${width}x$height',
      );
    }

    final tensor = output ?? Float32List(expectedLen);
    if (tensor.length < expectedLen) {
      throw ArgumentError(
        'Output buffer length ${tensor.length} is too small for '
        '${width}x$height',
      );
    }

    final lut = _inv255Lut;
    // 逐平面写入（CHW）：每个平面一趟紧密循环，比单循环内三分支更缓存友好
    final plane1 = spatialSize;
    final plane2 = 2 * spatialSize;
    for (var i = 0; i < spatialSize; i++) {
      tensor[i] = lut[rgb[i * 3]];
    }
    for (var i = 0; i < spatialSize; i++) {
      tensor[plane1 + i] = lut[rgb[i * 3 + 1]];
    }
    for (var i = 0; i < spatialSize; i++) {
      tensor[plane2 + i] = lut[rgb[i * 3 + 2]];
    }
    return tensor;
  }
}
