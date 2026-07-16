import 'package:flutter/material.dart';

import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/theme/app_text_styles.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

class ThemeColorPresetPicker extends StatelessWidget {
  const ThemeColorPresetPicker({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    return Align(
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final id in kThemeColorPresetIds)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ThemeColorPresetChip(
                  id: id,
                  label: l10n.themeColorPresetName(id),
                  selected: id == selected,
                  onTap: () => onSelect(id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ThemeColorPresetChip extends StatelessWidget {
  const ThemeColorPresetChip({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textBase = isDark ? Colors.white : const Color(0xFF111827);
    final primary = themePresetSwatchPrimary(id);
    final secondary = themePresetSwatchSecondary(id);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.workspaceInset,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.of(context).bodySmall.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: textBase.withValues(alpha: selected ? 1 : 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
