import 'package:flutter/widgets.dart';

/// Replaces the OS-supplied [MediaQuery.textScaler] with [TextScaler.noScaling].
///
/// Platform text-scaling diverges the UI: on Linux the GTK embedder folds the
/// GNOME `text-scaling-factor` into [MediaQuery.textScaler]; Windows/macOS keep
/// it at 1.0. The app owns its density through the theme (typography + spacing +
/// icon sizes, driven by the interface-scale setting), so the OS textScaler is
/// neutralized here to keep all platforms identical at a given scale.
class AppTextScaleBoundary extends StatelessWidget {
  const AppTextScaleBoundary({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.textScaler == TextScaler.noScaling) return child;
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.noScaling),
      child: child,
    );
  }
}
