@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/clip_flow_test_helper.dart';

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
  // The app reads auth tokens via shared_preferences; provide an empty
  // mock so the channel is present in the test VM.
  SharedPreferences.setMockInitialValues(<String, Object>{});

  group('clip flow integration — demo video to completed task', () {
    late bool ncnnAvailable;

    setUpAll(() async {
      await ClipFlowTestHelper.setUp();
    });

    setUp(() async {
      await ClipFlowTestHelper.setUp();
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
        markTestSkipped('huji_ncnn native plugin not available');
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
  });
}
