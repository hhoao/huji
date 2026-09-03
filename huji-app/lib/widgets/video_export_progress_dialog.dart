import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_resolve.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

/// Export progress dialog bound to a [VideoExportTask] in [TaskStorage].
///
/// The task runs in the background regardless of this dialog: closing it
/// (via 后台运行 or leaving the page) does not interrupt the export.
class VideoExportProgressDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String taskId;

  const VideoExportProgressDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.taskId,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String taskId,
  }) {
    return showTpDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VideoExportProgressDialog(
        title: title,
        subtitle: subtitle,
        taskId: taskId,
      ),
    );
  }

  @override
  State<VideoExportProgressDialog> createState() =>
      _VideoExportProgressDialogState();
}

class _VideoExportProgressDialogState extends State<VideoExportProgressDialog> {
  VideoExportTask? _task;
  String _formattedFileSize = '';
  bool _fileSizeResolved = false;

  @override
  void initState() {
    super.initState();
    _syncTask();
    TaskStorage().addListener(_onTaskStorageChanged);
  }

  @override
  void dispose() {
    TaskStorage().removeListener(_onTaskStorageChanged);
    super.dispose();
  }

  void _onTaskStorageChanged() {
    if (!mounted) return;
    setState(_syncTask);
  }

  void _syncTask() {
    _task = TaskStorage().getTaskById(widget.taskId) as VideoExportTask?;
  }

  bool get _isRunning {
    final status = _task?.status;
    return status == TaskStatusEnum.pending ||
        status == TaskStatusEnum.processing;
  }

  bool get _isCompleted => _task?.status == TaskStatusEnum.completed;

  bool get _isFailed =>
      _task?.status == TaskStatusEnum.failed ||
      _task?.status == TaskStatusEnum.cancelled;

  String? get _errorMessage => _isFailed
      ? (_task?.extraInfo?.isNotEmpty == true
            ? _task!.extraInfo
            : _task?.status == TaskStatusEnum.cancelled
            ? resolveHujiL10n().taskStatusCancelledShort
            : resolveHujiL10n().exportFailedTitle)
      : null;

  String get _statusText {
    final l10n = resolveHujiL10n();
    if (_isCompleted) return l10n.exportComplete;
    if (_task?.status == TaskStatusEnum.pending) return l10n.exportPreparing;
    if (_isFailed) return l10n.exportFailedTitle;
    final p = _task?.progress ?? 0;
    if (p <= 0.01) return l10n.exportPreparing;
    return l10n.exportProgressPercent((p * 100).toStringAsFixed(0));
  }

  Future<void> _resolveFileSize() async {
    if (_fileSizeResolved) return;
    final outputPath = _task?.outputPath;
    if (!_isCompleted || outputPath == null || outputPath.isEmpty) return;
    _fileSizeResolved = true;
    final file = File(outputPath);
    if (!await file.exists()) return;
    if (!mounted) return;
    setState(() {
      _formattedFileSize = _formatFileSize(file.lengthSync());
    });
  }

  Future<void> _openFolder() async {
    final outputPath = _task?.outputPath;
    if (outputPath == null || outputPath.isEmpty) return;
    try {
      final dir = File(outputPath).parent;
      if (await dir.exists()) {
        await OpenFile.open(dir.path);
      }
    } catch (e) {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.openFolderFailed('$e'),
        variant: TpToastVariant.error,
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    _resolveFileSize();
    final isDesktop = PlatformCapability.isDesktop;
    final cs = isDesktop ? context.desktopColors : Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final onSurface = isDesktop ? cs.onSurface : Colors.white;
    final onSurfaceVariant =
        isDesktop ? cs.onSurfaceVariant : Colors.white70;
    final surface = isDesktop ? cs.surfaceContainer : Colors.grey[900]!;
    final progress = _task?.progress ?? 0;
    final outputPath =
        (_isCompleted && (_task?.outputPath ?? '').isNotEmpty)
        ? _task!.outputPath
        : null;
    final title = _errorMessage != null
        ? context.hujiL10n.exportFailedTitle
        : widget.title;
    final statusIcon = Icon(
      _errorMessage != null
          ? Icons.error_outline
          : _isCompleted
              ? Icons.check_circle_outline
              : Icons.file_download_outlined,
      color: _errorMessage != null
          ? cs.error
          : _isCompleted
              ? Colors.green
              : cs.primary,
      size: 22,
    );
    final titleStyle = (Theme.of(context).textTheme.bodyLarge ??
            const TextStyle())
        .copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final header = _isRunning
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(title, style: titleStyle)),
                  statusIcon,
                ],
              ),
              SizedBox(height: context.tpSpacing.lg),
              const TpDialogDivider(),
            ],
          )
        : TpDialogHeader(
            title: title,
            onClose: () => Navigator.of(context).pop(),
            trailing: statusIcon,
          );

    return TpDialog(
      backgroundColor: surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SizedBox(height: context.tpSpacing.lg),
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: styles.md.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16),
          ],
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: styles.sm.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            LinearProgressIndicator(
              value: _isRunning && progress == 0 ? null : progress,
              backgroundColor: isDesktop
                  ? context.desktopBorderMedium
                  : Colors.grey[700],
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: styles.md.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Flexible(
                  child: Text(
                    _statusText,
                    style: styles.sm.copyWith(color: onSurfaceVariant),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (_isCompleted && outputPath != null) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDesktop
                      ? cs.surfaceContainerHighest
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                  border: isDesktop
                      ? Border.all(color: context.desktopBorderLight)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.hujiL10n.labelSize,
                          style: styles.sm
                              .copyWith(color: onSurfaceVariant),
                        ),
                        Text(
                          _formattedFileSize,
                          style:
                              styles.sm.copyWith(color: onSurface),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      context.hujiL10n.saveLocationLabel,
                      style:
                          styles.sm.copyWith(color: onSurfaceVariant),
                    ),
                    Text(
                      path.dirname(outputPath),
                      style: styles.sm.copyWith(color: onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
          TpDialogActions(
            children: [
              if (_isRunning)
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.hujiL10n.exportRunInBackground),
                ),
              if (_isCompleted && outputPath != null)
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: _openFolder,
                  child: Text(context.hujiL10n.openFolder),
                ),
              TpButton(
                variant: TpButtonVariant.primary,
                onPressed:
                    _isRunning ? null : () => Navigator.of(context).pop(),
                child: Text(
                  _errorMessage != null
                      ? context.hujiL10n.actionConfirm
                      : (_isCompleted
                          ? context.hujiL10n.actionDone
                          : context.hujiL10n.actionClose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
