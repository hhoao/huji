import 'package:flutter/material.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_layout.dart';

/// Semantic color tokens for the video trimmer UI.
///
/// Registered on [ThemeData] via [withTrimmerTheme]; widgets read it through
/// [BuildContext.trimmerTheme].
@immutable
class TrimmerThemeData extends ThemeExtension<TrimmerThemeData> {
  const TrimmerThemeData({
    required this.scaffoldBackground,
    required this.previewBackground,
    required this.toolbarBackground,
    required this.timelineBackground,
    required this.timelineBottomSpan,
    required this.segmentBorder,
    required this.segmentSelectedBorder,
    required this.segmentChipBackground,
    required this.segmentChipSelectedBackground,
    required this.segmentSelectedOverlay,
    required this.segmentUnselectedOverlay,
    required this.playheadColor,
    required this.rulerTickColor,
    required this.rulerLabelColor,
    required this.handleBackground,
    required this.handleForeground,
    required this.playOverlayBackground,
    required this.onToolbar,
    required this.onToolbarMuted,
    required this.disabled,
    required this.active,
    required this.onActive,
    required this.popupSurface,
    required this.placeholderBackground,
    required this.placeholderIcon,
    required this.coverOverlay,
    required this.coverBorder,
    required this.favorite,
    required this.sliderActiveTrack,
    required this.sliderInactiveTrack,
    required this.sliderThumb,
    required this.sliderOverlay,
  });

  final Color scaffoldBackground;
  final Color previewBackground;
  final Color toolbarBackground;
  final Color timelineBackground;
  final Color timelineBottomSpan;
  final Color segmentBorder;
  final Color segmentSelectedBorder;
  final Color segmentChipBackground;
  final Color segmentChipSelectedBackground;
  final Color segmentSelectedOverlay;
  final Color segmentUnselectedOverlay;
  final Color playheadColor;
  final Color rulerTickColor;
  final Color rulerLabelColor;
  final Color handleBackground;
  final Color handleForeground;
  final Color playOverlayBackground;
  final Color onToolbar;
  final Color onToolbarMuted;
  final Color disabled;
  final Color active;
  final Color onActive;
  final Color popupSurface;
  final Color placeholderBackground;
  final Color placeholderIcon;
  final Color coverOverlay;
  final Color coverBorder;
  final Color favorite;
  final Color sliderActiveTrack;
  final Color sliderInactiveTrack;
  final Color sliderThumb;
  final Color sliderOverlay;

  factory TrimmerThemeData.from(ColorScheme scheme) {
    return TrimmerThemeData(
      scaffoldBackground: scheme.surface,
      previewBackground: scheme.surfaceContainerLow,
      toolbarBackground: scheme.surfaceContainer,
      timelineBackground: scheme.surfaceContainerHigh,
      timelineBottomSpan: scheme.outlineVariant.withValues(alpha: 0.18),
      segmentBorder: scheme.outline,
      segmentSelectedBorder: scheme.primary,
      segmentChipBackground: scheme.surfaceContainerHighest,
      segmentChipSelectedBackground: scheme.primary,
      segmentSelectedOverlay: scheme.primary.withValues(alpha: 0.28),
      segmentUnselectedOverlay: scheme.scrim.withValues(alpha: 0.12),
      playheadColor: scheme.primary,
      rulerTickColor: scheme.outline,
      rulerLabelColor: scheme.onSurface,
      handleBackground: scheme.primary,
      handleForeground: scheme.onPrimary,
      playOverlayBackground: scheme.scrim.withValues(alpha: 0.45),
      onToolbar: scheme.onSurface,
      onToolbarMuted: scheme.onSurfaceVariant,
      disabled: scheme.onSurface.withValues(alpha: 0.38),
      active: scheme.primary,
      onActive: scheme.onPrimary,
      popupSurface: scheme.surfaceContainerHigh,
      placeholderBackground: scheme.surfaceContainerHighest,
      placeholderIcon: scheme.onSurfaceVariant,
      coverOverlay: scheme.scrim.withValues(alpha: 0.32),
      coverBorder: scheme.outline,
      favorite: scheme.tertiary,
      sliderActiveTrack: scheme.primary,
      sliderInactiveTrack: scheme.outlineVariant,
      sliderThumb: scheme.primary,
      sliderOverlay: scheme.primary.withValues(alpha: 0.16),
    );
  }

