import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;
import 'package:get/get_utils/get_utils.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/constants/global.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/models/upload.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/services/multipart_uploader.dart';
import 'package:restcut/services/websocket_service.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/user.dart';
import 'package:restcut/store/video.dart';

class StateNotMatchException implements Exception {
  final String message;
  StateNotMatchException(this.message);
}

class VideoClipTaskManager extends AbstractTaskManager {
  static const String videoClipTable = 'video_clip_tasks';
  StreamSubscription? _websocketSubscription;
  final TaskStorage _taskRunner;
  final MultipartUploader _multipartUploader = MultipartUploader();
  final double _uploadProgress = 0.1;
  final double _clipProgress = 0.8;

  VideoClipTaskManager(this._taskRunner);

  Future<void> _onProgress(String taskId, UploadTask uploadTask) async {
    Task? latestTask = _taskRunner.getTaskById(taskId);
    if (latestTask != null) {
      await _taskRunner.updateTask(
        taskId,
        (oldTask) =>
            oldTask.copyWith(progress: uploadTask.progress * _uploadProgress),
      );
    }
    if (latestTask != null) {
      if (latestTask.status == TaskStatusEnum.paused) {
        await _multipartUploader.pauseUpload(uploadTask.id);
        return;
      } else if (latestTask.status == TaskStatusEnum.cancelled) {
        await _multipartUploader.cancelUpload(uploadTask.id);
        return;
      }
    }
  }

  Future<void> _onStatus(
    String taskId,
    UploadStatus status,
    String? error,
    UploadTask uploadTask,
  ) async {
    VideoClipTask latestTask =
        _taskRunner.getTaskById(taskId)! as VideoClipTask;
    if (latestTask.status == TaskStatusEnum.paused) {
      await _multipartUploader.pauseUpload(uploadTask.id);
      return;
    } else if (latestTask.status == TaskStatusEnum.cancelled) {
      await _multipartUploader.cancelUpload(uploadTask.id);
      return;
    }
    await _taskRunner.updateTask(taskId, (oldTask) {
      final task = oldTask as VideoClipTask;
      if (status == UploadStatus.completed) {
        return task.copyWith(
          presignedUrl: uploadTask.uploadUrl,
          presignedPath: uploadTask.remotePath,
          presignedConfigId: uploadTask.configId,
          status: TaskStatusEnum.processing,
          supportsPause: false,
          uploadTaskId: uploadTask.id,
        );
      } else if (status == UploadStatus.failed) {
        return task.copyWith(
          status: TaskStatusEnum.failed,
          extraInfo: error,
          supportsPause: false,
          uploadTaskId: uploadTask.id,
        );
      } else if (status == UploadStatus.uploading) {
        return task.copyWith(
          supportsPause: true,
          status: TaskStatusEnum.processing,
          uploadTaskId: uploadTask.id,
        );
      }
      return task.copyWith(uploadTaskId: uploadTask.id);
    });
  }

  Future<FileInfo?> _tryUploadFile(VideoClipTask task) async {
    FileInfo? uploadResult;
    // 1. 检查是否已经上传过
    if (task.uploadTaskId == null ||
        !_multipartUploader.isCompleted(task.uploadTaskId!)) {
      await _multipartUploader.startOrRetryUpload(
        task.uploadTaskId!,
        onProgress: (uploadTask) => _onProgress(task.id, uploadTask),
        onStatus: (status, error, uploadTask) =>
            _onStatus(task.id, status, error, uploadTask),
      );
    }
    if (!_multipartUploader.isCompleted(task.uploadTaskId!)) {
      return null;
    }
    task = _taskRunner.getTaskById(task.id) as VideoClipTask;
    uploadResult = FileInfo(
      configId: task.presignedConfigId,
      url: task.presignedUrl!,
      path: task.presignedPath ?? '',
      name: task.videoPath.split('/').last,
      type: 'video/mp4',
      size: await File(task.videoPath).length(),
    );
    return uploadResult;
  }

  void _checkTaskStatus(VideoClipTask task) {
    if (task.status != TaskStatusEnum.processing &&
        task.status != TaskStatusEnum.pending) {
      throw StateNotMatchException(
        'Task is not processing or pending, current status: ${task.status}',
      );
    }
  }

