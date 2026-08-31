import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/pages/desktop/precision_edit_seek_accelerator.dart';

void main() {
  group('PrecisionEditSeekAccelerator', () {
    test('first press seeks 0.1s', () {
      final accelerator = PrecisionEditSeekAccelerator();

      expect(
        accelerator.stepMsFor(isRepeat: false, direction: 1),
        PrecisionEditSeekAccelerator.baseStepMs,
      );
    });

    test('early repeats stay at 0.1s tier', () {
      final accelerator = PrecisionEditSeekAccelerator();

      accelerator.stepMsFor(isRepeat: false, direction: -1);
      for (var i = 0; i < 3; i++) {
        expect(
          accelerator.stepMsFor(isRepeat: true, direction: -1),
          100,
        );
      }
    });

    test('repeated presses advance through tiers', () {
      final accelerator = PrecisionEditSeekAccelerator();

      accelerator.stepMsFor(isRepeat: false, direction: -1);
      for (var i = 0; i < 3; i++) {
        accelerator.stepMsFor(isRepeat: true, direction: -1);
      }
      expect(
        accelerator.stepMsFor(isRepeat: true, direction: -1),
        500,
      );

      for (var i = 0; i < 4; i++) {
        accelerator.stepMsFor(isRepeat: true, direction: -1);
      }
      expect(
        accelerator.stepMsFor(isRepeat: true, direction: -1),
        1000,
      );
    });

    test('direction change resets acceleration', () {
      final accelerator = PrecisionEditSeekAccelerator();

      accelerator.stepMsFor(isRepeat: false, direction: 1);
      accelerator.stepMsFor(isRepeat: true, direction: 1);
      accelerator.stepMsFor(isRepeat: true, direction: 1);

      expect(
        accelerator.stepMsFor(isRepeat: false, direction: -1),
        PrecisionEditSeekAccelerator.baseStepMs,
      );
    });

    test('step reaches max tier on long hold', () {
      final accelerator = PrecisionEditSeekAccelerator();

      accelerator.stepMsFor(isRepeat: false, direction: 1);
      var step = PrecisionEditSeekAccelerator.baseStepMs;
      for (var i = 0; i < 100; i++) {
        step = accelerator.stepMsFor(isRepeat: true, direction: 1);
      }

      expect(step, PrecisionEditSeekAccelerator.maxStepMs);
    });
  });
}
