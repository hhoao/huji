import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/models/autoclip/permission_models.dart';
import 'package:restcut/pages/clip/round_selection_dialog.dart';
import 'package:restcut/router/modules/main.dart';
import 'package:restcut/widgets/multi_video_player/bloc/multi_video_player_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:restcut/widgets/video_trimmer/trimmer_view.dart';
import 'package:uuid/uuid.dart';

import '../../api/api_manager.dart';
import '../../models/autoclip_models.dart';
import '../../models/ffmpeg.dart';
import '../../models/video.dart';
import '../../widgets/common_app_bar_with_tabs.dart';
import '../../widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import '../../widgets/multi_video_player/bloc/multi_video_player_state.dart';
import '../../widgets/multi_video_player/bloc_multi_video_player_widget.dart';
import '../../widgets/video_export_quality_dialog.dart';
import '../../widgets/video_save_progress_dialog.dart';
import 'bloc/round_clip_bloc.dart';
import 'bloc/round_clip_event.dart';
import 'bloc/round_clip_state.dart';

/// 回合编辑页面
class RoundClipPage extends StatefulWidget {
  final EdittingVideoRecord? videoRecord;

  const RoundClipPage({super.key, this.videoRecord});

  @override
  State<RoundClipPage> createState() => _RoundClipPageState();
}

