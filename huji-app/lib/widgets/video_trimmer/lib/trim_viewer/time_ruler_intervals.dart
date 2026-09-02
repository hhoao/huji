/// Adaptive time-ruler tick/label intervals for the trimmer timeline.
class TimeRulerIntervals {
  const TimeRulerIntervals({
    required this.shortInterval,
    required this.longInterval,
    required this.textInterval,
  });

  /// Seconds between minor tick marks.
  final double shortInterval;

  /// Seconds between major tick marks (aligned with labels).
  final double longInterval;

  /// Number of [shortInterval] steps between time labels.
  final int textInterval;

  /// Seconds between consecutive time labels.
  double get labelInterval => shortInterval * textInterval;
}

const _minLabelPx = 48.0;
const _minTickPx = 8.0;

/// Candidate label spacings (seconds), from fine to coarse.
const _labelCandidates = <double>[
  0.2,
  0.5,
  1,
  2,
  5,
  10,
  15,
  30,
  60,
  120,
  300,
  600,
];

/// Preferred number of minor ticks per label interval (tried in order).
const _tickDivisions = <int>[5, 4, 2, 10, 1];

/// Picks readable tick/label spacing for the current [pixelsPerSecond].
///
/// Labels stay at least ~48px apart; minor ticks at least ~8px apart.
TimeRulerIntervals resolveTimeRulerIntervals(double pixelsPerSecond) {
  final pps = pixelsPerSecond.isFinite && pixelsPerSecond > 0
      ? pixelsPerSecond
      : 1.0;

  final labelSeconds = _labelCandidates.firstWhere(
    (seconds) => seconds * pps >= _minLabelPx,
    orElse: () => _labelCandidates.last,
  );

  var shortSeconds = labelSeconds;
  for (final divisions in _tickDivisions) {
    final candidate = labelSeconds / divisions;
    if (candidate * pps >= _minTickPx) {
      shortSeconds = candidate;
      break;
    }
  }

  final textInterval = (labelSeconds / shortSeconds).round().clamp(1, 1000);

  return TimeRulerIntervals(
    shortInterval: shortSeconds,
    longInterval: labelSeconds,
    textInterval: textInterval,
  );
}

/// Whether a tick at [tickX] (tile-local) should be drawn by this tile.
///
/// Uses a half-open range `[0, tileWidth)` so the shared boundary belongs to
/// the next tile only. The last tile also owns `tickX == tileWidth`.
bool timeRulerTickOwnedByTile(
  double tickX, {
  required double tileWidth,
  required bool isLastTile,
}) {
  const epsilon = 1e-6;
  if (tickX < -epsilon) return false;
  if (tickX > tileWidth + epsilon) return false;
  final onRightEdge = (tickX - tileWidth).abs() <= epsilon;
  if (onRightEdge) return isLastTile;
  return true;
}

/// Left edge for a label centered on [tickX]. Does not clamp into the tile,
/// so text can spill into neighboring segments instead of packing at edges.
double timeRulerLabelPaintX({
  required double tickX,
  required double labelWidth,
}) {
  return tickX - labelWidth / 2;
}
