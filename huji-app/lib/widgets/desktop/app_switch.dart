import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/utils/desktop_style.dart';

/// macOS-style toggle switch.
class AppSwitch extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;

  const AppSwitch({super.key, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;

    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      pressScale: 0.97,
      child: AnimatedContainer(
        width: 36,
        height: 20,
        duration: desktopAnimationFast,
        curve: desktopDefaultCurve,
        decoration: BoxDecoration(
          color: active ? cs.primary : context.desktopBorderMedium,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.onPrimary,
          ),
        ),
      ),
    );
  }
}
