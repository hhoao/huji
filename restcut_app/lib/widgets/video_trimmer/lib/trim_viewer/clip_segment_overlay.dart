import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_state.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:restcut/widgets/video_trimmer/lib/trim_viewer/custom_divider_painters.dart';

/// 视频剪辑片段覆盖层
class ClipSegmentOverlay extends StatelessWidget {
  final double thumbnailHeight;

  const ClipSegmentOverlay({super.key, required this.thumbnailHeight});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
      bloc: context.read<ClipSegmentBloc>(),
      buildWhen: (previous, current) =>
          previous.activeSegments != current.activeSegments,
      builder: (context, state) {
        final segments = state.allSegments;
        if (segments.isEmpty) {
          return const SizedBox.shrink();
        }

        // 计算总宽度
        final totalDurationSeconds =
            context.read<TrimmerBloc>().state.totalDuration / 1000.0;
        final actualThumbnailCount =
            (totalDurationSeconds /
                    context.read<TrimmerBloc>().state.timeIntervalSeconds)
                .ceil();
        final totalWidth = actualThumbnailCount * thumbnailHeight;

        // 使用 StatefulBuilder 来管理 controller 的生命周期
        return _ClipSegmentOverlayContent(
          thumbnailHeight: thumbnailHeight,
          totalWidth: totalWidth,
          segments: segments,
        );
      },
    );
  }
}

/// 内部 StatefulWidget 用于管理 MultiSplitViewController 的生命周期
class _ClipSegmentOverlayContent extends StatefulWidget {
  final double thumbnailHeight;
  final double totalWidth;
  final List<VideoClipSegment> segments;

  const _ClipSegmentOverlayContent({
    required this.thumbnailHeight,
    required this.totalWidth,
    required this.segments,
  });

  @override
  State<_ClipSegmentOverlayContent> createState() =>
      _ClipSegmentOverlayContentState();
}

class _ClipSegmentOverlayContentState
    extends State<_ClipSegmentOverlayContent> {
  late MultiSplitViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MultiSplitViewController();
    _updateController();
  }

  @override
  void didUpdateWidget(_ClipSegmentOverlayContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments) {
      _updateController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateController() {
    final segments = widget.segments;
    if (segments.isEmpty) {
      return;
    }
    final totalDuration = context.read<TrimmerBloc>().state.totalDuration;

    setState(() {
      _controller.areas = List.generate(segments.length, (index) {
        final segment = segments[index];
        // 填充区域使用固定的小尺寸
        final size =
            segment.getDuration().toDouble() /
            totalDuration *
            widget.totalWidth;
        return Area(
          size: size,
          builder: (context, area) => _buildSegmentWidget(segment),
        );
      });
    });
  }

  Widget _buildSegmentWidget(VideoClipSegment segment) {
    // 如果片段已删除，显示占位符
    if (segment.isDeleted) {
      return Container(height: widget.thumbnailHeight);
    }

    // 正常片段的显示
    return GestureDetector(
      onTap: () {
        if (!segment.isSelected) {
          context.read<ClipSegmentBloc>().add(
            ClipSegmentSelect(segment: segment),
          );
        }
      },
      child: Container(
        height: widget.thumbnailHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: segment.isSelected ? Colors.white : Colors.white,
            width: segment.isSelected ? 2.0 : 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.segments;
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildMultiSplitView(context, segments);
  }

  Widget _buildMultiSplitView(
    BuildContext context,
    List<VideoClipSegment> segments,
  ) {
    MultiSplitView multiSplitView = MultiSplitView(
      onDividerDragUpdate: (dividerIndex) {
        final areas = _controller.areas;

        if (dividerIndex >= 0 && dividerIndex < areas.length - 1) {
          final leftAreaEndPosition = areas
              .take(dividerIndex + 1)
              .fold<double>(0, (sum, area) => sum + (area.size ?? 0.0));

          context.read<ClipSegmentBloc>().add(
            ClipSegmentDividerDragUpdate(
              dividerIndex: dividerIndex,
              newPosition: leftAreaEndPosition,
              totalWidth: widget.totalWidth,
            ),
          );
        }
      },
      dividerBuilder:
          (axis, dividerIndex, resizable, dragging, highlighted, themeData) {
            // 使用独立的 Widget，只有 Divider 部分会响应状态变化
            return _ConditionalDivider(
              axis: axis,
              dividerIndex: dividerIndex,
              resizable: resizable,
              dragging: dragging,
              highlighted: highlighted,
              themeData: themeData,
              segments: segments,
            );
          },
      pushDividers: true,
      controller: _controller,
      axis: Axis.horizontal,
    );

    MultiSplitViewTheme theme = MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 0,
        dividerHandleBuffer: 12,
        dividerPainter: CustomDividerPainters.roundedRect(
          size: 30,
          thickness: 8,
          highlightedSize: widget.thumbnailHeight,
          highlightedThickness: 8,
          backgroundColor: Colors.white,
          highlightedBackgroundColor: Colors.white,
          dividerColor: Colors.black,
          highlightedDividerColor: Colors.black,
          borderRadius: 4,
        ),
      ),
      child: multiSplitView,
    );

    // 直接返回 MultiSplitView，滚动由外层处理
    return SizedBox(width: widget.totalWidth, child: theme);
  }
}

/// 条件显示的 Divider Widget，使用 BlocBuilder 只更新 Divider 部分
class _ConditionalDivider extends StatelessWidget {
  final Axis axis;
  final int dividerIndex;
  final bool resizable;
  final bool dragging;
  final bool highlighted;
  final MultiSplitViewThemeData themeData;
  final List<VideoClipSegment> segments;

  const _ConditionalDivider({
    required this.axis,
    required this.dividerIndex,
    required this.resizable,
    required this.dragging,
    required this.highlighted,
    required this.themeData,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 BlocSelector 只选择 selectedSegment，避免不必要的重建
    return BlocSelector<ClipSegmentBloc, ClipSegmentState, VideoClipSegment?>(
      selector: (state) => state.selectedSegment,
      builder: (context, selectedSegment) {
        // 读取最新的 segments 状态
        final currentSegments = context
            .read<ClipSegmentBloc>()
            .state
            .allSegments;

        // Divider 位于两个片段之间，需要检查左右两侧片段是否至少有一个被选中
        // dividerIndex 表示左侧片段的索引
        final leftSegmentSelected =
            dividerIndex >= 0 &&
            dividerIndex < currentSegments.length &&
            currentSegments[dividerIndex].isSelected;
        final rightSegmentSelected =
            dividerIndex + 1 < currentSegments.length &&
            currentSegments[dividerIndex + 1].isSelected;

        // 如果左右两侧片段都没有被选中，不显示 Divider
        if (!leftSegmentSelected && !rightSegmentSelected) {
          return const SizedBox.shrink();
        }

        // 返回默认的 Divider（使用主题的 DividerWidget）
        return DividerWidget(
          axis: axis,
          index: dividerIndex,
          themeData: themeData,
          highlighted: highlighted,
          resizable: resizable,
          dragging: dragging,
        );
      },
    );
  }
}
