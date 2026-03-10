import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart' hide Preview;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/utils/time_utils.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_state.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_state.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/video_trimmer_bloc_manager.dart';
import 'package:restcut/widgets/video_trimmer/lib/trim_viewer/trim_editor_properties.dart';
import 'package:restcut/widgets/video_trimmer/lib/trim_viewer/thumbnail_viewer.dart';
import 'package:restcut/widgets/video_trimmer/lib/trim_viewer/video_viewer.dart';

class TrimmerView extends StatefulWidget {
  final File file;
  final List<VideoClipSegment>? initialSegments;
  final void Function(List<VideoClipSegment>)? onSegmentsChanged;

  const TrimmerView(
    this.file, {
    super.key,
    this.initialSegments,
    this.onSegmentsChanged,
  });

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  late final VideoTrimmerBlocManager _videoTrimmerBlocManager;

  @override
  void initState() {
    super.initState();
    // 只在 initState 中创建一次，避免每次 build 都创建新实例
    _videoTrimmerBlocManager = VideoTrimmerBlocManager(
      file: widget.file,
      initialSegments: widget.initialSegments,
    );
  }

  @override
  void dispose() {
    // 手动关闭 bloc，因为使用了 BlocProvider.value，需要手动管理生命周期
    _videoTrimmerBlocManager.clipSegmentBloc.close();
    _videoTrimmerBlocManager.trimmerBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ClipSegmentBloc>.value(
          value: _videoTrimmerBlocManager.clipSegmentBloc,
        ),
        BlocProvider<TrimmerBloc>.value(
          value: _videoTrimmerBlocManager.trimmerBloc,
        ),
      ],
      child: _TrimmerViewContent(onSegmentsChanged: widget.onSegmentsChanged),
    );
  }
}

