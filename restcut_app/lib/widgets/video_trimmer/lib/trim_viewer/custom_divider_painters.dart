import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

/// 自定义分割线绘制器集合
class CustomDividerPainters {
  /// 圆角矩形分割线 - 类似图片中的样式
  static DividerPainter roundedRect({
    double size = 30,
    double thickness = 3,
    double? highlightedSize,
    double? highlightedThickness,
    Color backgroundColor = Colors.white,
    Color? highlightedBackgroundColor,
    Color dividerColor = Colors.black,
    Color? highlightedDividerColor,
    double borderRadius = 8,
    bool animationEnabled = true,
    Duration animationDuration = const Duration(milliseconds: 250),
  }) {
    return _RoundedRectDividerPainter(
      size: size,
      thickness: thickness,
      highlightedSize: highlightedSize ?? size * 1.5,
      highlightedThickness: highlightedThickness ?? thickness * 1.5,
      backgroundColor: backgroundColor,
      highlightedBackgroundColor: highlightedBackgroundColor ?? backgroundColor,
      dividerColor: dividerColor,
      highlightedDividerColor: highlightedDividerColor ?? dividerColor,
      borderRadius: borderRadius,
      animationEnabled: animationEnabled,
      animationDuration: animationDuration,
    );
  }

  /// 双线分割线
  static DividerPainter doubleLine({
    double size = 20,
    double thickness = 2,
    double gap = 4,
    double? highlightedSize,
    double? highlightedThickness,
    Color color = Colors.black,
    Color? highlightedColor,
    Color? backgroundColor,
    Color? highlightedBackgroundColor,
    bool animationEnabled = true,
    Duration animationDuration = const Duration(milliseconds: 250),
  }) {
    return _DoubleLineDividerPainter(
      size: size,
      thickness: thickness,
      gap: gap,
      highlightedSize: highlightedSize ?? size * 1.3,
      highlightedThickness: highlightedThickness ?? thickness * 1.5,
      color: color,
      highlightedColor: highlightedColor ?? color,
      backgroundColor: backgroundColor,
      highlightedBackgroundColor: highlightedBackgroundColor ?? backgroundColor,
      animationEnabled: animationEnabled,
      animationDuration: animationDuration,
    );
  }

  /// 点状分割线
  static DividerPainter dotted({
    double size = 25,
    double dotSize = 4,
    double gap = 3,
    double? highlightedSize,
    double? highlightedDotSize,
    Color color = Colors.black,
    Color? highlightedColor,
    Color? backgroundColor,
    Color? highlightedBackgroundColor,
    bool animationEnabled = true,
    Duration animationDuration = const Duration(milliseconds: 250),
  }) {
    return _DottedDividerPainter(
      size: size,
      dotSize: dotSize,
      gap: gap,
      highlightedSize: highlightedSize ?? size * 1.4,
      highlightedDotSize: highlightedDotSize ?? dotSize * 1.5,
      color: color,
      highlightedColor: highlightedColor ?? color,
      backgroundColor: backgroundColor,
      highlightedBackgroundColor: highlightedBackgroundColor ?? backgroundColor,
      animationEnabled: animationEnabled,
      animationDuration: animationDuration,
    );
  }

  /// 箭头分割线
  static DividerPainter arrow({
    double size = 30,
    double thickness = 3,
    double? highlightedSize,
    double? highlightedThickness,
    Color color = Colors.black,
    Color? highlightedColor,
    Color? backgroundColor,
    Color? highlightedBackgroundColor,
    bool animationEnabled = true,
    Duration animationDuration = const Duration(milliseconds: 250),
  }) {
    return _ArrowDividerPainter(
      size: size,
      thickness: thickness,
      highlightedSize: highlightedSize ?? size * 1.5,
      highlightedThickness: highlightedThickness ?? thickness * 1.5,
      color: color,
      highlightedColor: highlightedColor ?? color,
      backgroundColor: backgroundColor,
      highlightedBackgroundColor: highlightedBackgroundColor ?? backgroundColor,
      animationEnabled: animationEnabled,
      animationDuration: animationDuration,
    );
  }
}

/// 圆角矩形分割线绘制器
class _RoundedRectDividerPainter extends DividerPainter {
  final double size;
  final double thickness;
  final double highlightedSize;
  final double highlightedThickness;
  final Color dividerColor;
  final Color highlightedDividerColor;
  final double borderRadius;

  _RoundedRectDividerPainter({
    required this.size,
    required this.thickness,
    required this.highlightedSize,
    required this.highlightedThickness,
    required this.dividerColor,
    required this.highlightedDividerColor,
    required this.borderRadius,
    super.backgroundColor,
    super.highlightedBackgroundColor,
    super.animationEnabled,
    super.animationDuration,
  });

  @override
  void paint({
    required Axis dividerAxis,
    required bool resizable,
    required bool highlighted,
    required Canvas canvas,
    required Size dividerSize,
    required Map<int, dynamic> animatedValues,
  }) {
    final currentSize = highlighted ? highlightedSize : size;
    final currentThickness = highlighted ? highlightedThickness : thickness;
    final currentBgColor = highlighted
        ? highlightedBackgroundColor!
        : backgroundColor!;
    final currentDividerColor = highlighted
        ? highlightedDividerColor
        : dividerColor;

    final center = Offset(dividerSize.width / 2, dividerSize.height / 2);

    // 绘制圆角矩形背景
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: currentThickness,
        height: currentSize,
      ),
      Radius.circular(borderRadius),
    );

    final bgPaint = Paint()
      ..color = currentBgColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, bgPaint);

    // 绘制中心分割线
    final dividerPaint = Paint()
      ..color = currentDividerColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startY = center.dy - currentSize / 2 + 4;
    final endY = center.dy + currentSize / 2 - 4;

    canvas.drawLine(
      Offset(center.dx, startY),
      Offset(center.dx, endY),
      dividerPaint,
    );
  }
}

