import 'package:flutter/material.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';

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
                    color: active
                        ? DesktopTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: active
                          ? Colors.white
                          : DesktopTheme.textMuted,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: DesktopTheme.primaryColor
                            .withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                            fontSize: 11,
                            color: DesktopTheme.indigoText),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(labels.length, (i) {
        final active = i == activeIndex;
        return AppHoverBox(
          onTap: () => onChanged?.call(i),
          borderRadius: DesktopTheme.radiusMd,
          backgroundColor: active
              ? DesktopTheme.primaryColor.withAlpha(31)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(
                icons[i],
                size: 16,
                color: active
                    ? DesktopTheme.indigoText
                    : DesktopTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  color: active
                      ? DesktopTheme.indigoText
                      : DesktopTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
