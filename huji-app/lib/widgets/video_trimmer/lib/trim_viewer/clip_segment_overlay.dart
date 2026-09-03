import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_state.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_layout.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';

/// 视频剪辑片段覆盖层
class ClipSegmentOverlay extends StatelessWidget {
  final double thumbnailHeight;

  /// Must match the ruler / thumbnail strip width (single coordinate space).
  final double totalWidth;

  const ClipSegmentOverlay({
    super.key,
    required this.thumbnailHeight,
    required this.totalWidth,
  });

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

        return _ClipSegmentOverlayContent(
          thumbnailHeight: thumbnailHeight,
          totalWidth: totalWidth,
          segments: segments,
        );
      },
    );
  }
}

/// Absolute-time Stack overlay: borders sit on [timeToTimelineX], independent of
/// MultiSplitView cumulative pane layout.
class _ClipSegmentOverlayContent extends StatelessWidget {
  final double thumbnailHeight;
  final double totalWidth;
  final List<VideoClipSegment> segments;

  const _ClipSegmentOverlayContent({
    required this.thumbnailHeight,
    required this.totalWidth,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = context.read<TrimmerBloc>().state.totalDuration;
    if (totalDuration <= 0 || totalWidth <= 0) {
      return const SizedBox.shrink();
    }

    final totalDurationSeconds = totalDuration / 1000.0;
    final layout = context.trimmerLayout;

    return SizedBox(
      width: totalWidth,
      height: thumbnailHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._buildSegmentBorders(totalDurationSeconds),
          for (var i = 0; i < segments.length - 1; i++)
            _SegmentBoundaryHandle(
              key: ValueKey('divider_${segments[i].id}_${segments[i + 1].id}'),
              dividerIndex: i,
              boundaryX: timeToTimelineX(
                timeSeconds: segments[i].endTime / 1000.0,
                totalDurationSeconds: totalDurationSeconds,
                totalWidth: totalWidth,
              ),
              totalWidth: totalWidth,
              thumbnailHeight: thumbnailHeight,
              layout: layout,
              leftSegment: segments[i],
              rightSegment: segments[i + 1],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSegmentBorders(double totalDurationSeconds) {
    final borders = <Widget>[];
    for (final segment in segments) {
      if (segment.isDeleted) continue;
      final left = timeToTimelineX(
        timeSeconds: segment.startTime / 1000.0,
        totalDurationSeconds: totalDurationSeconds,
        totalWidth: totalWidth,
      );
      final right = timeToTimelineX(
        timeSeconds: segment.endTime / 1000.0,
        totalDurationSeconds: totalDurationSeconds,
        totalWidth: totalWidth,
      );
      final width = (right - left).clamp(0.0, totalWidth);
      if (width <= 0) continue;
      borders.add(
        Positioned(
          left: left,
          width: width,
          top: 0,
          bottom: 0,
          child: _SegmentBorder(segment: segment),
        ),
      );
    }
    return borders;
  }
}

class _SegmentBorder extends StatelessWidget {
  const _SegmentBorder({required this.segment});

  final VideoClipSegment segment;

  @override
  Widget build(BuildContext context) {
    final layout = context.trimmerLayout;

    return BlocSelector<ClipSegmentBloc, ClipSegmentState, bool>(
      selector: (state) => state.selectedSegment?.id == segment.id,
      builder: (context, isSelected) {
        final borderWidth = isSelected
            ? layout.segmentSelectedBorderWidth
            : layout.segmentBorderWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!isSelected) {
              context.read<ClipSegmentBloc>().add(
                ClipSegmentSelect(segment: segment),
              );
            }
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: borderWidth),
            ),
          ),
        );
      },
    );
  }
}

class _SegmentBoundaryHandle extends StatefulWidget {
  const _SegmentBoundaryHandle({
    super.key,
    required this.dividerIndex,
    required this.boundaryX,
    required this.totalWidth,
    required this.thumbnailHeight,
    required this.layout,
    required this.leftSegment,
    required this.rightSegment,
  });

