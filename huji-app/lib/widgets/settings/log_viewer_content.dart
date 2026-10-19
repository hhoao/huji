import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/settings/log_viewer_filter.dart';
import 'package:shared_ui/shared_ui.dart';

/// Centered placeholder used for empty / not-yet-created log files.
class LogViewerCenteredMessage extends StatelessWidget {
  const LogViewerCenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: context.tpIconSizes.md,
              color: cs.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TpTextStyles.of(context).lgBoldSnug,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TpTextStyles.of(context).mutedMd,
            ),
          ],
        ),
      ),
    );
  }
}

/// Virtualized log line list with optional wrapping.
class LogViewerLineList extends StatelessWidget {
  const LogViewerLineList({
    required this.lines,
    required this.wrapLines,
    required this.scrollController,
    super.key,
  });

  final List<String> lines;
  final bool wrapLines;
  final ScrollController scrollController;

  static const _singleLineExtent = 21.0;
  static final _cacheExtent = ScrollCacheExtent.pixels(1200);

  @override
  Widget build(BuildContext context) {
    if (wrapLines) {
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: scrollController,
          scrollCacheExtent: _cacheExtent,
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          itemCount: lines.length,
          itemBuilder: (context, index) {
            return _LogLineTile(
              line: lines[index],
              index: index,
              singleLine: false,
            );
          },
        ),
      );
    }

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        itemExtent: _singleLineExtent,
        scrollCacheExtent: _cacheExtent,
        addAutomaticKeepAlives: false,
        addSemanticIndexes: false,
        itemCount: lines.length,
        itemBuilder: (context, index) {
          return _LogLineTile(
            line: lines[index],
            index: index,
            singleLine: true,
          );
        },
      ),
    );
  }
}

class _LogLineTile extends StatelessWidget {
  const _LogLineTile({
    required this.line,
    required this.index,
    required this.singleLine,
  });

  final String line;
  final int index;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tinted = logLineColor(context, line);
    final background = index.isEven
        ? Colors.transparent
        : cs.onSurface.withValues(alpha: 0.03);

    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Text(
          line,
          maxLines: singleLine ? 1 : null,
          overflow: singleLine ? TextOverflow.clip : null,
          style: logMonospaceStyle(context, color: tinted),
        ),
      ),
    );
  }
}

/// Body of the log viewer: pending / empty / error / lines.
class LogViewerBody extends StatelessWidget {
  const LogViewerBody({
    required this.logFiles,
    required this.loading,
    required this.lines,
    required this.wrapLines,
    required this.scrollController,
    required this.errorLines,
    super.key,
  });

  final List<String> logFiles;
  final bool loading;
  final List<String> lines;
  final bool wrapLines;
  final ScrollController scrollController;
  final List<String>? errorLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.hujiL10n;
    final errors = errorLines;

    if (errors != null && errors.isNotEmpty) {
      return _ErrorLines(lines: errors);
    }

    final showPending =
        !AppLogger.instance.getFileLoggerInitialized() && logFiles.isEmpty;
    if (showPending) {
      return _PendingLogs();
    }

    if (logFiles.isEmpty && !loading) {
      return LogViewerCenteredMessage(
        icon: Icons.article_outlined,
        title: l10n.logViewerEmpty,
        subtitle: l10n.logViewerEmptyHint,
      );
    }

    if (loading && lines.isEmpty) {
      return const Center(child: TpIndeterminateSpinner());
    }

    return ColoredBox(
      color: cs.workspaceCode,
      child: SelectionArea(
        child: LogViewerLineList(
          lines: lines,
          wrapLines: wrapLines,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _ErrorLines extends StatelessWidget {
  const _ErrorLines({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.workspaceCode,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectionArea(
          child: Text(
            lines.join('\n'),
            style: logMonospaceStyle(context, color: cs.error),
          ),
        ),
      ),
    );
  }
}

class _PendingLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            l10n.logViewerPendingTitle,
            style: TpTextStyles.of(context).mdBoldTightSnug,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            l10n.logViewerPendingBody,
            style: TpTextStyles.of(context).mutedSm,
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: cs.workspaceCode,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                AppLogger.instance.getFormattedPendingLogs(),
                style: logMonospaceStyle(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