class _TrimmerViewContent extends StatelessWidget {
  final void Function(List<VideoClipSegment>)? onSegmentsChanged;
  const _TrimmerViewContent({this.onSegmentsChanged});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ClipSegmentBloc, ClipSegmentState>(
          listenWhen: (previous, current) =>
              previous.activeSegments != current.activeSegments,
          listener: (context, state) {
            if (onSegmentsChanged != null) {
              onSegmentsChanged!(state.activeSegments);
            }
          },
        ),
      ],
      child: PopScope(
        canPop: !Navigator.of(context).userGestureInProgress,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Column(
              children: [
                Expanded(
                  child: BlocBuilder<TrimmerBloc, TrimmerState>(
                    buildWhen: (previous, current) =>
                        previous.isLoading != current.isLoading,
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      log('trimmer view build');

                      return Column(
                        children: [
                          // 顶部状态栏和工具栏
                          _buildTopBar(context),

                          // 视频预览区域
                          Expanded(flex: 3, child: _buildVideoPreview(context)),

                          // 视频片段编辑器
                          _buildSegmentOverview(context),

                          // 播放控制
                          _buildControls(context),

                          // 视频时间轴
                          _buildTrimViewer(),

                          // 视频进度控制
                          _buildVideoProgressControl(context),

                          // 底部工具栏
                          _buildBottomToolbar(context),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建顶部状态栏和工具栏
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black,
      child: Column(
        children: [
          // 工具栏
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // 收藏按钮 - 只在选中片段变化时重新渲染
                    BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
                      buildWhen: (previous, current) =>
                          previous.selectedSegment != current.selectedSegment ||
                          (previous.selectedSegment?.isFavorite !=
                              current.selectedSegment?.isFavorite),
                      builder: (context, state) {
                        final isFavorite =
                            state.selectedSegment?.isFavorite ?? false;

                        return IconButton(
                          onPressed: state.selectedSegment != null
                              ? () {
                                  if (context.mounted) {
                                    context.read<ClipSegmentBloc>().add(
                                      ClipSegmentToggleFavorite(
                                        state.selectedSegment!,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.amber : Colors.white,
                          ),
                          tooltip: '收藏片段',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建视频预览区域
  Widget _buildVideoPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: VideoViewer(
              videoPlayerController: context
                  .read<TrimmerBloc>()
                  .state
                  .videoPlayerController,
            ),
          ),

          Center(
            child: GestureDetector(
              onTap: () {
                if (context.mounted) {
                  context.read<TrimmerBloc>().add(TrimmerTogglePlayPause());
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: BlocBuilder<TrimmerBloc, TrimmerState>(
                  buildWhen: (previous, current) =>
                      previous.isPlaying != current.isPlaying,
                  builder: (context, state) => Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimViewer() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey[900],
      child: ScrollableTrimViewer(
        editorProperties: TrimEditorProperties(
          backgroundColor: Colors.grey[900]!,
        ),
      ),
    );
  }

  Widget _buildVideoProgressControl(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<TrimmerBloc, TrimmerState>(
        buildWhen: (previous, current) =>
            previous.currentMilliseconds != current.currentMilliseconds ||
            previous.totalDuration != current.totalDuration,

        builder: (context, state) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(state.currentMilliseconds / 1000),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatTime(state.totalDuration / 1000),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),

            SizedBox(height: 8),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.grey[700],
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: state.isDragging ? 8 : 6,
                ),
                trackHeight: 2,
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: state.isDragging ? 16 : 12,
                ),
                trackShape: RoundedRectSliderTrackShape(),
                valueIndicatorColor: Colors.white,
                valueIndicatorTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                showValueIndicator: state.isDragging
                    ? ShowValueIndicator.always
                    : ShowValueIndicator.never,
              ),
              child: Slider(
                value: state.totalDuration > 0
                    ? (state.currentMilliseconds) / state.totalDuration
                    : 0.0,
                onChanged: (value) {
                  final targetTime = (value * state.totalDuration).round();

                  if ((targetTime - state.currentMilliseconds).abs() > 100) {
                    if (context.mounted) {
                      context.read<TrimmerBloc>().add(
                        TrimmerSeekTo(Duration(milliseconds: targetTime)),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建时间显示和播放控制按钮
  Widget _buildControls(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<TrimmerBloc, TrimmerState>(
            buildWhen: (previous, current) =>
                previous.currentMilliseconds != current.currentMilliseconds ||
                previous.totalDuration != current.totalDuration,
            builder: (context, state) {
              return Text(
                '${formatTime(state.currentMilliseconds / 1000)} / ${formatTime(state.totalDuration / 1000)}',
                style: TextStyle(color: Colors.white, fontSize: 14),
              );
            },
          ),
          Row(
            children: [
              BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.isSlowMotion != current.isSlowMotion,
                builder: (context, state) {
                  return GestureDetector(
                    onTap: () {
                      if (context.mounted) {
                        context.read<TrimmerBloc>().add(
                          TrimmerToggleSlowMotion(),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.slow_motion_video,
                          color: state.isSlowMotion
                              ? Colors.blue
                              : Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '慢放',
                          style: TextStyle(
                            color: state.isSlowMotion
                                ? Colors.blue
                                : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(width: 8),
              // 播放速度菜单 - 只在播放速度变化时重新渲染
              BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.playbackSpeed != current.playbackSpeed,
                builder: (context, state) {
                  return _buildSpeedMenu(context, state);
                },
              ),
              SizedBox(width: 8),
              // 播放/暂停按钮 - 只在播放状态变化时重新渲染
              BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.isPlaying != current.isPlaying,
                builder: (context, state) {
                  return IconButton(
                    onPressed: () {
                      if (context.mounted) {
                        context.read<TrimmerBloc>().add(
                          TrimmerTogglePlayPause(),
                        );
                      }
                    },
                    icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建视频片段
  Widget _buildSegmentOverview(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 片段缩略图列表
          Expanded(
            child: BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
              buildWhen: (previous, current) {
                final activeSegments = previous.activeSegments;
                final activeSegments2 = current.activeSegments;
                return activeSegments != activeSegments2 ||
                    activeSegments.length != activeSegments2.length;
              },
              builder: (context, state) => ListView.builder(
                controller: ScrollController(),
                scrollDirection: Axis.horizontal,
                itemCount: state.activeSegments.length + 1,
                itemBuilder: (context, index) {
                  final activeSegments = state.activeSegments;
                  if (index == activeSegments.length) {
                    return Container(
                      width: 60,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[600]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (context.mounted) {
                            context.read<ClipSegmentBloc>().add(
                              ClipSegmentAddAt(
                                startTimeMs: context
                                    .read<TrimmerBloc>()
                                    .state
                                    .currentMilliseconds,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                      ),
                    );
                  }

                  final segment = activeSegments[index];

                  return GestureDetector(
                    onTap: () {
                      if (context.mounted) {
                        context.read<ClipSegmentBloc>().add(
                          ClipSegmentSelect(
                            segment: segment,
                            isScrollToSegment: true,
                          ),
                        );
                      }
                    },
                    child: BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
                      buildWhen: (previous, current) =>
                          previous.selectedSegment != current.selectedSegment &&
                          (current.selectedSegment == segment ||
                              previous.selectedSegment == segment),
                      builder: (context, state) {
                        final isSelected = state.selectedSegment == segment;
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[600]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      formatSegmentDuration(
                                        (segment.endTime - segment.startTime) /
                                            1000,
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 20,
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey[600],
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(7),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ' ${formatSegmentDuration(segment.startTime / 1000, precision: 0)} - ${formatSegmentDuration(segment.endTime / 1000, precision: 0)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部工具栏
  Widget _buildBottomToolbar(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 分割按钮 - 只在片段数量变化时重新渲染
          BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
            buildWhen: (previous, current) =>
                previous.activeSegments.isNotEmpty !=
                current.activeSegments.isNotEmpty,
            builder: (context, state) {
              return _buildToolButton(
                icon: Icons.content_cut,
                label: '分割',
                onTap: () {
                  if (context.mounted) {
                    context.read<ClipSegmentBloc>().add(
                      ClipSegmentSplitAt(
                        context.read<TrimmerBloc>().state.currentMilliseconds,
                      ),
                    );
                  }
                },
                isEnabled: state.activeSegments.isNotEmpty,
              );
            },
          ),
          // 添加片段按钮 - 不需要状态，始终可用
          _buildToolButton(
            icon: Icons.add,
            label: '添加片段',
            onTap: () {
              if (context.mounted) {
                context.read<ClipSegmentBloc>().add(
                  ClipSegmentAddAt(
                    startTimeMs: context
                        .read<TrimmerBloc>()
                        .state
                        .currentMilliseconds,
                  ),
                );
              }
            },
            isEnabled: true,
          ),
          // 只播放片段按钮 - 只在片段列表和播放模式变化时重新渲染
          BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
            buildWhen: (previous, current) =>
                previous.activeSegments.length != current.activeSegments.length,
            builder: (context, segmentState) {
              return BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.playSelectedSegmentOnly !=
                    current.playSelectedSegmentOnly,
                builder: (context, trimmerState) {
                  final hasActiveSegments =
                      segmentState.activeSegments.isNotEmpty;
                  return _buildToolButton(
                    icon: Icons.play_arrow,
                    label: '只播放片段',
                    onTap: () {
                      if (context.mounted && hasActiveSegments) {
                        context.read<TrimmerBloc>().add(
                          TrimmerTogglePlaySelectedSegmentOnly(),
                        );
                      }
                    },
                    color: trimmerState.playSelectedSegmentOnly
                        ? Colors.blue
                        : Colors.white,
                    isEnabled: hasActiveSegments,
                  );
                },
              );
            },
          ),

          BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
            buildWhen: (previous, current) =>
                previous.selectedSegment != current.selectedSegment,
            builder: (context, state) {
              return _buildToolButton(
                icon: Icons.delete,
                label: '删除',
                onTap: () {
                  Throttles.throttle(
                    'trimmer_delete_segment',
                    const Duration(milliseconds: 500),
                    () {
                      if (context.mounted) {
                        context.read<ClipSegmentBloc>().add(
                          ClipSegmentDeleteSelected(),
                        );
                      }
                    },
                  );
                },
                isEnabled: state.selectedSegment != null,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建播放速度菜单
  Widget _buildSpeedMenu(BuildContext context, TrimmerState state) {
    return StatefulBuilder(
      builder: (context, setState) {
        return PopupMenuButton<bool>(
          icon: const Icon(Icons.speed, color: Colors.white, size: 20),
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Colors.black.withValues(alpha: 0.9),
          elevation: 8,
          onSelected: (value) {
            // 这个值不会被使用，我们通过子菜单处理
          },
          menuPadding: EdgeInsets.zero,
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpeedMenuItem(context, state, '0.5x', 0.5),
                    _buildSpeedMenuItem(context, state, '1x', 1.0),
                    _buildSpeedMenuItem(context, state, '2x', 2.0),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建播放速度菜单项
  Widget _buildSpeedMenuItem(
    BuildContext context,
    TrimmerState state,
    String label,
    double speed,
  ) {
    final isSelected = state.playbackSpeed == speed;
    return GestureDetector(
      onTap: () {
        if (context.mounted) {
          try {
            context.read<TrimmerBloc>().add(TrimmerSetPlaybackSpeed(speed));
            Navigator.of(context).pop(); // 关闭菜单
          } catch (e) {
            // 忽略在页面退出时的错误
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
    Color? color,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? (color ?? Colors.white) : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
