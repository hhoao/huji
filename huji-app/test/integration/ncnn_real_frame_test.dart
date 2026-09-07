@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
import 'package:huji_app/services/inference/ncnn_model_predictor.dart';
import 'package:huji_app/models/autoclip_models.dart';

/// Classify real ffmpeg-extracted frames from the golden test video inside
/// the flutter test VM — mirrors the exact production predict path
/// (NcnnModelPredictor.predictRgb24).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real frames from test.mp4 classify correctly', () async {
    final spec = await NcnnModelAssetResolver.resolve(
      sportType: 'ping_pong',
      matchType: 'profession',
    );

    final predictor = NcnnModelPredictor(
      paramFilePath: spec.paramFilePath,
      binFilePath: spec.binFilePath,
      fallbackClassNames: spec.classNames,
    );
    addTearDown(predictor.dispose);

    final mappings = <String, ActionType>{
      'fireball': ActionType.fireBall,
      'pickball': ActionType.pickBall,
      'playball': ActionType.playBall,
      'transition': ActionType.transition,
    };

    for (final t in [5, 8, 10, 12]) {
      final frame = File('C:/Users/haung/AppData/Local/Temp/frame_${t}s.rgb')
          .readAsBytesSync();
      final action = await predictor.predictRgb24(
        frame,
        640,
        640,
        mappings,
      );
      print('t=$t s → $action');
      expect(action, isA<ActionType>());
    }
  });
}
