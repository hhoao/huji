import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/platform/desktop_window_actions.dart';
import 'package:huji_app/platform/platform_utils.dart';

/// Default height for [WindowChromeControls] when embedded in
/// [DesktopWindowTitleBar].
const double kDefaultWindowChromeHeight = 40;

/// Desktop window controls: macOS traffic lights (left) or Windows-style icons.
class WindowChromeControls extends StatelessWidget {
  const WindowChromeControls({
    required this.isMaximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    this.height = kDefaultWindowChromeHeight,
    super.key,
  });

  final bool isMaximized;
  final Future<void> Function() onMinimize;
  final Future<void> Function({bool optionPressed}) onToggleMaximize;
  final Future<void> Function() onClose;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!useCustomDesktopWindowTitleBar) {
      return const SizedBox.shrink();
    }

    if (useMacWindowChromeStyle) {
      return MacTrafficLightControls(
        isMaximized: isMaximized,
        height: height,
        onMinimize: onMinimize,
        onToggleMaximize: onToggleMaximize,
        onClose: onClose,
      );
    }

    return WindowsStyleChromeControls(
      isMaximized: isMaximized,
      height: height,
      onMinimize: onMinimize,
      onToggleMaximize: onToggleMaximize,
      onClose: onClose,
    );
  }
}

/// macOS close / minimize / maximize traffic-light cluster.
class MacTrafficLightControls extends StatefulWidget {
  const MacTrafficLightControls({
    required this.isMaximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    this.height = kDefaultWindowChromeHeight,
    super.key,
  });

  final bool isMaximized;
  final Future<void> Function() onMinimize;
  final Future<void> Function({bool optionPressed}) onToggleMaximize;
  final Future<void> Function() onClose;
  final double height;

  @override
  State<MacTrafficLightControls> createState() =>
      _MacTrafficLightControlsState();
}

class _MacTrafficLightControlsState extends State<MacTrafficLightControls> {
  bool _hovered = false;
  bool _optionHeld = false;

