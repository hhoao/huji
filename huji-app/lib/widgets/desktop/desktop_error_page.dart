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
    final styles = TpTextStyles.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              l10n.pageLoadFailed,
              style: styles.mdMedium.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? l10n.unknownError,
              style: styles.mutedSm,
            ),
            const SizedBox(height: 24),
            TpButton(
              variant: TpButtonVariant.primary,
              onPressed: () => context.go('/'),
              child: Text(l10n.returnToHome),
            ),
          ],
        ),
      ),
    );
  }
}
