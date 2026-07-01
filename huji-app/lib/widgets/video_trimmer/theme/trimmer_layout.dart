import 'package:flutter/material.dart';

/// Layout metrics for the video trimmer timeline.
///
/// Registered on [ThemeData] via [withTrimmerTheme]; widgets read through
/// [BuildContext.trimmerLayout]. [TrimmerLayoutMetrics.standard] is the single
/// source of truth for scroll/sync math in [TrimmerBloc].
@immutable
class TrimmerLayoutMetrics extends ThemeExtension<TrimmerLayoutMetrics> {
  const TrimmerLayoutMetrics({
    required this.thumbnailTileSize,
    required this.timeRulerHeight,
    required this.bottomSpanHeight,
    required this.leftWidgetWidth,
    required this.segmentBorderWidth,
    required this.segmentSelectedBorderWidth,
    required this.dividerHandleSize,
    required this.dividerHandleThickness,
    required this.dividerHandleBuffer,
    required this.playheadWidth,
    required this.scrollStripHeight,
    required this.thumbnailGenerateWidth,
  });

  /// Canonical timeline tile width/height in logical pixels.
  final double thumbnailTileSize;
  final double timeRulerHeight;
  final double bottomSpanHeight;
  final double leftWidgetWidth;
  final double segmentBorderWidth;
  final double segmentSelectedBorderWidth;
  final double dividerHandleSize;
  final double dividerHandleThickness;
  final double dividerHandleBuffer;
  final double playheadWidth;
  final double scrollStripHeight;

  /// FFmpeg thumbnail width; scaled with [thumbnailTileSize] for crisp tiles.
  final int thumbnailGenerateWidth;

  double get timelineContentHeight =>
      timeRulerHeight + thumbnailTileSize + bottomSpanHeight;

  static const standard = TrimmerLayoutMetrics(
    thumbnailTileSize: 72,
    timeRulerHeight: 48,
    bottomSpanHeight: 56,
    leftWidgetWidth: 220,
    segmentBorderWidth: 2,
    segmentSelectedBorderWidth: 3,
    dividerHandleSize: 52,
    dividerHandleThickness: 12,
    dividerHandleBuffer: 20,
    playheadWidth: 3,
    scrollStripHeight: 20,
    thumbnailGenerateWidth: 320,
  );

  @override
  TrimmerLayoutMetrics copyWith({
    double? thumbnailTileSize,
    double? timeRulerHeight,
    double? bottomSpanHeight,
    double? leftWidgetWidth,
    double? segmentBorderWidth,
    double? segmentSelectedBorderWidth,
    double? dividerHandleSize,
    double? dividerHandleThickness,
    double? dividerHandleBuffer,
    double? playheadWidth,
    double? scrollStripHeight,
    int? thumbnailGenerateWidth,
  }) {
    return TrimmerLayoutMetrics(
      thumbnailTileSize: thumbnailTileSize ?? this.thumbnailTileSize,
      timeRulerHeight: timeRulerHeight ?? this.timeRulerHeight,
      bottomSpanHeight: bottomSpanHeight ?? this.bottomSpanHeight,
      leftWidgetWidth: leftWidgetWidth ?? this.leftWidgetWidth,
      segmentBorderWidth: segmentBorderWidth ?? this.segmentBorderWidth,
      segmentSelectedBorderWidth:
          segmentSelectedBorderWidth ?? this.segmentSelectedBorderWidth,
      dividerHandleSize: dividerHandleSize ?? this.dividerHandleSize,
      dividerHandleThickness:
          dividerHandleThickness ?? this.dividerHandleThickness,
      dividerHandleBuffer: dividerHandleBuffer ?? this.dividerHandleBuffer,
      playheadWidth: playheadWidth ?? this.playheadWidth,
      scrollStripHeight: scrollStripHeight ?? this.scrollStripHeight,
      thumbnailGenerateWidth:
          thumbnailGenerateWidth ?? this.thumbnailGenerateWidth,
    );
  }

  @override
  TrimmerLayoutMetrics lerp(TrimmerLayoutMetrics? other, double t) {
    if (other is! TrimmerLayoutMetrics) return this;
    double l(double a, double b) => a + (b - a) * t;
    return TrimmerLayoutMetrics(
      thumbnailTileSize: l(thumbnailTileSize, other.thumbnailTileSize),
      timeRulerHeight: l(timeRulerHeight, other.timeRulerHeight),
      bottomSpanHeight: l(bottomSpanHeight, other.bottomSpanHeight),
      leftWidgetWidth: l(leftWidgetWidth, other.leftWidgetWidth),
      segmentBorderWidth: l(segmentBorderWidth, other.segmentBorderWidth),
      segmentSelectedBorderWidth: l(
        segmentSelectedBorderWidth,
        other.segmentSelectedBorderWidth,
      ),
      dividerHandleSize: l(dividerHandleSize, other.dividerHandleSize),
      dividerHandleThickness:
          l(dividerHandleThickness, other.dividerHandleThickness),
      dividerHandleBuffer: l(dividerHandleBuffer, other.dividerHandleBuffer),
      playheadWidth: l(playheadWidth, other.playheadWidth),
      scrollStripHeight: l(scrollStripHeight, other.scrollStripHeight),
      thumbnailGenerateWidth:
          (thumbnailGenerateWidth +
                  (other.thumbnailGenerateWidth - thumbnailGenerateWidth) * t)
              .round(),
    );
  }
}

extension TrimmerLayoutContext on BuildContext {
  TrimmerLayoutMetrics get trimmerLayout {
    final extension = Theme.of(this).extension<TrimmerLayoutMetrics>();
    return extension ?? TrimmerLayoutMetrics.standard;
  }
}
