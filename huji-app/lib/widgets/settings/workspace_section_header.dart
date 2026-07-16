import 'package:flutter/material.dart';
import 'package:shared_ui/theme/app_text_styles.dart';

/// Section header for workspace content / settings panes (Teampilot style).
class WorkspaceSectionHeader extends StatelessWidget {
  const WorkspaceSectionHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final styles = AppTextStyles.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textBase = isDark ? Colors.white : const Color(0xFF111827);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.subtitle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textBase,
                  height: 1.05,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
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
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 12),
          Row(mainAxisSize: MainAxisSize.min, children: _spaced(actions)),
        ] else if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }

  List<Widget> _spaced(List<Widget> widgets) {
    return widgets.asMap().entries.expand((e) {
      if (e.key > 0) return [const SizedBox(width: 8), e.value];
      return [e.value];
    }).toList();
  }
}
