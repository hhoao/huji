import 'dart:io';

import 'package:huji_app/models/task.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/video_export_utils.dart';

/// 本地视频导出任务：concat + x264 编码合成高光片段。
///
/// 进度/状态通过 [TaskStorage] 持久化，页面切走后任务继续运行；
/// 取消时按 taskId 精确杀掉对应的 ffmpeg 进程。
class VideoExportTaskManager extends AbstractTaskManager {
  static const String videoExportTable = 'video_export_tasks';

  final TaskStorage _taskRunner;

  /// taskId -> 正在运行的 ffmpeg 进程（用于精确取消）。
  final Map<String, Process> _runningProcesses = {};

  VideoExportTaskManager(this._taskRunner);

  Future<VideoExportTask?> _updateExportTask(
    String taskId,
    Task Function(Task) updateFn,
  ) async {
    final updated = await _taskRunner.tryUpdateTask(taskId, updateFn);
    return updated is VideoExportTask ? updated : null;
  }

  @override
  Future<void> processTask(Task task) async {
    final exportTask = task as VideoExportTask;
    final outputPath =
        '${exportTask.savePath}/${exportTask.fileName}.mp4';
    try {
      await runConcatVideoExport(
        videoPath: exportTask.videoPath,
        segments: exportTask.segments,
        quality: exportTask.quality,
        outputPath: outputPath,
        onProgress: (progress) async {
          await _updateExportTask(
            exportTask.id,
            (oldTask) => (oldTask as VideoExportTask).copyWith(
              status: TaskStatusEnum.processing,
              progress: progress,
            ),
          );
        },
        onProcessStarted: (process) {
          // 任务若在进程启动前已被取消，直接杀掉避免产出半成品。
          final latest = _taskRunner.getTaskById(exportTask.id);
          if (latest?.status == TaskStatusEnum.cancelled) {
            process.kill();
            return;
          }
          _runningProcesses[exportTask.id] = process;
        },
      );

      final latestTask = _taskRunner.getTaskById(exportTask.id);
      if (latestTask?.status == TaskStatusEnum.cancelled) return;

      await _updateExportTask(
        exportTask.id,
        (oldTask) => (oldTask as VideoExportTask).copyWith(
          status: TaskStatusEnum.completed,
          outputPath: outputPath,
          progress: 1.0,
        ),
      );
    } catch (e) {
      // 进程被取消 kill 时走到这里，保留已写入的 cancelled 状态。
      final latestTask = _taskRunner.getTaskById(exportTask.id);
      if (latestTask?.status == TaskStatusEnum.cancelled) return;

      await _updateExportTask(
        exportTask.id,
        (oldTask) => (oldTask as VideoExportTask).copyWith(
          status: TaskStatusEnum.failed,
          extraInfo: e.toString(),
        ),
      );
    } finally {
      _runningProcesses.remove(exportTask.id);
    }
  }

  @override
  Future<List<Task>> loadTasks(
    List<Map<String, dynamic>> mainTasks,
    List<Map<String, dynamic>> subTasks,
  ) async {
    final tasks = <Task>[];
    for (int i = 0; i < mainTasks.length; i++) {
      final mainTask = mainTasks[i];
      final subTask = subTasks[i];
      tasks.add(VideoExportTask.fromJson({...mainTask, ...subTask}));
    }
    return tasks;
  }

  @override
  String getTableName() {
    return videoExportTable;
  }

  @override
  String getCreateTableSql() {
    return '''
    CREATE TABLE IF NOT EXISTS $videoExportTable (
            taskId TEXT PRIMARY KEY,
            videoPath TEXT NOT NULL,
            savePath TEXT NOT NULL,
            fileName TEXT NOT NULL,
            quality TEXT NOT NULL,
            segments TEXT NOT NULL,
            outputPath TEXT NOT NULL
          )
    ''';
  }

  @override
  Map<int, String> getUpgradeTableSql(int oldVersion) {
    return {};
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    final exportTask = task as VideoExportTask;
    return {
      'taskId': exportTask.id,
      'videoPath': exportTask.videoPath,
      'savePath': exportTask.savePath,
      'fileName': exportTask.fileName,
      'quality': exportTask.quality,
      'segments': segmentListToJsonStr(exportTask.segments),
      'outputPath': exportTask.outputPath,
    };
  }

  @override
  Future<void> deleteTask(Task task) async {}

  @override
  Future<void> cancelTask(Task task) async {
    _runningProcesses[task.id]?.kill();
  }

  @override
  Task copyTask(Task task) {
    final exportTask = task as VideoExportTask;
    return exportTask.copyWith();
  }

  @override
  bool supportsPause(Task task) => false;
}
