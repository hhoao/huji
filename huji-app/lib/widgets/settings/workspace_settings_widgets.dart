import 'package:flutter/material.dart';

import 'package:huji_app/theme/workspace_surface_layers.dart';

const _settingCardBorderRadius = 14.0;
const _settingRowPadding = EdgeInsets.fromLTRB(20, 16, 20, 16);
const _settingGroupHeaderPadding = EdgeInsets.fromLTRB(20, 20, 20, 8);
const _titleSubtitleGap = 4.0;
const _labelTrailingGap = 24.0;

bool _hasSettingsSubtitle(String? subtitle) =>
    subtitle != null && subtitle.trim().isNotEmpty;

/// Rounded settings panel (card) using global colors and spacing tokens.
class SettingsSurfaceCard extends StatelessWidget {
  const SettingsSurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: workspaceCardDecoration(
        cs,
        radius: _settingCardBorderRadius,
        borderAlpha: 0.5,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Section label inside a settings card (e.g. "区域可见性").
class SettingsGroupHeader extends StatelessWidget {
  const SettingsGroupHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: _settingGroupHeaderPadding,
      child: Text(
        title,
        style: tt.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// One settings row: title + subtitle on the left, [trailing] on the right.
class SettingsLabeledRow extends StatelessWidget {
  const SettingsLabeledRow({
    super.key,
    required this.title,
    this.subtitle,
    this.titleLeading,
    required this.trailing,
    this.showDividerBelow = true,
  });

  final String title;
  final String? subtitle;
  final Widget? titleLeading;
  final Widget trailing;
  final bool showDividerBelow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasSubtitle = _hasSettingsSubtitle(subtitle);
    final subtitleStyle = tt.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: _settingRowPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (titleLeading != null) ...[
                titleLeading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    if (hasSubtitle) ...[
                      SizedBox(height: _titleSubtitleGap),
                      Text(subtitle!.trim(), style: subtitleStyle),
                    ],
                  ],
                ),
              ),
              SizedBox(width: _labelTrailingGap),
              Flexible(
                fit: FlexFit.loose,
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          ),
        ),
        if (showDividerBelow)
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
