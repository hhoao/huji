import 'package:flutter/material.dart';

/// Shared [ListTile] defaults for TeamPilot.
///
/// Do not use [ListTile.dense] — in Material 3 it pins title/subtitle to fixed
/// 13/12 logical px and bypasses [AppTypographyScale]. Compact rows come from
/// tighter padding here plus the app-wide [VisualDensity.compact].
ListTileThemeData buildAppListTileTheme({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
}) {
  final title = textTheme.bodyMedium ?? const TextStyle();
  final subtitle =
      textTheme.bodySmall ?? textTheme.bodyMedium ?? const TextStyle();

  return ListTileThemeData(
    dense: false,
    minVerticalPadding: 4,
    contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 16),
    titleTextStyle: title.copyWith(
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    ),
    subtitleTextStyle: subtitle.copyWith(color: colorScheme.onSurfaceVariant),
  );
}
