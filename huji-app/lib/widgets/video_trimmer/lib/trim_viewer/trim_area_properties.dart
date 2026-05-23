import 'package:flutter/material.dart';

class TrimAreaProperties {
  final BoxFit thumbnailFit;

  final int thumbnailQuality;

  final bool blurEdges;

  final double borderRadius;

  const TrimAreaProperties({
    this.thumbnailFit = BoxFit.fitHeight,
    this.thumbnailQuality = 2,
    this.blurEdges = false,
    this.borderRadius = 4.0,
  });
}