  @override
  Future<void> processTask(Task task) async {
    VideoClipTask currentTask = task as VideoClipTask;
    await _startTask(currentTask);
  }

  Future<void> _startTask(VideoClipTask task) async {
    _startWebSocketListener();
    VideoClipTask currentTask = task.copyWith(supportsPause: false);
    try {
      currentTask =
          await _taskRunner.updateTask(
                task.id,
                (oldTask) =>
                    (oldTask as VideoClipTask).copyWith(supportsPause: false),
              )
              as VideoClipTask;

      _checkTaskStatus(currentTask);
      FileInfo? fileInfo = await _tryUploadFile(currentTask);
      currentTask = _taskRunner.getTaskById(currentTask.id) as VideoClipTask;
      if (fileInfo == null) {
        if (currentTask.status == TaskStatusEnum.paused ||
            currentTask.status == TaskStatusEnum.cancelled) {
          return;
        }
        currentTask =
            await _taskRunner.updateTask(
                  task.id,
                  (oldTask) => (oldTask as VideoClipTask).copyWith(
                    status: TaskStatusEnum.failed,
                  ),
                )
                as VideoClipTask;
        return;
      }

      currentTask =
          await _taskRunner.updateTask(
                task.id,
                (oldTask) =>
                    (oldTask as VideoClipTask).copyWith(supportsPause: false),
              )
              as VideoClipTask;

      _checkTaskStatus(currentTask);

      final recordId = await _callBackendClipApi(
        fileInfo,
        task.clipConfig,
        task.sportType,
      );
      if (recordId == null) {
        currentTask =
            await _taskRunner.updateTask(
                  task.id,
                  (oldTask) => (oldTask as VideoClipTask).copyWith(
                    status: TaskStatusEnum.failed,
                  ),
                )
                as VideoClipTask;
        return;
      }

      currentTask =
          await _taskRunner.updateTask(
                task.id,
                (oldTask) => (oldTask as VideoClipTask).copyWith(
                  processRecordId: recordId,
                ),
              )
              as VideoClipTask;

      _checkTaskStatus(currentTask);
      _startWebSocketListener();
    } catch (e, stackTrace) {
      if (e is UpdateTaskOnPauseError) {
        AppLogger().i('Update task on pause: ${e.message}');
        return;
      }
      if (e is StateNotMatchException) {
        AppLogger().i('State not match: ${e.message}');
        return;
      }
      AppLogger().e('Error processing task: $e', stackTrace, e);

      currentTask =
          await _taskRunner.updateTask(
                task.id,
                (oldTask) => (oldTask as VideoClipTask).copyWith(
                  status: TaskStatusEnum.failed,
                  extraInfo: e.toString(),
                ),
              )
              as VideoClipTask;
    }
  }

  // 启动WebSocket监听器
  void _startWebSocketListener() {
    final token = UserStore.currentToken?.refreshToken ?? '';
    if (token.isEmpty) {
      return;
    }

    GlobalWebSocketService.connect(Global.wsUrl, token);

    _websocketSubscription = GlobalWebSocketService.progressStream.listen(
      (progress) async {
        await _processWebSocketProgress(progress);
      },
      onError: (error) {
        AppLogger().e('WebSocket error: $error', StackTrace.current, error);
      },
    );
  }

