import 'package:flutter/material.dart';

/// Scrollable middle slot inside [HujiSidebar]. Use inside a [Column] with
/// [HujiSidebarHeader] / [HujiSidebarFooter].
class HujiSidebarContent extends StatelessWidget {
  const HujiSidebarContent({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}
