import 'package:flutter/material.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';

/// Toggle chip with selected/unselected visual states and hover feedback.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final double fontSize;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;

    if (selected) {
      bg = DesktopTheme.primaryColor.withAlpha(51);
      fg = DesktopTheme.indigoText;
      border = DesktopTheme.primaryColor;
    } else {
      bg = DesktopTheme.cardBg;
      fg = DesktopTheme.textSecondary;
      border = DesktopTheme.borderMedium;
    }

    return AppHoverBox(
      onTap: onTap,
      borderRadius: DesktopTheme.radiusMd,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      backgroundColor: bg,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(DesktopTheme.radiusMd),
        ),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: fg),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(fontSize: fontSize, color: fg)),
          ],
        ),
      ),
    );
  }
}
