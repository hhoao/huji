import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:huji_app/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_state.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/custom_divider_painters.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_layout.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';

/// 视频剪辑片段覆盖层
class ClipSegmentOverlay extends StatelessWidget {
  final double thumbnailHeight;

  const ClipSegmentOverlay({super.key, required this.thumbnailHeight});

  @override
  Widget build(BuildContext context) {
    // Depend on trimmer theme so light/dark and palette changes rebuild overlays.
    final _ = context.trimmerTheme;

    return BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
      bloc: context.read<ClipSegmentBloc>(),
      // 用内容比较：state 每次 emit 都是新 List，引用比较会恒真，
      // 导致选中变化等无关更新也触发整层重建
      buildWhen: (previous, current) => !previous.sameSegments(current),
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

  /// 分割线拖拽进行中。multi_split_view 拖拽时自己维护布局，
  /// 此时用 segments 回写 [MultiSplitViewController.areas] 会和手势
  /// 相互对抗（每次 tick 重排、跟手感差），所以拖拽期间跳过同步，
  /// 结束后一次性对齐。
  bool _dividerDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = MultiSplitViewController();
    _updateController();
  }

  @override
  void didUpdateWidget(_ClipSegmentOverlayContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameSegmentLayout(oldWidget.segments, widget.segments) &&
        !_dividerDragging) {
      _updateController();
    }
  }

  bool _sameSegmentLayout(
    List<VideoClipSegment> a,
    List<VideoClipSegment> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].startTime != b[i].startTime ||
          a[i].endTime != b[i].endTime ||
          a[i].isDeleted != b[i].isDeleted) {
        return false;
      }
    }
    return true;
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
    if (totalDuration <= 0) {
      return;
    }

    setState(() {
      _controller.areas = List.generate(segments.length, (index) {
        final segment = segments[index];
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
    final layout = context.trimmerLayout;
    if (segment.isDeleted) {
      return Container(height: widget.thumbnailHeight);
    }

    return BlocSelector<ClipSegmentBloc, ClipSegmentState, bool>(
      selector: (state) => state.selectedSegment?.id == segment.id,
      builder: (context, isSelected) {
        final borderWidth = isSelected
            ? layout.segmentSelectedBorderWidth
            : layout.segmentBorderWidth;
        const borderColor = Colors.white;

        return GestureDetector(
          onTap: () {
            if (!isSelected) {
              context.read<ClipSegmentBloc>().add(
                ClipSegmentSelect(segment: segment),
              );
            }
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: borderWidth),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Depend on trimmer theme so divider handles track palette changes.
    final trimmerTheme = context.trimmerTheme;

    final segments = widget.segments;
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildMultiSplitView(context, segments, trimmerTheme);
  }

  Widget _buildMultiSplitView(
    BuildContext context,
    List<VideoClipSegment> segments,
    TrimmerThemeData trimmerTheme,
  ) {
    final layout = context.trimmerLayout;
    MultiSplitView multiSplitView = MultiSplitView(
      onDividerDragStart: (_) => _dividerDragging = true,
      onDividerDragEnd: (_) {
        _dividerDragging = false;
        // 拖拽期间跳过了同步，结束后用最新 segments 对齐一次
        _updateController();
      },
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
              thumbnailHeight: widget.thumbnailHeight,
              segments: segments,
            );
          },
      pushDividers: true,
      controller: _controller,
      axis: Axis.horizontal,
    );

    MultiSplitViewTheme theme = MultiSplitViewTheme(
      data: _dividerThemeData(
        layout: layout,
        thumbnailHeight: widget.thumbnailHeight,
        isActive: true,
      ),
      child: multiSplitView,
    );

    // 直接返回 MultiSplitView，滚动由外层处理
    return SizedBox(width: widget.totalWidth, child: theme);
  }
}

/// 片段边界拖动手柄；选中片段相邻的手柄高亮，其余保持可见但弱化。
class _ConditionalDivider extends StatelessWidget {
  final Axis axis;
  final int dividerIndex;
  final bool resizable;
  final bool dragging;
  final bool highlighted;
  final double thumbnailHeight;
  final List<VideoClipSegment> segments;

  const _ConditionalDivider({
    required this.axis,
    required this.dividerIndex,
    required this.resizable,
    required this.dragging,
    required this.highlighted,
    required this.thumbnailHeight,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ClipSegmentBloc, ClipSegmentState, VideoClipSegment?>(
      selector: (state) => state.selectedSegment,
      builder: (context, selectedSegment) {
        final currentSegments = context
            .read<ClipSegmentBloc>()
            .state
            .allSegments;

        final leftSegmentSelected =
            dividerIndex >= 0 &&
            dividerIndex < currentSegments.length &&
            currentSegments[dividerIndex].isSelected;
        final rightSegmentSelected =
            dividerIndex + 1 < currentSegments.length &&
            currentSegments[dividerIndex + 1].isSelected;
        final isActive = leftSegmentSelected || rightSegmentSelected;

        final layout = context.trimmerLayout;

        final themeData = _dividerThemeData(
          layout: layout,
          thumbnailHeight: thumbnailHeight,
          isActive: isActive,
        );

        return DividerWidget(
          axis: axis,
          index: dividerIndex,
          themeData: themeData,
          highlighted: highlighted || isActive,
          resizable: resizable,
          dragging: dragging,
        );
      },
    );
  }
}

MultiSplitViewThemeData _dividerThemeData({
  required TrimmerLayoutMetrics layout,
  required double thumbnailHeight,
  required bool isActive,
}) {
  // Fixed dark-theme handle chrome: white pill + dark center line on thumbnails.
  const handleBg = Colors.white;
  const handleFg = Color(0xFF1A1A1D);
  final activeBg = isActive ? handleBg : handleBg.withValues(alpha: 0.72);
  final activeFg = isActive ? handleFg : handleFg.withValues(alpha: 0.85);

  return MultiSplitViewThemeData(
    dividerThickness: 0,
    dividerHandleBuffer: layout.dividerHandleBuffer,
    dividerPainter: CustomDividerPainters.roundedRect(
      size: isActive
          ? layout.dividerHandleSize
          : layout.dividerHandleSize * 0.88,
      thickness: isActive
          ? layout.dividerHandleThickness
          : layout.dividerHandleThickness - 2,
      highlightedSize: thumbnailHeight,
      highlightedThickness: layout.dividerHandleThickness + 2,
      backgroundColor: activeBg,
      highlightedBackgroundColor: handleBg,
      dividerColor: activeFg,
      highlightedDividerColor: handleFg,
      borderRadius: 6,
    ),
  );
}
