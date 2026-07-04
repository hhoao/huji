@Tags(['integration'])
library;

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/inference/onnx_model_asset_resolver.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';

import '../helpers/clip_flow_test_helper.dart';

Future<bool> _onnxPluginAvailable(String sportType, String matchType) async {
  try {
    final spec = await OnnxModelAssetResolver.resolve(
      sportType: sportType,
      matchType: matchType,
    );
    final ort = OnnxRuntime();
    final session = await ort.createSession(spec.modelFilePath);
    await session.close();
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clip flow integration — demo video to completed task', () {
    late bool onnxAvailable;

    setUpAll(() async {
      await ClipFlowTestHelper.setUp();
    });

    setUp(() async {
      await ClipFlowTestHelper.setUp();
      final demo = demoVideos.first;
      onnxAvailable = await _onnxPluginAvailable(
        demo.sportTypeKey,
        demo.matchType,
      );
    });

    test('ping pong demo: task reaches completed with segments', () async {
      if (!PlatformCapability.isDesktop) {
        return;
      }
      if (!onnxAvailable) {
        markTestSkipped('flutter_onnxruntime native plugin not available');
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
