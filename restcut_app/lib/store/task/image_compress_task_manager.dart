import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';

class ImageCompressTaskManager extends AbstractTaskManager {
  static const String imageCompressTable = 'image_compress_tasks';

  final TaskStorage _taskRunner;

  ImageCompressTaskManager(this._taskRunner);

  @override
  Future<List<Task>> loadTasks(
    List<Map<String, dynamic>> mainTasks,
    List<Map<String, dynamic>> subTasks,
  ) async {
    final tasks = <Task>[];
    for (int i = 0; i < mainTasks.length; i++) {
      final mainTask = mainTasks[i];
      final subTask = subTasks[i];
      tasks.add(ImageCompressTask.fromJson({...mainTask, ...subTask}));
    }
    return tasks;
  }

  @override
  Future<void> processTask(Task task) async {
    ImageCompressTask currentTask = task as ImageCompressTask;
    _taskRunner.updateTask(
      currentTask.id,
      (oldTask) =>
          oldTask.copyWith(status: TaskStatusEnum.processing, progress: 0),
    );
    try {
      // 直接在主 isolate 调用，不用 compute
      final List<String> outputList = [];
      final totalImages = currentTask.imageList.length;

      for (int i = 0; i < currentTask.imageList.length; i++) {
        final path = currentTask.imageList[i];
        final file = File(path);
        final dir = file.parent;
        final outPath =
            '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

        // 更新进度
        final progress = (i + 1) / totalImages;
        _taskRunner.updateTask(
          currentTask.id,
          (oldTask) => oldTask.copyWith(
            status: TaskStatusEnum.processing,
            progress: progress,
          ),
        );

        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          outPath,
          quality: currentTask.quality.toInt(),
          minWidth: currentTask.maxWidth,
          minHeight: currentTask.maxHeight,
        );
        if (result != null) {
          outputList.add(result.path);
        }
      }

      if (outputList.isNotEmpty) {
        _taskRunner.updateTask(
          currentTask.id,
          (oldTask) => (oldTask as ImageCompressTask).copyWith(
            status: TaskStatusEnum.completed,
            progress: 1.0,
            outputList: outputList,
          ),
        );
      } else {
        _taskRunner.updateTask(
          currentTask.id,
          (oldTask) => (oldTask as ImageCompressTask).copyWith(
            status: TaskStatusEnum.failed,
          ),
        );
      }
    } catch (e) {
      _taskRunner.updateTask(
        currentTask.id,
        (oldTask) => (oldTask as ImageCompressTask).copyWith(
          status: TaskStatusEnum.failed,
        ),
      );
    }
  }

  @override
  Future<void> pauseTask(Task task) async {
    // 图片压缩任务不支持暂停，直接标记为失败
    final currentTask = task as ImageCompressTask;
    _taskRunner.updateTask(
      currentTask.id,
      (oldTask) => oldTask.copyWith(status: TaskStatusEnum.failed),
    );
  }

  @override
  Future<void> resumeTask(Task task) async {
    // 图片压缩任务不支持恢复，重新开始处理
    final currentTask = task as ImageCompressTask;
    _taskRunner.updateTask(
      currentTask.id,
      (oldTask) =>
          oldTask.copyWith(status: TaskStatusEnum.pending, progress: 0),
    );
    processTask(currentTask);
  }

  @override
  String getTableName() {
    return imageCompressTable;
  }

  @override
  String getCreateTableSql() {
    return '''
          CREATE TABLE IF NOT EXISTS $imageCompressTable (
            taskId TEXT PRIMARY KEY,
            imageList TEXT NOT NULL,
            outputList TEXT NOT NULL,
            quality REAL NOT NULL,
            maxWidth INTEGER NOT NULL,
            maxHeight INTEGER NOT NULL,
            targetSizeKB INTEGER NOT NULL
          )
        ''';
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    ImageCompressTask imageCompressTask = task as ImageCompressTask;
    return {
      'taskId': imageCompressTask.id,
      'imageList': jsonEncode(imageCompressTask.imageList),
      'outputList': jsonEncode(imageCompressTask.outputList),
      'quality': imageCompressTask.quality,
      'maxWidth': imageCompressTask.maxWidth,
      'maxHeight': imageCompressTask.maxHeight,
      'targetSizeKB': imageCompressTask.targetSizeKB,
    };
  }

  @override
  bool supportsPause(Task task) => false;

  @override
  Task copyTask(Task task) {
    final imageCompressTask = task as ImageCompressTask;
    return imageCompressTask.copyWith();
  } // 图片压缩不支持暂停
}
