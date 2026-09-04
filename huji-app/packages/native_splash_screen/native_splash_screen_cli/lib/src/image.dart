import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:image/image.dart' as img;

import '../models/image.dart';

/// Main function to load an image with various options
Future<BGRAImage> loadImageAsBGRA(
  String path, {
  // Image sizing options
  int targetWidth = 0,
  int targetHeight = 0,
  bool resizeToFit = false,
  double blurRadius = 0,

  // Background options
  img.Color? backgroundColor,
  int backgroundWidth = 0,
  int backgroundHeight = 0,
  double imageBorderRadius = 0,
  double backgroundBorderRadius = 0,

  // Position options
  ImageAlignment alignment = ImageAlignment.center,

  // PLATFORM-SPECIFIC OVERRIDE
  // When true, guarantees the final image has the dimensions of targetWidth/Height,
  // creating a transparent canvas if no background color is provided.
  // This is essential for the macOS asset pipeline.
  bool ensureCanvasSize = false,
}) async {
  // Load and decode the image
  final img.Image decodedImage = await _decodeImageFromPath(path);

  // Process the image (resize, blur)
  final img.Image processedImage = _processImage(
    decodedImage,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    resizeToFit: resizeToFit,
    blurRadius: blurRadius,
    borderRadius: imageBorderRadius,
  );

  // Determine if a background composition is needed.
  final bool hasVisibleBackground =
      backgroundColor != null && backgroundColor.a != 0;

  // If the user specified a visible background, use it.
  if (hasVisibleBackground) {
    final composedImage = _composeWithBackground(
      processedImage,
      backgroundColor: backgroundColor,
      backgroundWidth:
          backgroundWidth > 0 ? backgroundWidth : processedImage.width,
      backgroundHeight:
          backgroundHeight > 0 ? backgroundHeight : processedImage.height,
      backgroundBorderRadius: backgroundBorderRadius,
      alignment: alignment,
    );
    return _convertToGBRA(composedImage);
  }
  // If macOS requires a canvas, create a transparent one and compose.
  else if (ensureCanvasSize && targetWidth > 0 && targetHeight > 0) {
    final composedImage = _composeWithBackground(
      processedImage,
      // Use a completely transparent background to force the canvas size.
      backgroundColor: img.ColorRgba8(0, 0, 0, 0),
      backgroundWidth: targetWidth,
      backgroundHeight: targetHeight,
      backgroundBorderRadius: backgroundBorderRadius, // Still respect rounding
      alignment: alignment,
    );
    return _convertToGBRA(composedImage);
  }

  // Otherwise return the processed image directly
  return _convertToGBRA(processedImage);
}

/// Decodes an image from a file path
Future<img.Image> _decodeImageFromPath(String path) async {
  final bytes = await File(path).readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception('Failed to decode image at $path');
  }

  return image;
}

/// Processes an image with the specified options
img.Image _processImage(
  img.Image image, {
  int targetWidth = 0,
  int targetHeight = 0,
  bool resizeToFit = false,
  double blurRadius = 0,
  double borderRadius = 0,
}) {
  img.Image result = image;

  // We resize under two conditions:
  // 1. The user explicitly allows it (resizeToFit = true).
  // 2. We are DOWN-scaling a larger image, which preserves quality.
  final bool shouldResize = (resizeToFit ||
          (image.width > targetWidth || image.height > targetHeight)) &&
      (targetWidth > 0 && targetHeight > 0);

  if (shouldResize) {
    result = img.copyResize(
      result,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );
  }

  // Apply blur if requested
  if (blurRadius > 0) {
    result = img.gaussianBlur(result, radius: blurRadius.round());
  }

  // Apply border radius if requested
  if (borderRadius > 0) {
    result = _applyBorderRadius(result, borderRadius);
  }

  return result;
}

/// Applies border radius to an image
img.Image _applyBorderRadius(img.Image image, double radius) {
  if (radius <= 0) return image;

  final width = image.width;
  final height = image.height;
  final result = img.Image(width: width, height: height, numChannels: 4);

  // Initialize all pixels as transparent
  img.fill(result, color: img.ColorRgba8(0, 0, 0, 0));

  // Create a mask with rounded corners
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);

      // Check if pixel is inside the rounded rectangle
      if (_isInsideRoundedRect(x, y, width, height, radius)) {
        result.setPixel(x, y, pixel);
      } else {
        // Set transparent pixel
        result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
      }
    }
  }

  return result;
}

