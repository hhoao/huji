import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';

/// Error page shown when desktop route navigation fails.
class DesktopErrorPage extends StatelessWidget {
  final Exception? error;
  const DesktopErrorPage(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = context.desktopColors;

    return Scaffold(
      backgroundColor: cs.surface,
      body: TpEmptyState(
        centered: true,
        icon: Icons.error_outline,
        title: l10n.pageLoadFailed,
        hint: error?.toString() ?? l10n.unknownError,
        actionLabel: l10n.returnToHome,
        onAction: () => context.go('/'),
      ),
    );
  }
}
