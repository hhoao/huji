import 'dart:io';

import 'package:flutter/material.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';
import 'package:restcut/services/multipart_uploader.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/task/video_upload_task_manager.dart';

class FileUploaderTestTab extends StatefulWidget {
  const FileUploaderTestTab({super.key});

  @override
  State<FileUploaderTestTab> createState() => _FileUploaderTestTabState();
}

class _FileUploaderTestTabState extends State<FileUploaderTestTab> {
  final TaskStorage _taskStorage = TaskStorage();
  final MultipartUploader _multipartUploader = MultipartUploader();

  final List<VideoUploadTask> _uploadTasks = [];
  bool _isLoading = false;
  String? _selectedFileInfo;
  File? _selectedFile;

  // 配置选项
  int _chunkSize = 5 * 1024 * 1024; // 5MB
  final String _uploadDirectory = 'test_uploads';
  int _maxRetries = 3;
  bool _showDetailedLogs = false;
  final List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = false);
  }

  void _addLog(String message) {
    if (_showDetailedLogs) {
      setState(() {
        _logMessages.add(
          '${DateTime.now().toString().substring(11, 19)}: $message',
        );
        if (_logMessages.length > 50) {
          _logMessages.removeAt(0);
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FileSelection.selectVideos(
        context: context,
        allowMultiple: false,
      );

      if (result != null && result.isNotEmpty) {
        final file = File(result.first.path);
        final fileName = result.first.path.split('/').last;
        final fileSize = await file.length();

        setState(() {
          _selectedFile = file;
          _selectedFileInfo = '$fileName (${_formatFileSize(fileSize)})';
        });

        _addLog('选择了文件: $fileName');
      }
    } catch (e) {
      _addLog('选择文件失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createUploadTask() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择文件'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final task = await VideoUploadTaskManager.createUploadTask(
        filePath: _selectedFile!.path,
        fileName: _selectedFile!.path.split('/').last,
        directory: _uploadDirectory,
        contentType: 'video/mp4',
        chunkSize: _chunkSize,
        maxRetries: _maxRetries,
      );
      await _taskStorage.addAndAsyncProcessTask(task);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建上传任务成功: ${task.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _addLog('创建上传任务失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建上传任务失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startUpload(String taskId) async {
    try {
      _addLog('开始上传任务: $taskId');
      final task = _taskStorage.getTaskById(taskId);
      if (task != null) {
        await _taskStorage.retryTask(task);
      }
    } catch (e) {
      _addLog('开始上传失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('开始上传失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _retryUpload(String taskId) async {
    try {
      _addLog('重试上传任务: $taskId');
      final task = _taskStorage.getTaskById(taskId);
      if (task != null) {
        await _taskStorage.retryTask(task);
      }
    } catch (e) {
      _addLog('重试上传失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('重试上传失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pauseUpload(String taskId) async {
    try {
      _addLog('暂停上传任务: $taskId');
      final task = _taskStorage.getTaskById(taskId);
      if (task != null) {
        await _taskStorage.pauseTask(task);
      }
    } catch (e) {
      _addLog('暂停上传失败: $e');
    }
  }

  Future<void> _resumeUpload(String taskId) async {
    try {
      _addLog('恢复上传任务: $taskId');
      final task = _taskStorage.getTaskById(taskId);
      if (task != null) {
        await _taskStorage.resumeTask(task);
      }
    } catch (e) {
      _addLog('恢复上传失败: $e');
    }
  }

  Future<void> _cancelUpload(String taskId) async {
    try {
      _addLog('取消上传任务: $taskId');
      final task = _taskStorage.getTaskById(taskId);
      if (task != null) {
        await _taskStorage.cancelTask(task);
      }
    } catch (e) {
      _addLog('取消上传失败: $e');
    }
  }

  Future<void> _deleteUploadTask(String taskId) async {
    try {
      _addLog('删除上传任务: $taskId');
      final task = _taskStorage.getTaskById(taskId);
      if (task != null) {
        await _taskStorage.deleteByTaskId(task.id);
      }
    } catch (e) {
      _addLog('删除上传任务失败: $e');
    }
  }

  Future<void> _retryAllFailed() async {
    try {
      _addLog('重试所有失败的上传任务');
      final tasks = _taskStorage.getTasksByTypeWithStatus(
        TaskTypeEnum.videoUpload,
        TaskStatusEnum.failed,
      );
      for (var task in tasks) {
        await _taskStorage.retryTask(task);
      }
    } catch (e) {
      _addLog('批量重试失败: $e');
    }
  }

  Future<void> _cleanupCompleted() async {
    try {
      _addLog('清理已完成的上传任务');
      final tasks = _taskStorage.getTasksByTypeWithStatus(
        TaskTypeEnum.videoUpload,
        TaskStatusEnum.completed,
      );
      for (var task in tasks) {
        await _taskStorage.deleteByTaskId(task.id);
      }
    } catch (e) {
      _addLog('清理任务失败: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getStatusText(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.pending:
        return '等待中';
      case TaskStatusEnum.processing:
        return '上传中';
      case TaskStatusEnum.paused:
        return '已暂停';
      case TaskStatusEnum.completed:
        return '已完成';
      case TaskStatusEnum.failed:
        return '失败';
      case TaskStatusEnum.cancelled:
        return '已取消';
    }
  }

  Color _getStatusColor(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.pending:
        return Colors.orange;
      case TaskStatusEnum.processing:
        return Colors.blue;
      case TaskStatusEnum.paused:
        return Colors.grey;
      case TaskStatusEnum.completed:
        return Colors.green;
      case TaskStatusEnum.failed:
        return Colors.red;
      case TaskStatusEnum.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '文件上传测试',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('当前文件: ${_selectedFileInfo ?? '未选择文件'}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickFile,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('选择文件'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _selectedFile == null
                            ? null
                            : _createUploadTask,
                        icon: const Icon(Icons.add_task),
                        label: const Text('创建任务'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('分片大小: '),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _chunkSize,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 1 * 1024 * 1024,
                            child: Text('1MB'),
                          ),
                          DropdownMenuItem(
                            value: 5 * 1024 * 1024,
                            child: Text('5MB'),
                          ),
                          DropdownMenuItem(
                            value: 10 * 1024 * 1024,
                            child: Text('10MB'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _chunkSize = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('重试次数: '),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _maxRetries,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 1, child: Text('1次')),
                          DropdownMenuItem(value: 3, child: Text('3次')),
                          DropdownMenuItem(value: 5, child: Text('5次')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _maxRetries = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _showDetailedLogs,
                      onChanged: (value) {
                        setState(() => _showDetailedLogs = value ?? false);
                      },
                    ),
                    const Text('显示详细日志'),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 批量操作
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _uploadTasks
                            .where((t) => t.status == TaskStatusEnum.failed)
                            .isEmpty
                        ? null
                        : _retryAllFailed,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试所有失败'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _uploadTasks
                            .where((t) => t.status == TaskStatusEnum.completed)
                            .isEmpty
                        ? null
                        : _cleanupCompleted,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('清理已完成'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 上传统计
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '上传统计',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _taskStorage.getTaskCounts().entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: entry.value > 0
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 上传任务列表
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '上传任务列表',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('共 ${_uploadTasks.length} 个任务'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _uploadTasks.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无上传任务',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Column(
                          children: _uploadTasks.map((task) {
                            final uploadTask = _multipartUploader.getTaskById(
                              task.uploadTaskId,
                            )!;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _getStatusColor(
                                            task.status,
                                          ),
                                          child: Text(
                                            uploadTask.uploadedChunksCount
                                                .toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '大小: ${_formatFileSize(uploadTask.fileSize)}',
                                              ),
                                              Text(
                                                '进度: ${(task.progress * 100).toStringAsFixed(1)}% (${uploadTask.uploadedChunksCount}/${uploadTask.totalChunksCount})',
                                              ),
                                              Text(
                                                '状态: ${_getStatusText(task.status)}',
                                              ),
                                              if (uploadTask.error != null)
                                                Text(
                                                  '错误: ${uploadTask.error}',
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (task.status ==
                                            TaskStatusEnum.pending)
                                          IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: () =>
                                                _startUpload(task.id),
                                          ),
                                        if (task.status ==
                                            TaskStatusEnum.processing)
                                          IconButton(
                                            icon: const Icon(Icons.pause),
                                            onPressed: () =>
                                                _pauseUpload(task.id),
                                          ),
                                        if (task.status ==
                                            TaskStatusEnum.paused)
                                          IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: () =>
                                                _resumeUpload(task.id),
                                          ),
                                        if (task.status ==
                                                TaskStatusEnum.failed &&
                                            uploadTask.canRetry)
                                          IconButton(
                                            icon: const Icon(Icons.refresh),
                                            onPressed: () =>
                                                _retryUpload(task.id),
                                          ),
                                        if (task.status ==
                                            TaskStatusEnum.processing)
                                          IconButton(
                                            icon: const Icon(Icons.stop),
                                            onPressed: () =>
                                                _cancelUpload(task.id),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () =>
                                              _deleteUploadTask(task.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ),

        // 详细日志
        if (_showDetailedLogs && _logMessages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '详细日志',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _logMessages.clear());
                        },
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logMessages[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
