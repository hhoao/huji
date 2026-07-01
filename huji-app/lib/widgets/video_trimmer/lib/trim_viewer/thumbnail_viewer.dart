import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_state.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/clip_segment_overlay.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/trim_area_properties.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/trim_editor_properties.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_layout.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';

/// Widget for displaying the video trimmer.
class ScrollableTrimViewer extends StatelessWidget {
  final TrimEditorProperties editorProperties;

  final TrimAreaProperties areaProperties;

  const ScrollableTrimViewer({
    super.key,
    this.editorProperties = const TrimEditorProperties(),
    this.areaProperties = const TrimAreaProperties(),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildThumbnailArea(context)]);
  }

  Widget _buildThumbnailArea(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final layout = context.trimmerLayout;
    final thumbnailTileSize = layout.thumbnailTileSize;
    final timeRulerHeight = layout.timeRulerHeight;
    final bottomSpanHeight = editorProperties.bottomSpanHeight;
    final numberOfThumbnails =
        ((context.read<TrimmerBloc>().state.totalDuration /
                    context.read<TrimmerBloc>().state.timeIntervalSeconds) /
                1000.0)
            .ceil();
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
                  numberOfThumbnails * thumbnailTileSize +
                  constraints.maxWidth +
                  constraints.maxWidth,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScrollableThumbnailViewer(
                    fit: areaProperties.thumbnailFit,
                    thumbnailHeight: thumbnailTileSize,
                    numberOfThumbnails: numberOfThumbnails,
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
    required this.fit,
    this.timeRulerHeight = 40,
    this.bottomSpanHeight = 0,
    this.leftWidgetWidth = 0,
  });

  final double thumbnailHeight;

  final int numberOfThumbnails;

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
    final totalWidth = leftWidgetWidth + thumbnailHeight * numberOfThumbnails;

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

/// 时间标尺片段绘制器（只绘制当前 item 对应位置的时间刻度）
class _TimeRulerSegmentPainter extends CustomPainter {
  final double totalDuration;
  final double totalWidth;
  final double itemStartTime;
  final double itemEndTime;
  final double itemLeftInTotal; // item 在整个时间标尺中的位置（固定）
  final double itemLeftInView; // item 在可见区域中的位置（随滚动变化）
  final double shortInterval;
  final double longInterval;
  final int textInterval;
  final Color tickColor;
  final TextStyle textStyle;

  _TimeRulerSegmentPainter({
    required this.totalDuration,
    required this.totalWidth,
    required this.itemStartTime,
    required this.itemEndTime,
    required this.itemLeftInTotal,
    required this.itemLeftInView,
    required this.shortInterval,
    required this.longInterval,
    required this.textInterval,
    required this.tickColor,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 提前计算常量，避免循环内重复计算
    final longIntervalCount = (longInterval / shortInterval).round();
    final startMark = (itemStartTime / shortInterval).floor();
    final endMark = (itemEndTime / shortInterval).ceil();

    // 复用 Paint 对象，避免重复创建
    final paint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 只绘制在当前 item 时间范围内的刻度线
    for (int i = startMark; i <= endMark; i++) {
      final time = i * shortInterval;
      // 计算刻度在整个时间标尺中的 x 位置
      final xInTotal = (time / totalDuration) * totalWidth;
      // 转换为当前 item 内的相对位置（考虑滚动）
      final x = xInTotal - itemLeftInTotal;

      // 跳过超出当前 item 范围的刻度线
      if (x < 0 || x > size.width) continue;

      // 判断是否为长线（每5秒）
      final isLongLine = (i % longIntervalCount) == 0;

      // 绘制刻度线
      canvas.drawLine(Offset(x, 0), Offset(x, isLongLine ? 8 : 4), paint);

      // 绘制时间文本（textInterval 表示刻度数量，每5个刻度即1秒显示一次）
      if (i % textInterval == 0) {
        final timeText = _formatTime(time);
        textPainter.text = TextSpan(text: timeText, style: textStyle);
        textPainter.layout();
        // 确保文本不超出当前 item 范围
        final textX = (x - textPainter.width / 2).clamp(
          0.0,
          size.width - textPainter.width,
        );
        textPainter.paint(canvas, Offset(textX, 16));
      }
    }
  }

  /// 格式化时间显示
  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _TimeRulerSegmentPainter oldDelegate) {
    return oldDelegate.itemLeftInView != itemLeftInView ||
        oldDelegate.itemStartTime != itemStartTime ||
        oldDelegate.itemEndTime != itemEndTime ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.textStyle != textStyle;
  }
}

/// 缩略图列表构建器，内部维护列表并使用 StreamBuilder 监听流
class _ThumbnailListBuilder extends StatelessWidget {
  final Stream<ThumbnailConfig> stream;
  final int numberOfThumbnails;
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
    final totalWidth = numberOfThumbnails * thumbnailHeight;

    // 使用 Stack 叠加覆盖层
    return Stack(
      children: [
        // ListView 作为底层
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
            return RepaintBoundary(
              key: ValueKey('thumbnail_$thumbnailIndex'),
              child: SizedBox(
                height: itemHeight,
                width: thumbnailHeight,
                child: _getListViewItem(
                  context,
                  thumbnailIndex,
                  totalDuration: totalDuration,
                  totalDurationSeconds: totalDurationSeconds,
                  totalWidth: totalWidth,
                ),
              ),
            );
          },
        ),
        // 覆盖层 - 使用 AnimatedBuilder 跟随滚动
        AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final scrollOffset = scrollController.hasClients
                ? scrollController.offset
                : 0.0;

