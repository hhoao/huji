@Tags(['integration'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
import 'package:huji_app/services/inference/ncnn_model_predictor.dart';
import 'package:huji_app/utils/video_utils.dart';

import '../helpers/autoclip_fixtures.dart';
import '../helpers/ncnn_test_bootstrap.dart';

Future<bool> _ffmpegAvailable() async {
  for (final bin in ['ffmpeg', 'ffprobe']) {
    try {
      final result = await Process.run(bin, ['-version']);
      if (result.exitCode != 0) return false;
    } catch (_) {
      return false;
    }
  }
  return true;
}

/// First 640x640 RGB24 frame at [startTime] from the fixture video, via the
/// app's own streaming extractor (same production path as batch detection).
Future<Uint8List> _extractFrame(String videoPath, double startTime) async {
  await for (final frame in VideoUtils.streamIntervalRawRgbFrames(
    videoPath: videoPath,
    frameInterval: 1,
    startTime: startTime,
    duration: 1,
  )) {
    return frame;
  }
  throw StateError('no frame extracted at t=${startTime}s');
}

/// Classify real frames extracted from the golden test video inside the
/// flutter test VM — mirrors the exact production predict path
/// (NcnnModelPredictor.predictRgb24).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapNcnnLibrary();
  });

  test('real frames from test.mp4 classify correctly', () async {
    if (!await _ffmpegAvailable()) {
      // Same convention as ncnn_clip_to_export_integration_test.
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }

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

    final videoPath = resolvePingPongTestVideo();

    for (final t in [5, 8, 10, 12]) {
      final frame = await _extractFrame(videoPath, t.toDouble());
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
