import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/router/modules/clip.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import '../../../../models/task.dart';
import 'bloc/video_clip_progress_dialog_bloc.dart';
import 'bloc/video_clip_progress_dialog_event.dart';
import 'bloc/video_clip_progress_dialog_state.dart';
import 'package:huji_app/l10n/huji_l10n_helpers.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

class VideoClipProgressDialog extends StatefulWidget {
  final Task task;

  const VideoClipProgressDialog({super.key, required this.task});

  @override
  State<VideoClipProgressDialog> createState() =>
      _VideoClipProgressDialogState();
}

class _VideoClipProgressDialogState extends State<VideoClipProgressDialog> {
  late final VideoClipProgressDialogBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = VideoClipProgressDialogBloc(task: widget.task);
    // 发送初始化事件
    _bloc.add(const VideoClipProgressDialogInitializeEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _getStatusText(HujiLocalizations l10n, TaskStatusEnum status) {
    return l10n.taskStatusLabel(status);
  }

  Color _getStatusColor(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.pending:
        return Colors.orange;
      case TaskStatusEnum.processing:
        return Colors.blue;
      case TaskStatusEnum.completed:
        return Colors.green;
      case TaskStatusEnum.failed:
        return Colors.red;
      case TaskStatusEnum.paused:
        return Colors.yellow;
      case TaskStatusEnum.cancelled:
        return Colors.grey;
    }
  }

  String _getProgressDescription(
    HujiLocalizations l10n,
    TaskStatusEnum status,
    double progress,
  ) {
    if (status == TaskStatusEnum.pending) {
      return l10n.taskSubmittedWaiting;
    } else if (status == TaskStatusEnum.processing) {
      if (progress < 0.1) {
        return l10n.uploadingVideo;
      } else if (progress < 0.3) {
        return l10n.analyzingVideoContent;
      } else if (progress < 0.7) {
        return l10n.clippingVideo;
      } else if (progress < 0.9) {
        return l10n.generatingFinalVideo;
      } else {
        return l10n.downloadingResult;
      }
    } else if (status == TaskStatusEnum.completed) {
      return l10n.clipCompleted;
    } else {
      return l10n.processFailedRetry;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<VideoClipProgressDialogBloc, VideoClipProgressDialogState>(
        listenWhen: (previous, current) {
          // 只在 shouldClose 从 false 变为 true 时触发
          return !previous.shouldClose && current.shouldClose;
        },
        listener: (context, state) {
          // 如果任务完成，延迟关闭对话框
          if (state.task?.status == TaskStatusEnum.completed &&
              context.mounted) {
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          } else if (state.task?.status == TaskStatusEnum.failed) {
            // 任务失败时立即关闭（用户可以选择重试）
            // 这里不自动关闭，让用户手动关闭
          }
        },
        child: BlocBuilder<VideoClipProgressDialogBloc, VideoClipProgressDialogState>(
          buildWhen: (previous, current) {
            // 只在影响 UI 的状态变化时重建，避免不必要的重建

            // 1. 任务对象引用变化（Task 没有实现 Equatable，所以引用不同即内容不同）
            if (previous.task != current.task) {
              return true;
            }

            // 2. 缩略图相关状态变化
            if (previous.thumbnailPath != current.thumbnailPath ||
                previous.isGeneratingThumbnail !=
                    current.isGeneratingThumbnail) {
              return true;
            }

            // shouldClose 不需要触发 UI 重建，只用于 BlocListener
            return false;
          },
          builder: (context, state) {
            final currentTask = state.task ?? widget.task;
            final l10n = context.hujiL10n;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Row(
                      children: [
                        Icon(
                          Icons.cut,
                          color: _getStatusColor(currentTask.status),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.videoClipProgressTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TpIconButton(
                          onTap: () {
                            Throttles.throttle(
                              'video_clip_dialog_close_icon',
                              const Duration(milliseconds: 500),
                              () => Navigator.of(context).pop(),
                            );
                          },
                          icon: Icons.close,
                          iconSize: 20,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // 视频缩略图
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: state.isGeneratingThumbnail
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text(l10n.generatingThumbnail),
                                ],
                              ),
                            )
                          : state.thumbnailPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(state.thumbnailPath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[300],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.video_file,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      l10n.cannotGenerateThumbnail,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: 20),

                    // 文件名
                    Text(
                      currentTask.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16),

                    // 进度条
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getStatusText(l10n, currentTask.status),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(currentTask.status),
                              ),
                            ),
                            Text(
                              '${(currentTask.progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: currentTask.progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(currentTask.status),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getProgressDescription(
                            l10n,
                            currentTask.status,
                            currentTask.progress,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // 操作按钮
                    if (currentTask.status == TaskStatusEnum.completed)
                      SizedBox(
                        width: double.infinity,
                        child: TpButton(
                          onPressed: () {
                            Throttles.throttle(
                              'video_clip_dialog_play',
                              const Duration(milliseconds: 500),
                              () async {
                                Navigator.of(context).pop();
                                if (currentTask is VideoClipTask &&
                                    currentTask.outputPath.isNotEmpty) {
                                  context.push(
                                    '/video/player?videoUrl=${Uri.encodeComponent(currentTask.outputPath)}&fileName=${Uri.encodeComponent(currentTask.name)}',
                                  );
                                }
                                if (currentTask is VideoSegmentDetectTask) {
                                  if (currentTask.edittingRecordId != null) {
                                    final edittingRecord =
                                        await LocalVideoStorage().findById(
                                              currentTask.edittingRecordId!,
                                            )
                                            as EdittingVideoRecord?;
                                    if (context.mounted &&
                                        edittingRecord != null) {
                                      context.push(
                                        ClipRoute.roundClip,
                                        extra: edittingRecord,
                                      );
                                    }
                                  }
                                }
                              },
                            );
                          },
                          child: Text(
                            currentTask is VideoSegmentDetectTask
                                ? l10n.editVideo
                                : l10n.actionPlay,
                          ),
                        ),
                      )
                    else if (currentTask.status == TaskStatusEnum.failed)
                      SizedBox(
                        width: double.infinity,
                        child: TpButton(
                          variant: TpButtonVariant.destructive,
                          onPressed: () {
                            Throttles.throttle(
                              'video_clip_dialog_retry',
                              const Duration(milliseconds: 500),
                              () {
                                Navigator.of(context).pop();
                                // 这里可以添加重试的逻辑
                              },
                            );
                          },
                          child: Text(context.hujiL10n.actionRetry),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: TpButton(
                          variant: TpButtonVariant.ghost,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(context.hujiL10n.actionClose),
                        ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
