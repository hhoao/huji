import 'package:flutter/material.dart';
import 'package:shared_ui/theme/app_text_styles.dart';

/// Page header for hub / settings right panes (Teampilot [WorkspaceHubTitleBar]).
class WorkspaceHubTitleBar extends StatelessWidget {
  const WorkspaceHubTitleBar({
    required this.title,
    required this.subtitle,
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textBase = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(20, 20, 20, 16)
          : const EdgeInsets.fromLTRB(40, 42, 40, 28),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(context).subtitle.copyWith(
              color: textBase,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textBase.withValues(alpha: 0.66),
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
