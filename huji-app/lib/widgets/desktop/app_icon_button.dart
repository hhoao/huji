import 'package:flutter/material.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';

/// Small icon-only button with hover/tap feedback.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 32,
    this.color,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.desktopOnSurfaceVariant;

    return AppHoverBox(
      onTap: onTap,
      borderRadius: desktopRadiusMd,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: iconSize, color: effectiveColor),
      ),
    );
  }
}
