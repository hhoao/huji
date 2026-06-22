import 'package:flutter/material.dart';
import 'package:huji_app/constants/demo_videos.dart';

typedef DemoVideoTap = Future<void> Function(DemoVideo demo);

/// Compact list of bundled demo videos.
class DemoVideoPicker extends StatelessWidget {
  const DemoVideoPicker({
    super.key,
    required this.onDemoSelected,
    this.loading = false,
    this.filterSportLabel,
    this.dense = false,
  });

  final DemoVideoTap onDemoSelected;
  final bool loading;
  final String? filterSportLabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final items = filterSportLabel == null
        ? demoVideos
        : demoVideosForSportLabel(filterSportLabel!);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '或使用演示视频',
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
            color: dense ? Colors.white70 : Colors.grey,
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
    final emoji = demo.sportTypeKey == 'ping_pong' ? '🏓' : '🏸';
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 14,
          vertical: dense ? 8 : 10,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: dense ? 14 : 16)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                demo.title,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
              Text(
                demo.subtitle,
                style: TextStyle(
                  fontSize: dense ? 10 : 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
