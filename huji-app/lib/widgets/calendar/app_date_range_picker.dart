import 'package:flutter/material.dart';
import 'package:huji_app/widgets/calendar/app_range_calendar.dart';
import 'package:huji_app/widgets/dropdown/popover/app_popover.dart';
import 'package:huji_app/widgets/menu/sidebar_action_menu.dart';

/// Popover date-range picker using [AppPopover] + [AppRangeCalendar].
class AppDateRangePicker extends StatefulWidget {
  const AppDateRangePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.triggerBuilder,
    this.value,
    this.onChanged,
    this.closeOnCompleteSelection = true,
    this.panelWidth = 280,
    this.controller,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?>? onChanged;
  final bool closeOnCompleteSelection;
  final double panelWidth;

  /// Receives open state so the trigger can reflect popover visibility.
  final Widget Function(BuildContext context, bool isOpen) triggerBuilder;

  final AppPopoverController? controller;

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  late final AppPopoverController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AppPopoverController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handleRangeChanged(DateTimeRange? range) {
    widget.onChanged?.call(range);
    if (widget.closeOnCompleteSelection &&
        range != null &&
        !range.start.isAfter(range.end)) {
      _controller.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = SidebarActionMenuMetrics.panelDecoration(context);

    return AppPopover(
      controller: _controller,
      panelWidth: widget.panelWidth,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: decoration,
      anchor: const AppAnchor(
        childAlignment: Alignment.topRight,
        overlayAlignment: Alignment.bottomRight,
        offset: Offset(0, 4),
      ),
      popover: (_) => AppRangeCalendar(
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        value: widget.value,
        initialMonth: widget.value?.start ?? widget.lastDate,
        onChanged: _handleRangeChanged,
      ),
      child: GestureDetector(
        onTap: _controller.toggle,
        behavior: HitTestBehavior.opaque,
        child: widget.triggerBuilder(context, _controller.isOpen),
      ),
    );
  }
}
