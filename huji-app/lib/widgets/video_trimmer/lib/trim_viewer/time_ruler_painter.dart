import 'package:flutter/material.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';

/// Viewport-fixed time ruler: ticks are painted at their on-screen position
/// (timeline x + [leftWidgetWidth] - [scrollOffset]), so the CustomPaint layer
/// itself never moves and each repaint covers only the visible window instead
/// of the whole video duration.
class TimeRulerPainter extends CustomPainter {
  TimeRulerPainter({
    required this.totalDurationSeconds,
    required this.totalWidth,
    required this.scrollOffset,
    required this.leftWidgetWidth,
    required this.shortInterval,
    required this.longInterval,
    required this.textInterval,
    required this.tickColor,
    required this.textStyle,
  });

  final double totalDurationSeconds;
  final double totalWidth;
  final double scrollOffset;
  final double leftWidgetWidth;
  final double shortInterval;
  final double longInterval;
  final int textInterval;
  final Color tickColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalDurationSeconds <= 0 || totalWidth <= 0 || shortInterval <= 0) {
      return;
    }

    final longIntervalCount = (longInterval / shortInterval).round().clamp(1, 1000);
    final endMark = (totalDurationSeconds / shortInterval).ceil();

    final translateX = leftWidgetWidth - scrollOffset;
    final pxPerSecond = totalWidth / totalDurationSeconds;

    // 只画视口内的刻度；两侧各留一个标签宽度的溢出量，让边缘标签
    // 仍能跨刻度显示（与整条绘制时的视觉一致）。
    const labelPadPx = 64.0;
    final minTickTime = (-labelPadPx - translateX) / pxPerSecond;
    final maxTickTime = (size.width + labelPadPx - translateX) / pxPerSecond;
    final firstTick = (minTickTime / shortInterval).floor();
    final lastTick = (maxTickTime / shortInterval).ceil();

    final paint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (
      var i = firstTick < 0 ? 0 : firstTick;
      i <= endMark && i <= lastTick;
      i++
    ) {
      final time = i * shortInterval;
      if (time > totalDurationSeconds + 1e-9) break;

      final x = time * pxPerSecond + translateX;

      final isLongLine = (i % longIntervalCount) == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, isLongLine ? 8 : 4), paint);

      if (i % textInterval == 0) {
        textPainter.text = TextSpan(text: _formatTime(time), style: textStyle);
        textPainter.layout();
        final textX = timeRulerLabelPaintX(
          tickX: x,
          labelWidth: textPainter.width,
        );
        textPainter.paint(canvas, Offset(textX, 16));
      }
    }
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant TimeRulerPainter oldDelegate) {
    return oldDelegate.totalDurationSeconds != totalDurationSeconds ||
        oldDelegate.totalWidth != totalWidth ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.leftWidgetWidth != leftWidgetWidth ||
        oldDelegate.shortInterval != shortInterval ||
        oldDelegate.longInterval != longInterval ||
        oldDelegate.textInterval != textInterval ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.textStyle != textStyle;
  }
}
