import 'package:flutter/material.dart';
import 'package:huji_app/theme/app_fonts.dart';
import 'package:shared_ui/shared_ui.dart';

const kLogViewerLevels = ['ALL', 'DEBUG', 'INFO', 'WARNING', 'ERROR'];

final _levelColumnPattern = RegExp(
  r'\|\s*(DEBUG|INFO|WARN|WARNING|ERROR)\s+\d+\s*\|',
);

final _decorationPattern = RegExp(r'^[│┌┐└┘├┤─\s#0-9.:]+$');

/// Matches the level column of a single-line log4j-style record.
///
/// Falls back to keyword matching for logs written before the format change
/// (the old pretty printer emitted multi-line, boxed records).
bool logLineMatchesLevel(String line, String level) {
  if (level == 'ALL') return true;

  final column = _levelColumnPattern.firstMatch(line.toUpperCase());
  if (column != null) {
    final found = column.group(1)!;
    return switch (level) {
      'DEBUG' => found == 'DEBUG',
      'INFO' => found == 'INFO',
      'WARNING' => found == 'WARN' || found == 'WARNING',
      'ERROR' => found == 'ERROR',
      _ => true,
    };
  }

  final upper = line.toUpperCase();
  return switch (level) {
    'DEBUG' => upper.contains('DEBUG'),
    'INFO' => upper.contains('INFO') || upper.contains('[BOOT]'),
    'WARNING' => upper.contains('WARNING') || upper.contains('WARN'),
    'ERROR' => upper.contains('ERROR') || upper.contains('EXCEPTION'),
    _ => true,
  };
}

/// True for pretty-printer borders / stack-frame decorations that add noise in
/// compact mode.
bool isLogDecorationLine(String line) {
  final t = line.trim();
  if (t.isEmpty) return true;
  if (t.startsWith('│ #') ||
      t.startsWith('├') ||
      t.startsWith('└') ||
      t.startsWith('┌')) {
    return true;
  }
  return _decorationPattern.hasMatch(t);
}

List<String> filterLogLines({
  required List<String> rawLines,
  required bool compactView,
  required String searchText,
  required String selectedLevel,
}) {
  var filtered = List<String>.from(rawLines);
  if (compactView) {
    filtered = filtered.where((l) => !isLogDecorationLine(l)).toList();
  }
  if (searchText.isNotEmpty) {
    final query = searchText.toLowerCase();
    filtered = filtered.where((l) => l.toLowerCase().contains(query)).toList();
  }
  if (selectedLevel != 'ALL') {
    filtered = filtered
        .where((l) => logLineMatchesLevel(l, selectedLevel))
        .toList();
  }
  return filtered;
}

TextStyle logMonospaceStyle(BuildContext context, {Color? color}) {
  final cs = Theme.of(context).colorScheme;
  return appMonoTextStyle(
    context,
    base: TpTextStyles.of(context).sm,
    height: 1.45,
    color: color ?? cs.onSurface.withValues(alpha: 0.92),
  );
}

Color? logLineColor(BuildContext context, String line) {
  final cs = Theme.of(context).colorScheme;
  if (logLineMatchesLevel(line, 'ERROR')) return cs.error;
  if (logLineMatchesLevel(line, 'WARNING')) return cs.tertiary;
  if (logLineMatchesLevel(line, 'DEBUG')) return cs.onSurfaceVariant;
  return null;
}