  @override
  TrimmerThemeData copyWith({
    Color? scaffoldBackground,
    Color? previewBackground,
    Color? toolbarBackground,
    Color? timelineBackground,
    Color? timelineBottomSpan,
    Color? segmentBorder,
    Color? segmentSelectedBorder,
    Color? segmentChipBackground,
    Color? segmentChipSelectedBackground,
    Color? segmentSelectedOverlay,
    Color? segmentUnselectedOverlay,
    Color? playheadColor,
    Color? rulerTickColor,
    Color? rulerLabelColor,
    Color? handleBackground,
    Color? handleForeground,
    Color? playOverlayBackground,
    Color? onToolbar,
    Color? onToolbarMuted,
    Color? disabled,
    Color? active,
    Color? onActive,
    Color? popupSurface,
    Color? placeholderBackground,
    Color? placeholderIcon,
    Color? coverOverlay,
    Color? coverBorder,
    Color? favorite,
    Color? sliderActiveTrack,
    Color? sliderInactiveTrack,
    Color? sliderThumb,
    Color? sliderOverlay,
  }) {
    return TrimmerThemeData(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      previewBackground: previewBackground ?? this.previewBackground,
      toolbarBackground: toolbarBackground ?? this.toolbarBackground,
      timelineBackground: timelineBackground ?? this.timelineBackground,
      timelineBottomSpan: timelineBottomSpan ?? this.timelineBottomSpan,
      segmentBorder: segmentBorder ?? this.segmentBorder,
      segmentSelectedBorder:
          segmentSelectedBorder ?? this.segmentSelectedBorder,
      segmentChipBackground:
          segmentChipBackground ?? this.segmentChipBackground,
      segmentChipSelectedBackground: segmentChipSelectedBackground ??
          this.segmentChipSelectedBackground,
      segmentSelectedOverlay:
          segmentSelectedOverlay ?? this.segmentSelectedOverlay,
      segmentUnselectedOverlay:
          segmentUnselectedOverlay ?? this.segmentUnselectedOverlay,
      playheadColor: playheadColor ?? this.playheadColor,
      rulerTickColor: rulerTickColor ?? this.rulerTickColor,
      rulerLabelColor: rulerLabelColor ?? this.rulerLabelColor,
      handleBackground: handleBackground ?? this.handleBackground,
      handleForeground: handleForeground ?? this.handleForeground,
      playOverlayBackground:
          playOverlayBackground ?? this.playOverlayBackground,
      onToolbar: onToolbar ?? this.onToolbar,
      onToolbarMuted: onToolbarMuted ?? this.onToolbarMuted,
      disabled: disabled ?? this.disabled,
      active: active ?? this.active,
      onActive: onActive ?? this.onActive,
      popupSurface: popupSurface ?? this.popupSurface,
      placeholderBackground:
          placeholderBackground ?? this.placeholderBackground,
      placeholderIcon: placeholderIcon ?? this.placeholderIcon,
      coverOverlay: coverOverlay ?? this.coverOverlay,
      coverBorder: coverBorder ?? this.coverBorder,
      favorite: favorite ?? this.favorite,
      sliderActiveTrack: sliderActiveTrack ?? this.sliderActiveTrack,
      sliderInactiveTrack: sliderInactiveTrack ?? this.sliderInactiveTrack,
      sliderThumb: sliderThumb ?? this.sliderThumb,
      sliderOverlay: sliderOverlay ?? this.sliderOverlay,
    );
  }

  @override
  TrimmerThemeData lerp(TrimmerThemeData? other, double t) {
    if (other is! TrimmerThemeData) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TrimmerThemeData(
      scaffoldBackground: l(scaffoldBackground, other.scaffoldBackground),
      previewBackground: l(previewBackground, other.previewBackground),
      toolbarBackground: l(toolbarBackground, other.toolbarBackground),
      timelineBackground: l(timelineBackground, other.timelineBackground),
      timelineBottomSpan: l(timelineBottomSpan, other.timelineBottomSpan),
      segmentBorder: l(segmentBorder, other.segmentBorder),
      segmentSelectedBorder:
          l(segmentSelectedBorder, other.segmentSelectedBorder),
      segmentChipBackground:
          l(segmentChipBackground, other.segmentChipBackground),
      segmentChipSelectedBackground: l(
        segmentChipSelectedBackground,
        other.segmentChipSelectedBackground,
      ),
      segmentSelectedOverlay:
          l(segmentSelectedOverlay, other.segmentSelectedOverlay),
      segmentUnselectedOverlay:
          l(segmentUnselectedOverlay, other.segmentUnselectedOverlay),
      playheadColor: l(playheadColor, other.playheadColor),
      rulerTickColor: l(rulerTickColor, other.rulerTickColor),
      rulerLabelColor: l(rulerLabelColor, other.rulerLabelColor),
      handleBackground: l(handleBackground, other.handleBackground),
      handleForeground: l(handleForeground, other.handleForeground),
      playOverlayBackground:
          l(playOverlayBackground, other.playOverlayBackground),
      onToolbar: l(onToolbar, other.onToolbar),
      onToolbarMuted: l(onToolbarMuted, other.onToolbarMuted),
      disabled: l(disabled, other.disabled),
      active: l(active, other.active),
      onActive: l(onActive, other.onActive),
      popupSurface: l(popupSurface, other.popupSurface),
      placeholderBackground:
          l(placeholderBackground, other.placeholderBackground),
      placeholderIcon: l(placeholderIcon, other.placeholderIcon),
      coverOverlay: l(coverOverlay, other.coverOverlay),
      coverBorder: l(coverBorder, other.coverBorder),
      favorite: l(favorite, other.favorite),
      sliderActiveTrack: l(sliderActiveTrack, other.sliderActiveTrack),
      sliderInactiveTrack: l(sliderInactiveTrack, other.sliderInactiveTrack),
      sliderThumb: l(sliderThumb, other.sliderThumb),
      sliderOverlay: l(sliderOverlay, other.sliderOverlay),
    );
  }
}

/// Attaches [TrimmerThemeData] derived from [ThemeData.colorScheme].
ThemeData withTrimmerTheme(ThemeData theme) {
  final trimmer = TrimmerThemeData.from(theme.colorScheme);
  final layout = TrimmerLayoutMetrics.standard;
  final extensions = theme.extensions.values
      .where(
        (extension) =>
            extension is! TrimmerThemeData &&
            extension is! TrimmerLayoutMetrics,
      )
      .followedBy([trimmer, layout]);
  return theme.copyWith(extensions: extensions);
}

extension TrimmerThemeContext on BuildContext {
  TrimmerThemeData get trimmerTheme {
    final extension = Theme.of(this).extension<TrimmerThemeData>();
    if (extension != null) return extension;
    return TrimmerThemeData.from(Theme.of(this).colorScheme);
  }

  ColorScheme get trimmerColorScheme => Theme.of(this).colorScheme;
}
