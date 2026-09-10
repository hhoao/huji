@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:ncnn/ncnn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/clip_flow_test_helper.dart';
import '../helpers/ncnn_test_bootstrap.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The app reads auth tokens via shared_preferences and SettingsManager
  // loads its flags from it; provide a mock with notifications off so the
  // task-notification path (flutter_local_notifications, no test impl)
  // never runs.
  SharedPreferences.setMockInitialValues(<String, Object>{
    'notifications': false,
  });

  group('clip flow integration — demo video to completed task', () {
    late bool ncnnAvailable;

    setUpAll(() async {
      await ClipFlowTestHelper.setUp();
    });

    setUp(() async {
      await ClipFlowTestHelper.setUp();
      await bootstrapNcnnLibrary();
      final demo = demoVideos.first;
      ncnnAvailable = await _ncnnPluginAvailable(
        demo.sportTypeKey,
        demo.matchType,
      );
    });

    test('ping pong demo: task reaches completed with segments', () async {
      if (!PlatformCapability.isDesktop) {
        return;
      }
      if (!ncnnAvailable) {
        markTestSkipped('ncnn native plugin not available');
        return;
      }

      final demo = demoVideos.first;
      final taskId = await ClipFlowTestHelper.startLocalClipFromDemo(demo);

      final pending = TaskStorage().getTaskById(taskId);
      expect(pending, isNotNull);
      expect(pending!.status, TaskStatusEnum.processing);

      final finished = await ClipFlowTestHelper.waitForTerminalStatus(taskId);
      expect(
        finished.status,
        TaskStatusEnum.completed,
        reason: finished.extraInfo,
      );
      expect(finished.progress, 1.0);

      final libraryRecords = await LocalVideoStorage().load();
      final editing = libraryRecords.whereType<EdittingVideoRecord>().toList();
      expect(editing, isNotEmpty);
      expect(editing.last.allMatchSegments, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 15)));

    // Regression: "no valid segments" used to kill the worker isolate with
    // an unhandled async error before its 'error' reply reached the UI,
    // leaving the task stuck at 100% "detecting" forever.
    test('ping pong demo: no valid segments fails the task instead of hanging', () async {
      if (!PlatformCapability.isDesktop) {
        return;
      }
      if (!ncnnAvailable) {
        markTestSkipped('ncnn native plugin not available');
        return;
      }

      final demo = demoVideos.first;
      // Impossible minimum duration → filterSegmentsWithoutFireBall finds
      // no valid segments after inference completes.
      final taskId = await ClipFlowTestHelper.startLocalClipFromDemo(
        demo,
        clipConfig: PingPongVideoClipConfigReqVo(
          greatBallEditing: true,
          removeReplay: true,
          mergeFireBallAndPlayBall: true,
          minimumDurationSingleRound: 99999.0,
          minimumDurationGreatBall: 99999.0,
          reserveTimeBeforeSingleRound: 0.0,
          reserveTimeAfterSingleRound: 1.0,
        ),
      );

      final finished = await ClipFlowTestHelper.waitForTerminalStatus(
        taskId,
        // Generous but finite: the pre-fix bug never settled at all.
        timeout: const Duration(minutes: 3),
      );
      expect(
        finished.status,
        TaskStatusEnum.failed,
        reason: finished.extraInfo,
      );
      expect(finished.extraInfo, contains('没有有效的片段'));
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
