import 'package:flutter/material.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/theme/app_typography_scale.dart';

/// Layout metrics for the video trimmer timeline.
///
/// Registered on [ThemeData] via [withTrimmerTheme]; widgets read through
/// [BuildContext.trimmerLayout]. [TrimmerLayoutMetrics.resolve] is the single
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
    required this.rulerLabelFontSize,
    required this.microLabelFontSize,
    required this.segmentLabelFontSize,
    required this.muteIconSize,
    required this.toolbarHeight,
    required this.segmentOverviewHeight,
    required this.segmentChipFooterHeight,
    required this.segmentChipMinWidth,
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

  final double rulerLabelFontSize;
  final double microLabelFontSize;
  final double segmentLabelFontSize;
  final double muteIconSize;
  final double toolbarHeight;
  final double segmentOverviewHeight;
  final double segmentChipFooterHeight;
  final double segmentChipMinWidth;

  double get timelineContentHeight =>
      timeRulerHeight + thumbnailTileSize + bottomSpanHeight;

  /// Mobile metrics follow restcut_app's original timeline sizing
  /// (tile 44 / ruler 40 / span 44 / handle 30x8), restored after the
  /// centralizing refactor had inflated them.
  static const standard = TrimmerLayoutMetrics(
    thumbnailTileSize: 44,
    timeRulerHeight: 40,
    bottomSpanHeight: 44,
    leftWidgetWidth: 190,
    segmentBorderWidth: 2,
    segmentSelectedBorderWidth: 3,
    dividerHandleSize: 30,
    dividerHandleThickness: 8,
    dividerHandleBuffer: 12,
    playheadWidth: 3,
    scrollStripHeight: 18,
    thumbnailGenerateWidth: 320,
    rulerLabelFontSize: 10,
    microLabelFontSize: 8,
    segmentLabelFontSize: 11,
    muteIconSize: 18,
    toolbarHeight: 56,
    segmentOverviewHeight: 60,
    segmentChipFooterHeight: 20,
    segmentChipMinWidth: 60,
  );

  static const desktop = TrimmerLayoutMetrics(
    thumbnailTileSize: 88,
    timeRulerHeight: 56,
    bottomSpanHeight: 68,
    leftWidgetWidth: 268,
    segmentBorderWidth: 2,
    segmentSelectedBorderWidth: 3,
    dividerHandleSize: 60,
    dividerHandleThickness: 14,
    dividerHandleBuffer: 22,
    playheadWidth: 3,
    scrollStripHeight: 24,
    thumbnailGenerateWidth: 384,
    rulerLabelFontSize: 12,
    microLabelFontSize: 11,
    segmentLabelFontSize: 13,
    muteIconSize: 22,
    toolbarHeight: 64,
    segmentOverviewHeight: 72,
    segmentChipFooterHeight: 24,
    segmentChipMinWidth: 72,
  );

  /// Picks mobile vs desktop structural metrics, then scales typography tokens
  /// from [AppTypographyTheme] so timeline text tracks appearance settings.
  static TrimmerLayoutMetrics resolve({AppTypographyTheme? typography}) {
    final base = PlatformCapability.isDesktop ? desktop : standard;
    final type =
        typography ?? AppTypographyTheme.fromScale(AppTypographyScale.standard);
    final textRatio = type.labelSmall / AppTypographyScale.standard.labelSmall;
    return base.copyWith(
      rulerLabelFontSize: base.rulerLabelFontSize * textRatio,
      microLabelFontSize: base.microLabelFontSize * textRatio,
      segmentLabelFontSize: base.segmentLabelFontSize * textRatio,
      muteIconSize: base.muteIconSize * textRatio,
    );
  }

  /// Structural + typography layout for the current platform (no theme context).
  static TrimmerLayoutMetrics forPlatform() => resolve();

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
    double? rulerLabelFontSize,
    double? microLabelFontSize,
    double? segmentLabelFontSize,
    double? muteIconSize,
    double? toolbarHeight,
    double? segmentOverviewHeight,
    double? segmentChipFooterHeight,
    double? segmentChipMinWidth,
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
      rulerLabelFontSize: rulerLabelFontSize ?? this.rulerLabelFontSize,
      microLabelFontSize: microLabelFontSize ?? this.microLabelFontSize,
      segmentLabelFontSize:
          segmentLabelFontSize ?? this.segmentLabelFontSize,
      muteIconSize: muteIconSize ?? this.muteIconSize,
      toolbarHeight: toolbarHeight ?? this.toolbarHeight,
      segmentOverviewHeight:
          segmentOverviewHeight ?? this.segmentOverviewHeight,
      segmentChipFooterHeight:
          segmentChipFooterHeight ?? this.segmentChipFooterHeight,
      segmentChipMinWidth: segmentChipMinWidth ?? this.segmentChipMinWidth,
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
      rulerLabelFontSize: l(rulerLabelFontSize, other.rulerLabelFontSize),
      microLabelFontSize: l(microLabelFontSize, other.microLabelFontSize),
      segmentLabelFontSize:
          l(segmentLabelFontSize, other.segmentLabelFontSize),
      muteIconSize: l(muteIconSize, other.muteIconSize),
      toolbarHeight: l(toolbarHeight, other.toolbarHeight),
      segmentOverviewHeight:
          l(segmentOverviewHeight, other.segmentOverviewHeight),
      segmentChipFooterHeight:
          l(segmentChipFooterHeight, other.segmentChipFooterHeight),
      segmentChipMinWidth: l(segmentChipMinWidth, other.segmentChipMinWidth),
    );
  }
}

extension TrimmerLayoutContext on BuildContext {
  TrimmerLayoutMetrics get trimmerLayout {
    final extension = Theme.of(this).extension<TrimmerLayoutMetrics>();
    return extension ?? TrimmerLayoutMetrics.forPlatform();
  }
}
