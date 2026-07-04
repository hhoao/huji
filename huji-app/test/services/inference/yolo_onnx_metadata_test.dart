import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/inference/yolo_onnx_metadata.dart';

void main() {
  group('YoloOnnxMetadata', () {
    test('parses normal ping pong class names in index order', () {
      const literal = "{0: 'fire_ball', 1: 'pick_ball', 2: 'play_ball'}";
      expect(
        YoloOnnxMetadata.parseClassNames(literal),
        ['fire_ball', 'pick_ball', 'play_ball'],
      );
    });

    test('parses profession ping pong class names in index order', () {
      const literal =
          "{0: 'fireball', 1: 'pickball', 2: 'playball', 3: 'transition'}";
      expect(
        YoloOnnxMetadata.parseClassNames(literal),
        ['fireball', 'pickball', 'playball', 'transition'],
      );
    });
    test('returns null for empty metadata', () {
      expect(YoloOnnxMetadata.tryParseClassNames('{}'), isNull);
      expect(YoloOnnxMetadata.tryParseClassNames(''), isNull);
    });
  });
}
