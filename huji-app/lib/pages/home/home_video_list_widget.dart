import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/clip/round_clip_page.dart';
import 'package:huji_app/pages/home/bloc/home_video_list_bloc.dart';
import 'package:huji_app/pages/home/bloc/home_video_list_event.dart';
import 'package:huji_app/pages/home/bloc/home_video_list_state.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/clip.dart';
import 'package:huji_app/router/modules/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/time_utils.dart' as time_utils;
import 'package:shared_ui/shared_ui.dart';

class HomeVideoListWidget extends StatelessWidget {
  const HomeVideoListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HomeVideoListBloc()..add(const HomeVideoListInitializeEvent()),
      child: const _HomeVideoListWidget(),
    );
  }
}

class _HomeVideoListWidget extends StatelessWidget {
  const _HomeVideoListWidget();

  @override
  Widget build(BuildContext context) {
    final size = 50.0;
    return BlocListener<HomeVideoListBloc, HomeVideoListState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null && context.mounted) {
          TpToast.show(
            context,
            message: state.errorMessage!,
            variant: TpToastVariant.error,
          );
        }
      },
      child: BlocBuilder<HomeVideoListBloc, HomeVideoListState>(
        buildWhen: (previous, current) =>
            previous.videoList != current.videoList ||
            previous.isLoading != current.isLoading ||
            previous.taskProgressMap != current.taskProgressMap,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SizedBox(
            height: size,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = size;
                int count = state.videoList.length;
                double totalCardWidth = count * (cardWidth + 12);
                double remain = constraints.maxWidth - totalCardWidth;
                double placeholderWidth = remain > cardWidth
                    ? remain
                    : cardWidth;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: remain >= 0 ? count + 1 : count,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    if (idx < count) {
                      final item = state.videoList[idx];
                      return _buildVideoCard(
                        context: context,
                        title: _getRecordTitle(context, item),
                        thumbnailUrl: item.thumbnailPath,
                        subtitle: _getRecordSubtitle(context, item),
                        extra: _getRecordExtra(context, state, item),
                        onTap: () => _onRecordTap(context, item),
                        onDelete: () => _deleteVideo(context, item.id),
                        highlight: _isHighlightVideo(item),
                        time: _getRecordTime(item),
                        category: _getRecordCategory(context, item),
                      );
                    } else if (remain >= 0) {
                      return _buildPlaceholderCard(
                        context,
                        width: placeholderWidth,
                      );
                    } else {
                      return null;
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _getRecordTime(LocalVideoRecord record) {
    return time_utils.timeStampToTimeAgo(record.createdAt);
  }

  String _getRecordCategory(BuildContext context, LocalVideoRecord record) {
    final l10n = context.hujiL10n;
    if (record is RawVideoRecord) {
      return l10n.homeVideoCategoryRaw;
    } else if (record is ProcessVideoRecord) {
      return l10n.homeVideoCategoryProcessing;
    } else if (record is EdittingVideoRecord) {
      return l10n.homeVideoCategoryCompleted;
    }
    return l10n.homeVideoCategoryUnknown;
  }

  void _deleteVideo(BuildContext context, String id) {
    context.read<HomeVideoListBloc>().add(HomeVideoListDeleteEvent(id));
    // 错误处理通过 BlocListener 在 Bloc 中处理
  }

  Widget? _getRecordExtra(
    BuildContext context,
    HomeVideoListState state,
    LocalVideoRecord record,
  ) {
    final l10n = context.hujiL10n;
    if (record is ProcessVideoRecord) {
      // 从 Bloc 状态中获取任务进度
      final progress = state.taskProgressMap[record.taskId] ?? 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: progress,
            color: Colors.blue,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeVideoProcessingProgress((progress * 100).round()),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      );
    } else if (record is EdittingVideoRecord) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            l10n.homeVideoSubtitleCompleted,
            style: const TextStyle(fontSize: 11, color: Colors.green),
          ),
        ],
      );
    }
    return null;
  }

  void _onRecordTap(BuildContext context, LocalVideoRecord record) {
    if (record is RawVideoRecord) {
      // 跳转到运动类型选择页面
      context.push(ClipRoute.videoEditConfig, extra: record);
    } else if (record is ProcessVideoRecord) {
      // 跳转到进度页面
      context.push(VideoRoute.videoProgress);
    } else if (record is EdittingVideoRecord) {
      // 跳转到编辑页面，使用处理后的视频文件路径
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoundClipPage(videoRecord: record),
        ),
      );
    }
  }

  String _getRecordSubtitle(BuildContext context, LocalVideoRecord record) {
    final l10n = context.hujiL10n;
    if (record is RawVideoRecord) {
      return l10n.homeVideoSubtitlePending;
    } else if (record is ProcessVideoRecord) {
      return l10n.homeVideoSubtitleProcessing(record.taskId);
    } else if (record is EdittingVideoRecord) {
      return l10n.homeVideoSubtitleCompleted;
    }
    return '';
  }

  bool _isHighlightVideo(LocalVideoRecord record) {
    if (record is ProcessVideoRecord) {
      return true; // 正在处理的视频高亮显示
    }
    return false;
  }

  String _getRecordTitle(BuildContext context, LocalVideoRecord record) {
    final l10n = context.hujiL10n;
    if (record is RawVideoRecord) {
      return l10n.homeVideoTitleRaw;
    } else if (record is ProcessVideoRecord) {
      return l10n.homeVideoTitleProcessing(record.taskId);
    } else if (record is EdittingVideoRecord) {
      return l10n.homeVideoTitleEditing;
    }
    return l10n.homeVideoTitleUnknown;
  }

  Widget _buildVideoCard({
    required BuildContext context,
    required String title,
    String? thumbnailUrl,
    String? subtitle,
    Widget? extra,
    required VoidCallback onTap,
    VoidCallback? onDelete,
    bool highlight = false,
    String? time,
    String? category,
  }) {
    return TpHover(
      onTap: () {
        Throttles.throttle(
          'home_video_tap',
          const Duration(milliseconds: 500),
          () => onTap(),
        );
      },
      borderRadius: BorderRadius.circular(12),
      pressScale: 0.97,
      child: AspectRatio(
        aspectRatio: 1,
        child:
            // 缩略图区域
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        (thumbnailUrl != null &&
                            thumbnailUrl.isNotEmpty &&
                            File(thumbnailUrl).existsSync())
                        ? Image.file(
                            File(thumbnailUrl),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : (thumbnailUrl != null &&
                              thumbnailUrl.startsWith('http'))
                        ? Image.network(
                            thumbnailUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                title.isNotEmpty ? title.characters.first : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                  // 左下角时间
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        time ?? '00:00',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // 右下角类别
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category ?? context.hujiL10n.unknownLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: TpHover(
                        onTap: () {
                          Throttles.throttle(
                            'home_video_delete',
                            const Duration(milliseconds: 500),
                            () => onDelete(),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context, {double? width}) {
    return SizedBox(
      width: width,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: Radius.circular(12),
          color: Colors.grey[400]!,
          strokeWidth: 1.5,
          dashPattern: [6, 4],
        ),
        child: Container(
          width: width,
          color: Colors.transparent,
          child: Center(
            child: Text(
              context.hujiL10n.homeVideoNoMoreRecords,
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}
