import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_state.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/clip_segment_overlay.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_painter.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/trim_area_properties.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_layout.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';
import 'package:shared_ui/shared_ui.dart';

/// Widget for displaying the video trimmer.
class ScrollableTrimViewer extends StatelessWidget {
  final TrimAreaProperties areaProperties;

  const ScrollableTrimViewer({
    super.key,
    this.areaProperties = const TrimAreaProperties(),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildThumbnailArea(context)]);
  }

  Widget _buildThumbnailArea(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final layout = context.trimmerLayout;
    final trimmerState = context.read<TrimmerBloc>().state;
    final thumbnailTileSize = layout.thumbnailTileSize;
    final timeRulerHeight = layout.timeRulerHeight;
    final bottomSpanHeight = layout.bottomSpanHeight;
    final durationSeconds = trimmerState.totalDuration / 1000.0;
    final timeIntervalSeconds = trimmerState.timeIntervalSeconds;
    final numberOfThumbnails = timelineThumbnailCount(
      durationSeconds: durationSeconds,
      timeIntervalSeconds: timeIntervalSeconds,
    );
    final timelineWidth = timelineTotalWidth(
      durationSeconds: durationSeconds,
      tileSize: thumbnailTileSize,
      timeIntervalSeconds: timeIntervalSeconds,
    );
    final thumbnailWidgetHeight = thumbnailTileSize + timeRulerHeight;
    final totalWidgetHeight = thumbnailWidgetHeight + bottomSpanHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(areaProperties.borderRadius),
          child: ColoredBox(
            color: trimmerTheme.timelineBackground,
            child: SizedBox(
              width:
                  timelineWidth +
                  constraints.maxWidth +
                  constraints.maxWidth,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScrollableThumbnailViewer(
                    fit: areaProperties.thumbnailFit,
                    thumbnailHeight: thumbnailTileSize,
                    numberOfThumbnails: numberOfThumbnails,
                    timelineContentWidth: timelineWidth,
                    timeIntervalSeconds: timeIntervalSeconds,
                    timeRulerHeight: timeRulerHeight,
                    bottomSpanHeight: bottomSpanHeight,
                    leftWidgetWidth: layout.leftWidgetWidth,
                  ),
                  Positioned(
                    left: layout.leftWidgetWidth,
                    top: 0,
                    bottom: 0,
                    child: AbsorbPointer(
                      child: CustomPaint(
                        size: Size(layout.playheadWidth, totalWidgetHeight),
                        painter: TimeIndicatorPainter(
                          color: trimmerTheme.playheadColor,
                          strokeWidth: layout.playheadWidth,
                        ),
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
}

class ScrollableThumbnailViewer extends StatelessWidget {
  const ScrollableThumbnailViewer({
    super.key,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.timelineContentWidth,
    required this.timeIntervalSeconds,
    required this.fit,
    this.timeRulerHeight = 40,
    this.bottomSpanHeight = 0,
    this.leftWidgetWidth = 0,
  });

  final double thumbnailHeight;

  final int numberOfThumbnails;

  /// Exact timeline strip width (duration-based; last tile may be partial).
  final double timelineContentWidth;

  final double timeIntervalSeconds;

  final BoxFit fit;

  final double timeRulerHeight;

  final double bottomSpanHeight;

  final double leftWidgetWidth;

  @override
  Widget build(BuildContext context) {
    // 直接返回缩略图区域，覆盖层将在内部处理
    return _buildTimeThumbnails(context);
  }

  Widget _buildTimeThumbnails(BuildContext context) {
    // 计算总高度：时间标尺 + 缩略图 + 底部区域（灰色区域 + 滑动区域）
    final totalHeight =
        timeRulerHeight +
        thumbnailHeight +
        (bottomSpanHeight > 0 ? bottomSpanHeight : 0);
    // 总宽度包括左侧组件和所有缩略图
    final totalWidth = leftWidgetWidth + timelineContentWidth;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: ClipRect(
        child: BlocSelector<TrimmerBloc, TrimmerState, ThumbnailConfig?>(
          selector: (state) => state.thumbnailConfig,
          builder: (context, thumbnailStream) {
            if (thumbnailStream == null) {
              return Container(
                color: context.trimmerTheme.timelineBackground,
                height: totalHeight,
                width: double.maxFinite,
              );
            }

            // 使用 StreamBuilder 监听流，在内部维护列表
            return _ThumbnailListBuilder(
              stream: Stream.value(thumbnailStream),
              thumbnailHeight: thumbnailHeight,
              numberOfThumbnails: numberOfThumbnails,
              timelineContentWidth: timelineContentWidth,
              timeIntervalSeconds: timeIntervalSeconds,
              coverImage: context.read<TrimmerBloc>().state.coverImage,
              fit: fit,
              scrollController: context
                  .read<TrimmerBloc>()
                  .state
                  .scrollController!,
              timeRulerHeight: timeRulerHeight,
              bottomSpanHeight: bottomSpanHeight,
              leftWidgetWidth: leftWidgetWidth,
            );
          },
        ),
      ),
    );
  }
}

/// 片段边框层：与 ListView 共用 scroll offset，保证同一时间轴坐标。
/// 刻度改由 viewport-fixed 的 [TimeRulerPainter] 绘制（见 _ThumbnailListBuilder）。
class _SegmentChromeOverlay extends StatelessWidget {
  const _SegmentChromeOverlay({
    required this.totalWidth,
    required this.thumbnailHeight,
  });

  final double totalWidth;
  final double thumbnailHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: totalWidth,
      height: thumbnailHeight,
      // RepaintBoundary：拖动滚动时 overlay 只是平移缓存的 layer，
      // 不会每帧重画所有片段边框
      child: RepaintBoundary(
        child: ClipSegmentOverlay(
          thumbnailHeight: thumbnailHeight,
          totalWidth: totalWidth,
        ),
      ),
    );
  }
}

/// 缩略图列表构建器，内部维护列表并使用 StreamBuilder 监听流
class _ThumbnailListBuilder extends StatelessWidget {
  final Stream<ThumbnailConfig> stream;
  final int numberOfThumbnails;
  final double timelineContentWidth;
  final double timeIntervalSeconds;
  final double thumbnailHeight;
  final BoxFit fit;
  final String? coverImage;
  final ScrollController scrollController;
  final double timeRulerHeight;
  final double bottomSpanHeight;
  final double leftWidgetWidth;

  const _ThumbnailListBuilder({
    required this.stream,
    required this.numberOfThumbnails,
    required this.timelineContentWidth,
    required this.timeIntervalSeconds,
    required this.thumbnailHeight,
    required this.fit,
    required this.coverImage,
    required this.scrollController,
    required this.timeRulerHeight,
    required this.bottomSpanHeight,
    required this.leftWidgetWidth,
  });

  @override
  Widget build(BuildContext context) {
    final itemHeight = timeRulerHeight + thumbnailHeight + bottomSpanHeight;
    final itemCount =
        numberOfThumbnails + 2; // +1 for left_widget, +1 for right_widget
    final screenWidth = MediaQuery.of(context).size.width;
    final rightWidgetWidth = screenWidth - leftWidgetWidth;

    // 提前获取 totalDuration，避免每个 item 都重复读取
    final totalDuration = context.read<TrimmerBloc>().state.totalDuration;
    final totalDurationSeconds = totalDuration / 1000.0;
    final totalWidth = timelineContentWidth;

    // 使用 Stack 叠加覆盖层：刻度与片段边框共用同一套滚动坐标系
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ListView 作为底层（缩略图 + 底部条；刻度改由 overlay 绘制）
        ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          itemCount: itemCount,
          cacheExtent: 200.0,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: false,
          itemBuilder: (context, index) {
            if (index == 0) {
              return RepaintBoundary(
                key: const ValueKey('left_widget'),
                child: SizedBox(
                  height: itemHeight,
                  width: leftWidgetWidth,
                  child: _buildLeftWidget(context),
                ),
              );
            }

            // 最后一个 item 是 right_widget
            if (index == itemCount - 1) {
              return RepaintBoundary(
                key: const ValueKey('right_widget'),
                child: SizedBox(
                  height: itemHeight,
                  width: rightWidgetWidth,
                  child: _buildRightWidget(context),
                ),
              );
            }

            final thumbnailIndex = index - 1;
            final tileWidth = timelineTileWidth(
              index: thumbnailIndex,
              thumbnailCount: numberOfThumbnails,
              durationSeconds: totalDurationSeconds,
              tileSize: thumbnailHeight,
              timeIntervalSeconds: timeIntervalSeconds,
            );
            return RepaintBoundary(
              key: ValueKey('thumbnail_$thumbnailIndex'),
              child: SizedBox(
                height: itemHeight,
                width: tileWidth,
                child: _getListViewItem(
                  context,
                  thumbnailIndex,
                  tileWidth: tileWidth,
                  totalDurationSeconds: totalDurationSeconds,
                ),
              ),
            );
          },
        ),
        // 刻度：viewport 固定层，每帧按 scrollOffset 重画但只画可见窗口内的
        // 刻度（旧实现每帧全量重画整个视频时长的刻度 + 标签排版）
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: timeRulerHeight,
          child: IgnorePointer(
            child: ClipRect(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: scrollController,
                  builder: (context, _) {
                    final intervals = totalDurationSeconds > 0
                        ? resolveTimeRulerIntervals(
                            totalWidth / totalDurationSeconds,
                          )
                        : const TimeRulerIntervals(
                            shortInterval: 1,
                            longInterval: 1,
                            textInterval: 1,
                          );
                    final trimmerTheme = context.trimmerTheme;
                    final layout = context.trimmerLayout;
                    final textTheme = Theme.of(context).textTheme;

                    return CustomPaint(
                      painter: TimeRulerPainter(
                        totalDurationSeconds: totalDurationSeconds,
                        totalWidth: totalWidth,
                        scrollOffset: scrollController.hasClients
                            ? scrollController.offset
                            : 0.0,
                        leftWidgetWidth: leftWidgetWidth,
                        shortInterval: intervals.shortInterval,
                        longInterval: intervals.longInterval,
                        textInterval: intervals.textInterval,
                        tickColor: trimmerTheme.rulerTickColor,
                        textStyle:
                            textTheme.labelSmall?.copyWith(
                              color: trimmerTheme.rulerLabelColor,
                              fontSize: layout.rulerLabelFontSize,
                              fontWeight: FontWeight.w500,
                            ) ??
                            TextStyle(
                              color: trimmerTheme.rulerLabelColor,
                              fontSize: layout.rulerLabelFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // 片段边框：同一坐标系平移；RepaintBoundary 内部缓存，滚动时只挪 layer
        AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final scrollOffset = scrollController.hasClients
                ? scrollController.offset
                : 0.0;

            return Positioned(
              top: timeRulerHeight,
              left: leftWidgetWidth - scrollOffset,
              width: totalWidth,
              height: thumbnailHeight,
              child: child!,
            );
          },
          child: _SegmentChromeOverlay(
            totalWidth: totalWidth,
            thumbnailHeight: thumbnailHeight,
          ),
        ),
      ],
    );
  }

  Widget _getListViewItem(
    BuildContext context,
    int index, {
    required double tileWidth,
    required double totalDurationSeconds,
  }) {
    final totalHeight = timeRulerHeight + thumbnailHeight + bottomSpanHeight;

    return SizedBox(
      height: totalHeight,
      width: tileWidth,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 时间标尺占位（实际刻度画在 scroll-synced overlay 里）
          SizedBox(height: timeRulerHeight, width: tileWidth),
          // 缩略图图片 - 高度固定，最后一格可窄于整格
          SizedBox(
            height: thumbnailHeight,
            width: tileWidth,
            child: _ThumbnailImage(
              index: index,
              timeIntervalSeconds: timeIntervalSeconds,
              totalDurationSeconds: totalDurationSeconds,
              coverImage: coverImage!,
              thumbnailHeight: thumbnailHeight,
              fit: fit,
            ),
          ),
          // 底部区域部分（灰色区域 + 滑动区域）- 固定高度
          SizedBox(
            height: bottomSpanHeight,
            width: tileWidth,
            child: _buildBottomSpanSegment(context, index, tileWidth),
          ),
        ],
      ),
    );
  }

  /// 构建底部区域片段（灰色区域 + 滑动区域，每个 item 只显示自己对应位置的部分）
  Widget _buildBottomSpanSegment(
    BuildContext context,
    int index,
    double tileWidth,
  ) {
    final bottomSpanColor = context.trimmerTheme.timelineBottomSpan;
    final scrollStripHeight = context.trimmerLayout.scrollStripHeight;
    final greyHeight =
        bottomSpanHeight > 0 ? bottomSpanHeight - scrollStripHeight : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 灰色区域
        if (greyHeight > 0)
          Container(
            height: greyHeight,
            width: tileWidth,
            color: bottomSpanColor,
          ),
        // 滑动区域（颜色不同，用于滑动）
        SizedBox(height: scrollStripHeight),
      ],
    );
  }

  /// 构建左侧组件（第一帧）
  Widget _buildLeftWidget(BuildContext context) {
    return SizedBox(
      width: leftWidgetWidth,
      child: Column(
        children: [
          // 时间标尺占位（左侧组件不需要时间标尺）
          SizedBox(height: timeRulerHeight),
          // 缩略图区域 - 包含 MuteButton 和封面图片
          SizedBox(
            height: thumbnailHeight,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MuteButton(
                    onPress: (mute) {
                      context.read<TrimmerBloc>().add(
                        TrimmerSetVolume(mute ? 0.0 : 1.0),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildCoverImage(context)],
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
          // 透明占位空间，保持与缩略图 item 的高度一致（但不显示底部区域）
          SizedBox(height: bottomSpanHeight),
        ],
      ),
    );
  }

  /// 构建右侧组件（用于让时间指示器可以指示到缩略图末尾）
  Widget _buildRightWidget(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rightWidgetWidth = screenWidth - leftWidgetWidth;

    return SizedBox(
      width: rightWidgetWidth,
      child: Column(
        children: [
          // 时间标尺占位（右侧组件不需要时间标尺）
          SizedBox(height: timeRulerHeight),
          // 空白区域
          SizedBox(
            height: thumbnailHeight,
            child: Container(color: Colors.transparent),
          ),
          // 透明占位空间，保持与缩略图 item 的高度一致
          SizedBox(height: bottomSpanHeight),
        ],
      ),
    );
  }

  /// 构建封面图片组件
  Widget _buildCoverImage(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final layout = context.trimmerLayout;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: thumbnailHeight,
      height: thumbnailHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: trimmerTheme.coverBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频第一帧作为背景
            RepaintBoundary(
              child: FutureBuilder<Uint8List?>(
                future: (() async {
                  if (coverImage != null) {
                    return File(coverImage!).readAsBytesSync();
                  }
                  return null;
                })(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: trimmerTheme.placeholderBackground,
                          child: Icon(
                            Icons.broken_image,
                            color: trimmerTheme.placeholderIcon,
                            size: 48,
                          ),
                        );
                      },
                    );
                  } else {
                    // 加载中或失败时显示占位符
                    return Container(
                      color: trimmerTheme.placeholderBackground,
                      child: Icon(
                        Icons.video_library,
                        color: trimmerTheme.placeholderIcon,
                        size: 20,
                      ),
                    );
                  }
                },
              ),
            ),
            // 半透明遮罩
            Container(color: trimmerTheme.coverOverlay),
            Center(
              child: Text(
                '只播放片段',
                style: textTheme.labelSmall?.copyWith(
                  color: trimmerTheme.onToolbar,
                  fontSize: layout.segmentLabelFontSize,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                      color: trimmerTheme.coverOverlay,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 静音按钮组件
class _MuteButton extends StatefulWidget {
  final Function(bool mute) onPress;

  const _MuteButton({required this.onPress});

  @override
  State<_MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<_MuteButton> {
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final layout = context.trimmerLayout;
    final textTheme = Theme.of(context).textTheme;
    final label = _isMuted ? '开启声音' : '关闭声音';
    final onTap = () {
      setState(() {
        _isMuted = !_isMuted;
      });
      widget.onPress(_isMuted);
    };

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isMuted ? Icons.volume_off : Icons.volume_up,
          color: trimmerTheme.onToolbar,
          size: layout.muteIconSize,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: trimmerTheme.onToolbar,
            fontSize: layout.microLabelFontSize,
          ),
        ),
      ],
    );

    if (!PlatformCapability.isDesktop) {
      return TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onTap,
        child: content,
      );
    }

    return Tooltip(
      message: label,
      child: TpHover(
        borderRadius: BorderRadius.circular(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        hoverColor: trimmerTheme.onToolbar.withValues(alpha: 0.1),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// 时间指示器绘制器 - 绘制一条固定的竖线
class TimeIndicatorPainter extends CustomPainter {
  const TimeIndicatorPainter({
    required this.color,
    this.strokeWidth = 3,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    // 绘制一条从顶部到底部的固定竖线，位于容器中心
    canvas.drawLine(
      Offset(0, 0), // 在容器中心位置 (width=2, 所以中心是1)
      Offset(0, size.height - 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TimeIndicatorPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// 缩略图图片组件 - 按需生成和加载对应时间点的缩略图
class _ThumbnailImage extends StatefulWidget {
  final int index;
  final double timeIntervalSeconds;
  final double totalDurationSeconds;
  final String coverImage;
  final double thumbnailHeight;
  final BoxFit fit;

  const _ThumbnailImage({
    required this.index,
    required this.timeIntervalSeconds,
    required this.totalDurationSeconds,
    required this.coverImage,
    required this.thumbnailHeight,
    required this.fit,
  });

  @override
  State<_ThumbnailImage> createState() => _ThumbnailImageState();
}

/// 缩略图生成任务包装器
class _ThumbnailTask {
  final int index;
  final Completer<void> completer;
  bool isCancelled = false;

  _ThumbnailTask(this.index, this.completer);

  void cancel() {
    if (!isCancelled && !completer.isCompleted) {
      isCancelled = true;
      completer.completeError('Task cancelled');
    }
  }

  void complete() {
    if (!isCancelled && !completer.isCompleted) {
      completer.complete();
    }
  }
}

/// 缩略图生成管理器 - 限制并发生成数量
class _ThumbnailGenerationManager {
  static final _ThumbnailGenerationManager _instance =
      _ThumbnailGenerationManager._internal();
  factory _ThumbnailGenerationManager() => _instance;
  _ThumbnailGenerationManager._internal();

  // 最大并发数（同时生成的缩略图数量）。
  // 每个 ffmpeg 自身还开多线程解码，8 并发会打满 CPU 拖垮滚动帧率；
  // 2 已足够流水线供图，且给 UI/光栅线程留出余量。
  static const int _maxConcurrent = 2;
  // 最大队列长度（超过则拒绝新任务）
  static const int _maxQueueLength = 100;

  int _currentCount = 0;
  final List<_ThumbnailTask> _waitingQueue = [];
  final Map<int, _ThumbnailTask> _taskMap = {};

  /// 请求生成缩略图的许可
  Future<void> acquire(int index) async {
    // 检查队列是否已满
    if (_waitingQueue.length >= _maxQueueLength) {
      throw Exception('Queue full');
    }

    if (_currentCount < _maxConcurrent) {
      _currentCount++;
      return;
    }

    // 需要等待
    final completer = Completer<void>();
    final task = _ThumbnailTask(index, completer);
    _waitingQueue.add(task);
    _taskMap[index] = task;

    try {
      await completer.future;
      _taskMap.remove(index);
    } catch (e) {
      _taskMap.remove(index);
      rethrow;
    }
  }

  /// 取消指定索引的任务
  void cancel(int index) {
    final task = _taskMap[index];
    if (task != null) {
      task.cancel();
      _waitingQueue.remove(task);
      _taskMap.remove(index);
    }
  }

  /// 释放生成许可
  void release(int index) {
    // 清理已取消的任务
    _waitingQueue.removeWhere((task) => task.isCancelled);

    if (_waitingQueue.isNotEmpty) {
      // 唤醒下一个等待的任务
      final task = _waitingQueue.removeAt(0);
      task.complete();
    } else {
      _currentCount--;
    }
  }
}

class _ThumbnailImageState extends State<_ThumbnailImage> {
  String? _thumbnailPath;
  bool _isGenerating = false;
  bool _hasError = false;
  bool _isCancelled = false; // 标记任务是否被取消
  final _manager = _ThumbnailGenerationManager();
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();
    _checkCacheOrScheduleGeneration();
  }

  /// 检查缓存，如果不存在则安排延迟生成
  Future<void> _checkCacheOrScheduleGeneration() async {
    if (_isCancelled) return;

    final trimmerBloc = context.read<TrimmerBloc>();
    final thumbnailConfig = trimmerBloc.state.thumbnailConfig;

    if (thumbnailConfig == null) return;

    final timeOffset = _calculateTimeOffset();
    final fileName = _getThumbnailFileName(
      timeOffset,
      thumbnailConfig.format,
      thumbnailConfig.width,
    );
    final thumbnailPath = path.join(thumbnailConfig.dirPath, fileName);
    final thumbnailFile = File(thumbnailPath);

    // 检查缓存是否存在
    if (await thumbnailFile.exists()) {
      // 缓存存在，立即加载
      if (mounted) {
        setState(() {
          _thumbnailPath = thumbnailPath;
        });
      }
    } else {
      // 缓存不存在，延迟生成（避免快速滚动时浪费资源）
      _initTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted && !_isCancelled) {
          _loadOrGenerateThumbnail();
        }
      });
    }
  }

  @override
  void dispose() {
    _isCancelled = true;
    _initTimer?.cancel();
    _manager.cancel(widget.index);
    super.dispose();
  }

  /// 计算当前缩略图对应的时间点（秒）
  ///
  /// Uses fixed [timeIntervalSeconds] per tile so sample times match tile seams
  /// (not duration/N, which drifts when the last tile is partial).
  double _calculateTimeOffset() {
    final interval = widget.timeIntervalSeconds;
    final start = widget.index * interval;
    final end = (start + interval).clamp(0.0, widget.totalDurationSeconds);
    return (start + end) / 2.0;
  }

  /// 生成缩略图文件名（基于时间点与生成宽度，确保唯一性和可复用性）
  String _getThumbnailFileName(double timeOffset, String format, int width) {
    // 使用两位小数精度，避免文件名过长；宽度参与命名，桌面/移动 tile 互不混淆
    final timeStr = timeOffset.toStringAsFixed(2);
    return 'thumbnail_${width}_$timeStr.$format';
  }

  /// 生成缩略图（缓存不存在时调用）
  Future<void> _loadOrGenerateThumbnail() async {
    if (_isGenerating || _hasError || _isCancelled) return;

    try {
      final trimmerBloc = context.read<TrimmerBloc>();
      final thumbnailConfig = trimmerBloc.state.thumbnailConfig;

      if (thumbnailConfig == null) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      final timeOffset = _calculateTimeOffset();
      final fileName = _getThumbnailFileName(
        timeOffset,
        thumbnailConfig.format,
        thumbnailConfig.width,
      );

      if (mounted) {
        setState(() => _isGenerating = true);
      }

      // 请求生成许可（如果并发数已满，会在这里等待）
      try {
        await _manager.acquire(widget.index);
      } catch (e) {
        // 队列已满或任务被取消
        if (mounted) {
          setState(() => _isGenerating = false);
        }
        return;
      }

      // 获得许可后再次检查是否已取消
      if (_isCancelled) {
        _manager.release(widget.index);
        return;
      }

      try {
        // 重试机制：最多尝试2次
        String? generatedPath;
        int retryCount = 0;
        const maxRetries = 2;

        while (retryCount < maxRetries &&
            generatedPath == null &&
            !_isCancelled) {
          try {
            generatedPath = await VideoUtils.generateVideoThumbnail(
              thumbnailConfig.videoPath,
              dirPath: thumbnailConfig.dirPath,
              fileName: fileName,
              timeOffset: timeOffset,
              width: thumbnailConfig.width,
              quality: thumbnailConfig.quality,
              format: thumbnailConfig.format,
              reuseExisting: true,
            );
          } catch (e) {
            retryCount++;
            if (retryCount >= maxRetries) {
              rethrow;
            }
            // 重试前等待一小段时间
            if (!_isCancelled) {
              await Future.delayed(Duration(milliseconds: 100 * retryCount));
            }
          }
        }

        if (_isCancelled) return;

        if (mounted && generatedPath != null) {
          setState(() {
            _thumbnailPath = generatedPath;
            _isGenerating = false;
          });
        }
      } finally {
        // 无论成功或失败，都要释放许可
        _manager.release(widget.index);
        if (mounted && _isGenerating) {
          setState(() => _isGenerating = false);
        }
      }
    } catch (e) {
      if (mounted && !_isCancelled) {
        setState(() {
          _hasError = true;
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果缩略图已生成，显示缩略图
    if (_thumbnailPath != null) {
      return Image.file(
        File(_thumbnailPath!),
        fit: widget.fit,
        width: widget.thumbnailHeight,
        height: widget.thumbnailHeight,
        // 按显示尺寸×2 解码（高 DPI 清晰）；解码原始 384px PNG 约 4 倍内存/上传开销
        cacheWidth: (widget.thumbnailHeight * 2).round(),
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          // 加载失败时也使用第一帧缩略图作为后备
          return _buildCoverImagePlaceholder();
        },
      );
    }

    // 如果正在生成或出错，显示第一帧缩略图作为占位符
    return _buildCoverImagePlaceholder();
  }

  /// 构建占位符（使用第一帧封面图）
  Widget _buildCoverImagePlaceholder() {
    return Image.file(
      File(widget.coverImage),
      fit: widget.fit,
      width: widget.thumbnailHeight,
      height: widget.thumbnailHeight,
      // 同上：封面图也按显示尺寸×2 解码
      cacheWidth: (widget.thumbnailHeight * 2).round(),
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        // 如果连第一帧也加载失败，显示灰色占位符
        return Container(
          color: context.trimmerTheme.placeholderBackground,
          child: const Center(child: SizedBox(width: 16, height: 16)),
        );
      },
    );
  }
}
