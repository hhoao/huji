import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/changelog.dart';
import 'package:shared_ui/shared_ui.dart';

/// Changelog rendered inline (no Scaffold) for embedding in a settings
/// section body — the desktop About pane. The mobile entry point keeps
/// pushing the full-screen [ChangelogPage].
class ChangelogInlineList extends StatefulWidget {
  const ChangelogInlineList({super.key});

  @override
  State<ChangelogInlineList> createState() => _ChangelogInlineListState();
}

class _ChangelogInlineListState extends State<ChangelogInlineList> {
  List<ChangelogEntry>? _entries;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _entries = null;
      _errorMessage = null;
    });
    try {
      final entries = await ChangelogData.entries;
      if (!mounted) return;
      setState(() {
        _entries = entries;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.hujiL10n.loadChangelogFailed('$e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.aboutChangelogTitle,
                style: TpTextStyles.of(context).smSemibold,
              ),
              const Spacer(),
              if (_entries != null)
                TpIconButton(
                  icon: Icons.refresh,
                  onTap: _load,
                  tooltip: l10n.actionRefresh,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aboutChangelogDescription,
            style: TpTextStyles.of(context).mutedSm,
          ),
          const SizedBox(height: 16),
          if (_entries == null && _errorMessage == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            TpEmptyState(
              icon: Icons.error_outline,
              title: _errorMessage!,
              actionLabel: l10n.actionRetry,
              onAction: _load,
            )
          else if (_entries!.isEmpty)
            TpEmptyState(
              icon: Icons.description_outlined,
              title: l10n.noChangelogEntries,
            )
          else
            ..._entries!.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ChangelogData.buildChangelogItem(context, entry),
              ),
            ),
        ],
      ),
    );
  }
}
