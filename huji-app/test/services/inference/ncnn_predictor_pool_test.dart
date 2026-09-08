@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
import 'package:huji_app/services/inference/ncnn_predictor_pool.dart';

import '../../helpers/ncnn_test_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NcnnPredictorPool warm-up', () {
    late InferenceSpec spec;

    setUpAll(() async {
      await bootstrapNcnnLibrary();
      spec = await NcnnModelAssetResolver.resolve(
        sportType: 'ping_pong',
        matchType: 'profession',
      );
    });

    test('create() returns with every predictor loaded', () async {
      final pool = await NcnnPredictorPool.create(
        paramFilePath: spec.paramFilePath,
        binFilePath: spec.binFilePath,
        fallbackClassNames: spec.classNames,
        size: 2,
      );
      addTearDown(pool.dispose);

      expect(pool.allLoaded, isTrue,
          reason: 'create() must return with every predictor loaded');

      // Every borrowed predictor must be usable without any lazy load
      // happening: predict immediately (a garbage frame still exercises
      // the full FFI path).
      //
      // _classifyRgb24 validates the top class against classMappings
      // even in the ForResult variants, so pass a mapping that covers
      // every fallback class name.
      final classMappings = <String, ActionType>{
        for (final name in spec.classNames) name: ActionType.fromString(name),
      };
      final frame = Uint8List.fromList(List<int>.filled(640 * 640 * 3, 114));
      final results = await Future.wait([
        pool.withPredictor((p) => p.predictRgb24ForResult(
              frame,
              640,
              640,
              classMappings,
            )),
        pool.withPredictor((p) => p.predictRgb24ForResult(
              frame,
              640,
              640,
              classMappings,
            )),
      ]);
      expect(results.length, 2);
      // Assert on the RESULT object: it carries classification.topClass
      // which is one of the model's classes.
      expect(spec.classNames, contains(results.first.classification.topClass));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
