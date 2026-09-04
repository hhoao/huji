import 'dart:typed_data' show Uint8List;

import 'package:image/image.dart' as img;

/// A wrapper for an BGRA image with metadata.
class BGRAImage {
  final Uint8List data;
  final int width;
  final int height;
  final img.Image original;

  BGRAImage({
    required this.data,
    required this.width,
    required this.height,
    required this.original,
  });
}

/// Position class for placement calculations
class Position {
  final int x;
  final int y;

  Position(this.x, this.y);
}

/// Enum for image alignment options
enum ImageAlignment {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}
