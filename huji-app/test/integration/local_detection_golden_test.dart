import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/services/local_detection_service.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/autoclip_fixtures.dart';
import '../helpers/fake_path_provider.dart';

Future<bool> _onnxPluginAvailable(String assetPath) async {
  try {
    final ort = OnnxRuntime();
    final session = await ort.createSessionFromAsset(assetPath);
    await session.close();
    return true;
  } catch (_) {
    return false;
  }
}

typedef _GoldenCase = ({
  String name,
  String videoRel,
  String goldenRel,
  String sportTypeKey,
  String matchType,
  String onnxAsset,
  VideoClipConfigReqVo Function() clipConfig,
});

final _cases = <_GoldenCase>[
  (
    name: 'ping pong test.mp4',
    videoRel: pingPongTestVideoRel,
    goldenRel: pingPongGoldenRel,
    sportTypeKey: 'ping_pong',
    matchType: 'profession',
    onnxAsset: 'assets/models/ping_pong/profession/best.onnx',
    clipConfig: algorithmPingPongConfig,
  ),
  (
    name: 'badminton blue.mp4',
    videoRel: badmintonTestVideoRel,
    goldenRel: badmintonGoldenRel,
    sportTypeKey: 'badminton',
    matchType: 'singles',
    onnxAsset: 'assets/models/badminton/singles/best.onnx',
    clipConfig: algorithmBadmintonConfig,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    if (!StorageService.isInitialized) {
      await StorageService.init();
    }
  });

  for (final testCase in _cases) {
    group('LocalDetectionService golden — ${testCase.name}', () {
      late bool onnxAvailable;

      setUp(() async {
        onnxAvailable = await _onnxPluginAvailable(testCase.onnxAsset);
      });

      test('bundled video and golden fixture are present', () {
        final appRoot = findAppRoot();
        expect(
          () => resolveFixtureFile(testCase.videoRel, appRoot: appRoot),
          returnsNormally,
        );
        expect(
          () => loadGoldenJson(testCase.goldenRel, appRoot: appRoot),
          returnsNormally,
        );
      });

      test('matches golden segment count', () async {
        if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
          return;
        }
        if (!onnxAvailable) {
          markTestSkipped('flutter_onnxruntime native plugin not available in test VM');
          return;
        }

        final appRoot = findAppRoot();
        final videoPath = resolveFixtureFile(testCase.videoRel, appRoot: appRoot).path;
        final golden = loadGoldenJson(testCase.goldenRel, appRoot: appRoot);
        final expectedCount = golden['all_match_segment_count'] as int;

        final service = LocalDetectionService();
        final result = await service.runAutoclip(
          videoPath: videoPath,
          clipConfig: testCase.clipConfig(),
          sportTypeKey: testCase.sportTypeKey,
          matchType: testCase.matchType,
        );

        final actualCount = result.clipOutput.allMatchSegments.length;
        expect(
          actualCount,
          expectedCount,
          reason:
              'Segment count mismatch vs algorithm golden ($expectedCount). '
              'Actual: ${result.clipOutput.allMatchSegments.map((m) => m.values.first).toList()}',
        );
        expect(actualCount, greaterThan(0));
      }, timeout: const Timeout(Duration(minutes: 15)));

      test('segment timings within tolerance of algorithm golden', () async {
        if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
          return;
        }
        if (!onnxAvailable) {
          markTestSkipped('flutter_onnxruntime native plugin not available in test VM');
          return;
        }

        const toleranceSeconds = 2.0;
        final appRoot = findAppRoot();
        final videoPath = resolveFixtureFile(testCase.videoRel, appRoot: appRoot).path;
        final golden = loadGoldenJson(testCase.goldenRel, appRoot: appRoot);
        final expectedSegments = goldenAllMatchSegments(golden);

        final service = LocalDetectionService();
        final result = await service.runAutoclip(
          videoPath: videoPath,
          clipConfig: testCase.clipConfig(),
          sportTypeKey: testCase.sportTypeKey,
          matchType: testCase.matchType,
        );

        final actualSegments = result.clipOutput.allMatchSegments;
        expect(actualSegments.length, expectedSegments.length);

        for (var i = 0; i < expectedSegments.length; i++) {
          final expected = expectedSegments[i];
          final actual = actualSegments[i].values.first;
          expect(
            normalizeActionName(actualSegments[i].keys.first.name),
            normalizeActionName(expected['action'] as String),
          );
          expect(
            (actual.startSeconds - (expected['start'] as num).toDouble()).abs(),
            lessThanOrEqualTo(toleranceSeconds),
            reason: 'segment $i start',
          );
          expect(
            (actual.endSeconds - (expected['end'] as num).toDouble()).abs(),
            lessThanOrEqualTo(toleranceSeconds),
            reason: 'segment $i end',
          );
        }
      }, timeout: const Timeout(Duration(minutes: 15)));

      test('produces stable action types from golden set', () async {
        if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
          return;
        }
        if (!onnxAvailable) {
          markTestSkipped('flutter_onnxruntime native plugin not available in test VM');
          return;
        }

        final appRoot = findAppRoot();
        final videoPath = resolveFixtureFile(testCase.videoRel, appRoot: appRoot).path;
        final golden = loadGoldenJson(testCase.goldenRel, appRoot: appRoot);
        final expectedActions = goldenAllMatchSegments(golden)
            .map((s) => normalizeActionName(s['action'] as String))
            .toSet();

        final service = LocalDetectionService();
        final result = await service.runAutoclip(
          videoPath: videoPath,
          clipConfig: testCase.clipConfig(),
          sportTypeKey: testCase.sportTypeKey,
          matchType: testCase.matchType,
        );

        final actualActions = result.clipOutput.allMatchSegments
            .map((m) => normalizeActionName(m.keys.first.name))
            .toSet();

        for (final action in expectedActions) {
          expect(
            actualActions.contains(action),
            isTrue,
            reason: 'Expected action $action in $actualActions',
          );
        }
      }, timeout: const Timeout(Duration(minutes: 15)));
    });
  }
}
