import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/autoclip_models.dart';
import '../../models/video.dart';
import '../../utils/debounce/throttles.dart';
import 'bloc/round_clip_bloc.dart';
import 'bloc/round_clip_event.dart';
import 'bloc/round_clip_state.dart';

/// 通用回合选择弹窗
class RoundsSelectionDialog extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color titleColor;
  final List<SegmentInfo> segments;

  const RoundsSelectionDialog({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.titleColor,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundClipBloc, RoundClipState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // 标题栏
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(titleIcon, color: titleColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: titleColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${segments.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: titleColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 删除当前回合按钮
                      GestureDetector(
                        onTap: () {
                          Throttles.throttle(
                            'round_delete_current',
                            const Duration(milliseconds: 500),
                            () => _deleteCurrentRound(context, state),
                          );
                        },
                        child: Tooltip(
                          message: '删除当前回合',
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      // 收藏当前回合按钮
                      GestureDetector(
                        onTap: () {
                          Throttles.throttle(
                            'round_toggle_favorite',
                            const Duration(milliseconds: 500),
                            () => _toggleCurrentFavorite(context),
                          );
                        },
                        child: Tooltip(
                          message: _isCurrentFavorite(state)
                              ? '取消收藏当前回合'
                              : '收藏当前回合',
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _isCurrentFavorite(state)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: _isCurrentFavorite(state)
                                  ? Colors.orange
                                  : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // 关闭按钮
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Tooltip(
                          message: '关闭',
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.grey[300], height: 1),

                // 回合列表
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: segments.length,
                      itemBuilder: (context, index) {
                        final segment = segments[index];
                        final duration =
                            segment.endSeconds - segment.startSeconds;
                        final isCurrentSegment =
                            state.currentPlayingSegment == segment;
                        final isFavorite = state.isSegmentFavorite(segment);

                        return GestureDetector(
                          onTap: () {
                            Throttles.throttle(
                              'round_play_segment_$index',
                              const Duration(milliseconds: 500),
                              () {
                                context.read<RoundClipBloc>().add(
                                  PlaySegmentEvent(segment),
                                );
                              },
                            );
                          },
                          onLongPress: () {
                            context.read<RoundClipBloc>().add(
                              ToggleFavoriteEvent(segment),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCurrentSegment
                                  ? titleColor.withValues(alpha: 0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrentSegment
                                    ? titleColor
                                    : titleColor.withValues(alpha: 0.3),
                                width: isCurrentSegment ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 顶部 - 回合编号和状态
                                Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isCurrentSegment
                                        ? titleColor.withValues(alpha: 0.2)
                                        : titleColor.withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Row(
                                          children: [
                                            if (titleIcon == Icons.star)
                                              Icon(
                                                Icons.star,
                                                size: 12,
                                                color: titleColor,
                                              ),
                                            if (titleIcon == Icons.star)
                                              const SizedBox(width: 4),
                                            Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrentSegment
                                                    ? titleColor.withValues(
                                                        alpha: 0.8,
                                                      )
                                                    : titleColor.withValues(
                                                        alpha: 0.7,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (isFavorite &&
                                              titleIcon != Icons.star)
                                            Icon(
                                              Icons.star,
                                              size: 12,
                                              color: Colors.orange,
                                            ),
                                          if (isCurrentSegment &&
                                              state.isSegmentPlaying)
                                            Icon(
                                              Icons.play_arrow,
                                              size: 12,
                                              color: titleColor,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 中间 - 时长和时间范围
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${duration.toStringAsFixed(1)}s',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isCurrentSegment
                                                ? titleColor.withValues(
                                                    alpha: 0.8,
                                                  )
                                                : titleColor.withValues(
                                                    alpha: 0.7,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '${_formatSequenceTime(_getSegmentStartTimeInSequence(segment, segments))}-${_formatSequenceTime(_getSegmentEndTimeInSequence(segment, segments))}',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 检查当前播放的回合是否已收藏
  bool _isCurrentFavorite(RoundClipState state) {
    if (state.currentPlayingSegment == null) return false;
    return state.isSegmentFavorite(state.currentPlayingSegment!);
  }

  /// 切换当前播放回合的收藏状态
  void _toggleCurrentFavorite(BuildContext context) {
    // 通过Bloc处理业务逻辑
    context.read<RoundClipBloc>().add(
      const ToggleCurrentPlayingSegmentFavoriteEvent(),
    );
  }

  /// 删除当前播放的回合（需要确认）
  void _deleteCurrentRound(BuildContext context, RoundClipState state) {
    if (state.currentPlayingSegment == null) {
      context.read<RoundClipBloc>().add(
        const ShowErrorMessageEvent('没有正在播放的回合'),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除当前正在播放的回合吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () {
              Throttles.throttle(
                'round_delete_cancel',
                const Duration(milliseconds: 500),
                () => Navigator.of(context).pop(),
              );
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Throttles.throttle(
                'round_delete_confirm',
                const Duration(milliseconds: 500),
                () {
                  Navigator.of(context).pop(); // 关闭确认对话框
                  Navigator.of(context).pop(); // 关闭回合选择弹窗

                  // 通过Bloc处理删除逻辑
                  context.read<RoundClipBloc>().add(
                    const DeleteCurrentPlayingSegmentEvent(),
                  );
                },
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 格式化序列时间显示
  String _formatSequenceTime(int timeMs) {
    final seconds = timeMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 获取片段在序列中的开始时间
  int _getSegmentStartTimeInSequence(
    SegmentInfo segment,
    List<SegmentInfo> allSegments,
  ) {
    int accumulatedTime = 0;
    for (final s in allSegments) {
      if (s == segment) {
        return accumulatedTime;
      }
      accumulatedTime += ((s.endSeconds - s.startSeconds) * 1000).round();
    }
    return accumulatedTime;
  }

  /// 获取片段在序列中的结束时间
  int _getSegmentEndTimeInSequence(
    SegmentInfo segment,
    List<SegmentInfo> allSegments,
  ) {
    return _getSegmentStartTimeInSequence(segment, allSegments) +
        ((segment.endSeconds - segment.startSeconds) * 1000).round();
  }
}

/// 所有回合选择弹窗
class AllRoundsDialog extends StatelessWidget {
  const AllRoundsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundClipBloc, RoundClipState>(
      builder: (context, state) {
        return RoundsSelectionDialog(
          title: '全部回合',
          titleIcon: Icons.list,
          titleColor: Colors.blue,
          segments: state.playBallSegments,
        );
      },
    );
  }
}

/// 收藏回合选择弹窗
class FavoriteRoundsDialog extends StatelessWidget {
  const FavoriteRoundsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundClipBloc, RoundClipState>(
      builder: (context, state) {
        return RoundsSelectionDialog(
          title: '收藏回合',
          titleIcon: Icons.star,
          titleColor: Colors.orange,
          segments: state.favoriteSegments,
        );
      },
    );
  }
}

/// 简化的片段选择对话框（不依赖Bloc，支持实时更新）
class SimpleSegmentsDialog extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color titleColor;
  final ValueNotifier<EdittingVideoRecord?> edittingRecord;

  const SimpleSegmentsDialog({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.titleColor,
    required this.edittingRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ValueListenableBuilder<EdittingVideoRecord?>(
        valueListenable: edittingRecord,
        builder: (context, record, _) {
          final segments = record?.allMatchSegments ?? [];

          return Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // 标题栏
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(titleIcon, color: titleColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: titleColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${segments.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: titleColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 关闭按钮
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Tooltip(
                          message: '关闭',
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.grey[300], height: 1),

                // 片段列表
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: segments.isEmpty
                        ? Center(
                            child: Text(
                              '暂无片段',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: segments.length,
                            itemBuilder: (context, index) {
                              final segment = segments[index];
                              final duration =
                                  segment.endSeconds - segment.startSeconds;

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: titleColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 顶部 - 片段编号
                                    Container(
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: titleColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Row(
                                          children: [
                                            if (titleIcon == Icons.star)
                                              Icon(
                                                Icons.star,
                                                size: 12,
                                                color: titleColor,
                                              ),
                                            if (titleIcon == Icons.star)
                                              const SizedBox(width: 4),
                                            Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: titleColor.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // 中间 - 时长和时间范围
                                    Expanded(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${duration.toStringAsFixed(1)}s',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: titleColor.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              '${_formatSequenceTime(_getSegmentStartTimeInSequence(segment, segments))}-${_formatSequenceTime(_getSegmentEndTimeInSequence(segment, segments))}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 格式化序列时间显示
  String _formatSequenceTime(int timeMs) {
    final seconds = timeMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 获取片段在序列中的开始时间
  int _getSegmentStartTimeInSequence(
    SegmentInfo segment,
    List<SegmentInfo> allSegments,
  ) {
    int accumulatedTime = 0;
    for (final s in allSegments) {
      if (s == segment) {
        return accumulatedTime;
      }
      accumulatedTime += ((s.endSeconds - s.startSeconds) * 1000).round();
    }
    return accumulatedTime;
  }

  /// 获取片段在序列中的结束时间
  int _getSegmentEndTimeInSequence(
    SegmentInfo segment,
    List<SegmentInfo> allSegments,
  ) {
    return _getSegmentStartTimeInSequence(segment, allSegments) +
        ((segment.endSeconds - segment.startSeconds) * 1000).round();
  }
}
