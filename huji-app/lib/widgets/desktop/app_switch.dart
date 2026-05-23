import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';

/// macOS-style toggle switch.
class AppSwitch extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;

  const AppSwitch({super.key, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppHoverBox(
      onTap: onTap,
      borderRadius: 10,
      child: AnimatedContainer(
        width: 36,
        height: 20,
        duration: DesktopTheme.animationFast,
        curve: DesktopTheme.defaultCurve,
        decoration: BoxDecoration(
          color: active
              ? DesktopTheme.primaryColor
              : DesktopTheme.borderMedium,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment:
            active ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
