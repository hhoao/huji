import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/router/modules/clip.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import '../../../../models/task.dart';
import 'bloc/video_clip_progress_dialog_bloc.dart';
import 'bloc/video_clip_progress_dialog_event.dart';
import 'bloc/video_clip_progress_dialog_state.dart';

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

  String _getStatusText(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.pending:
        return '等待中';
      case TaskStatusEnum.processing:
        return '处理中';
      case TaskStatusEnum.completed:
        return '已完成';
      case TaskStatusEnum.failed:
        return '失败';
      case TaskStatusEnum.paused:
        return '暂停';
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

  String _getProgressDescription(TaskStatusEnum status, double progress) {
    if (status == TaskStatusEnum.pending) {
      return '任务已提交，等待处理...';
    } else if (status == TaskStatusEnum.processing) {
      if (progress < 0.1) {
        return '正在上传视频...';
      } else if (progress < 0.3) {
        return '正在分析视频内容...';
      } else if (progress < 0.7) {
        return '正在剪辑视频...';
      } else if (progress < 0.9) {
        return '正在生成最终视频...';
      } else {
        return '正在下载结果...';
      }
    } else if (status == TaskStatusEnum.completed) {
      return '剪辑完成！';
    } else {
      return '处理失败，请重试';
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
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '视频剪辑进度',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Throttles.throttle(
                              'video_clip_dialog_close_icon',
                              const Duration(milliseconds: 500),
                              () => Navigator.of(context).pop(),
                            );
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black87,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 视频缩略图
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: state.isGeneratingThumbnail
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('生成缩略图中...'),
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
                              child: const Center(
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
                                      '无法生成缩略图',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 16),

                    // 进度条
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getStatusText(currentTask.status),
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
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: currentTask.progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(currentTask.status),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getProgressDescription(
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
                    const SizedBox(height: 20),

                    // 操作按钮
                    if (currentTask.status == TaskStatusEnum.completed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            currentTask is VideoSegmentDetectTask
                                ? '编辑视频'
                                : '播放',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (currentTask.status == TaskStatusEnum.failed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '重试',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '关闭',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
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
