@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../helpers/clip_flow_test_helper.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ncnn detection → clip segments → ffmpeg export → library entry',
      () async {
    if (!PlatformCapability.isDesktop) {
      return;
    }
    await bootstrapNcnnLibrary();
    if (!await _ffmpegAvailable()) {
      // Same convention as video_export_library_registration_test.
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }

    // The app reads settings via shared_preferences; provide a mock with
    // notifications off so the task-notification path (which has no test
    // implementation) never runs. Must precede ClipFlowTestHelper.setUp()
    // (Get.put(SettingsManager) → SharedPreferences.getInstance).
    SharedPreferences.setMockInitialValues(<String, Object>{
      'notifications': false,
    });
    await ClipFlowTestHelper.setUp();

    // --- Phase 1: ncnn local detection over the demo video ---
    final demo = demoVideos.first;
    final taskId = await ClipFlowTestHelper.startLocalClipFromDemo(demo);
    final detected = await ClipFlowTestHelper.waitForTerminalStatus(taskId);
    expect(detected.status, TaskStatusEnum.completed,
        reason: 'detection task failed: ${detected.extraInfo}');

    final libraryRecords = await LocalVideoStorage().load();
    final editing = libraryRecords.whereType<EdittingVideoRecord>().toList();
    expect(editing, isNotEmpty, reason: 'detection must register a record');
    final segments =
        editing.last.allMatchSegments.cast<SegmentInfo>().toList();
    expect(segments, isNotEmpty,
        reason: 'ncnn detection must produce clip segments');

    // --- Phase 2: export exactly what ncnn detected ---
    final tempDir =
        await Directory.systemTemp.createTemp('huji_e2e_export_');
    addTearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });
    final saveDir = Directory(p.join(tempDir.path, 'save'));
    await saveDir.create(recursive: true);
    final fileName = 'e2e_${const Uuid().v4()}';

    final exportTask = VideoExportTask(
      id: const Uuid().v4(),
      name: '$fileName.mp4',
      videoPath: editing.last.filePath!,
      savePath: saveDir.path,
      fileName: fileName,
      quality: 'high',
      segments: segments,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskStorage().addAndAsyncProcessTask(exportTask);

    final exported = await ClipFlowTestHelper.waitForTerminalStatus(
      exportTask.id,
      timeout: const Duration(minutes: 10),
    );
    expect(exported.status, TaskStatusEnum.completed,
        reason: 'export task failed: ${exported.extraInfo}');

    // --- Phase 3: verify the artifact ---
    final outputPath = p.join(saveDir.path, '$fileName.mp4');
    expect(File(outputPath).existsSync(), isTrue,
        reason: 'exported file must exist');

    final expectedSeconds = segments.fold<double>(
        0, (sum, s) => sum + (s.endSeconds - s.startSeconds));
    expect(expectedSeconds, greaterThan(0));
    final info = await VideoUtils.getVideoInfo(outputPath);
    // Per-segment 1s tolerance: ffmpeg concat/intro rounding.
    expect(
      (info.duration - expectedSeconds).abs(),
      lessThan(segments.length * 1.0 + 0.5),
      reason: 'exported duration ${info.duration}s vs segments '
          '$expectedSeconds (${segments.length} segments)',
    );

    final saved = await LocalVideoStorage().loadSavedVideos();
    final registered =
        saved.where((r) => r.filePath == outputPath).toList();
    expect(registered, hasLength(1),
        reason: 'export must be registered in the video library');
    expect(registered.single.videoProcessType, VideoProcessType.exported);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
