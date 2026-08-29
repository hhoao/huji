import 'package:flutter/material.dart';

import 'huji_sidebar_scope.dart';
import 'huji_sidebar_theme.dart';

/// Owns sidebar open/width state and keyboard shortcuts for the subtree.
class HujiSidebarProvider extends StatefulWidget {
  const HujiSidebarProvider({
    super.key,
    this.defaultOpen = true,
    this.open,
    this.onOpenChange,
    this.openMobile,
    this.onOpenMobileChange,
    this.defaultWidth,
    this.width,
    this.onWidthChanged,
    this.minWidth = 200,
    this.maxWidth = 480,
    this.mobileBreakpoint = 768,
    this.edgeOpenEnabled = true,
    this.enableKeyboardShortcut = true,
    required this.child,
  });

  final bool defaultOpen;
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final bool? openMobile;
  final ValueChanged<bool>? onOpenMobileChange;

  /// Initial expanded width when uncontrolled. Defaults to theme `sidebar.width`.
  final double? defaultWidth;
  final double? width;
  final ValueChanged<double>? onWidthChanged;
  final double minWidth;
  final double maxWidth;

  final double mobileBreakpoint;
  final bool edgeOpenEnabled;
  final bool enableKeyboardShortcut;
  final Widget child;

  @override
  State<HujiSidebarProvider> createState() => _HujiSidebarProviderState();
}

class _HujiSidebarProviderState extends State<HujiSidebarProvider> {
  late bool _open;
  bool _openMobile = false;
  late double _width;
  bool _isResizing = false;
  bool _widthInitialized = false;

  @override
  void initState() {
    super.initState();
    _open = widget.defaultOpen;
    _width = widget.defaultWidth ?? 256;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_widthInitialized &&
        widget.defaultWidth == null &&
        widget.width == null) {
      _width = HujiSidebarTheme.of(context).width;
      _widthInitialized = true;
    }
  }

  @override
  void didUpdateWidget(HujiSidebarProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == null && oldWidget.defaultOpen != widget.defaultOpen) {
      _open = widget.defaultOpen;
    }
    if (widget.width == null &&
        widget.defaultWidth != null &&
        oldWidget.defaultWidth != widget.defaultWidth) {
      _width = _clamp(widget.defaultWidth!);
    }
  }

  bool get _isOpenControlled => widget.open != null;
  bool get _isOpenMobileControlled => widget.openMobile != null;
  bool get _isWidthControlled => widget.width != null;

  bool get _openValue => widget.open ?? _open;
  bool get _openMobileValue => widget.openMobile ?? _openMobile;
  double get _widthValue => _clamp(widget.width ?? _width);

  double _clamp(double value) => value.clamp(widget.minWidth, widget.maxWidth);

  void _setOpen(bool value) {
    if (_isOpenControlled) {
      widget.onOpenChange?.call(value);
    } else {
      setState(() => _open = value);
    }
  }

  void _setOpenMobile(bool value) {
    if (_isOpenMobileControlled) {
      widget.onOpenMobileChange?.call(value);
    } else {
      setState(() => _openMobile = value);
    }
  }

  void _setWidth(double value) {
    final next = _clamp(value);
    if (_isWidthControlled) {
      widget.onWidthChanged?.call(next);
    } else {
      if ((next - _width).abs() < 0.5) return;
      setState(() => _width = next);
      widget.onWidthChanged?.call(next);
    }
  }

  // Do not setState here — rebuilding mid-drag cancels the gesture.
  void _beginResize() {
    _isResizing = true;
  }

  void _endResize() {
    if (!_isResizing) return;
    setState(() => _isResizing = false);
  }

  void _toggleSidebar() {
    final isMobile = MediaQuery.sizeOf(context).width < widget.mobileBreakpoint;
    if (isMobile) {
      _setOpenMobile(!_openMobileValue);
    } else {
      _setOpen(!_openValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < widget.mobileBreakpoint;

    Widget child = HujiSidebarScope(
      open: _openValue,
      openMobile: _openMobileValue,
      isMobile: isMobile,
      edgeOpenEnabled: widget.edgeOpenEnabled,
      width: _widthValue,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
      isResizing: _isResizing,
      setOpen: _setOpen,
      setOpenMobile: _setOpenMobile,
      setWidth: _setWidth,
      beginResize: _beginResize,
      endResize: _endResize,
      toggleSidebar: _toggleSidebar,
      child: widget.child,
    );

    if (widget.enableKeyboardShortcut) {
      // Ctrl/Cmd+B lives in the global command catalog (CommandIds.toggleSidebar);
      // the shell only guarantees focus here.
      child = Focus(autofocus: true, child: child);
    }

    return child;
  }
}
