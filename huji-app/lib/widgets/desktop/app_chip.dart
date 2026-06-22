import 'package:flutter/material.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';
import 'package:shared_ui/shared_ui.dart';

/// Toggle chip with selected/unselected visual states and hover feedback.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    final Color bg;
    final Color fg;
    final Color border;

    if (selected) {
      bg = cs.primary.withAlpha(51);
      fg = cs.primary;
      border = cs.primary;
    } else {
      bg = cs.surfaceContainer;
      fg = cs.onSurfaceVariant;
      border = cs.outlineVariant.withValues(alpha: 0.55);
    }

    return AppHoverBox(
      onTap: onTap,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      backgroundColor: bg,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
            ],
            Text(label, style: styles.caption.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
