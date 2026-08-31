/// Computes tiered seek steps for precision-edit arrow-key shortcuts.
class PrecisionEditSeekAccelerator {
  static const baseStepMs = 100;
  static const maxStepMs = 5000;

  /// Each entry is `(maxRepeatCount, stepMs)`. The first tier whose
  /// [maxRepeatCount] is >= the current repeat count wins.
  static const List<(int maxRepeat, int stepMs)> tiers = [
    (3, 100), // 0.1s — fine scrub
    (7, 500), // 0.5s
    (14, 1000), // 1s
    (24, 2000), // 2s
  ];

  int _repeatCount = 0;
  int? _lastDirection;

  /// Returns the seek delta in milliseconds for [direction] (-1 or 1).
  ///
  /// The first press in a hold sequence uses [baseStepMs] (0.1s). Each repeat
  /// while the key stays down advances through [tiers] until [maxStepMs].
  int stepMsFor({required bool isRepeat, required int direction}) {
    if (!isRepeat || _lastDirection != direction) {
      _repeatCount = 0;
      _lastDirection = direction;
      return baseStepMs;
    }

    _repeatCount++;
    return _stepForRepeatCount(_repeatCount);
  }

  static int _stepForRepeatCount(int repeatCount) {
    for (final (maxRepeat, stepMs) in tiers) {
      if (repeatCount <= maxRepeat) return stepMs;
    }
    return maxStepMs;
  }
}
