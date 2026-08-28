import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:gal/gal.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/file_utils.dart' as path_utils;
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/widgets/video_player/video_player_page.dart';
import 'package:uuid/uuid.dart';

import '../models/autoclip_models.dart';
import '../models/ffmpeg.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class VideoSaveProgressDialog extends StatefulWidget {
  final String videoPath;
  final List<SegmentInfo> segments;
  final String fileName;
  final VideoCompressQuality? quality;
  final SportType? sportType;
  final VideoProcessType? videoProcessType;

  const VideoSaveProgressDialog({
    super.key,
    required this.videoPath,
    required this.segments,
    required this.fileName,
    this.quality,
    this.sportType,
    this.videoProcessType,
  });

  @override
  State<VideoSaveProgressDialog> createState() =>
      _VideoSaveProgressDialogState();
}

class _VideoSaveProgressDialogState extends State<VideoSaveProgressDialog> {
  double _progress = 0.0;
  String _status = '';
  bool _isCompleted = false;
  String? _errorMessage;
  String? _savedVideoPath;
  int _fileSize = 0;
  String _formattedFileSize = '0 B';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveVideo());
  }

  Future<void> _saveVideo() async {
    final l10n = context.hujiL10n;
    try {
      if (!mounted) return;
      setState(() {
        _status = l10n.savePreparingInProgress;
        _progress = 0.1;
      });

      // 获取保存目录
      final downloadsDir = await path_utils.getDownloadsDirectory();
      final videoDir = path.join(downloadsDir.path, 'Videos');
      await Directory(videoDir).create(recursive: true);

      // 生成文件名（简化格式以便相册识别）
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      // 截断原始文件名，避免过长（保留前30个字符）
      final baseFileName = widget.fileName.length > 30
          ? widget.fileName.substring(0, 30)
          : widget.fileName;
      final fileName = '${baseFileName}_$timestamp.mp4';
      final targetPath = path.join(videoDir, fileName);

      if (!mounted) return;
      setState(() {
        _progress = 0.2;
        _status = l10n.saveProcessingSegmentsStart;
      });

      // 准备压缩参数（如果指定了质量）
      int? crf;
      int? bitrate; // 比特率（kbps），用于硬件编码器或自定义比特率
      int? audioBitrate;
      String? preset;
      if (widget.quality != null) {
        // 根据质量获取 CRF 值、比特率、音频比特率和预设
        // 使用 withDefaultPreset 工厂方法，会根据质量自动选择预设
        final config = VideoCompressConfig.fromQuality(
          quality: widget.quality!,
          includeAudio: true,
          optimizeForWeb: true,
        );
        crf = config.crfValue;
        // 如果是自定义质量且有自定义比特率，使用自定义比特率；否则使用根据质量获取的比特率
        bitrate = config.customBitrate;
        audioBitrate = config.audioBitrate;
        preset = config.presetString;
      }

      // 根据片段数量选择保存策略
      if (widget.segments.length == 1) {
        // 单个片段，直接裁剪（应用质量设置）
        await _saveSingleSegment(widget.segments.first, targetPath);
      } else {
        // 多个片段，先裁剪再合并（应用质量设置）
        await _saveMultipleSegments(
          widget.segments,
          targetPath,
          crf: crf,
          bitrate: bitrate,
          audioBitrate: audioBitrate,
          preset: preset,
        );
      }

      // 检查文件是否生成成功
      final file = File(targetPath);
      if (await file.exists()) {
        _fileSize = await file.length();
        _formattedFileSize = _formatFileSize(_fileSize);

        if (!mounted) return;
        setState(() {
          _progress = 0.92;
          _status = l10n.saveSavingMetadata;
        });

        // 持久化视频元数据到本地数据库
        try {
          final videoInfo = await VideoUtils.getVideoInfo(targetPath);
          String? thumbnailPath;
          try {
            thumbnailPath = await VideoUtils.generateVideoThumbnail(targetPath);
          } catch (e) {
            AppLogger().w('生成缩略图失败', e);
          }

          final savedRecord = SavedVideoRecord(
            id: const Uuid().v4(),
            sportType: widget.sportType ?? SportType.pingpong,
            filePath: targetPath,
            thumbnailPath: thumbnailPath,
            duration: videoInfo.duration,
            fileSize: _fileSize,
            videoProcessType: widget.videoProcessType,
          );
          await LocalVideoStorage().add(savedRecord);
        } catch (e, stackTrace) {
          AppLogger().w('保存视频元数据失败', e, stackTrace);
        }

        if (!mounted) return;
        setState(() {
          _progress = 0.95;
          _status = l10n.saveSavingToGallery;
        });

        // 保存到相册
        try {
          if (PlatformCapability.supportsGalleryAccess) {
            await Gal.putVideo(targetPath);
          }
        } catch (e, stackTrace) {
          AppLogger().w('保存到相册失败', e, stackTrace);
        }

        if (!mounted) return;
        setState(() {
          _progress = 1.0;
          _status = l10n.saveComplete;
          _isCompleted = true;
          _savedVideoPath = targetPath;
        });
      } else {
        throw Exception(l10n.videoFileNotGenerated);
      }
    } catch (e, stackTrace) {
      AppLogger().e('保存视频失败', stackTrace, e);
      if (!mounted) return;
      setState(() {
        _errorMessage = l10n.videoSaveFailed;
        _status = l10n.saveFailedShort;
      });
    }
  }

  /// 保存单个片段
  Future<void> _saveSingleSegment(SegmentInfo segment, String savePath) async {
    final l10n = context.hujiL10n;
    final startTime = segment.startSeconds;
    final duration = segment.endSeconds - segment.startSeconds;

    if (!mounted) return;
    setState(() {
      _progress = 0.2;
      _status = l10n.saveTrimmingSegments;
    });

    await VideoUtils.clipVideoByTimes(
      inputFile: widget.videoPath,
      startTime: startTime,
      duration: duration,
      outputFile: savePath,
      onProgress: (progress, currentTime, totalDuration) {
        // 单个片段：裁剪占20%（0.2-0.4），直接完成占60%（0.4-1.0）
        // 由于单个片段不需要合并，裁剪完成后直接到90%
        if (mounted) {
          setState(() {
            _progress = 0.2 + progress * 0.7; // 0.2 到 0.9
            _status = l10n.saveTrimmingSegmentsProgress(
              (progress * 100).toStringAsFixed(1),
            );
          });
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _progress = 0.9;
      _status = l10n.videoProcessingComplete;
    });
  }

  /// 保存多个片段（先裁剪再合并）
  Future<void> _saveMultipleSegments(
    List<SegmentInfo> segments,
    String savePath, {
    int? crf,
    int? bitrate,
    int? audioBitrate,
    String? preset,
  }) async {
    final l10n = context.hujiL10n;
    final tempDir = await Directory.systemTemp.createTemp('video_clip_');
    final tempFiles = <String>[];

    try {
      // 第一步：裁剪所有片段到临时文件
      if (!mounted) return;
      setState(() {
        _status = l10n.saveTrimmingSegments;
      });

      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final tempFile = '${tempDir.path}/segment_$i.mp4';
        tempFiles.add(tempFile);

        final startTime = segment.startSeconds;
        final duration = segment.endSeconds - segment.startSeconds;

        // 计算当前片段在裁剪阶段的进度范围
        final segmentStartProgress = 0.2 + (i / segments.length) * 0.2;
        final segmentEndProgress = 0.2 + ((i + 1) / segments.length) * 0.2;

        if (!mounted) return;
        setState(() {
          _status = l10n.saveTrimmingSegment;
          _progress = segmentStartProgress;
        });

        await VideoUtils.clipVideoByTimes(
          inputFile: widget.videoPath,
          startTime: startTime,
          duration: duration,
          outputFile: tempFile,
          onProgress: (progress, currentTime, totalDuration) {
            // 将单个片段的进度映射到整体裁剪进度范围
            if (mounted) {
              final segmentProgress =
                  segmentStartProgress +
                  (progress * (segmentEndProgress - segmentStartProgress));
              setState(() {
                _progress = segmentProgress;
              });
            }
          },
        );
      }

      // 第二步：合并所有临时文件（应用质量设置）
      // 合并占50%，从0.4到0.9
      if (!mounted) return;
      setState(() {
        _progress = 0.4;
        _status = l10n.saveMergingSegments;
      });

      await VideoUtils.mergeVideosByFFmpeg(
        inputFiles: tempFiles,
        outputFile: savePath,
        codec: 'h264',
        crf: crf,
        bitrate: bitrate,
        preset: preset,
        includeAudio: true,
        audioBitrate: audioBitrate,
        optimizeForWeb: true,
        onProgress: (progress, currentTime, totalDuration) {
          // 合并进度映射到 0.4-0.9 范围（占50%）
          if (mounted) {
            setState(() {
              _progress = 0.4 + progress * 0.5;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _progress = 0.9;
        _status = l10n.videoProcessingComplete;
      });
    } finally {
      // 清理临时文件
      if (mounted) {
        setState(() {
          _status = l10n.saveCleaningTempFiles;
        });
      }

      for (final tempFile in tempFiles) {
        try {
          await File(tempFile).delete();
        } catch (e) {
          debugPrint('删除临时文件失败: $tempFile, 错误: $e');
        }
      }
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        debugPrint('删除临时目录失败: ${tempDir.path}, 错误: $e');
      }
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
      if (_savedVideoPath != null) {
        final file = File(_savedVideoPath!);
        if (await file.exists()) {
          await OpenFile.open(file.parent.path);
        } else {
          if (context.mounted) {
            TpToast.show(
              context,
              message: context.hujiL10n.videoPlayerFileNotFound,
              variant: TpToastVariant.error,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.openFolderFailed(e.toString()),
          variant: TpToastVariant.error,
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      if (_savedVideoPath != null) {
        final file = File(_savedVideoPath!);
        if (await file.exists()) {
          // 使用VideoPlayerPage播放视频
          final fileName = path.basename(_savedVideoPath!);
          if (context.mounted) {
            VideoPlayerPage.show(context, _savedVideoPath!, fileName);
          }
        } else {
          if (context.mounted) {
            TpToast.show(
              context,
              message: context.hujiL10n.videoPlayerFileNotFound,
              variant: TpToastVariant.error,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.openFileFailed(e.toString()),
          variant: TpToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final title = _errorMessage != null
        ? l10n.saveFailedShort
        : l10n.saveProgressTitle;
    final statusIcon = Icon(
      _isCompleted ? Icons.check_circle : Icons.video_library,
      color: _isCompleted ? Colors.green : cs.primary,
      size: 24,
    );
    final completedMenu = _isCompleted && _savedVideoPath != null
        ? PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(value: 'open_file', child: Text(l10n.playVideo)),
              PopupMenuItem(value: 'open_folder', child: Text(l10n.openFolder)),
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
          )
        : null;

    return TpDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogHeader(
            title: title,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                statusIcon,
                if (completedMenu != null) completedMenu,
              ],
            ),
            onClose: () => Navigator.of(context).pop(),
          ),
          SizedBox(height: context.tpSpacing.lg),
          Text(
            l10n.fileNameWithSegmentCount(
              widget.fileName,
              widget.segments.length,
            ),
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
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
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
                  style: TextStyle(color: cs.onSurface, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isCompleted && _savedVideoPath != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.fileInfoLabel,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formattedFileSize,
                          style: TextStyle(color: cs.onSurface, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.saveLocationLabel,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      path.dirname(_savedVideoPath!),
                      style: TextStyle(color: cs.onSurface, fontSize: 11),
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
              if (_isCompleted && _savedVideoPath != null)
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'video_save_play',
                      const Duration(milliseconds: 500),
                      () => _openFile(context),
                    );
                  },
                  child: Text(l10n.playVideo),
                ),
              TpButton(
                onPressed: () {
                  Throttles.throttle(
                    'video_save_close',
                    const Duration(milliseconds: 500),
                    () => Navigator.of(context).pop(),
                  );
                },
                child: Text(
                  _errorMessage != null
                      ? l10n.actionConfirm
                      : (_isCompleted ? l10n.actionDone : l10n.actionClose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
