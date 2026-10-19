import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/settings/log_viewer_filter.dart';

const _info =
    '2026-10-19 12:00:00.000 |  INFO 123 | package:huji_app/a.dart:1:1 | started';
const _error =
    '2026-10-19 12:00:01.000 | ERROR 123 | package:huji_app/b.dart:2:2 | failed';
const _debug =
    '2026-10-19 12:00:02.000 | DEBUG 123 | package:huji_app/c.dart:3:3 | trace';

void main() {
  test('level parsing reads the level column, not the message text', () {
    const line =
        '2026-10-19 12:00:00.000 |  INFO 123 | package:huji_app/a.dart:1:1 | this ERROR happened';

    expect(logLineMatchesLevel(line, 'INFO'), isTrue);
    expect(logLineMatchesLevel(line, 'ERROR'), isFalse);
    expect(logLineMatchesLevel(line, 'ALL'), isTrue);
  });

  test('WARNING matches the padded WARN label', () {
    const line =
        '2026-10-19 12:00:00.000 |  WARN 123 | package:huji_app/a.dart:1:1 | slow';

    expect(logLineMatchesLevel(line, 'WARNING'), isTrue);
  });

  test('filterLogLines combines compact, search, and level filters', () {
    const lines = [
      _info,
      _error,
      _debug,
      '┌────────────────────────',
      '│ #0   AppLogger.i (package:huji_app/utils/logger_utils.dart:1:1)',
      '│ message: failed',
    ];

    final filtered = filterLogLines(
      rawLines: lines,
      compactView: true,
      searchText: 'failed',
      selectedLevel: 'ERROR',
    );

    expect(filtered, [_error]);
  });

  test('filterLogLines does not mutate the input list', () {
    final lines = [_info, _error];

    filterLogLines(
      rawLines: lines,
      compactView: false,
      searchText: '',
      selectedLevel: 'ERROR',
    );

    expect(lines, [_info, _error]);
  });
}
