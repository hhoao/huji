import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/settings/log_viewer_filter.dart';
import 'package:shared_ui/shared_ui.dart';

/// Toolbar for the log viewer: file selection, search, level filter and
/// actions (refresh / copy / clean / reverse).
class LogViewerToolbar extends StatelessWidget {
  const LogViewerToolbar({
    required this.logFiles,
    required this.selectedFile,
    required this.searchController,
    required this.selectedLevel,
    required this.compactView,
    required this.wrapLines,
    required this.reverseOrder,
    required this.lineCount,
    required this.onFileSelected,
    required this.onSearchChanged,
    required this.onLevelChanged,
    required this.onCompactViewChanged,
    required this.onWrapLinesChanged,
    required this.onRefresh,
    required this.onCopyPath,
    required this.onCopyAll,
    required this.onClearOld,
    required this.onReverseOrderChanged,
    super.key,
  });

  final List<String> logFiles;
  final String? selectedFile;
  final TextEditingController searchController;
  final String selectedLevel;
  final bool compactView;
  final bool wrapLines;
  final bool reverseOrder;
  final int lineCount;
  final ValueChanged<String> onFileSelected;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<bool> onCompactViewChanged;
  final ValueChanged<bool> onWrapLinesChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCopyPath;
  final Future<void> Function() onCopyAll;
  final Future<void> Function() onClearOld;
  final ValueChanged<bool> onReverseOrderChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fileValue =
        selectedFile ?? (logFiles.isNotEmpty ? logFiles.first : null);

    final fileSelect = SizedBox(
      width: 190,
      child: TpCompactSelect<String>(
        value: fileValue ?? '',
        entries: logFiles
            .map((path) => (path, _fileName(path)))
            .toList(growable: false),
        onChanged: (value) {
          if (value != null && value.isNotEmpty) onFileSelected(value);
        },
        enabled: logFiles.isNotEmpty,
        minWidth: 0,
      ),
    );

    final searchField = TpInput(
      controller: searchController,
      decoration: InputDecoration(
        hintText: context.hujiL10n.searchLogsHint,
        prefixIcon: Icon(
          Icons.search,
          size: context.tpIconSizes.md,
          color: cs.onSurfaceVariant,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      onChanged: onSearchChanged,
    );

    final levelSelect = SizedBox(
      width: 118,
      child: TpCompactSelect<String>(
        value: selectedLevel,
        entries: kLogViewerLevels
            .map((level) => (level, level))
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) onLevelChanged(value);
        },
        minWidth: 0,
      ),
    );

    final toggles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconToggle(
          context: context,
          tooltip: context.hujiL10n.logViewerCompactView,
          onIcon: Icons.filter_alt,
          offIcon: Icons.filter_alt_outlined,
          value: compactView,
          onPressed: () => onCompactViewChanged(!compactView),
        ),
        const SizedBox(width: 4),
        _iconToggle(
          context: context,
          tooltip: context.hujiL10n.logViewerWrapLines,
          onIcon: Icons.wrap_text,
          offIcon: Icons.wrap_text_outlined,
          value: wrapLines,
          onPressed: () => onWrapLinesChanged(!wrapLines),
        ),
        const SizedBox(width: 4),
        TpActionMenuButton(
          tooltip: context.hujiL10n.filterOptionsTitle,
          icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
          specs: [
            TpActionMenuSpec.item(
              value: 'refresh',
              icon: Icons.refresh,
              label: context.hujiL10n.logViewerRefresh,
            ),
            TpActionMenuSpec.item(
              value: 'copy',
              icon: Icons.copy_outlined,
              label: context.hujiL10n.logViewerCopyPath,
            ),
            TpActionMenuSpec.item(
              value: 'copyAll',
              icon: Icons.copy_all_outlined,
              label: context.hujiL10n.logViewerCopyAll,
            ),
            TpActionMenuSpec.item(
              value: 'clear',
              icon: Icons.cleaning_services_outlined,
              label: context.hujiL10n.logViewerClearOld,
            ),
            TpActionMenuSpec.item(
              value: 'reverse',
              icon: Icons.swap_vert,
              label: context.hujiL10n.logViewerReverseOrder,
              selected: reverseOrder,
            ),
          ],
          onSelected: (action) async {
            switch (action) {
              case 'refresh':
                await onRefresh();
              case 'copy':
                await onCopyPath();
              case 'copyAll':
                await onCopyAll();
              case 'clear':
                await onClearOld();
              case 'reverse':
                onReverseOrderChanged(!reverseOrder);
            }
          },
        ),
      ],
    );

    final countBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.hujiL10n.logViewerLineCount(lineCount),
        style: TpTextStyles.of(
          context,
        ).xsSemiboldColored(cs.onPrimaryContainer),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: cs.workspaceInset,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 640;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (logFiles.isNotEmpty) ...[
                      Expanded(child: fileSelect),
                      const SizedBox(width: 8),
                    ],
                    toggles,
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 8),
                    levelSelect,
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: countBadge),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (logFiles.isNotEmpty) ...[
                fileSelect,
                const SizedBox(width: 8),
              ],
              Expanded(child: searchField),
              const SizedBox(width: 8),
              levelSelect,
              const SizedBox(width: 4),
              toggles,
              const SizedBox(width: 8),
              countBadge,
            ],
          );
        },
      ),
    );
  }

  static String _fileName(String path) {
    final index = path.lastIndexOf(RegExp(r'[/\\]'));
    return index >= 0 ? path.substring(index + 1) : path;
  }

  Widget _iconToggle({
    required BuildContext context,
    required String tooltip,
    required IconData onIcon,
    required IconData offIcon,
    required bool value,
    required VoidCallback onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TpIconButton(
      icon: value ? onIcon : offIcon,
      iconSize: context.tpIconSizes.md,
      size: 36,
      tooltip: tooltip,
      color: value ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      backgroundColor: value
          ? cs.primaryContainer.withValues(alpha: 0.7)
          : cs.workspaceInset,
      onTap: onPressed,
    );
  }
}

/// Loading spinner shown below the toolbar while a file is read.
class LogViewerLoadingBar extends StatelessWidget {
  const LogViewerLoadingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LinearProgressIndicator(
      minHeight: 2,
      color: cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
    );
  }
}
