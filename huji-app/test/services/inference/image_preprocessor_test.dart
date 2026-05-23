import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:restcut/services/inference/image_preprocessor.dart';

void main() {
  group('ImagePreprocessor', () {
    test('preprocesses raw RGB buffer to NCHW float32 tensor', () {
      // 2x2 RGB image: all pixels red (255, 0, 0)
      final rgb = Uint8List.fromList([
        255, 0, 0,  255, 0, 0,
        255, 0, 0,  255, 0, 0,
      ]);

      final tensor = ImagePreprocessor.preprocess(rgb, 2, 2);

      // Output shape: [3, 2, 2] (C, H, W), batch dim implied
      expect(tensor.length, 3 * 2 * 2);

      // Red channel: (255/255 - 0.485) / 0.229 = (1.0 - 0.485) / 0.229 ~ 2.249
      final expectedRed = ((1.0 - 0.485) / 0.229);
      // Green channel: (0/255 - 0.456) / 0.224 = (0 - 0.456) / 0.224 ~ -2.036
      final expectedGreen = ((0.0 - 0.456) / 0.224);
      // Blue channel: (0/255 - 0.406) / 0.225 = (0 - 0.406) / 0.225 ~ -1.804
      final expectedBlue = ((0.0 - 0.406) / 0.225);

      // NCHW layout: R-plane at offset 0, G-plane at offset spatialSize
      final spatialSize = 2 * 2; // H*W = 4
      expect(tensor[0], closeTo(expectedRed, 0.001));     // R at (0,0)
      expect(tensor[2], closeTo(expectedRed, 0.001));     // R at (1,0)
      expect(tensor[0 + spatialSize], closeTo(expectedGreen, 0.001));   // G at (0,0)
      expect(tensor[2 + spatialSize], closeTo(expectedGreen, 0.001));   // G at (1,0)
      expect(tensor[0 + 2 * spatialSize], closeTo(expectedBlue, 0.001)); // B at (0,0)
      expect(tensor[2 + 2 * spatialSize], closeTo(expectedBlue, 0.001)); // B at (1,0)
    });

    test('handles non-square input', () {
      // 4x2 RGB image — all black
      final rgb = Uint8List(4 * 2 * 3);
      final tensor = ImagePreprocessor.preprocess(rgb, 4, 2);

      expect(tensor.length, 3 * 2 * 4); // C*H*W = 3*2*4 = 24

      final spatialSize = 2 * 4; // H*W

      // Verify normalized values for all-black pixels
      final expectedR = ((0.0 - 0.485) / 0.229);
      final expectedG = ((0.0 - 0.456) / 0.224);
      final expectedB = ((0.0 - 0.406) / 0.225);

      // Check first pixel (h=0, w=0)
      expect(tensor[0], closeTo(expectedR, 0.001));
      expect(tensor[spatialSize], closeTo(expectedG, 0.001));
      expect(tensor[2 * spatialSize], closeTo(expectedB, 0.001));

      // Check last pixel (h=1, w=3) — verify row-major layout with non-square
      final lastIdx = 1 * 4 + 3; // h*width + w = 7
      expect(tensor[lastIdx], closeTo(expectedR, 0.001));
      expect(tensor[spatialSize + lastIdx], closeTo(expectedG, 0.001));
      expect(tensor[2 * spatialSize + lastIdx], closeTo(expectedB, 0.001));
    });
  });
}
