import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/inference/onnx_image_preprocessor.dart';
import 'package:huji_app/services/inference/onnx_predictor_pool.dart';

void main() {
  group('OnnxImagePreprocessor', () {
    test('padColorHex matches Ultralytics pad 114', () {
      expect(OnnxImagePreprocessor.padValue, 114);
      expect(OnnxImagePreprocessor.padColorHex, '0x727272');
    });

    test('toTensor converts letterboxed RGB24 to CHW /255', () {
      // 2x2 RGB: R G / B W  (values chosen for easy CHW checks)
      final rgb = Uint8List.fromList([
        255, 0, 0, // (0,0) red
        0, 255, 0, // (1,0) green
        0, 0, 255, // (0,1) blue
        255, 255, 255, // (1,1) white
      ]);

      final tensor = OnnxImagePreprocessor.toTensor(rgb, 2, 2);
      expect(tensor.length, 12);

      // Channel R
      expect(tensor[0], 1.0);
      expect(tensor[1], 0.0);
      expect(tensor[2], 0.0);
      expect(tensor[3], 1.0);
      // Channel G
      expect(tensor[4], 0.0);
      expect(tensor[5], 1.0);
      expect(tensor[6], 0.0);
      expect(tensor[7], 1.0);
      // Channel B
      expect(tensor[8], 0.0);
      expect(tensor[9], 0.0);
      expect(tensor[10], 1.0);
      expect(tensor[11], 1.0);
    });

    test('rgb24ByteLength', () {
      expect(OnnxImagePreprocessor.rgb24ByteLength(640, 640), 640 * 640 * 3);
    });
  });

  group('OnnxPredictorPool', () {
    test('limits concurrency to pool size', () async {
      final pool = OnnxPredictorPool.create(
        modelFilePath: '/tmp/unused.onnx',
        fallbackClassNames: const ['a'],
        size: 2,
      );

      var inFlight = 0;
      var maxInFlight = 0;
      final started = <int>[];
      final gate = <Completer<void>>[];

      Future<void> job(int id) {
        return pool.withPredictor((_) async {
          inFlight++;
          maxInFlight = maxInFlight < inFlight ? inFlight : maxInFlight;
          started.add(id);
          final c = Completer<void>();
          gate.add(c);
          await c.future;
          inFlight--;
        });
      }

      final f1 = job(1);
      final f2 = job(2);
      final f3 = job(3);

      // Let microtasks schedule acquires
      await Future<void>.delayed(Duration.zero);
      expect(started, [1, 2]);
      expect(maxInFlight, 2);

      gate[0].complete();
      await Future<void>.delayed(Duration.zero);
      expect(started, [1, 2, 3]);

      gate[1].complete();
      gate[2].complete();
      await Future.wait([f1, f2, f3]);
      expect(maxInFlight, 2);

      await pool.dispose();
    });
  });
}
