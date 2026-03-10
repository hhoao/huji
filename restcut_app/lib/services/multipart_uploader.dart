import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/upload.dart';

typedef UploadProgressCallback = Future<void> Function(UploadTask task);
typedef UploadStatusCallback =
    Future<void> Function(
      UploadStatus status,
      String? error,
      UploadTask uploadTask,
    );

class MultipartUploader {
  static final MultipartUploader _instance = MultipartUploader._internal();
  factory MultipartUploader() => _instance;
  MultipartUploader._internal() {
    _loadTasks();
  }

  final Map<String, UploadTask> _tasks = {};
  final String _storageFileName = 'upload_tasks.json';

  // 获取所有任务
  List<UploadTask> get tasks => _tasks.values.toList();

  // 获取指定状态的任务
  List<UploadTask> getTasksByStatus(UploadStatus status) {
    return _tasks.values.where((task) => task.status == status).toList();
  }

  // 获取指定任务
  UploadTask? getTask(String taskId) => _tasks[taskId];

  // 创建上传任务
  Future<UploadTask> createUploadTask({
    required String filePath,
    required String fileName,
    String? directory,
    String? contentType,
    int chunkSize = 5 * 1024 * 1024, // 5MB
    int maxRetries = 3,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final fileSize = await file.length();
    final taskId =
        '${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}';

    // 计算分片信息
    final chunks = <ChunkInfo>[];
    for (int i = 0; i < (fileSize / chunkSize).ceil(); i++) {
      final startByte = i * chunkSize;
      final endByte = (i + 1) * chunkSize > fileSize
          ? fileSize
          : (i + 1) * chunkSize;
      chunks.add(
        ChunkInfo(partNumber: i + 1, startByte: startByte, endByte: endByte),
      );
    }

    final task = UploadTask(
      id: taskId,
      filePath: filePath,
      fileName: fileName,
      directory: directory,
      contentType: contentType ?? _getContentType(fileName),
      fileSize: fileSize,
      chunkSize: chunkSize,
      chunks: chunks,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      maxRetries: maxRetries,
    );

    _tasks[taskId] = task;
    await _saveTasks();

    return task;
  }

  // 开始上传任务
  Future<void> startOrRetryUpload(
    String taskId, {
    UploadProgressCallback? onProgress,
    UploadStatusCallback? onStatus,
  }) async {
    UploadTask task = _tasks[taskId]!;

    if (task.status == UploadStatus.cancelled) {
      return;
    }
    if (!task.canRetry) {
      await onTaskFailed(task, onStatus, Exception('Task cannot be retried'));
      return;
    }

    try {
      await beforeTaskUpload(task, onStatus);

      await _startUploadFile(task, onProgress: onProgress);

      if (await checkAndUpdateNotProcessingTaskStatus(task, onStatus)) {
        return;
      }

      await onTaskCompleted(task, onStatus);
    } catch (e) {
      await onTaskFailed(task, onStatus, e);
    }
  }

  Future<void> _startUploadFile(
    UploadTask task, {
    UploadProgressCallback? onProgress,
    UploadStatusCallback? onStatus,
  }) async {
    // 1. 创建分片上传会话（如果还没有）
    String uploadId = task.uploadId ?? '';
    String path = task.path ?? '';

    if (uploadId.isEmpty) {
      final createResponse = await Api.video.createMultipartUpload(
        MultipartUploadReqVO(
          name: task.fileName,
          directory: task.directory,
          contentType: task.contentType,
        ),
      );

      // 请求预签名URL获取uploadId
      uploadId = await _getUploadIdFromPresignedUrl(createResponse.uploadUrl);
      path = createResponse.path ?? '';

      if (uploadId.isEmpty || path.isEmpty) {
        throw Exception('Failed to create multipart upload session');
      }
      task.uploadId = uploadId;
      task.path = path;
      await _updateTask(task);
    }

    // 2. 上传未完成的分片
    final unuploadedChunks = task.chunks.where((c) => !c.isUploaded).toList();
    for (int i = 0; i < unuploadedChunks.length; i++) {
      if (await checkAndUpdateNotProcessingTaskStatus(task, onStatus)) {
        return;
      }

      final chunk = unuploadedChunks[i];

      try {
        // 获取分片上传预签名URL
        final partResponse = await Api.video.getUploadPartPresignedUrl(
          MultipartUploadPartReqVO(
            uploadId: uploadId,
            path: path,
            partNumber: chunk.partNumber,
          ),
        );

        // 读取分片数据
        final file = File(task.filePath);
        final chunkData = await file
            .openRead(chunk.startByte, chunk.endByte)
            .toList()
            .then((list) => Uint8List.fromList(list.expand((e) => e).toList()));

        // 上传分片
        final dio = Dio();
        final uploadResponse = await dio.put(
          partResponse.uploadUrl,
          data: chunkData,
          options: Options(
            headers: {'Content-Type': 'application/octet-stream'},
          ),
        );

        // 获取ETag
        final eTag = uploadResponse.headers.value('ETag')?.replaceAll('"', '');
        if (eTag == null) {
          throw Exception('Failed to get ETag for part ${chunk.partNumber}');
        }

        // 更新分片信息
        final updatedChunk = chunk.copyWith(
          eTag: eTag,
          isUploaded: true,
          uploadedAt: DateTime.now().millisecondsSinceEpoch,
        );
        task.chunks[task.chunks.indexWhere(
              (c) => c.partNumber == chunk.partNumber,
            )] =
            updatedChunk;

        // 更新进度
        final progress = (i + 1) / unuploadedChunks.length;
        task.progress = progress;
        task.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _updateTask(task);

        await onProgress?.call(task);
      } catch (e, stackTrace) {
        AppLogger().e(
          'Failed to upload chunk ${chunk.partNumber}: $e',
          stackTrace,
          e,
        );
      }
    }

    if (await checkAndUpdateNotProcessingTaskStatus(task, onStatus)) {
      return;
    }

    if (task.multipartUploaded) {
      return;
    }

    final completedChunks = task.chunks.where((c) => c.isUploaded).toList();
    if (completedChunks.length == task.totalChunksCount) {
      final completeResponse = await Api.video
          .getCompleteMultipartUploadPresignedUrl(
            MultipartCompleteReqVO(
              uploadId: uploadId,
              path: path,
              parts: completedChunks
                  .map(
                    (c) =>
                        CompletedPart(partNumber: c.partNumber, eTag: c.eTag!),
                  )
                  .toList(),
            ),
          );

      final dio = Dio();

      // 构建完成分片上传的XML数据
      final completedParts = completedChunks
          .map((c) => CompletedPart(partNumber: c.partNumber, eTag: c.eTag!))
          .toList();
      final completeXml = _buildCompleteMultipartUploadXml(completedParts);

      await dio.post(
        completeResponse.uploadUrl,
        data: completeXml,
        options: Options(headers: {'Content-Type': 'application/xml'}),
      );

      task.progress = 1.0;
      task.updatedAt = DateTime.now().millisecondsSinceEpoch;
      task.configId = completeResponse.configId;
      task.uploadUrl = completeResponse.uploadUrl;
      task.remotePath = completeResponse.path;
      task.multipartUploaded = true;

      await _updateTask(task);

      await onProgress?.call(task);
    } else {
      throw Exception('Some chunks failed to upload');
    }
  }

  // 暂停上传任务
  Future<void> pauseUpload(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    await _updateTask(
      task.copyWith(
        status: UploadStatus.paused,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // 取消上传任务
  Future<void> cancelUpload(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    if (task.status == UploadStatus.uploading &&
        task.uploadId != null &&
        task.path != null) {
      try {
        // 尝试中止分片上传
        final abortResponse = await Api.video
            .getAbortMultipartUploadPresignedUrl(
              MultipartAbortReqVO(uploadId: task.uploadId!, path: task.path!),
            );

        final dio = Dio();
        await dio.delete(abortResponse.uploadUrl);
      } catch (e, stackTrace) {
        AppLogger().e('Failed to abort upload: $e', stackTrace, e);
      }
    }

    await _updateTask(
      task.copyWith(
        status: UploadStatus.cancelled,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // 删除上传任务
  Future<void> deleteTask(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) {
      return;
    }

    // 如果任务正在上传，先取消
    if (task.status == UploadStatus.uploading) {
      await cancelUpload(taskId);
    }

    _tasks.remove(taskId);
    await _saveTasks();
  }

  // 清理已完成的任务
  Future<void> cleanupCompletedTasks() async {
    final completedTasks = _tasks.values
        .where((task) => task.status == UploadStatus.completed)
        .map((task) => task.id)
        .toList();

    for (final taskId in completedTasks) {
      _tasks.remove(taskId);
    }

    await _saveTasks();
  }

  // 更新任务
  Future<void> _updateTask(UploadTask task) async {
    _tasks[task.id] = task;
    await _saveTasks();
  }

  // 保存任务到本地存储
  Future<void> _saveTasks() async {
    try {
      final appDocDir = storage.getApplicationDocumentsDirectory();
      final file = File('${appDocDir.path}/$_storageFileName');

      final tasksJson = _tasks.values.map((task) => task.toJson()).toList();
      await file.writeAsString(jsonEncode(tasksJson));
    } catch (e, stackTrace) {
      AppLogger().e('Failed to save tasks: $e', stackTrace, e);
    }
  }

  // 从本地存储加载任务
  Future<void> _loadTasks() async {
    try {
      final appDocDir = storage.getApplicationDocumentsDirectory();
      final file = File('${appDocDir.path}/$_storageFileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        final tasksJson = jsonDecode(content) as List;

        _tasks.clear();
        for (final taskJson in tasksJson) {
          final task = UploadTask.fromJson(taskJson);
          _tasks[task.id] = task;
        }
      }
    } catch (e, stackTrace) {
      AppLogger().e('Failed to load tasks: $e', stackTrace, e);
    }
  }

  // 获取文件内容类型
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  // 从预签名URL请求获取uploadId
  Future<String> _getUploadIdFromPresignedUrl(String presignedUrl) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        presignedUrl,
        options: Options(headers: {'Content-Type': 'application/xml'}),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data.toString();
        return _extractUploadIdFromXml(responseBody);
      } else {
        throw Exception('创建多部分上传失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger().e('请求预签名URL失败: $e', stackTrace, e);
      throw Exception('请求预签名URL失败: $e');
    }
  }

  /// \<InitiateMultipartUploadResult\>
  /// \<Bucket\>example-bucket\</Bucket\>
  /// \<Key\>example-key\</Key\>
  /// \<UploadId\>abc123def456\</UploadId\>
  /// \</InitiateMultipartUploadResult\>
  String _extractUploadIdFromXml(String xmlResponse) {
    try {
      // 简化的XML解析，查找<UploadId>标签
      final startIndex = xmlResponse.indexOf('<UploadId>');
      final endIndex = xmlResponse.indexOf('</UploadId>');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        return xmlResponse.substring(startIndex + 10, endIndex);
      }

      // 如果找不到标准格式，尝试其他可能的格式
      final uploadIdPattern = RegExp(r'<UploadId[^>]*>([^<]+)</UploadId>');
      final match = uploadIdPattern.firstMatch(xmlResponse);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!;
      }

      throw Exception('无法从XML响应中提取uploadId: $xmlResponse');
    } catch (e) {
      throw Exception('解析XML响应失败: $e');
    }
  }

  /// 构建完成分片上传的XML数据
  ///
  /// 格式示例：
  /// \<CompleteMultipartUpload\>
  ///   \<Part\>
  ///     \<PartNumber\>1\</PartNumber\>
  ///     \<ETag\>"abc123"\</ETag\>
  ///   \</Part\>
  ///   \<Part\>
  ///     \<PartNumber\>2\</PartNumber\>
  ///     \<ETag\>"def456"\</ETag\>
  ///   \</Part\>
  /// \</CompleteMultipartUpload\>
  String _buildCompleteMultipartUploadXml(List<CompletedPart> parts) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<CompleteMultipartUpload>');

    // 按分片号排序
    final sortedParts = List<CompletedPart>.from(parts)
      ..sort((a, b) => a.partNumber.compareTo(b.partNumber));

    for (final part in sortedParts) {
      buffer.writeln('  <Part>');
      buffer.writeln('    <PartNumber>${part.partNumber}</PartNumber>');
      buffer.writeln('    <ETag>"${part.eTag}"</ETag>');
      buffer.writeln('  </Part>');
    }

    buffer.writeln('</CompleteMultipartUpload>');
    return buffer.toString();
  }

  Future<void> beforeTaskUpload(
    UploadTask task,
    UploadStatusCallback? onStatus,
  ) async {
    if (task.status != UploadStatus.paused) {
      task.retryCount++;
    }
    task.status = UploadStatus.uploading;
    task.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _updateTask(task);
    await onStatus?.call(UploadStatus.uploading, null, task);
  }

  Future<void> onTaskFailed(
    UploadTask task,
    UploadStatusCallback? onStatus,
    Object error,
  ) async {
    AppLogger().e('Task failed', StackTrace.current, error);
    task.status = UploadStatus.failed;
    task.error = error.toString();
    task.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _updateTask(task);
    await onStatus?.call(UploadStatus.failed, error.toString(), task);
  }

  Future<void> onTaskCompleted(
    UploadTask task,
    UploadStatusCallback? onStatus,
  ) async {
    task.status = UploadStatus.completed;
    task.progress = 1.0;
    task.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _updateTask(task);
    await onStatus?.call(UploadStatus.completed, null, task);
  }

  Future<bool> checkAndUpdateNotProcessingTaskStatus(
    UploadTask task,
    UploadStatusCallback? onStatus,
  ) async {
    if (task.status == UploadStatus.cancelled ||
        task.status == UploadStatus.paused) {
      await onStatus?.call(task.status, null, task);
      return true;
    }
    return false;
  }

  bool isCompleted(String taskId) {
    final task = _tasks[taskId];
    if (task == null) {
      return false;
    }
    return task.status == UploadStatus.completed;
  }

  UploadTask? getTaskById(String uploadTaskId) {
    return _tasks[uploadTaskId];
  }
}
