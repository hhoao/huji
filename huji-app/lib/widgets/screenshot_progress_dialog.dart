import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_resolve.dart';
import 'package:huji_app/services/ffmpeg/ffmpeg_runner.dart';
import 'package:gal/gal.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/file_utils.dart' as path_utils;
import 'package:huji_app/l10n/l10n_extensions.dart';

class ScreenshotProgressDialog extends StatefulWidget {
  final String videoPath;
  final Duration currentPosition;
  final String fileName;
  final bool isLocal;

  const ScreenshotProgressDialog({
    super.key,
    required this.videoPath,
    required this.currentPosition,
    required this.fileName,
    required this.isLocal,
  });

  @override
  State<ScreenshotProgressDialog> createState() =>
      _ScreenshotProgressDialogState();
}

class _ScreenshotProgressDialogState extends State<ScreenshotProgressDialog> {
  double _progress = 0.0;
  String _status = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_status.isEmpty) {
      _status = context.hujiL10n.screenshotPrepare;
    }
  }
  bool _isCompleted = false;
  String? _errorMessage;
  String? _screenshotPath;
  int _fileSize = 0;
  String _formattedFileSize = '0 B';
  String _formattedPosition = '0:00';
  bool _savedToGallery = false;

  @override
  void initState() {
    super.initState();
    _formattedPosition = _formatDuration(widget.currentPosition);
    _captureScreenshot();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _captureScreenshot() async {
    final l10n = resolveHujiL10n();
    try {
      setState(() {
        _status = l10n.screenshotCapturing;
        _progress = 0.3;
      });

      // 获取截图保存目录
      final downloadsDir = await path_utils.getDownloadsDirectory();
      final screenshotPath = path.join(downloadsDir.path, 'Screenshots');
      await Directory(screenshotPath).create(recursive: true);

      // 生成文件名
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final positionStr = '${widget.currentPosition.inSeconds}s';
      final fileName = '${widget.fileName}_${positionStr}_$timestamp.jpg';
      final targetPath = path.join(screenshotPath, fileName);

      setState(() {
        _progress = 0.6;
        _status = l10n.screenshotGeneratingImage;
      });

      // 使用FFmpeg截取当前帧
      final seconds = widget.currentPosition.inMilliseconds / 1000.0;
      final command =
          '-i "${widget.videoPath}" -ss $seconds -vframes 1 -q:v 2 "$targetPath"';

      final result = await FFmpegRunner.instance.execute(
        splitFFmpegCommand(command),
      );

      if (result.isSuccess) {
        final file = File(targetPath);
        if (await file.exists()) {
          // 获取文件大小
          _fileSize = await file.length();
          _formattedFileSize = _formatFileSize(_fileSize);

          setState(() {
            _progress = 0.8;
            _status = l10n.screenshotSavingToGallery;
            _screenshotPath = targetPath;
          });

          // 保存到相册
          try {
            if (PlatformCapability.supportsGalleryAccess) {
              await Gal.putImageBytes(
                await file.readAsBytes(),
                album: 'Video Screenshots',
              );
            }
            _savedToGallery = PlatformCapability.supportsGalleryAccess;
          } catch (e) {
            debugPrint('保存到相册失败: $e');
            _savedToGallery = false;
          }

          setState(() {
            _progress = 1.0;
            _status = l10n.screenshotCompleted;
            _isCompleted = true;
          });
        } else {
          throw Exception(l10n.screenshotFileNotGenerated);
        }
      } else {
        final logs = result.output ?? '';
        throw Exception(l10n.screenshotCaptureFailedWithLogs(logs));
      }
    } catch (e) {
      final errorL10n = mounted ? context.hujiL10n : resolveHujiL10n();
      setState(() {
        _errorMessage = e.toString();
        _status = errorL10n.screenshotFailedTitle;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> _openFolder(BuildContext context) async {
    try {
      if (_screenshotPath != null) {
        final file = File(_screenshotPath!);
        if (await file.exists()) {
          await OpenFile.open(file.parent.path);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.hujiL10n.fileDoesNotExist),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.hujiL10n.openFolderFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      if (_screenshotPath != null) {
        final file = File(_screenshotPath!);
        if (await file.exists()) {
          await OpenFile.open(_screenshotPath!);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.hujiL10n.fileDoesNotExist),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.hujiL10n.openFileFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.hujiL10n.shareFeatureInDevelopment),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Icon(
            _isCompleted ? Icons.check_circle : Icons.camera_alt,
            color: _isCompleted ? Colors.green : Colors.blue,
            size: 24,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage != null
                  ? context.hujiL10n.screenshotFailedTitle
                  : context.hujiL10n.screenshotProgressTitle,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.black.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'open_file',
                child: Text(
                  context.hujiL10n.openFile,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
              PopupMenuItem(
                value: 'open_folder',
                child: Text(context.hujiL10n.openFolder, style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'open_file':
                  _openFile(context);
                  break;
                case 'open_folder':
                  _openFolder(context);
                  break;
              }
            },
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件名和时间位置
          Text(
            '${widget.fileName} ($_formattedPosition)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16),

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
                  SizedBox(width: 8),
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 12),

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
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 截图预览
            if (_isCompleted && _screenshotPath != null) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_screenshotPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 12),

              // 文件信息
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.hujiL10n.fileInfoLabel,
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        Text(
                          _formattedFileSize,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      context.hujiL10n.saveLocationLabel,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      path.dirname(_screenshotPath!),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_savedToGallery) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(context.hujiL10n.savedToGallery, style: TextStyle(color: Colors.green, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_isCompleted && _screenshotPath != null) ...[
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'screenshot_share',
                    const Duration(milliseconds: 500),
                    () => _shareImage(context),
                  );
                },
                child: Text(
                  context.hujiL10n.actionShare,
                  style: const TextStyle(color: Colors.purple),
                ),
              ),
            ],
            TextButton(
              onPressed: () {
                Throttles.throttle(
                  'screenshot_close',
                  const Duration(milliseconds: 500),
                  () => Navigator.of(context).pop(),
                );
              },
              child: Text(
                _errorMessage != null
                    ? context.hujiL10n.actionConfirm
                    : (_isCompleted
                        ? context.hujiL10n.actionDone
                        : context.hujiL10n.actionClose),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
