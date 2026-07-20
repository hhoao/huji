import 'package:flutter/material.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';

/// Compact filter dropdown trigger shared by task list filter menus.
class TaskFilterMenuTrigger extends StatelessWidget {
  const TaskFilterMenuTrigger({
    super.key,
    required this.label,
    required this.isActive,
    required this.isOpen,
    this.onTap,
    this.icon = Icons.tune,
  });

  final String label;
  final bool isActive;
  final bool isOpen;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;

    final face = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : cs.surfaceContainer,
        border: Border.all(
          color: isActive
              ? cs.primary.withValues(alpha: 0.45)
              : cs.outlineVariant.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? cs.primary : cs.outline,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TpTextStyles.of(context).xs.copyWith(
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 18,
            color: isActive ? cs.primary : cs.outline,
          ),
        ],
      ),
    );

    if (onTap == null) return face;

    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      pressScale: 0.97,
      child: face,
    );
  }
}
