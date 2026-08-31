import 'package:huji_app/models/autoclip_models.dart';

/// Resolves the active round index for the precision-edit sidebar.
///
/// Prefer [activeRoundIndex] because [activeSegment] value equality breaks after
/// the trimmer updates start/end times.
int resolvePrecisionEditRoundIndex({
  required List<SegmentInfo> segments,
  int? activeRoundIndex,
  SegmentInfo? activeSegment,
}) {
  if (segments.isEmpty) return -1;

  if (activeRoundIndex != null &&
      activeRoundIndex >= 0 &&
      activeRoundIndex < segments.length) {
    return activeRoundIndex;
  }

  if (activeSegment != null) {
    final index = segments.indexWhere((segment) => segment == activeSegment);
    if (index >= 0) return index;
  }

  return 0;
}

/// Moves [currentIndex] by [delta], clamped to [segmentCount].
int shiftPrecisionEditRoundIndex(
  int currentIndex,
  int delta,
  int segmentCount,
) {
  if (segmentCount <= 0) return -1;
  final base = currentIndex < 0 ? 0 : currentIndex;
  return (base + delta).clamp(0, segmentCount - 1);
}