  Future<void> _processWebSocketProgress(
    VideoProcessProgressVO progress,
  ) async {
    try {
      VideoClipTask? currentTask = _taskRunner.tasks
          .where(
            (t) =>
                t is VideoClipTask &&
                (t).processRecordId == progress.videoProcessRecordId,
          )
          .cast<VideoClipTask>()
          .firstOrNull;

      if (currentTask != null) {
        _checkTaskStatus(currentTask);
        final normalizedProgress = progress.progress.clamp(0.0, 1.0);
        final mappedProgress =
            _uploadProgress + (normalizedProgress * _clipProgress);

        currentTask =
            await _taskRunner.updateTask(
                  currentTask.id,
                  (oldTask) => (oldTask as VideoClipTask).copyWith(
                    progress: mappedProgress,
                    status: TaskStatusEnum.processing,
                  ),
                )
                as VideoClipTask;

        String? outputPath = progress.url;

        if (progress.status == ProcessStatus.completed) {
          if (currentTask.autoDownload && (progress.url?.isNotEmpty ?? false)) {
            final localPath = await _downloadVideo(progress.url!);
            outputPath = localPath;
          }
          currentTask =
              await _taskRunner.updateTask(
                    currentTask.id,
                    (oldTask) => (oldTask as VideoClipTask).copyWith(
                      status: TaskStatusEnum.completed,
                      outputPath: outputPath,
                      progress: 1.0,
                    ),
                  )
                  as VideoClipTask;
        } else if (progress.status == ProcessStatus.failed) {
          currentTask =
              await _taskRunner.updateTask(
                    currentTask.id,
                    (oldTask) => (oldTask as VideoClipTask).copyWith(
                      status: TaskStatusEnum.failed,
                    ),
                  )
                  as VideoClipTask;
        }
        await _updateProcessRecordProgress(progress);
      }
    } catch (e, stackTrace) {
      if (e is StateNotMatchException) {
        return;
      }
      AppLogger().e('Error processing WebSocket progress: $e', stackTrace, e);
    }
  }

  // 下载视频到本地
  Future<String> _downloadVideo(String url) async {
    var file = await cache.DefaultCacheManager().getSingleFile(url);
    return file.path;
  }

  // 调用后端剪辑API，返回recordId
  Future<int?> _callBackendClipApi(
    FileInfo fileInfo,
    VideoClipConfigReqVo? clipConfig,
    SportType? sportType,
  ) async {
    try {
      int? recordId;
      if (sportType == SportType.pingpong) {
        final request = PingPongAutoClipParams(
          fileInfo: FileCreateReqVO(
            name: fileInfo.name,
            url: fileInfo.url,
            type: fileInfo.type,
            size: fileInfo.size,
            configId: fileInfo.configId,
            path: fileInfo.path,
          ),
          videoClipConfig: clipConfig as PingPongVideoClipConfigReqVo?,
        );
        recordId = await Api.clip.autoPingpongClipVideo(request);
      } else if (sportType == SportType.badminton) {
        final request = BadmintonAutoClipParams(
          fileInfo: FileCreateReqVO(
            name: fileInfo.name,
            url: fileInfo.url,
            type: fileInfo.type,
            size: fileInfo.size,
            configId: fileInfo.configId,
            path: fileInfo.path,
          ),
          videoClipConfig: clipConfig as BadmintonVideoClipConfigReqVo?,
        );
        recordId = await Api.clip.processBadmintonClip(request);
      } else {
        throw Exception('Unsupported sport type: $sportType');
      }
      return recordId;
    } catch (e, stackTrace) {
      AppLogger().e('Error calling backend clip API: $e', stackTrace, e);
      return null;
    }
  }

  @override
  Future<List<Task>> loadTasks(
    List<Map<String, dynamic>> mainTasks,
    List<Map<String, dynamic>> subTasks,
  ) async {
    List<VideoClipTask> videoClipTasks = [];
    for (final mainTask in mainTasks) {
      final subTask = subTasks.firstWhere(
        (subTask) => subTask['taskId'] == mainTask['id'],
      );
      final videoClipTask = VideoClipTask.fromJson({...mainTask, ...subTask});
      videoClipTasks.add(videoClipTask);
    }
    List<VideoClipTask> processingVideoClipTasks = [];
    for (final videoClipTask in videoClipTasks) {
      if (videoClipTask.status == TaskStatusEnum.processing &&
          videoClipTask.processRecordId != null) {
        processingVideoClipTasks.add(videoClipTask);
      }
    }
    if (processingVideoClipTasks.isNotEmpty) {
      final videoClipTaskIds = processingVideoClipTasks
          .map((t) => t.processRecordId!)
          .toList();
      final processRecords = await Api.clip.getVideoProcessRecords(
        VideoProcessRecordFilterParam(
          ids: videoClipTaskIds,
          status: ProcessStatus.processing.value,
        ),
      );

      for (final processingVideoClipTask in processingVideoClipTasks) {
        VideoProcessRecordVO? processRecord = processRecords.list
            .firstWhereOrNull(
              (t) => t.id == processingVideoClipTask.processRecordId,
            );
        if (processRecord != null) {
          if (processRecord.status == ProcessStatus.processing) {
            processingVideoClipTask.status = TaskStatusEnum.processing;
            processingVideoClipTask.progress = processRecord.progress;
          } else if (processRecord.status == ProcessStatus.completed) {
            processingVideoClipTask.status = TaskStatusEnum.completed;
            processingVideoClipTask.progress = 1.0;
            if (processingVideoClipTask.autoDownload) {
              final videoInfo = await Api.video.getVideoInfo(
                processRecord.outputVideoId!,
              );
              final localPath = await _downloadVideo(videoInfo.fileUrl);
              processingVideoClipTask.outputPath = localPath;
            }
          } else if (processRecord.status == ProcessStatus.failed) {
            processingVideoClipTask.status = TaskStatusEnum.failed;
          }
          processingVideoClipTask.extraInfo = processRecord.extraInfo;
        }
      }
    }
    return videoClipTasks;
  }

