import 'package:gal/gal.dart';
import 'package:huji_app/models/ffmpeg.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/background_service.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/services/ffmpeg/ffmpeg_runner.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/ffmpeg_error_utils.dart';
import 'package:huji_app/utils/video_compress_utils.dart';

class VideoCompressTaskManager extends AbstractTaskManager {
  static const String videoCompressTable = 'video_compress_tasks';

  final TaskStorage _taskRunner;

  VideoCompressTaskManager(this._taskRunner);

  @override
  Future<void> processTask(Task task) async {
    VideoCompressTask currentTask = task as VideoCompressTask;
    await BackgroundService.instance.startService();
    try {
      await VideoCompressUtils.compressVideo(
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
          if (PlatformCapability.supportsGalleryAccess) {
            await Gal.putVideo(videoCompressResult.outputPath!);
          }
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
          final latestTask = _taskRunner.getTaskById(currentTask.id);
          final isCancelled =
              latestTask?.status == TaskStatusEnum.cancelled ||
              FFmpegErrorUtils.isCancelledMessage(result.errorMessage);
          currentTask =
              await _taskRunner.updateTask(
                    currentTask.id,
                    (oldTask) => (oldTask as VideoCompressTask).copyWith(
                      status: isCancelled
                          ? TaskStatusEnum.cancelled
                          : TaskStatusEnum.failed,
                    ),
                  )
                  as VideoCompressTask;
          BackgroundService.instance.stopService();
        },
      );
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
    // 取消当前正在运行的FFmpeg操作
    await FFmpegRunner.instance.cancel();
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
