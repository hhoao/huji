import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restcut/models/ffmpeg.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/task/video_compress_task_manager.dart';

void main() {
  test(
    'ignores late error callbacks after the task has been deleted',
    () async {
      final store = _FakeTaskStore();
      final task = VideoCompressTask(
        id: 'task-1',
        name: 'compress',
        progress: 0.4,
        status: TaskStatusEnum.processing,
        videoPath: '/tmp/input.mp4',
        outputPath: '/tmp/output.mp4',
        compressConfig: const VideoCompressConfig(),
        createdAt: DateTime(2026).millisecondsSinceEpoch,
      );
      await store.addTask(task);

      final manager = VideoCompressTaskManager(
        store,
        compressVideo:
            (
              inputPath, {
              config = const VideoCompressConfig(),
              onProgress,
              onSuccess,
              onError,
            }) async {
              await store.deleteByTaskId(task.id);
              await onError?.call(VideoCompressResult.error('cancelled'));
              return null;
            },
        startBackgroundService: () async {},
        stopBackgroundService: () async {},
      );

      await expectLater(manager.processTask(task), completes);
      expect(store.getTaskById(task.id), isNull);
    },
  );
}

class _FakeTaskStore implements TaskStore {
  final Map<String, Task> _tasks = {};

  @override
  Future<void> addTask(Task task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> addAndAsyncProcessTask(Task task) {
    throw UnimplementedError();
  }

  @override
  void addTaskTypeListener(TaskTypeEnum type, VoidCallback listener) {}

  @override
  Future<void> deleteByTaskId(String taskId) async {
    _tasks.remove(taskId);
  }

  @override
  Task? getTaskById(String taskId) => _tasks[taskId];

  @override
  Future<Task?> getTaskByIdSync(String taskId) async => _tasks[taskId];

  @override
  Map<TaskStatusEnum, int> getTaskCounts() => {};

  @override
  List<Task> getTasksByStatus(TaskStatusEnum? status) => [];

  @override
  List<Task> getTasksByType(TaskTypeEnum type) => [];

  @override
  List<Task> getTasksByTypeWithStatus(
    TaskTypeEnum type,
    TaskStatusEnum? status,
  ) => [];

  @override
  Future<void> init() {
    throw UnimplementedError();
  }

  @override
  void removeTaskTypeListener(TaskTypeEnum type, VoidCallback listener) {}

  @override
  Future<void> resetDatabase() {
    throw UnimplementedError();
  }

  @override
  Future<Task> updateTask(String taskId, Task Function(Task) updateFn) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw StateError('Task not found for update: $taskId');
    }
    final updatedTask = updateFn(task);
    _tasks[taskId] = updatedTask;
    return updatedTask;
  }
}
