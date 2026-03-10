import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/utils/file_utils.dart';

class DownloadProgressDialog extends StatefulWidget {
  final DownloadTask task;
  const DownloadProgressDialog({super.key, required this.task});

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  String _status = '准备下载...';
  bool _isCompleted = false;
  bool _isDownloading = false;
  String? _errorMessage;
  int _totalSize = 0;
  int _processedSize = 0;
  double _speed = 0.0;

  @override
  void initState() {
    super.initState();
    startTaskListener();
  }

  void startTaskListener() {
    TaskStorage().addTaskTypeListener(TaskTypeEnum.download, listenProgress);
  }

  void listenProgress() {
    if (!mounted) {
      return;
    }
    final task = TaskStorage().getTaskById(widget.task.id);
    if (task == null) {
      return;
    }
    if (mounted) {
      setState(() {
        _progress = task.progress;
        _totalSize = task.total ?? 0;
        _processedSize = task.processed ?? 0;
        _speed =
            _processedSize /
            (DateTime.now().millisecondsSinceEpoch - task.createdAt);
        _status = _getStatusText(task.status);
        _isCompleted = task.status == TaskStatusEnum.completed;
        _isDownloading = task.status == TaskStatusEnum.processing;
        _errorMessage = task.status == TaskStatusEnum.failed ? '下载失败' : null;
      });
    }
  }

  String _getStatusText(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.pending:
        return '等待中';
      case TaskStatusEnum.processing:
        return '下载中';
      case TaskStatusEnum.completed:
        return '下载完成';
      case TaskStatusEnum.failed:
        return '下载失败';
      case TaskStatusEnum.paused:
        return '已暂停';
      case TaskStatusEnum.cancelled:
        return '已取消';
    }
  }

  @override
  void dispose() {
    TaskStorage().removeTaskTypeListener(TaskTypeEnum.download, listenProgress);
    super.dispose();
  }

  Future<void> _openFolder(BuildContext context) async {
    try {
      final file = File(widget.task.savePath);
      if (await file.exists()) {
        await OpenFile.open(file.parent.path);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件不存在'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文件夹失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      final file = File(widget.task.savePath);
      if (await file.exists()) {
        await OpenFile.open(widget.task.savePath);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件不存在'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文件失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelOrStartTask() {
    if (widget.task.status == TaskStatusEnum.processing) {
      TaskStorage().cancelTask(widget.task);
      Navigator.of(context).pop();
    } else {
      TaskStorage().processTask(widget.task);
    }
  }

  void _minimizeToBackground() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('下载将在后台继续'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Icon(
            _isCompleted ? Icons.check_circle : Icons.download,
            color: _isCompleted ? Colors.green : Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage != null ? '下载失败' : '下载进度',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件名
          Text(
            widget.task.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 进度条
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(
                _isDownloading ? Colors.orange : Colors.blue,
              ),
            ),
            const SizedBox(height: 12),

            // 进度信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _status,
                  style: TextStyle(
                    color: _isDownloading ? Colors.orange : Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 下载速度和大小信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatBytesSize(_processedSize.toDouble())} / ${formatBytesSize(_totalSize.toDouble())}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '${formatBytesSize(_speed)}/s',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 保存路径
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '保存位置:',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  Text(
                    widget.task.savePath,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_isCompleted && _errorMessage == null) ...[
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'download_minimize',
                    const Duration(milliseconds: 500),
                    () => _minimizeToBackground(),
                  );
                },
                child: const Text('后台下载', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'download_cancel_start',
                    const Duration(milliseconds: 500),
                    () => _cancelOrStartTask(),
                  );
                },
                child: Text(
                  _isDownloading ? '取消' : '开始下载',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
            if (_isCompleted) ...[
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'download_open_file',
                    const Duration(milliseconds: 500),
                    () => _openFile(context),
                  );
                },
                child: const Text(
                  '打开文件',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'download_open_folder',
                    const Duration(milliseconds: 500),
                    () => _openFolder(context),
                  );
                },
                child: const Text(
                  '打开文件夹',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