  LocalVideoProcessStatusEnum _processStatusToLocalVideoProcessStatusEnum(
    ProcessStatus processStatus,
  ) {
    return LocalVideoProcessStatusEnum.values.firstWhere(
      (e) => e.value == processStatus.value,
    );
  }

  // 更新ProcessVideoRecord的进度
  Future<void> _updateProcessRecordProgress(
    VideoProcessProgressVO progress,
  ) async {
    final processRecord = await LocalVideoStorage()
        .findProcessRecordByProcessRecordId(progress.videoProcessRecordId!);
    if (processRecord != null) {
      await LocalVideoStorage().update(processRecord.id, (record) {
            final process = record as ProcessVideoRecord;
            return process.copyWith(
              processStatus: _processStatusToLocalVideoProcessStatusEnum(
                progress.status,
              ),
            );
          })
          as ProcessVideoRecord;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _websocketSubscription?.cancel();
    _websocketSubscription = null;
  }

  @override
  String getTableName() {
    return videoClipTable;
  }

  @override
  Future<void> pauseTask(Task task) async {}

  @override
  Future<void> resumeTask(Task task) async {
    VideoClipTask videoClipTask = task as VideoClipTask;
    videoClipTask =
        await _taskRunner.updateTask(
              videoClipTask.id,
              (oldTask) => (oldTask as VideoClipTask).copyWith(
                status: TaskStatusEnum.pending,
              ),
            )
            as VideoClipTask;
    await _startTask(videoClipTask);
  }

  @override
  Future<void> retryTask(Task task) async {
    final videoClipTask = task as VideoClipTask;
    await processTask(videoClipTask);
  }

  @override
  Future<void> cancelTask(Task task) async {}

  @override
  String getCreateTableSql() {
    return '''
          CREATE TABLE IF NOT EXISTS $videoClipTable (
            taskId TEXT PRIMARY KEY,
            videoPath TEXT NOT NULL,
            outputPath TEXT NOT NULL,
            autoDownload INTEGER NOT NULL,
            clipConfig TEXT,
            processRecordId INTEGER,
            presignedUrl TEXT,
            presignedPath TEXT,
            presignedConfigId INTEGER,
            uploadTaskId TEXT,
            sportType INTEGER
          )
        ''';
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    VideoClipTask videoClipTask = task as VideoClipTask;
    return {
      'taskId': videoClipTask.id,
      'videoPath': videoClipTask.videoPath,
      'outputPath': videoClipTask.outputPath,
      'autoDownload': videoClipTask.autoDownload ? 1 : 0,
      'clipConfig': videoClipTask.clipConfig != null
          ? jsonEncode(videoClipTask.clipConfig!.toJson())
          : '',
      'processRecordId': videoClipTask.processRecordId,
      'presignedUrl': videoClipTask.presignedUrl,
      'presignedPath': videoClipTask.presignedPath,
      'presignedConfigId': videoClipTask.presignedConfigId,
      'uploadTaskId': videoClipTask.uploadTaskId,
      'sportType': videoClipTask.sportType?.value,
    };
  }

  @override
  bool supportsPause(Task task) => task.supportsPause;

  @override
  Task copyTask(Task task) {
    final videoClipTask = task as VideoClipTask;
    return videoClipTask.copyWith();
  }
}
