import 'dart:typed_data';

/// Preprocesses raw RGB24 frames for YOLO classification ONNX models.
///
/// Input: raw RGB bytes (HWC layout), already resized to model input size via ffmpeg.
/// Output: Float32List in CHW layout (channels first) with ImageNet normalization.
///
/// The batch dimension (N=1) is added by [OnnxInferenceEngine] via tensor shape.
class ImagePreprocessor {
  // ImageNet normalization constants used by ultralytics YOLO classification
  static const _meanR = 0.485;
  static const _meanG = 0.456;
  static const _meanB = 0.406;
  static const _stdR = 0.229;
  static const _stdG = 0.224;
  static const _stdB = 0.225;

  /// Converts raw RGB24 bytes (HWC) to CHW float32 tensor with normalization.
  ///
  /// [rgb] is raw RGB bytes, 3 bytes per pixel, row-major (HWC).
  /// [width] and [height] are the frame dimensions.
  /// Returns Float32List of length [3 * height * width] in CHW order.
  static Float32List preprocess(Uint8List rgb, int width, int height) {
    final expectedLen = 3 * height * width;
    if (rgb.length < expectedLen) {
      throw ArgumentError(
        'RGB buffer length ${rgb.length} is too small for '
        '$width'
            'x$height'
            ' (need at least $expectedLen bytes)',
      );
    }
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Invalid dimensions: $width'
            'x$height');
    }
    final spatialSize = height * width;
    final totalSize = 3 * spatialSize;
    final tensor = Float32List(totalSize);

    final rPlaneOffset = 0;
    final gPlaneOffset = spatialSize;
    final bPlaneOffset = 2 * spatialSize;

    for (var h = 0; h < height; h++) {
      for (var w = 0; w < width; w++) {
        final srcIdx = (h * width + w) * 3;
        final dstIdx = h * width + w;

        final r = rgb[srcIdx] / 255.0;
        final g = rgb[srcIdx + 1] / 255.0;
        final b = rgb[srcIdx + 2] / 255.0;

        tensor[rPlaneOffset + dstIdx] = (r - _meanR) / _stdR;
        tensor[gPlaneOffset + dstIdx] = (g - _meanG) / _stdG;
        tensor[bPlaneOffset + dstIdx] = (b - _meanB) / _stdB;
      }
    }

    return tensor;
  }
}