            return Positioned(
              top: timeRulerHeight,
              left: leftWidgetWidth - scrollOffset, // 根据滚动偏移调整位置
              width: totalWidth,
              height: thumbnailHeight,
              child: child!,
            );
          },
          child: IgnorePointer(
            ignoring: false, // 允许点击和拖动交互
            child: ClipSegmentOverlay(thumbnailHeight: thumbnailHeight),
          ),
        ),
      ],
    );
  }

  Widget _getListViewItem(
    BuildContext context,
    int index, {
    required double totalDuration,
    required double totalDurationSeconds,
    required double totalWidth,
  }) {
    final totalHeight = timeRulerHeight + thumbnailHeight + bottomSpanHeight;

    return SizedBox(
      height: totalHeight,
      width: thumbnailHeight,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 时间标尺部分 - 固定高度
          SizedBox(
            height: timeRulerHeight,
            width: thumbnailHeight,
            child: _buildTimeRulerSegment(
              context,
              index,
              totalDurationSeconds: totalDurationSeconds,
              totalWidth: totalWidth,
            ),
          ),
          // 缩略图图片 - 固定高度
          SizedBox(
            height: thumbnailHeight,
            width: thumbnailHeight,
            child: _ThumbnailImage(
              index: index,
              numberOfThumbnails: numberOfThumbnails,
              totalDurationSeconds: totalDurationSeconds,
              coverImage: coverImage!,
              thumbnailHeight: thumbnailHeight,
              fit: fit,
            ),
          ),
          // 底部区域部分（灰色区域 + 滑动区域）- 固定高度
          SizedBox(
            height: bottomSpanHeight,
            width: thumbnailHeight,
            child: _buildBottomSpanSegment(context, index),
          ),
        ],
      ),
    );
  }

  /// 构建时间标尺片段（每个 item 只绘制自己对应位置的时间刻度）
  Widget _buildTimeRulerSegment(
    BuildContext context,
    int index, {
    required double totalDurationSeconds,
    required double totalWidth,
  }) {
    if (totalDurationSeconds == 0) {
      return SizedBox(height: timeRulerHeight, width: thumbnailHeight);
    }

    final trimmerTheme = context.trimmerTheme;
    final textTheme = Theme.of(context).textTheme;
    const shortInterval = 0.2;
    const longInterval = 5.0;
    const textInterval = 5;

    // 计算每个 item 代表的时间段（固定值，不随滚动变化）
    final timePerItem = totalDurationSeconds / numberOfThumbnails;
    final itemStartTime = index * timePerItem;
    final itemEndTime = (index + 1) * timePerItem;

    // item 在整个时间标尺中的位置（固定值）
    final itemLeftInTotal = index * thumbnailHeight;

    // 使用 AnimatedBuilder 监听滚动位置，使时间标尺跟随滚动
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, child) {
          final scrollOffset = scrollController.offset;
          // item 在可见区域中的位置（随滚动变化）
          final itemLeftInView = itemLeftInTotal - scrollOffset;

          return CustomPaint(
            size: Size(thumbnailHeight, timeRulerHeight),
            painter: _TimeRulerSegmentPainter(
              totalDuration: totalDurationSeconds,
              totalWidth: totalWidth,
              itemStartTime: itemStartTime,
              itemEndTime: itemEndTime,
              itemLeftInTotal: itemLeftInTotal,
              itemLeftInView: itemLeftInView,
              shortInterval: shortInterval,
              longInterval: longInterval,
              textInterval: textInterval,
              tickColor: trimmerTheme.rulerTickColor,
              textStyle: textTheme.labelSmall?.copyWith(
                    color: trimmerTheme.rulerLabelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ) ??
                  TextStyle(
                    color: trimmerTheme.rulerLabelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          );
        },
      ),
    );
  }

  /// 构建底部区域片段（灰色区域 + 滑动区域，每个 item 只显示自己对应位置的部分）
  Widget _buildBottomSpanSegment(BuildContext context, int index) {
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
            width: thumbnailHeight,
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
    final textTheme = Theme.of(context).textTheme;
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        setState(() {
          _isMuted = !_isMuted;
        });
        widget.onPress(_isMuted);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isMuted ? Icons.volume_off : Icons.volume_up,
            color: trimmerTheme.onToolbar,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            _isMuted ? '开启声音' : '关闭声音',
            style: textTheme.labelSmall?.copyWith(
              color: trimmerTheme.onToolbar,
              fontSize: 8,
            ),
          ),
        ],
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
  final int numberOfThumbnails;
  final double totalDurationSeconds;
  final String coverImage;
  final double thumbnailHeight;
  final BoxFit fit;

  const _ThumbnailImage({
    required this.index,
    required this.numberOfThumbnails,
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

  // 最大并发数（同时生成的缩略图数量）
  static const int _maxConcurrent = 8;
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
    final fileName = _getThumbnailFileName(timeOffset, thumbnailConfig.format);
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
  double _calculateTimeOffset() {
    final timePerThumbnail =
        widget.totalDurationSeconds / widget.numberOfThumbnails;
    // 使用缩略图的中间时间点
    return (widget.index + 0.5) * timePerThumbnail;
  }

  /// 生成缩略图文件名（基于时间点，确保唯一性和可复用性）
  String _getThumbnailFileName(double timeOffset, String format) {
    // 使用两位小数精度，避免文件名过长
    final timeStr = timeOffset.toStringAsFixed(2);
    return 'thumbnail_$timeStr.$format';
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
        // 移除 cacheWidth/cacheHeight 限制，使用原始图片质量
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
      // 移除 cacheWidth/cacheHeight 限制，使用原始图片质量
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
