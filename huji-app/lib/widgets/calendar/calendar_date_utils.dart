/// Date helpers for [AppRangeCalendar] (range selection grid).
extension CalendarDateUtils on DateTime {
  DateTime get calendarDay => DateTime(year, month, day);

  bool isSameCalendarDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isOnOrAfterDay(DateTime other) {
    final a = calendarDay;
    final b = other.calendarDay;
    return a.isAfter(b) || a.isSameCalendarDay(b);
  }

  bool isOnOrBeforeDay(DateTime other) {
    final a = calendarDay;
    final b = other.calendarDay;
    return a.isBefore(b) || a.isSameCalendarDay(b);
  }

  DateTime get calendarMonthStart => DateTime(year, month);

  DateTime addCalendarMonths(int months) => DateTime(year, month + months, day);

  static int firstWeekdayForLocale(String languageCode) {
    // 弧迹默认中文界面：周一为一周起始。
    if (languageCode == 'zh') return DateTime.monday;
    return DateTime.sunday;
  }

  /// Builds a 6×7 grid (nullable = empty cell) for [month].
  static List<DateTime?> buildMonthGrid(
    DateTime month, {
    required int firstWeekday,
    bool showOutsideDays = true,
  }) {
    final monthStart = DateTime(month.year, month.month);
    var leading = monthStart.weekday - firstWeekday;
    if (leading < 0) leading += 7;

    final gridStart = monthStart.subtract(Duration(days: leading));
    return List.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      final inMonth = date.month == month.month && date.year == month.year;
      if (!inMonth && !showOutsideDays) return null;
      return date.calendarDay;
    });
  }
}