/// Helper to check if a point is inside a rounded rectangle
bool _isInsideRoundedRect(int x, int y, int width, int height, double radius) {
  // Handle corner regions
  if (x < radius && y < radius) {
    // Top-left corner
    return _isInsideCircle(x, y, radius.toInt(), radius.toInt(), radius);
  } else if (x >= width - radius && y < radius) {
    // Top-right corner
    return _isInsideCircle(
      x,
      y,
      (width - radius).toInt(),
      radius.toInt(),
      radius,
    );
  } else if (x < radius && y >= height - radius) {
    // Bottom-left corner
    return _isInsideCircle(
      x,
      y,
      radius.toInt(),
      (height - radius).toInt(),
      radius,
    );
  } else if (x >= width - radius && y >= height - radius) {
    // Bottom-right corner
    return _isInsideCircle(
      x,
      y,
      (width - radius).toInt(),
      (height - radius).toInt(),
      radius,
    );
  }

  // Non-corner regions
  return x >= 0 && x < width && y >= 0 && y < height;
}

/// Helper to check if a point is inside a circle with given center and radius
bool _isInsideCircle(int x, int y, int centerX, int centerY, double radius) {
  final dx = x - centerX;
  final dy = y - centerY;
  return dx * dx + dy * dy <= radius * radius;
}

/// Composes an image with a background
img.Image _composeWithBackground(
  img.Image foreground, {
  required img.Color backgroundColor,
  required int backgroundWidth,
  required int backgroundHeight,
  double backgroundBorderRadius = 0,
  ImageAlignment alignment = ImageAlignment.center,
}) {
  // Create a new image with the background color
  final background = img.Image(
    width: backgroundWidth,
    height: backgroundHeight,
    numChannels: 4,
  );

  // Fill with background color
  img.fill(background, color: backgroundColor);

  // Apply border radius to background if needed
  img.Image finalBackground = backgroundBorderRadius > 0
      ? _applyBorderRadius(background, backgroundBorderRadius)
      : background;

  // Calculate position for foreground image based on alignment
  final Position position = _calculatePosition(
    foreground.width,
    foreground.height,
    backgroundWidth,
    backgroundHeight,
    alignment,
  );

  // Compose the images
  img.compositeImage(
    finalBackground,
    foreground,
    dstX: position.x,
    dstY: position.y,
    blend: img.BlendMode.alpha,
  );

  return finalBackground;
}

/// Calculate position based on alignment
Position _calculatePosition(
  int fgWidth,
  int fgHeight,
  int bgWidth,
  int bgHeight,
  ImageAlignment alignment,
) {
  int x = 0;
  int y = 0;

  switch (alignment) {
    case ImageAlignment.topLeft:
      x = 0;
      y = 0;
      break;
    case ImageAlignment.topCenter:
      x = (bgWidth - fgWidth) ~/ 2;
      y = 0;
      break;
    case ImageAlignment.topRight:
      x = bgWidth - fgWidth;
      y = 0;
      break;
    case ImageAlignment.centerLeft:
      x = 0;
      y = (bgHeight - fgHeight) ~/ 2;
      break;
    case ImageAlignment.center:
      x = (bgWidth - fgWidth) ~/ 2;
      y = (bgHeight - fgHeight) ~/ 2;
      break;
    case ImageAlignment.centerRight:
      x = bgWidth - fgWidth;
      y = (bgHeight - fgHeight) ~/ 2;
      break;
    case ImageAlignment.bottomLeft:
      x = 0;
      y = bgHeight - fgHeight;
      break;
    case ImageAlignment.bottomCenter:
      x = (bgWidth - fgWidth) ~/ 2;
      y = bgHeight - fgHeight;
      break;
    case ImageAlignment.bottomRight:
      x = bgWidth - fgWidth;
      y = bgHeight - fgHeight;
      break;
  }

  return Position(x, y);
}

/// Converts an image to BGRA format
BGRAImage _convertToGBRA(img.Image image) {
  final width = image.width;
  final height = image.height;
  final output = Uint8List(width * height * 4);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      final offset = (y * width + x) * 4;
      output[offset + 0] = pixel.b.toInt(); // B
      output[offset + 1] = pixel.g.toInt(); // G
      output[offset + 2] = pixel.r.toInt(); // R
      output[offset + 3] = pixel.a.toInt(); // A
    }
  }

  return BGRAImage(data: output, width: width, height: height, original: image);
}
