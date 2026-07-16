import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_ui/theme/app_text_styles.dart';
import 'package:huji_app/widgets/calendar/calendar_date_utils.dart';
import 'package:huji_app/widgets/controls/hover_widget.dart';

/// Inline month grid for selecting a [DateTimeRange].
class AppRangeCalendar extends StatefulWidget {
  const AppRangeCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onChanged,
    this.initialMonth,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?>? onChanged;
  final DateTime? initialMonth;

  @override
  State<AppRangeCalendar> createState() => _AppRangeCalendarState();
}

class _AppRangeCalendarState extends State<AppRangeCalendar> {
  late DateTime _displayedMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _syncFromValue();
    _displayedMonth = _initialMonth();
  }

  @override
  void didUpdateWidget(AppRangeCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncFromValue();
    }
  }

  void _syncFromValue() {
    _start = widget.value?.start.calendarDay;
    _end = widget.value?.end.calendarDay;
  }

  DateTime _initialMonth() {
    return (widget.initialMonth ??
            widget.value?.start ??
            widget.lastDate)
        .calendarMonthStart;
  }

  bool _isDisabled(DateTime day) {
    return day.isBefore(widget.firstDate.calendarDay) ||
        day.isAfter(widget.lastDate.calendarDay);
  }

  void _selectDay(DateTime day) {
    if (_isDisabled(day)) return;

    setState(() {
      final hasCompleteRange = _start != null && _end != null;
      final singleSelected =
          _start != null && _end == null && day.isSameCalendarDay(_start!);

      if (hasCompleteRange) {
        if (day.isSameCalendarDay(_start!) || day.isSameCalendarDay(_end!)) {
          _start = day;
          _end = null;
        } else if (day.isBefore(_start!)) {
          _start = day;
        } else {
          _end = day;
        }
      } else if (singleSelected) {
        _start = null;
        _end = null;
      } else if (_start == null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else {
        _end = day;
      }
    });

    _emitChange();
  }

  void _emitChange() {
    if (_start == null && _end == null) {
      widget.onChanged?.call(null);
      return;
    }
    if (_start != null && _end != null) {
      widget.onChanged?.call(DateTimeRange(start: _start!, end: _end!));
    }
  }

  void _clear() {
    setState(() {
      _start = null;
      _end = null;
    });
    widget.onChanged?.call(null);
  }

  void _goMonth(int delta) {
    setState(() {
      _displayedMonth = _displayedMonth.addCalendarMonths(delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);
    final locale = Localizations.localeOf(context);
    final firstWeekday = CalendarDateUtils.firstWeekdayForLocale(
      locale.languageCode,
    );
    final dates = CalendarDateUtils.buildMonthGrid(
      _displayedMonth,
      firstWeekday: firstWeekday,
    );
    final monthLabel = DateFormat.yMMMM(locale.toString()).format(
      _displayedMonth,
    );
    final weekdays = _weekdayLabels(context, firstWeekday);
    final today = DateTime.now().calendarDay;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarHeader(
          label: monthLabel,
          onPrevious: () => _goMonth(-1),
          onNext: () => _goMonth(1),
        ),
        const SizedBox(height: 8),
        Row(
          children: weekdays
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: styles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (final date in dates)
              if (date == null)
                const SizedBox.shrink()
              else
                _DayCell(
                  date: date,
                  inMonth: date.month == _displayedMonth.month,
                  isToday: date.isSameCalendarDay(today),
                  isStart: _start != null && date.isSameCalendarDay(_start!),
                  isEnd: _end != null && date.isSameCalendarDay(_end!),
                  isInRange: _isInRange(date),
                  enabled: !_isDisabled(date),
                  onTap: () => _selectDay(date),
                ),
          ],
        ),
        if (_start != null || _end != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clear,
              child: Text('清除', style: styles.caption),
            ),
          ),
        ],
      ],
    );
  }

  bool _isInRange(DateTime date) {
    if (_start == null || _end == null) return false;
    return date.isOnOrAfterDay(_start!) && date.isOnOrBeforeDay(_end!);
  }

  List<String> _weekdayLabels(BuildContext context, int firstWeekday) {
    final material = MaterialLocalizations.of(context);
    final labels = material.narrowWeekdays;
    final startIndex = firstWeekday == DateTime.monday ? 1 : 0;
    return List.generate(7, (i) => labels[(startIndex + i) % 7]);
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);

    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left, onTap: onPrevious),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: styles.bodyStrong.copyWith(color: cs.onSurface),
          ),
        ),
        _NavButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return HoverWidget(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: cs.onSurface.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.isStart,
    required this.isEnd,
    required this.isInRange,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final bool isStart;
  final bool isEnd;
  final bool isInRange;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);
    final selected = isStart || isEnd;

    Color? bg;
    if (selected) {
      bg = cs.primary;
    } else if (isInRange) {
      bg = cs.primaryContainer.withValues(alpha: 0.55);
    }

    final textColor = !enabled
        ? cs.onSurface.withValues(alpha: 0.25)
        : selected
        ? cs.onPrimary
        : inMonth
        ? cs.onSurface
        : cs.onSurfaceVariant.withValues(alpha: 0.55);

    Widget child = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isToday && !selected
            ? Border.all(color: cs.primary.withValues(alpha: 0.65))
            : null,
      ),
      child: Text(
        '${date.day}',
        style: styles.caption.copyWith(
          color: textColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );

    if (!enabled) return child;

    if (selected) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }

    return HoverWidget(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: cs.onSurface.withValues(alpha: 0.06),
      child: child,
    );
  }
}
