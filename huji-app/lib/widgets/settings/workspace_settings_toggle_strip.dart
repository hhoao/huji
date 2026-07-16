import 'package:flutter/material.dart';

import 'package:huji_app/widgets/controls/app_toggle_switch.dart';

/// One option in [WorkspaceSettingsToggleStrip].
class WorkspaceToggleSegment<T extends Object> {
  const WorkspaceToggleSegment({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

/// Pill-shaped segmented control for settings rows and dialogs.
class WorkspaceSettingsToggleStrip<T extends Object> extends StatefulWidget {
  const WorkspaceSettingsToggleStrip({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.alignment = Alignment.centerRight,
    this.minWidth,
    this.customWidths,
  });

  final List<WorkspaceToggleSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final AlignmentGeometry alignment;
  final double? minWidth;
  final List<double>? customWidths;

  @override
  State<WorkspaceSettingsToggleStrip<T>> createState() =>
      _WorkspaceSettingsToggleStripState<T>();
}

class _WorkspaceSettingsToggleStripState<T extends Object>
    extends State<WorkspaceSettingsToggleStrip<T>> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _indexFor(widget.selected);
  }

  @override
  void didUpdateWidget(covariant WorkspaceSettingsToggleStrip<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _index = _indexFor(widget.selected);
    }
  }

  int _indexFor(T value) {
    final idx = widget.segments.indexWhere((s) => s.value == value);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: widget.alignment,
      child: AppToggleSwitch(
        totalSwitches: widget.segments.length,
        initialLabelIndex: _index,
        labels: widget.segments.map((e) => e.label).toList(),
        icons: widget.segments.map((e) => e.icon).toList(),
        minWidth: widget.minWidth,
        customWidths: widget.customWidths,
        onToggle: (index) {
          if (index == null || index < 0 || index >= widget.segments.length) {
            return;
          }
          setState(() => _index = index);
          widget.onChanged(widget.segments[index].value);
        },
      ),
    );
  }
}