  final int dividerIndex;
  final double boundaryX;
  final double totalWidth;
  final double thumbnailHeight;
  final TrimmerLayoutMetrics layout;
  final VideoClipSegment leftSegment;
  final VideoClipSegment rightSegment;

  @override
  State<_SegmentBoundaryHandle> createState() => _SegmentBoundaryHandleState();
}

class _SegmentBoundaryHandleState extends State<_SegmentBoundaryHandle> {
  bool _dragging = false;
  bool _hovering = false;
  late double _visualX = widget.boundaryX;

  @override
  void didUpdateWidget(covariant _SegmentBoundaryHandle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // While dragging, keep the pill on the finger path, not the model boundary —
    // otherwise each emit repositions the hit target and jitters.
    if (!_dragging) {
      _visualX = widget.boundaryX;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ClipSegmentBloc, ClipSegmentState, bool>(
      selector: (state) {
        final selectedId = state.selectedSegment?.id;
        return selectedId == widget.leftSegment.id ||
            selectedId == widget.rightSegment.id;
      },
      builder: (context, isActive) {
        final layout = widget.layout;
        final handleBuffer = layout.dividerHandleBuffer;
        final highlighted = isActive || _dragging || _hovering;
        // Match old MultiSplitView theme: idle capsule vs full-tile highlight.
        final handleHeight = highlighted
            ? widget.thumbnailHeight
            : layout.dividerHandleSize * 0.88;
        final thickness = highlighted
            ? layout.dividerHandleThickness + 2
            : layout.dividerHandleThickness - 2;

        // Hit target is symmetric around the shared border at [_visualX].
        // (Using left = x - buffer with width = thickness + 2*buffer centers
        // the paint at x + thickness/2 and leaves the capsule off the seam.)
        final hitWidth = layout.dividerHandleThickness + 2 * handleBuffer;

        return Positioned(
          left: _visualX - hitWidth / 2,
          width: hitWidth,
          top: 0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) {
                _dragging = true;
                _visualX = widget.boundaryX;
              },
              onHorizontalDragUpdate: (details) {
                _visualX = (_visualX + details.delta.dx).clamp(
                  0.0,
                  widget.totalWidth,
                );
                context.read<ClipSegmentBloc>().add(
                  ClipSegmentDividerDragUpdate(
                    dividerIndex: widget.dividerIndex,
                    newPosition: _visualX,
                    totalWidth: widget.totalWidth,
                  ),
                );
                setState(() {});
              },
              onHorizontalDragEnd: (_) {
                setState(() => _dragging = false);
              },
              onHorizontalDragCancel: () {
                setState(() => _dragging = false);
              },
              child: CustomPaint(
                painter: _RoundedHandlePainter(
                  handleHeight: handleHeight.clamp(0, widget.thumbnailHeight),
                  thickness: thickness,
                  background: Colors.white.withValues(
                    alpha: highlighted ? 1.0 : 0.72,
                  ),
                  foreground: const Color(0xFF1A1A1D).withValues(
                    alpha: highlighted ? 1.0 : 0.85,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Same visual language as [CustomDividerPainters.roundedRect]: tall white
/// capsule with a near-full-height dark grip line (not a tiny center stub).
class _RoundedHandlePainter extends CustomPainter {
  _RoundedHandlePainter({
    required this.handleHeight,
    required this.thickness,
    required this.background,
    required this.foreground,
  });

  final double handleHeight;
  final double thickness;
  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: thickness,
        height: handleHeight,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = background
        ..style = PaintingStyle.fill,
    );

    final linePaint = Paint()
      ..color = foreground
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final startY = center.dy - handleHeight / 2 + 4;
    final endY = center.dy + handleHeight / 2 - 4;
    if (endY > startY) {
      canvas.drawLine(Offset(center.dx, startY), Offset(center.dx, endY), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoundedHandlePainter oldDelegate) {
    return oldDelegate.handleHeight != handleHeight ||
        oldDelegate.thickness != thickness ||
        oldDelegate.background != background ||
        oldDelegate.foreground != foreground;
  }
}