class _RoundClipPageState extends State<RoundClipPage>
    with SingleTickerProviderStateMixin {
  late MultiVideoPlayerBloc _multiVideoPlayerBloc;
  late RoundClipBloc _roundClipBloc;

  // 跟踪拖动状态
  SegmentInfo? _draggingSegment;
  int? _dragTargetIndex;
  bool _isFavoriteListDragging = false;

  @override
  void initState() {
    super.initState();
    _multiVideoPlayerBloc = MultiVideoPlayerBloc();
    _roundClipBloc = RoundClipBloc(multiVideoPlayerBloc: _multiVideoPlayerBloc);

    // 初始化RoundClipBloc
    _roundClipBloc.add(RoundClipInitializeEvent(widget.videoRecord));
  }

  @override
  void dispose() {
    _multiVideoPlayerBloc.close();
    _roundClipBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MultiVideoPlayerBloc>.value(value: _multiVideoPlayerBloc),
        BlocProvider<RoundClipBloc>.value(value: _roundClipBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          // 监听RoundClipBloc的消息
          BlocListener<RoundClipBloc, RoundClipState>(
            listenWhen: (previous, current) {
              // 只在消息变化时监听
              return previous.errorMessage != current.errorMessage ||
                  previous.successMessage != current.successMessage;
            },
            listener: (context, state) {
              // 处理错误消息
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }

              // 处理成功消息
              if (state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // 监听MultiVideoPlayerBloc的状态变化
          BlocListener<MultiVideoPlayerBloc, MultiVideoPlayerState>(
            listenWhen: (previous, current) {
              // 监听当前播放项变化或播放时间变化
              return previous.currentItem != current.currentItem ||
                  previous.currentTimeMs != current.currentTimeMs;
            },
            listener: (context, state) {
              // 通知RoundClipBloc当前播放项或时间已变化
              _roundClipBloc.add(
                MultiVideoPlayerStateChangedEvent(
                  state.currentItem,
                  state.currentTimeMs,
                ),
              );
            },
          ),
        ],
        child: Scaffold(
          appBar: CommonAppBar(
            title: '回合剪辑',
            leftWidget: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // 使用 pop 返回上一页，如果无法 pop 则导航到任务页面
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(MainRoute.mainTask);
                    }
                  },
                ),
              ],
            ),
            rightWidget: Row(
              children: [
                BlocBuilder<RoundClipBloc, RoundClipState>(
                  buildWhen: (previous, current) {
                    // 只在保存状态变化时重建
                    return previous.isSaving != current.isSaving;
                  },
                  builder: (context, state) {
                    return TextButton(
                      onPressed: state.isSaving ? null : _saveVideoLocally,
                      child: Row(
                        children: [
                          Text(
                            state.isSaving ? '导出中...' : '导出',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: BlocBuilder<RoundClipBloc, RoundClipState>(
            buildWhen: (previous, current) {
              // 只在关键状态变化时重建
              return previous.isLoading != current.isLoading ||
                  previous.videoRecord != current.videoRecord ||
                  previous.errorMessage != current.errorMessage;
            },
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // 视频预览区域
                    _buildVideoPreview(),

                    // 回合选择区域
                    _buildRoundSelection(),

                    // 操作按钮区域
                    _buildActionButtons(),
                  ],
                ),
              );
            },
          ),
        ), // Scaffold 结束
      ), // MultiBlocListener 结束
    ); // MultiBlocProvider 结束
  }

  /// 构建视频预览区域
  Widget _buildVideoPreview() {
    return BlocBuilder<RoundClipBloc, RoundClipState>(
      buildWhen: (previous, current) {
        // 只在视频记录变化时重建
        return previous.videoRecord != current.videoRecord;
      },
      builder: (context, state) {
        return Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: state.videoRecord != null
                ? Stack(
                    children: [
                      // 多视频播放器
                      BlocMultiVideoPlayerWidget(
                        bloc: _multiVideoPlayerBloc,
                        aspectRatio: 16 / 9,
                        backgroundColor: Colors.black,
                        showControls: true,
                        padding: const EdgeInsets.all(0),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无视频数据',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// 构建回合选择区域
  Widget _buildRoundSelection() {
    return BlocBuilder<RoundClipBloc, RoundClipState>(
      buildWhen: (previous, current) {
        // 只在视频记录或当前播放片段变化时重建
        return previous.videoRecord != current.videoRecord ||
            previous.currentPlayingSegment != current.currentPlayingSegment ||
            previous.isSegmentPlaying != current.isSegmentPlaying;
      },
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 全部回合区域
              _buildAllRoundsSection(state),

              const SizedBox(height: 16),

              // 收藏回合区域
              _buildFavoriteRoundsSection(state),
            ],
          ),
        );
      },
    );
  }

  /// 构建全部回合区域
  Widget _buildAllRoundsSection(RoundClipState state) {
    if (state.videoRecord == null) {
      return const SizedBox.shrink();
    }

    final playBallSegments = state.playBallSegments;

    if (playBallSegments.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildRoundsSection(
      title: '全部回合',
      segments: playBallSegments,
      themeColor: Colors.blue,
      showStarIcon: false,
      isFavoriteList: false,
      onTapTitle: _showAllRoundsDialog,
      emptyView: null,
      actionButton: BlocBuilder<RoundClipBloc, RoundClipState>(
        builder: (context, state) {
          final hasCurrentSegment = state.currentPlayingSegment != null;
          final isCurrentFavorite =
              hasCurrentSegment &&
              state.isSegmentFavorite(state.currentPlayingSegment!);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动提示
              Tooltip(
                message: '长按拖动可调整顺序',
                child: Icon(
                  Icons.drag_handle,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              // 删除按钮（禁用时保持布局稳定）
              Tooltip(
                message: hasCurrentSegment ? '删除当前回合' : '',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  onPressed: hasCurrentSegment
                      ? () {
                          _roundClipBloc.add(
                            DeleteSegmentEvent(state.currentPlayingSegment!),
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              // 收藏按钮
              Tooltip(
                message: isCurrentFavorite ? '取消收藏' : '收藏当前回合',
                child: IconButton(
                  icon: Icon(
                    isCurrentFavorite ? Icons.star : Icons.star_border,
                    size: 20,
                  ),
                  color: Colors.orange,
                  onPressed: () {
                    _roundClipBloc.add(
                      const ToggleCurrentPlayingSegmentFavoriteEvent(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示所有回合弹窗
  void _showAllRoundsDialog() {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _roundClipBloc,
        child: const AllRoundsDialog(),
      ),
    );
  }

  /// 构建收起的回合列表
  Widget _buildCollapsedRoundsList(
    List<SegmentInfo> segments, {
    Color? themeColor,
    bool showStarIcon = false,
    bool isFavoriteList = false,
  }) {
    return BlocBuilder<RoundClipBloc, RoundClipState>(
      builder: (context, state) {
        // 从 state 获取最新的片段列表
        final currentSegments = isFavoriteList
            ? state.favoriteSegments
            : state.playBallSegments;

        return SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: currentSegments.length,
            itemBuilder: (context, index) {
              final segment = currentSegments[index];
              return _buildDraggableRoundItem(
                segment: segment,
                index: index,
                segments: currentSegments,
                themeColor: themeColor,
                showStarIcon: showStarIcon,
                isFavoriteList: isFavoriteList,
              );
            },
          ),
        );
      },
    );
  }

  /// 构建可拖动的回合项
  Widget _buildDraggableRoundItem({
    required SegmentInfo segment,
    required int index,
    required List<SegmentInfo> segments,
    Color? themeColor,
    bool showStarIcon = false,
    bool isFavoriteList = false,
  }) {
    return LongPressDraggable<SegmentInfo>(
      data: segment,
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Opacity(
            opacity: 0.8,
            child: _buildRoundItemStatic(
              segment: segment,
              index: index,
              themeColor: themeColor,
              showStarIcon: showStarIcon,
            ),
          ),
        ),
      ),
      childWhenDragging: StatefulBuilder(
        builder: (context, setState) {
          // 检查是否是被拖动的项目，并且在同一列表中
          final isDraggingThis =
              _draggingSegment != null &&
              _draggingSegment!.startSeconds == segment.startSeconds &&
              _draggingSegment!.endSeconds == segment.endSeconds &&
              _isFavoriteListDragging == isFavoriteList;
          return isDraggingThis
              ? Opacity(
                  opacity: 0.3,
                  child: _buildRoundItemStatic(
                    segment: segment,
                    index: index,
                    themeColor: themeColor,
                    showStarIcon: showStarIcon,
                  ),
                )
              : _buildRoundItemStatic(
                  segment: segment,
                  index: index,
                  themeColor: themeColor,
                  showStarIcon: showStarIcon,
                );
        },
      ),
      onDragStarted: () {
        // 开始拖动时记录拖动状态
        setState(() {
          _draggingSegment = segment;
          _isFavoriteListDragging = isFavoriteList;
          _dragTargetIndex = null;
        });
      },
      onDragEnd: (details) {
        // 清除拖动状态
        // 注意：重新排序已经在 onAccept 中执行了
        setState(() {
          _draggingSegment = null;
          _dragTargetIndex = null;
        });
      },
      child: BlocBuilder<RoundClipBloc, RoundClipState>(
        builder: (context, state) {
          // 从 state 获取最新的片段列表
          final currentSegments = isFavoriteList
              ? state.favoriteSegments
              : state.playBallSegments;

          return DragTarget<SegmentInfo>(
            onWillAcceptWithDetails: (details) {
              // 检查是否拖动到不同的位置
              if (_draggingSegment == null) {
                return false;
              }
              // 检查是否在同一个列表中
              if (_isFavoriteListDragging != isFavoriteList) {
                return false;
              }
              final latestState = _roundClipBloc.state;
              final latestSegments = _isFavoriteListDragging
                  ? latestState.favoriteSegments
                  : latestState.playBallSegments;
              final oldIndex = latestSegments.indexWhere(
                (s) =>
                    s.startSeconds == _draggingSegment!.startSeconds &&
                    s.endSeconds == _draggingSegment!.endSeconds,
              );
              final willAccept = oldIndex != -1 && oldIndex != index;
              return willAccept;
            },
            onAcceptWithDetails: (details) {
              // 立即执行重新排序，不等到 onDragEnd
              if (_draggingSegment == null) {
                return;
              }
              // 再次检查是否在同一个列表中
              if (_isFavoriteListDragging != isFavoriteList) {
                return;
              }

              final latestState = _roundClipBloc.state;
              final latestSegments = _isFavoriteListDragging
                  ? latestState.favoriteSegments
                  : latestState.playBallSegments;

              final oldIndex = latestSegments.indexWhere(
                (s) =>
                    s.startSeconds == _draggingSegment!.startSeconds &&
                    s.endSeconds == _draggingSegment!.endSeconds,
              );

              if (oldIndex != -1 && oldIndex != index) {
                _roundClipBloc.add(
                  ReorderSegmentsEvent(
                    oldIndex: oldIndex,
                    newIndex: index,
                    isFavoriteList: _isFavoriteListDragging,
                  ),
                );
              }
            },
            onMove: (details) {
              // 拖动过程中实时更新目标索引（用于视觉反馈）
              if (_draggingSegment != null) {
                if (_dragTargetIndex != index) {
                  setState(() {
                    _dragTargetIndex = index;
                  });
                }
              }
            },
            onLeave: (data) {
              // 离开时清除目标索引
              if (_dragTargetIndex == index) {
                setState(() {
                  _dragTargetIndex = null;
                });
              }
            },
            builder: (context, candidateData, rejectedData) {
              // 只有当拖动发生在同一个列表中时，才显示拖动效果
              final isSameList = _isFavoriteListDragging == isFavoriteList;
              final isDraggingOver =
                  isSameList &&
                  (candidateData.isNotEmpty ||
                      (_draggingSegment != null && _dragTargetIndex == index));
              // 扩大检测区域，确保能正确检测拖动
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: isDraggingOver
                      ? BoxDecoration(
                          border: Border.all(
                            color: themeColor ?? Colors.blue,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: _buildRoundItem(
                    segment: segment,
                    index: index,
                    segments: currentSegments,
                    themeColor: themeColor,
                    showStarIcon: showStarIcon,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 构建静态回合项（不依赖 Bloc，用于拖动时的反馈）
  Widget _buildRoundItemStatic({
    required SegmentInfo segment,
    required int index,
    Color? themeColor,
    bool showStarIcon = false,
  }) {
    final duration = segment.endSeconds - segment.startSeconds;
    final effectiveThemeColor = themeColor ?? Colors.blue;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: effectiveThemeColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部 - 回合编号和状态
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: effectiveThemeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showStarIcon)
                    const Icon(Icons.star, size: 8, color: Colors.orange),
                  if (showStarIcon) const SizedBox(width: 2),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: effectiveThemeColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 中间 - 时长
          Expanded(
            child: Center(
              child: Text(
                '${duration.toStringAsFixed(1)}s',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: effectiveThemeColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个回合项
  Widget _buildRoundItem({
    Key? key,
    required SegmentInfo segment,
    required int index,
    required List<SegmentInfo> segments,
    Color? themeColor,
    bool showStarIcon = false,
  }) {
    return BlocBuilder<RoundClipBloc, RoundClipState>(
      buildWhen: (previous, current) {
        // 只在这个特定片段的状态变化时重建
        final wasCurrent = previous.currentPlayingSegment == segment;
        final isCurrent = current.currentPlayingSegment == segment;
        return wasCurrent != isCurrent;
      },
      builder: (context, state) {
        final duration = segment.endSeconds - segment.startSeconds;
        final isCurrentSegment = state.currentPlayingSegment == segment;
        final isFavorite = state.isSegmentFavorite(segment);
        final effectiveThemeColor = themeColor ?? Colors.blue;

        return Container(
          key: key,
          width: 60,
          margin: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _playSegment(segment),
            child: Container(
              decoration: BoxDecoration(
                color: isCurrentSegment
                    ? effectiveThemeColor.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrentSegment
                      ? effectiveThemeColor
                      : effectiveThemeColor.withValues(alpha: 0.3),
                  width: isCurrentSegment ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 顶部 - 回合编号和状态
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCurrentSegment
                          ? effectiveThemeColor.withValues(alpha: 0.2)
                          : effectiveThemeColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showStarIcon)
                            const Icon(
                              Icons.star,
                              size: 8,
                              color: Colors.orange,
                            ),
                          if (showStarIcon) const SizedBox(width: 2),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCurrentSegment
                                  ? effectiveThemeColor.withValues(alpha: 0.8)
                                  : effectiveThemeColor.withValues(alpha: 0.7),
                            ),
                          ),
                          if (!showStarIcon && isFavorite)
                            const Icon(
                              Icons.star,
                              size: 8,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 中间 - 时长和时间范围
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${duration.toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: isCurrentSegment
                                  ? effectiveThemeColor.withValues(alpha: 0.8)
                                  : effectiveThemeColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${_formatSequenceTime(_getSegmentStartTimeInSequence(segment, segments))}-${_formatSequenceTime(_getSegmentEndTimeInSequence(segment, segments))}',
                            style: TextStyle(
                              fontSize: 6,
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
          ),
        );
      },
    );
  }

  /// 构建收藏回合区域
  Widget _buildFavoriteRoundsSection(RoundClipState state) {
    if (state.videoRecord == null) {
      return const SizedBox.shrink();
    }

    final favoriteSegments = state.favoriteSegments;

    return _buildRoundsSection(
      title: '收藏回合',
      segments: favoriteSegments,
      themeColor: Colors.orange,
      showStarIcon: true,
      isFavoriteList: true,
      onTapTitle: _showFavoriteRoundsDialog,
      emptyView: _buildEmptyFavoritesView(),
      actionButton: BlocBuilder<RoundClipBloc, RoundClipState>(
        builder: (context, state) {
          final hasCurrentSegment = state.currentPlayingSegment != null;
          final isCurrentFavorite =
              hasCurrentSegment &&
              state.isSegmentFavorite(state.currentPlayingSegment!);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动提示
              Tooltip(
                message: '长按拖动可调整顺序',
                child: Icon(
                  Icons.drag_handle,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              // 删除按钮（禁用时保持布局稳定）
              Tooltip(
                message: isCurrentFavorite ? '从收藏中移除' : '',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  onPressed: isCurrentFavorite
                      ? () {
                          _roundClipBloc.add(
                            ToggleFavoriteEvent(state.currentPlayingSegment!),
                          );
                        }
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建回合区域的通用方法
  Widget _buildRoundsSection({
    required String title,
    required List<SegmentInfo> segments,
    required Color themeColor,
    required bool showStarIcon,
    required bool isFavoriteList,
    required VoidCallback onTapTitle,
    Widget? emptyView,
    Widget? actionButton,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和展开按钮
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTapTitle,
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${segments.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: themeColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (actionButton != null) actionButton,
              if (actionButton != null) const SizedBox(width: 8),
              GestureDetector(
                onTap: onTapTitle,
                child: Icon(
                  Icons.open_in_full,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // 回合列表 - 只显示收起状态
        segments.isEmpty && emptyView != null
            ? emptyView
            : _buildCollapsedRoundsList(
                segments,
                themeColor: themeColor,
                showStarIcon: showStarIcon,
                isFavoriteList: isFavoriteList,
              ),
      ],
    );
  }

  /// 显示收藏回合弹窗
  void _showFavoriteRoundsDialog() {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _roundClipBloc,
        child: const FavoriteRoundsDialog(),
      ),
    );
  }

  /// 构建空收藏视图
  Widget _buildEmptyFavoritesView() {
    return SizedBox(
      height: 60, // 与列表高度一致，保持布局稳定
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border, size: 24, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                '暂无收藏回合',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建操作按钮区域
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startEditing,
              icon: const Icon(Icons.content_cut),
              label: const Text('编辑回合'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 播放指定片段
  void _playSegment(SegmentInfo segment) {
    _roundClipBloc.add(PlaySegmentEvent(segment));
  }

  /// 获取回合在序列中的开始时间（毫秒）
  int _getSegmentStartTimeInSequence(
    SegmentInfo segment,
    List<SegmentInfo> allSegments,
  ) {
    int accumulatedTime = 0;
    for (final seg in allSegments) {
      if (seg == segment) {
        return accumulatedTime;
      }
      final duration = (seg.endSeconds - seg.startSeconds) * 1000;
      accumulatedTime += duration.round();
    }
    return accumulatedTime;
  }

  /// 获取回合在序列中的结束时间（毫秒）
  int _getSegmentEndTimeInSequence(
    SegmentInfo segment,
    List<SegmentInfo> allSegments,
  ) {
    final startTime = _getSegmentStartTimeInSequence(segment, allSegments);
    final duration = (segment.endSeconds - segment.startSeconds) * 1000;
    return startTime + duration.round();
  }

  /// 格式化序列时间显示
  String _formatSequenceTime(int timeMs) {
    final totalSeconds = timeMs / 1000.0;
    final totalMinutes = (totalSeconds / 60).floor();
    final remainingSeconds = (totalSeconds % 60).floor();
    final milliseconds = ((totalSeconds % 1) * 100).floor();

    if (totalMinutes > 0) {
      return '${totalMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
    } else {
      return '${remainingSeconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
    }
  }

  /// 开始编辑 - 跳转到TrimmerView
  Future<void> _startEditing() async {
    // 检查是否有 custom_config 权限
    try {
      final hasPermission = await Api.permission.checkPermission(
        PermissionEnum.editClip.code,
      );
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法使用编辑功能'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开编辑功能失败'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final state = _roundClipBloc.state;
    if (state.videoRecord == null) {
      _roundClipBloc.add(const ShowErrorMessageEvent('没有可用的视频数据'));
      return;
    }

    final videoFile = File(state.videoRecord!.filePath!);
    if (!videoFile.existsSync()) {
      _roundClipBloc.add(const ShowErrorMessageEvent('视频文件不存在'));
      return;
    }

    // 转换SegmentInfo为VideoClipSegment
    final initialSegments = _convertSegmentInfoToVideoClipSegment(state);

    _multiVideoPlayerBloc.add(PauseEvent());
    // 跳转到TrimmerView页面
    final throttler = Debouncer(delay: const Duration(milliseconds: 200));
    if (mounted) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => TrimmerView(
                videoFile,
                initialSegments: initialSegments,
                onSegmentsChanged: (segments) {
                  throttler.call(() {
                    _roundClipBloc.add(
                      UpdateEdittingVideoRecordEvent(
                        segments,
                        isFlushState: false,
                      ),
                    );
                  });
                },
              ),
            ),
          )
          .then((value) {
            // 编辑完成后，从数据库重新加载并更新状态
            throttler.cancel();
            _roundClipBloc.add(const FlushStateEvent());
            _roundClipBloc.add(const UpdatePlaybackItemsEvent());
          });
    }
  }

  /// 转换SegmentInfo为VideoClipSegment
  List<VideoClipSegment> _convertSegmentInfoToVideoClipSegment(
    RoundClipState state,
  ) {
    if (state.videoRecord == null) return [];
    final segments = <VideoClipSegment>[];

    // 从所有片段中提取playBall动作，保持原始顺序
    int order = 0;
    for (final segmentInfo in state.videoRecord!.allMatchSegments) {
      if (segmentInfo.actionType == ActionType.playBall) {
        // 检查是否为收藏片段
        final isFavorite = state.isSegmentFavorite(segmentInfo);

        segments.add(
          VideoClipSegment(
            id: const Uuid().v4(),
            startTime: (segmentInfo.startSeconds * 1000).round(),
            endTime: (segmentInfo.endSeconds * 1000).round(),
            isDeleted: false,
            isFavorite: isFavorite,
            order: order, // 保持原始顺序
          ),
        );
        order++;
      }
    }

    // 不再按时间排序，保持用户设置的顺序
    return segments;
  }

  /// 保存视频到本地
  Future<void> _saveVideoLocally() async {
    final state = _roundClipBloc.state;
    if (state.videoRecord == null) {
      _showErrorSnackBar('没有可用的视频数据');
      return;
    }

    // 获取要保存的片段
    final segmentsToSave = _getSegmentsToSave(state);
    if (segmentsToSave.isEmpty) {
      _showErrorSnackBar('没有可保存的片段');
      return;
    }

    // 显示质量选择对话框
    final selectedQuality = await VideoExportQualityDialog.show(
      context,
      initialQuality: VideoCompressQuality.medium,
    );

    // 如果用户取消了选择，则不继续
    if (selectedQuality == null || !mounted) {
      return;
    }

    // 显示保存进度对话框
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => VideoSaveProgressDialog(
          videoPath: state.videoRecord!.filePath!,
          segments: segmentsToSave,
          fileName: state.videoRecord!.filePath!
              .split('/')
              .last
              .split('.')
              .first,
          quality: selectedQuality,
        ),
      );
    }
  }

  /// 获取要保存的片段
  List<SegmentInfo> _getSegmentsToSave(RoundClipState state) {
    if (state.videoRecord == null) return [];

    return state.playBallSegments;
  }

  /// 显示错误消息
  void _showErrorSnackBar(String message) {
    _roundClipBloc.add(ShowErrorMessageEvent(message));
  }
}
