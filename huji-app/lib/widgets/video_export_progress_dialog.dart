import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_resolve.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

typedef VideoExportProgressCallback = void Function(
  double progress,
  String status,
);

class VideoExportResult {
  final String outputPath;

  const VideoExportResult({required this.outputPath});
}

typedef VideoExportTask = Future<VideoExportResult> Function(
  VideoExportProgressCallback onProgress,
);

/// Generic export progress dialog. Runs [exportTask] on open and reports progress.
class VideoExportProgressDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VideoExportTask exportTask;

  const VideoExportProgressDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.exportTask,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required VideoExportTask exportTask,
  }) {
    return showTpDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VideoExportProgressDialog(
        title: title,
        subtitle: subtitle,
        exportTask: exportTask,
      ),
    );
  }

  @override
  State<VideoExportProgressDialog> createState() =>
      _VideoExportProgressDialogState();
}

class _VideoExportProgressDialogState extends State<VideoExportProgressDialog> {
  double _progress = 0;
  String _status = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_status.isEmpty) {
      _status = context.hujiL10n.exportPreparing;
    }
  }
  bool _isCompleted = false;
  bool _isRunning = true;
  String? _errorMessage;
  String? _outputPath;
  String _formattedFileSize = '';

  @override
  void initState() {
    super.initState();
    _runExport();
  }

  Future<void> _runExport() async {
    final l10n = resolveHujiL10n();
    try {
      final result = await widget.exportTask((progress, status) {
        if (!mounted) return;
        setState(() {
          _progress = progress.clamp(0.0, 1.0);
          _status = status;
        });
      });

      final file = File(result.outputPath);
      if (!await file.exists()) {
        throw Exception(l10n.exportFileNotGenerated);
      }

      final fileSize = await file.length();
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _status = context.hujiL10n.exportComplete;
        _isCompleted = true;
        _isRunning = false;
        _outputPath = result.outputPath;
        _formattedFileSize = _formatFileSize(fileSize);
      });
    } catch (e) {
      if (!mounted) return;
      final errorL10n = context.hujiL10n;
      setState(() {
        _errorMessage = e.toString();
        _status = errorL10n.exportFailedTitle;
        _isRunning = false;
      });
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

  Future<void> _openFolder() async {
    if (_outputPath == null) return;
    try {
      final dir = File(_outputPath!).parent;
      if (await dir.exists()) {
        await OpenFile.open(dir.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.hujiL10n.openFolderFailed('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformCapability.isDesktop;
    final cs = isDesktop ? context.desktopColors : Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final onSurface = isDesktop ? cs.onSurface : Colors.white;
    final onSurfaceVariant =
        isDesktop ? cs.onSurfaceVariant : Colors.white70;
    final surface = isDesktop ? cs.surfaceContainer : Colors.grey[900]!;

    return TpDialog(
      backgroundColor: surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogHeader(
            title: _errorMessage != null
                ? context.hujiL10n.exportFailedTitle
                : widget.title,
            onClose: _isRunning ? () {} : () => Navigator.of(context).pop(),
            trailing: Icon(
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
            ),
          ),
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
              value: _isRunning && _progress == 0 ? null : _progress,
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
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: styles.md.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Flexible(
                  child: Text(
                    _status,
                    style: styles.sm.copyWith(color: onSurfaceVariant),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (_isCompleted && _outputPath != null) ...[
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
                      path.dirname(_outputPath!),
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
              if (_isCompleted && _outputPath != null)
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
