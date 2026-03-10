import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:gal/gal.dart';
import 'package:restcut/models/ffmpeg.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/services/background_service.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/utils/video_compress_utils.dart';

class VideoCompressTaskManager extends AbstractTaskManager {
  static const String videoCompressTable = 'video_compress_tasks';
  final Map<String, Session> _taskSessionMap = {};

  final TaskStorage _taskRunner;

  VideoCompressTaskManager(this._taskRunner);

  @override
  Future<void> processTask(Task task) async {
    VideoCompressTask currentTask = task as VideoCompressTask;
    await BackgroundService.instance.startService();
    try {
      Session? result = await VideoCompressUtils.compressVideo(
        currentTask.videoPath,
        config: currentTask.compressConfig,
        onProgress: (progress) async {
          currentTask =
              await _taskRunner.updateTask(
                    currentTask.id,
                    (oldTask) => (oldTask as VideoCompressTask).copyWith(
                      status: TaskStatusEnum.processing,
                      progress: progress,
                    ),
                  )
                  as VideoCompressTask;
        },
        onSuccess: (result) async {
          VideoCompressResult videoCompressResult = result;
          await Gal.putVideo(videoCompressResult.outputPath!);
          currentTask =
              await _taskRunner.updateTask(
                    currentTask.id,
                    (oldTask) => (oldTask as VideoCompressTask).copyWith(
                      status: TaskStatusEnum.completed,
                      outputPath: videoCompressResult.outputPath!,
                      progress: 1.0,
                    ),
                  )
                  as VideoCompressTask;
          BackgroundService.instance.stopService();
        },
        onError: (result) async {
          currentTask =
              await _taskRunner.updateTask(
                    currentTask.id,
                    (oldTask) => (oldTask as VideoCompressTask).copyWith(
                      status: TaskStatusEnum.failed,
                    ),
                  )
                  as VideoCompressTask;
          BackgroundService.instance.stopService();
        },
      );
      if (result != null) {
        _taskSessionMap[currentTask.id] = result;
      }
    } catch (e) {
      await BackgroundService.instance.stopService();
      currentTask =
          await _taskRunner.updateTask(
                currentTask.id,
                (oldTask) => (oldTask as VideoCompressTask).copyWith(
                  status: TaskStatusEnum.failed,
                ),
              )
              as VideoCompressTask;
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
      tasks.add(VideoCompressTask.fromJson({...mainTask, ...subTask}));
    }
    return tasks;
  }

  @override
  String getTableName() {
    return videoCompressTable;
  }

  @override
  Future<void> pauseTask(Task task) async {
    // _taskIsolatesMap[task.id]?.pause();

    throw UnimplementedError();
  }

  @override
  Future<void> resumeTask(Task task) async {
    // _taskIsolatesMap[task.id]?.start();
    throw UnimplementedError();
  }

  @override
  String getCreateTableSql() {
    return '''
    CREATE TABLE IF NOT EXISTS $videoCompressTable (
            taskId TEXT PRIMARY KEY,
            videoPath TEXT NOT NULL,
            outputPath TEXT NOT NULL,
            compressConfig TEXT NOT NULL,
            compressResult TEXT NOT NULL
          )
    ''';
  }

  @override
  Map<int, String> getUpgradeTableSql(int oldVersion) {
    return {};
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    VideoCompressTask videoCompressTask = task as VideoCompressTask;
    return {
      'taskId': videoCompressTask.id,
      'videoPath': videoCompressTask.videoPath,
      'outputPath': videoCompressTask.outputPath,
      'compressConfig': videoCompressConfigToJsonStr(
        videoCompressTask.compressConfig,
      ),
      'compressResult': videoCompressResultToJsonStr(
        videoCompressTask.compressResult,
      ),
    };
  }

  @override
  Future<void> deleteTask(Task task) async {}

  @override
  Future<void> cancelTask(Task task) async {
    // 使用后台服务取消任务
    // 清理本地会话映射
    _taskSessionMap[task.id]?.cancel();
    _taskSessionMap.remove(task.id);
    return Future.value();
  }

  @override
  Task copyTask(Task task) {
    final videoCompressTask = task as VideoCompressTask;
    return videoCompressTask.copyWith();
  }

  @override
  bool supportsPause(Task task) => false;
}