  static const _closeColor = Color(0xFFFF5F57);
  static const _minimizeColor = Color(0xFFFEBC2E);
  static const _maximizeColor = Color(0xFF28C840);
  static const _symbolColor = Color(0xFF262626);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    final held = isMacOptionKeyPressed();
    if (held != _optionHeld) {
      setState(() => _optionHeld = held);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final diameter = context.tpIconSizes.md;
    // ~8px between traffic lights (legacy used icon xxs≈14 × 0.55).
    final gap = context.tpSpacing.sm;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: widget.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TrafficLightButton(
                diameter: diameter,
                color: _closeColor,
                tooltip: l10n.windowControlClose,
                showSymbol: _hovered,
                onPressed: widget.onClose,
                child: _TrafficLightCloseGlyph(diameter: diameter),
              ),
              SizedBox(width: gap),
              _TrafficLightButton(
                diameter: diameter,
                color: _minimizeColor,
                tooltip: l10n.windowControlMinimize,
                showSymbol: _hovered,
                onPressed: widget.onMinimize,
                child: _TrafficLightMinimizeGlyph(diameter: diameter),
              ),
              SizedBox(width: gap),
              _TrafficLightButton(
                diameter: diameter,
                color: _maximizeColor,
                tooltip: widget.isMaximized
                    ? l10n.windowControlRestore
                    : l10n.windowControlMaximize,
                showSymbol: _hovered,
                onPressed: () => widget.onToggleMaximize(
                  optionPressed: isMacOptionKeyPressed(),
                ),
                child: widget.isMaximized
                    ? _TrafficLightRestoreGlyph(
                        key: const Key('mac_traffic_light_restore_glyph'),
                        diameter: diameter,
                      )
                    : _TrafficLightMaximizeGlyph(
                        key: const Key('mac_traffic_light_maximize_glyph'),
                        diameter: diameter,
                        zoom: _optionHeld,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _trafficLightGlyphSize(double diameter) => diameter * 0.58;

/// Restore (↗ overlapping squares) reads smaller; give it more canvas.
double _trafficLightRestoreGlyphSize(double diameter) => diameter * 0.72;

double _trafficLightStrokeWidth(double diameter) =>
    (diameter * 0.1).clamp(1.35, 2.4);

double _trafficLightRestoreStrokeWidth(double diameter) =>
    (diameter * 0.13).clamp(1.7, 3.0);

Paint _trafficLightSymbolPaint(double diameter) {
  return Paint()
    ..color = _MacTrafficLightControlsState._symbolColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = _trafficLightStrokeWidth(diameter)
    ..strokeCap = StrokeCap.round;
}

class _TrafficLightCloseGlyph extends StatelessWidget {
  const _TrafficLightCloseGlyph({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final size = _trafficLightGlyphSize(diameter);
    return CustomPaint(
      size: Size.square(size),
      painter: _CloseGlyphPainter(diameter: diameter),
    );
  }
}

class _CloseGlyphPainter extends CustomPainter {
  const _CloseGlyphPainter({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _trafficLightSymbolPaint(diameter);
    final inset = size.width * 0.28;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloseGlyphPainter oldDelegate) =>
      oldDelegate.diameter != diameter;
}

class _TrafficLightMinimizeGlyph extends StatelessWidget {
  const _TrafficLightMinimizeGlyph({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final size = _trafficLightGlyphSize(diameter);
    return CustomPaint(
      size: Size.square(size),
      painter: _MinimizeGlyphPainter(diameter: diameter),
    );
  }
}

class _MinimizeGlyphPainter extends CustomPainter {
  const _MinimizeGlyphPainter({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _trafficLightSymbolPaint(diameter);
    final inset = size.width * 0.24;
    canvas.drawLine(
      Offset(inset, size.height * 0.5),
      Offset(size.width - inset, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MinimizeGlyphPainter oldDelegate) =>
      oldDelegate.diameter != diameter;
}

/// Green button hover glyph: corner arrows (fullscreen) or zoom arrows (⌥ held).
class _TrafficLightMaximizeGlyph extends StatelessWidget {
  const _TrafficLightMaximizeGlyph({
    required this.diameter,
    required this.zoom,
    super.key,
  });

  final double diameter;
  final bool zoom;

  @override
  Widget build(BuildContext context) {
    final size = _trafficLightGlyphSize(diameter);
    return CustomPaint(
      size: Size.square(size),
      painter: zoom
          ? _ZoomGlyphPainter(diameter: diameter)
          : _ExpandGlyphPainter(diameter: diameter),
    );
  }
}

class _ExpandGlyphPainter extends CustomPainter {
  const _ExpandGlyphPainter({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _trafficLightSymbolPaint(diameter);
    final pad = size.width * 0.18;
    final arm = size.width * 0.3;

    // Top-left outward corner (fullscreen).
    canvas.drawLine(Offset(pad, pad + arm), Offset(pad, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad + arm, pad), paint);

    // Bottom-right outward corner.
    final br = Offset(size.width - pad, size.height - pad);
    canvas.drawLine(Offset(br.dx, br.dy - arm), br, paint);
    canvas.drawLine(br, Offset(br.dx - arm, br.dy), paint);
  }

  @override
  bool shouldRepaint(covariant _ExpandGlyphPainter oldDelegate) =>
      oldDelegate.diameter != diameter;
}

class _ZoomGlyphPainter extends CustomPainter {
  const _ZoomGlyphPainter({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _trafficLightSymbolPaint(diameter);
    final pad = size.width * 0.18;
    final arm = size.width * 0.3;

    // Top-right inward corner (⌥ zoom).
    final tr = Offset(size.width - pad, pad);
    canvas.drawLine(tr, Offset(tr.dx - arm, tr.dy), paint);
    canvas.drawLine(tr, Offset(tr.dx, tr.dy + arm), paint);

    // Bottom-left inward corner.
    final bl = Offset(pad, size.height - pad);
    canvas.drawLine(bl, Offset(bl.dx + arm, bl.dy), paint);
    canvas.drawLine(bl, Offset(bl.dx, bl.dy - arm), paint);
  }

  @override
  bool shouldRepaint(covariant _ZoomGlyphPainter oldDelegate) =>
      oldDelegate.diameter != diameter;
}

class _TrafficLightRestoreGlyph extends StatelessWidget {
  const _TrafficLightRestoreGlyph({required this.diameter, super.key});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final size = _trafficLightRestoreGlyphSize(diameter);
    return CustomPaint(
      size: Size.square(size),
      painter: _RestoreGlyphPainter(diameter: diameter),
    );
  }
}

/// Inward corner arrows on all four sides — "exit fullscreen / restore".
class _RestoreGlyphPainter extends CustomPainter {
  const _RestoreGlyphPainter({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = _trafficLightRestoreStrokeWidth(diameter);
    final pad = size.width * 0.16;
    final arm = size.width * 0.26;
    final w = size.width;
    final h = size.height;

    void drawCorners(Paint paint) {
      _drawInwardCorner(
        canvas,
        Offset(pad, pad),
        arm,
        paint,
        axisX: 1,
        axisY: 1,
      );
      _drawInwardCorner(
        canvas,
        Offset(w - pad, pad),
        arm,
        paint,
        axisX: -1,
        axisY: 1,
      );
      _drawInwardCorner(
        canvas,
        Offset(pad, h - pad),
        arm,
        paint,
        axisX: 1,
        axisY: -1,
      );
      _drawInwardCorner(
        canvas,
        Offset(w - pad, h - pad),
        arm,
        paint,
        axisX: -1,
        axisY: -1,
      );
    }

    final halo = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    drawCorners(halo);

    final paint = Paint()
      ..color = const Color(0xFF121212)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    drawCorners(paint);
  }

  @override
  bool shouldRepaint(covariant _RestoreGlyphPainter oldDelegate) =>
      oldDelegate.diameter != diameter;
}

void _drawInwardCorner(
  Canvas canvas,
  Offset corner,
  double arm,
  Paint paint, {
  required int axisX,
  required int axisY,
}) {
  canvas.drawLine(
    Offset(corner.dx + arm * axisX, corner.dy),
    corner,
    paint,
  );
  canvas.drawLine(
    corner,
    Offset(corner.dx, corner.dy + arm * axisY),
    paint,
  );
}

class _TrafficLightButton extends StatelessWidget {
  const _TrafficLightButton({
    required this.diameter,
    required this.color,
    required this.tooltip,
    required this.showSymbol,
    required this.onPressed,
    required this.child,
  });

  final double diameter;

  final Color color;
  final String tooltip;
  final bool showSymbol;
  final Future<void> Function() onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TpHover(
        onTap: () => onPressed(),
        borderRadius: BorderRadius.circular(diameter / 2),
        pressScale: 0.97,
        child: Container(
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.14),
              width: 0.5,
            ),
          ),
          child: showSymbol ? child : null,
        ),
      ),
    );
  }
}

/// Windows / Linux minimize, maximize, and close buttons.
class WindowsStyleChromeControls extends StatelessWidget {
  const WindowsStyleChromeControls({
    required this.isMaximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    this.height = kDefaultWindowChromeHeight,
    super.key,
  });

  final bool isMaximized;
  final Future<void> Function() onMinimize;
  final Future<void> Function({bool optionPressed}) onToggleMaximize;
  final Future<void> Function() onClose;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowsChromeButton(
          height: height,
          tooltip: l10n.windowControlMinimize,
          icon: Icons.remove,
          onPressed: onMinimize,
        ),
        _WindowsChromeButton(
          height: height,
          tooltip: isMaximized
              ? l10n.windowControlRestore
              : l10n.windowControlMaximize,
          icon: isMaximized ? Icons.filter_none : Icons.crop_square_outlined,
          onPressed: () => onToggleMaximize(optionPressed: false),
        ),
        _WindowsChromeButton(
          height: height,
          tooltip: l10n.windowControlClose,
          icon: Icons.close,
          isClose: true,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _WindowsChromeButton extends StatefulWidget {
  const _WindowsChromeButton({
    required this.height,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  final double height;
  final String tooltip;
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool isClose;

  @override
  State<_WindowsChromeButton> createState() => _WindowsChromeButtonState();
}

class _WindowsChromeButtonState extends State<_WindowsChromeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color background = Colors.transparent;
    Color foreground = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFF374151);

    if (_hovered) {
      if (widget.isClose) {
        background = const Color(0xFFE81123);
        foreground = Colors.white;
      } else {
        background = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);
      }
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: SizedBox(
          width: 46,
          height: widget.height,
          child: Material(
            color: background,
            child: InkWell(
              onTap: () => widget.onPressed(),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Icon(
                widget.icon,
                size: context.tpIconSizes.md,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
