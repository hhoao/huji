import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/models/ffmpeg.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';

void main() {
  const createdAt = 1;

  group('canViewTaskResult', () {
    test('true for completed download with savePath', () {
      final task = DownloadTask(
        id: 'd1',
        name: 'apk',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        url: 'https://example.com/a.apk',
        savePath: '/tmp/a.apk',
        isInstall: false,
        cacheKey: 'k',
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isTrue);
    });

    test('false for completed upload', () {
      final task = VideoUploadTask(
        id: 'u1',
        name: 'upload',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        uploadTaskId: 'up-1',
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isFalse);
    });

    test('false for completed clip with empty outputPath', () {
      final task = VideoClipTask(
        id: 'c1',
        name: 'clip',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        videoPath: '/in.mp4',
        outputPath: '',
        autoDownload: false,
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isFalse);
    });

    test('true for completed clip with outputPath', () {
      final task = VideoClipTask(
        id: 'c2',
        name: 'clip',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        videoPath: '/in.mp4',
        outputPath: '/out.mp4',
        autoDownload: false,
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isTrue);
    });

    test('true for completed compress with outputPath', () {
      final task = VideoCompressTask(
        id: 'v1',
        name: 'compress',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        videoPath: '/in.mp4',
        outputPath: '/out.mp4',
        compressConfig: const VideoCompressConfig(),
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isTrue);
    });

    test('true for completed image compress with outputs', () {
      final task = ImageCompressTask(
        id: 'i1',
        name: 'images',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        imageList: const ['/a.jpg'],
        outputList: const ['/a_out.jpg'],
        quality: 0.8,
        maxWidth: 1280,
        maxHeight: 720,
        targetSizeKB: 500,
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isTrue);
    });

    test('true for completed segment detect with editing record', () {
      final task = VideoSegmentDetectTask(
        id: 's1',
        name: 'detect',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        videoPath: '/in.mp4',
        edittingRecordId: 'rec-1',
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isTrue);
    });

    test('false for completed segment detect without editing record', () {
      final task = VideoSegmentDetectTask(
        id: 's2',
        name: 'detect',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        videoPath: '/in.mp4',
      );
      expect(TaskTabListUtils.canViewTaskResult(task), isFalse);
    });
  });

  group('resolveTaskActions view gating', () {
    test('completed download includes view and delete', () {
      final task = DownloadTask(
        id: 'd1',
        name: 'apk',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        url: 'https://example.com/a.apk',
        savePath: '/tmp/a.apk',
        isInstall: false,
        cacheKey: 'k',
      );
      expect(
        TaskTabListUtils.resolveTaskActions(task),
        [TaskRowAction.view, TaskRowAction.delete],
      );
    });

    test('completed upload includes only delete', () {
      final task = VideoUploadTask(
        id: 'u1',
        name: 'upload',
        createdAt: createdAt,
        status: TaskStatusEnum.completed,
        uploadTaskId: 'up-1',
      );
      expect(
        TaskTabListUtils.resolveTaskActions(task),
        [TaskRowAction.delete],
      );
    });
  });
}
