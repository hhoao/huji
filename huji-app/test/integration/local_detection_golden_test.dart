import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
import 'package:huji_app/services/local_detection_service.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/autoclip_fixtures.dart';
import '../helpers/fake_path_provider.dart';

Future<bool> _ncnnPluginAvailable(String sportType, String matchType) async {
  try {
    final spec = await NcnnModelAssetResolver.resolve(
      sportType: sportType,
      matchType: matchType,
    );
    final net = await NcnnNet.load(
      paramPath: spec.paramFilePath,
      binPath: spec.binFilePath,
    );
    net.dispose();
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
  VideoClipConfigReqVo Function() clipConfig,
});

final _cases = <_GoldenCase>[
  (
    name: 'ping pong test.mp4',
    videoRel: pingPongTestVideoRel,
    goldenRel: pingPongGoldenRel,
    sportTypeKey: 'ping_pong',
    matchType: 'profession',
    clipConfig: algorithmPingPongConfig,
  ),
  (
    name: 'badminton blue.mp4',
    videoRel: badmintonTestVideoRel,
    goldenRel: badmintonGoldenRel,
    sportTypeKey: 'badminton',
    matchType: 'singles',
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
      late bool ncnnAvailable;

      setUp(() async {
        ncnnAvailable = await _ncnnPluginAvailable(
          testCase.sportTypeKey,
          testCase.matchType,
        );
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
        if (!PlatformCapability.isDesktop) {
          return;
        }
        if (!ncnnAvailable) {
          markTestSkipped('huji_ncnn native plugin not available in test VM');
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
        if (!PlatformCapability.isDesktop) {
          return;
        }
        if (!ncnnAvailable) {
          markTestSkipped('huji_ncnn native plugin not available in test VM');
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
        if (!PlatformCapability.isDesktop) {
          return;
        }
        if (!ncnnAvailable) {
          markTestSkipped('huji_ncnn native plugin not available in test VM');
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

      test('runInferenceAsync via worker isolate matches golden segment count', () async {
        if (!PlatformCapability.isDesktop) {
          return;
        }
        if (!ncnnAvailable) {
          markTestSkipped('huji_ncnn native plugin not available in test VM');
          return;
        }

        final appRoot = findAppRoot();
        final videoPath = resolveFixtureFile(testCase.videoRel, appRoot: appRoot).path;
        final golden = loadGoldenJson(testCase.goldenRel, appRoot: appRoot);
        final expectedCount = golden['all_match_segment_count'] as int;

        final result = await LocalDetectionService.runInferenceAsync(
          videoPath: videoPath,
          clipConfig: testCase.clipConfig(),
          sportTypeKey: testCase.sportTypeKey,
          matchType: testCase.matchType,
        );

        expect(result.clipOutput.allMatchSegments.length, expectedCount);
      }, timeout: const Timeout(Duration(minutes: 15)));
    });
  }
}
