import 'package:flutter/material.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

typedef DemoVideoTap = Future<void> Function(DemoVideo demo);

String demoVideoTitle(HujiLocalizations l10n, DemoVideo demo) =>
    switch (demo.id) {
      'ping_pong_demo' => l10n.demoPingPongTitle,
      'badminton_demo' => l10n.demoBadmintonTitle,
      _ => demo.title,
    };

String demoVideoSubtitle(HujiLocalizations l10n, DemoVideo demo) =>
    switch (demo.id) {
      'ping_pong_demo' => l10n.demoPingPongSubtitle,
      'badminton_demo' => l10n.demoBadmintonSubtitle,
      _ => demo.subtitle,
    };

/// Compact list of bundled demo videos.
class DemoVideoPicker extends StatelessWidget {
  const DemoVideoPicker({
    super.key,
    required this.onDemoSelected,
    this.loading = false,
    this.filterSportTypeKey,
    this.dense = false,
  });

  final DemoVideoTap onDemoSelected;
  final bool loading;
  final String? filterSportTypeKey;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;
    final items = filterSportTypeKey == null
        ? demoVideos
        : demoVideosForSportKey(filterSportTypeKey!);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.hujiL10n.useDemoVideo,
          style: styles.smMedium.copyWith(
            color: dense ? cs.onSurface : cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: dense ? 8 : 12),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final demo in items)
                _DemoChip(
                  demo: demo,
                  dense: dense,
                  onTap: loading ? null : () => onDemoSelected(demo),
                ),
            ],
          ),
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.demo,
    required this.dense,
    required this.onTap,
  });

  final DemoVideo demo;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final emoji = demo.sportTypeKey == 'ping_pong' ? '🏓' : '🏸';
    return TpButton(
      variant: TpButtonVariant.outline,
      size: dense ? TpControlSize.small : TpControlSize.medium,
      fitContentHeight: true,
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: dense ? styles.sm : styles.md),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                demoVideoTitle(context.hujiL10n, demo),
                style: styles.sm,
              ),
              Text(
                demoVideoSubtitle(context.hujiL10n, demo),
                style: styles.sm.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
