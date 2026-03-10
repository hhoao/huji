import 'package:restcut/models/task.dart';
import 'package:restcut/models/upload.dart';
import 'package:restcut/services/multipart_uploader.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:uuid/uuid.dart';

// 上传任务管理器 - 连接FileUploader和TaskManager
class VideoUploadTaskManager extends AbstractTaskManager {
  static const String videoUploadTable = 'video_upload_tasks';

  final MultipartUploader _fileUploader = MultipartUploader();
  final TaskStorage _taskManager;

  VideoUploadTaskManager(this._taskManager);

  static Future<Task> createUploadTask({
    required String filePath,
    required String fileName,
    String? directory,
    String? contentType,
    int chunkSize = 5 * 1024 * 1024,
    int maxRetries = 3,
  }) async {
    // 1. 创建FileUploader任务
    final uploadTask = await MultipartUploader().createUploadTask(
      filePath: filePath,
      fileName: fileName,
      directory: directory,
      contentType: contentType,
      chunkSize: chunkSize,
      maxRetries: maxRetries,
    );

    // 2. 创建TaskManager任务
    final task = VideoUploadTask(
      id: Uuid().v4(),
      name: fileName,
      image: null, // 可以生成缩略图
      uploadTaskId: uploadTask.id,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    return task;
  }

  @override
  Future<void> pauseTask(Task task) async {
    VideoUploadTask videoUploadTask = task as VideoUploadTask;

    await _fileUploader.pauseUpload(videoUploadTask.uploadTaskId);

    final taskById = _taskManager.getTaskById(videoUploadTask.id);
    if (taskById != null) {
      videoUploadTask =
          await _taskManager.updateTask(
                videoUploadTask.id,
                (oldTask) => oldTask.copyWith(status: TaskStatusEnum.paused),
              )
              as VideoUploadTask;
    }
  }

  @override
  Future<void> retryTask(Task task) async {
    final videoUploadTask = task as VideoUploadTask;

    await _fileUploader.startOrRetryUpload(
      videoUploadTask.uploadTaskId,
      onProgress: (uploadTask) => _onProgress(
        videoUploadTask.id,
        uploadTask.progress,
        uploadTask.uploadedChunksCount,
        uploadTask.totalChunksCount,
      ),
      onStatus: (status, error, uploadTask) =>
          _onStatus(videoUploadTask.id, status, error, uploadTask),
    );
  }

  Future<void> _onProgress(
    String taskId,
    progress,
    uploadedChunks,
    totalChunks,
  ) async {
    final task = _taskManager.getTaskById(taskId);
    if (task != null) {
      await _taskManager.updateTask(
        taskId,
        (oldTask) => oldTask.copyWith(
          progress: progress,
          status: TaskStatusEnum.processing,
        ),
      );
    }
  }

  Future<void> _onStatus(
    String taskId,
    status,
    error,
    UploadTask uploadTask,
  ) async {
    var task = _taskManager.getTaskById(taskId);
    if (task != null) {
      TaskStatusEnum taskStatus;
      switch (status) {
        case UploadStatus.completed:
          taskStatus = TaskStatusEnum.completed;
          break;
        case UploadStatus.failed:
          taskStatus = TaskStatusEnum.failed;
          break;
        case UploadStatus.cancelled:
          taskStatus = TaskStatusEnum.cancelled;
          break;
        case UploadStatus.paused:
          taskStatus = TaskStatusEnum.paused;
          break;
        case UploadStatus.uploading:
          taskStatus = TaskStatusEnum.processing;
          break;
        default:
          taskStatus = TaskStatusEnum.processing;
      }
      await _taskManager.updateTask(
        taskId,
        (oldTask) => oldTask.copyWith(
          status: taskStatus,
          progress: status == UploadStatus.completed ? 1.0 : oldTask.progress,
        ),
      );
    }
  }

  @override
  Future<void> resumeTask(Task task) async {
    final videoUploadTask = task as VideoUploadTask;

    await _fileUploader.startOrRetryUpload(
      videoUploadTask.uploadTaskId,
      onProgress: (uploadTask) => _onProgress(
        videoUploadTask.id,
        uploadTask.progress,
        uploadTask.uploadedChunksCount,
        uploadTask.totalChunksCount,
      ),
      onStatus: (status, error, uploadTask) =>
          _onStatus(videoUploadTask.id, status, error, uploadTask),
    );
  }

  @override
  Future<void> cancelTask(Task task) async {
    final videoUploadTask = task as VideoUploadTask;

    await _fileUploader.cancelUpload(videoUploadTask.uploadTaskId);

    final taskById = _taskManager.getTaskById(videoUploadTask.id);
    if (taskById != null) {
      await _taskManager.updateTask(
        videoUploadTask.id,
        (oldTask) => oldTask.copyWith(status: TaskStatusEnum.cancelled),
      );
    }
  }

  @override
  String getCreateTableSql() {
    return '''
    CREATE TABLE IF NOT EXISTS $videoUploadTable (
      uploadTaskId TEXT NOT NULL
    )
    ''';
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    final videoUploadTask = task as VideoUploadTask;
    return {'uploadTaskId': videoUploadTask.uploadTaskId};
  }

  @override
  String getTableName() {
    return videoUploadTable;
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
      tasks.add(VideoUploadTask.fromJson({...mainTask, ...subTask}));
    }
    return tasks;
  }

  @override
  Future<void> processTask(Task task) async {
    final videoUploadTask = task as VideoUploadTask;

    final uploadId = videoUploadTask.uploadTaskId;
    final uploadTask = _fileUploader.getTask(uploadId);
    if (uploadTask == null) {
      throw Exception('Upload task not found: $uploadId');
    }

    await _fileUploader.startOrRetryUpload(
      uploadId,
      onProgress: (uploadTask) async {
        // 更新TaskManager中的任务进度
        final task = _taskManager.getTaskById(videoUploadTask.id);
        if (task != null) {
          await _taskManager.updateTask(
            videoUploadTask.id,
            (oldTask) => oldTask.copyWith(
              progress: oldTask.progress,
              status: TaskStatusEnum.processing,
            ),
          );
        }
      },
      onStatus: (status, error, uploadTask) async {
        // 更新TaskManager中的任务状态
        final task = _taskManager.getTaskById(videoUploadTask.id);
        if (task != null) {
          TaskStatusEnum taskStatus;
          switch (status) {
            case UploadStatus.completed:
              taskStatus = TaskStatusEnum.completed;
              break;
            case UploadStatus.failed:
              taskStatus = TaskStatusEnum.failed;
              break;
            case UploadStatus.cancelled:
              taskStatus = TaskStatusEnum.cancelled;
              break;
            case UploadStatus.paused:
              taskStatus = TaskStatusEnum.paused;
              break;
            case UploadStatus.uploading:
              taskStatus = TaskStatusEnum.processing;
              break;
            default:
              taskStatus = TaskStatusEnum.processing;
          }

          await _taskManager.updateTask(
            videoUploadTask.id,
            (oldTask) => oldTask.copyWith(
              status: taskStatus,
              progress: status == UploadStatus.completed
                  ? 1.0
                  : oldTask.progress,
            ),
          );
        }
      },
    );
  }

  @override
  bool supportsPause(Task task) => task.supportsPause;

  @override
  Task copyTask(Task task) {
    final videoUploadTask = task as VideoUploadTask;
    return videoUploadTask.copyWith();
  }
}
