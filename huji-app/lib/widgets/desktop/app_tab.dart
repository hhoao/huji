import 'package:flutter/material.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';
import 'package:shared_ui/shared_ui.dart';

/// Desktop tab bar with animated underline indicator.
class AppTab extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int>? onChanged;
  final Map<int, String>? badges;
  final double spacing;

  const AppTab({
    super.key,
    required this.tabs,
    required this.activeIndex,
    this.onChanged,
    this.badges,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    return Row(
      children: List.generate(tabs.length, (i) {
        final active = i == activeIndex;
        final badge = badges?[i];

        return Padding(
          padding: EdgeInsets.only(right: spacing),
          child: AppHoverBox(
            onTap: () => onChanged?.call(i),
            borderRadius: 0,
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i],
                    style: styles.md.copyWith(
                      color: active ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: styles.xs.copyWith(color: cs.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Vertical section nav tabs (for settings-style left navigation).
class AppTabNav extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int activeIndex;
  final ValueChanged<int>? onChanged;

  const AppTabNav({
    super.key,
    required this.labels,
    required this.icons,
    required this.activeIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(labels.length, (i) {
        final active = i == activeIndex;
        return AppHoverBox(
          onTap: () => onChanged?.call(i),
          borderRadius: 6,
          backgroundColor: active
              ? cs.primaryContainer.withValues(alpha: 0.35)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(
                icons[i],
                size: 16,
                color: active ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                labels[i],
                style: styles.md.copyWith(
                  color: active ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
