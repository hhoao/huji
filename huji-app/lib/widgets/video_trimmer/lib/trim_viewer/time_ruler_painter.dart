import 'package:flutter/material.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/time_ruler_intervals.dart';

/// Full-width time ruler painted in the same overlay coordinate space as
/// segment borders (not per thumbnail tile).
class TimeRulerPainter extends CustomPainter {
  TimeRulerPainter({
    required this.totalDurationSeconds,
    required this.totalWidth,
    required this.shortInterval,
    required this.longInterval,
    required this.textInterval,
    required this.tickColor,
    required this.textStyle,
  });

  final double totalDurationSeconds;
  final double totalWidth;
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

    final paint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i <= endMark; i++) {
      final time = i * shortInterval;
      if (time > totalDurationSeconds + 1e-9) break;

      final x = timeToTimelineX(
        timeSeconds: time,
        totalDurationSeconds: totalDurationSeconds,
        totalWidth: totalWidth,
      );

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
        oldDelegate.shortInterval != shortInterval ||
        oldDelegate.longInterval != longInterval ||
        oldDelegate.textInterval != textInterval ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.textStyle != textStyle;
  }
}
