import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:open_file/open_file.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/file_utils.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class DownloadProgressDialog extends StatefulWidget {
  final DownloadTask task;
  const DownloadProgressDialog({super.key, required this.task});

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  String _status = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_status.isEmpty) {
      _status = context.hujiL10n.prepareDownload;
    }
  }
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
        _status = _getStatusText(context.hujiL10n, task.status);
        _isCompleted = task.status == TaskStatusEnum.completed;
        _isDownloading = task.status == TaskStatusEnum.processing;
        _errorMessage = task.status == TaskStatusEnum.failed
            ? context.hujiL10n.downloadFailed
            : null;
      });
    }
  }

  String _getStatusText(HujiLocalizations l10n, TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.pending => l10n.taskStatusPending,
      TaskStatusEnum.processing => l10n.downloadInProgress,
      TaskStatusEnum.completed => l10n.downloadCompleted,
      TaskStatusEnum.failed => l10n.downloadFailed,
      TaskStatusEnum.paused => l10n.taskStatusPaused,
      TaskStatusEnum.cancelled => l10n.taskStatusCancelled,
    };
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
          TpToast.show(
            context,
            message: context.hujiL10n.fileDoesNotExist,
            variant: TpToastVariant.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.openFolderFailed('$e'),
          variant: TpToastVariant.error,
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
          TpToast.show(
            context,
            message: context.hujiL10n.fileDoesNotExist,
            variant: TpToastVariant.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.openFileFailed('$e'),
          variant: TpToastVariant.error,
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
    TpToast.show(
      context,
      message: context.hujiL10n.downloadWillContinueInBackground,
      variant: TpToastVariant.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final title = _errorMessage != null
        ? l10n.downloadFailed
        : l10n.downloadProgress;
    final statusIcon = Icon(
      _isCompleted ? Icons.check_circle : Icons.download,
      color: _isCompleted ? Colors.green : cs.primary,
      size: 24,
    );

    return TpDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogHeader(
            title: title,
            trailing: statusIcon,
            onClose: () => Navigator.of(context).pop(),
          ),
          SizedBox(height: context.tpSpacing.lg),
          Text(
            widget.task.name,
            style: TextStyle(
              color: cs.onSurface,
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
                color: cs.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: cs.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: cs.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isDownloading ? Colors.orange : cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _status,
                  style: TextStyle(
                    color: _isDownloading ? Colors.orange : cs.onSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatBytesSize(_processedSize.toDouble())} / ${formatBytesSize(_totalSize.toDouble())}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                Text(
                  '${formatBytesSize(_speed)}/s',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.saveLocationLabel,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                  ),
                  Text(
                    widget.task.savePath,
                    style: TextStyle(color: cs.onSurface, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          TpDialogActions(
            children: [
              if (!_isCompleted && _errorMessage == null) ...[
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'download_minimize',
                      const Duration(milliseconds: 500),
                      () => _minimizeToBackground(),
                    );
                  },
                  child: Text(l10n.downloadInBackground),
                ),
                TpButton(
                  variant: _isDownloading
                      ? TpButtonVariant.destructive
                      : TpButtonVariant.primary,
                  onPressed: () {
                    Throttles.throttle(
                      'download_cancel_start',
                      const Duration(milliseconds: 500),
                      () => _cancelOrStartTask(),
                    );
                  },
                  child: Text(
                    _isDownloading
                        ? l10n.taskStatusCancelledShort
                        : l10n.downloadNow,
                  ),
                ),
              ],
              if (_isCompleted) ...[
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'download_open_file',
                      const Duration(milliseconds: 500),
                      () => _openFile(context),
                    );
                  },
                  child: Text(l10n.openFile),
                ),
                TpButton(
                  onPressed: () {
                    Throttles.throttle(
                      'download_open_folder',
                      const Duration(milliseconds: 500),
                      () => _openFolder(context),
                    );
                  },
                  child: Text(l10n.openFolder),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