/// 双线分割线绘制器
class _DoubleLineDividerPainter extends DividerPainter {
  final double size;
  final double thickness;
  final double gap;
  final double highlightedSize;
  final double highlightedThickness;
  final Color color;
  final Color highlightedColor;

  _DoubleLineDividerPainter({
    required this.size,
    required this.thickness,
    required this.gap,
    required this.highlightedSize,
    required this.highlightedThickness,
    required this.color,
    required this.highlightedColor,
    super.backgroundColor,
    super.highlightedBackgroundColor,
    super.animationEnabled,
    super.animationDuration,
  });

  @override
  void paint({
    required Axis dividerAxis,
    required bool resizable,
    required bool highlighted,
    required Canvas canvas,
    required Size dividerSize,
    required Map<int, dynamic> animatedValues,
  }) {
    final currentSize = highlighted ? highlightedSize : size;
    final currentThickness = highlighted ? highlightedThickness : thickness;
    final currentColor = highlighted ? highlightedColor : color;

    final center = Offset(dividerSize.width / 2, dividerSize.height / 2);

    final paint = Paint()
      ..color = currentColor
      ..strokeWidth = currentThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startY = center.dy - currentSize / 2;
    final endY = center.dy + currentSize / 2;

    // 绘制两条线
    canvas.drawLine(
      Offset(center.dx - gap / 2, startY),
      Offset(center.dx - gap / 2, endY),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx + gap / 2, startY),
      Offset(center.dx + gap / 2, endY),
      paint,
    );
  }
}

/// 点状分割线绘制器
class _DottedDividerPainter extends DividerPainter {
  final double size;
  final double dotSize;
  final double gap;
  final double highlightedSize;
  final double highlightedDotSize;
  final Color color;
  final Color highlightedColor;

  _DottedDividerPainter({
    required this.size,
    required this.dotSize,
    required this.gap,
    required this.highlightedSize,
    required this.highlightedDotSize,
    required this.color,
    required this.highlightedColor,
    super.backgroundColor,
    super.highlightedBackgroundColor,
    super.animationEnabled,
    super.animationDuration,
  });

  @override
  void paint({
    required Axis dividerAxis,
    required bool resizable,
    required bool highlighted,
    required Canvas canvas,
    required Size dividerSize,
    required Map<int, dynamic> animatedValues,
  }) {
    final currentSize = highlighted ? highlightedSize : size;
    final currentDotSize = highlighted ? highlightedDotSize : dotSize;
    final currentColor = highlighted ? highlightedColor : color;

    final center = Offset(dividerSize.width / 2, dividerSize.height / 2);

    final paint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;

    final startY = center.dy - currentSize / 2;
    final endY = center.dy + currentSize / 2;

    // 绘制点
    double currentY = startY;
    while (currentY < endY) {
      canvas.drawCircle(Offset(center.dx, currentY), currentDotSize / 2, paint);
      currentY += currentDotSize + gap;
    }
  }
}

/// 箭头分割线绘制器
class _ArrowDividerPainter extends DividerPainter {
  final double size;
  final double thickness;
  final double highlightedSize;
  final double highlightedThickness;
  final Color color;
  final Color highlightedColor;

  _ArrowDividerPainter({
    required this.size,
    required this.thickness,
    required this.highlightedSize,
    required this.highlightedThickness,
    required this.color,
    required this.highlightedColor,
    super.backgroundColor,
    super.highlightedBackgroundColor,
    super.animationEnabled,
    super.animationDuration,
  });

  @override
  void paint({
    required Axis dividerAxis,
    required bool resizable,
    required bool highlighted,
    required Canvas canvas,
    required Size dividerSize,
    required Map<int, dynamic> animatedValues,
  }) {
    final currentSize = highlighted ? highlightedSize : size;
    final currentThickness = highlighted ? highlightedThickness : thickness;
    final currentColor = highlighted ? highlightedColor : color;

    final center = Offset(dividerSize.width / 2, dividerSize.height / 2);

    final paint = Paint()
      ..color = currentColor
      ..strokeWidth = currentThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowSize = currentSize * 0.3;
    final lineLength = currentSize * 0.4;

    // 绘制中心线
    canvas.drawLine(
      Offset(center.dx, center.dy - lineLength / 2),
      Offset(center.dx, center.dy + lineLength / 2),
      paint,
    );

    // 绘制上箭头
    final path = Path();
    path.moveTo(center.dx, center.dy - lineLength / 2);
    path.lineTo(
      center.dx - arrowSize / 2,
      center.dy - lineLength / 2 - arrowSize,
    );
    path.lineTo(
      center.dx + arrowSize / 2,
      center.dy - lineLength / 2 - arrowSize,
    );
    path.close();
    canvas.drawPath(path, paint);

    // 绘制下箭头
    final path2 = Path();
    path2.moveTo(center.dx, center.dy + lineLength / 2);
    path2.lineTo(
      center.dx - arrowSize / 2,
      center.dy + lineLength / 2 + arrowSize,
    );
    path2.lineTo(
      center.dx + arrowSize / 2,
      center.dy + lineLength / 2 + arrowSize,
    );
    path2.close();
    canvas.drawPath(path2, paint);
  }
}
