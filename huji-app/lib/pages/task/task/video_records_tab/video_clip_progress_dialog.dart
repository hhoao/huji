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
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/utils/desktop_style.dart';
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
            final isDesktop = PlatformCapability.isDesktop;
            final cs = isDesktop
                ? context.desktopColors
                : Theme.of(context).colorScheme;
            final styles = TpTextStyles.of(context);
            final thumbnailHeight = isDesktop ? 240.0 : 180.0;

            return TpDialog(
              maxWidth: isDesktop ? 520 : 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TpDialogHeader(
                    title: l10n.videoClipProgressTitle,
                    onClose: () {
                      Throttles.throttle(
                        'video_clip_dialog_close_icon',
                        const Duration(milliseconds: 500),
                        () => Navigator.of(context).pop(),
                      );
                    },
                    trailing: Icon(
                      Icons.cut,
                      color: _getStatusColor(currentTask.status),
                      size: 24,
                    ),
                  ),
                  SizedBox(height: context.tpSpacing.lg),

                  Container(
                    width: double.infinity,
                    height: thumbnailHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: cs.surfaceContainerHighest,
                    ),
                    child: state.isGeneratingThumbnail
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: context.tpSpacing.sm),
                                Text(
                                  l10n.generatingThumbnail,
                                  style: styles.sm.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
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
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_file,
                                  size: 48,
                                  color: cs.onSurfaceVariant,
                                ),
                                SizedBox(height: context.tpSpacing.sm),
                                Text(
                                  l10n.cannotGenerateThumbnail,
                                  style: styles.sm.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(height: context.tpSpacing.lg),

                  Text(
                    currentTask.name,
                    style: styles.mdSemibold.copyWith(color: cs.onSurface),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.tpSpacing.md),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getStatusText(l10n, currentTask.status),
                            style: styles.mdMedium.copyWith(
                              color: _getStatusColor(currentTask.status),
                            ),
                          ),
                          Text(
                            '${(currentTask.progress * 100).toStringAsFixed(0)}%',
                            style: styles.mdSemibold.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.tpSpacing.sm),
                      LinearProgressIndicator(
                        value: currentTask.progress,
                        minHeight: 8,
                        backgroundColor: isDesktop
                            ? context.desktopBorderMedium
                            : cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(currentTask.status),
                        ),
                      ),
                      SizedBox(height: context.tpSpacing.sm),
                      Text(
                        _getProgressDescription(
                          l10n,
                          currentTask.status,
                          currentTask.progress,
                        ),
                        style: styles.sm.copyWith(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  TpDialogActions(
                    children: [
                      if (currentTask.status == TaskStatusEnum.completed)
                        TpButton(
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
                        )
                      else if (currentTask.status == TaskStatusEnum.failed)
                        TpButton(
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
                        )
                      else
                        TpButton(
                          variant: TpButtonVariant.ghost,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(context.hujiL10n.actionClose),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
