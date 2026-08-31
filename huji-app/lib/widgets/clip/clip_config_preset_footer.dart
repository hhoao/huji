import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/widgets/feature_stub_actions.dart';
import 'package:shared_ui/shared_ui.dart';

/// Shared "save as preset" stub — same on mobile and desktop until implemented.
class ClipConfigPresetFooter extends StatelessWidget {
  const ClipConfigPresetFooter({
    required this.presetLabel,
    this.padding = const EdgeInsets.all(22),
    this.outlined = false,
    super.key,
  });

  final String presetLabel;
  final EdgeInsets padding;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final muted = outlined
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Colors.grey;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.hujiL10n.configPresetMismatch(4, presetLabel),
            style: styles.xs.copyWith(color: muted),
          ),
          const SizedBox(height: 10),
          TpButton(
            variant: TpButtonVariant.outline,
            onPressed: () => FeatureStubActions.showPresetComingSoon(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save_outlined, size: 16),
                const SizedBox(width: 6),
                Text(context.hujiL10n.saveAsPreset),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
