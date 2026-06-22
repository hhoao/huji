import 'package:flutter/material.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';

/// Simple display-only timeline bar showing a segment's time range.
/// Phase 3: no drag handles yet — just a visual highlight of start..end.
class DesktopTimelineEditor extends StatelessWidget {
  final SegmentInfo segment;

  const DesktopTimelineEditor({super.key, required this.segment});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);

    return Column(
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            border: Border.all(color: context.desktopBorderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(89),
                    border: Border.all(
                      color: cs.primary.withAlpha(179),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    segment.actionType.name,
                    style: styles.caption.copyWith(
                      color: cs.primary.withAlpha(200),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${segment.startSeconds.toStringAsFixed(1)}s',
              style: styles.mono.copyWith(color: cs.outline),
            ),
            Text(
              '${segment.endSeconds.toStringAsFixed(1)}s',
              style: styles.mono.copyWith(color: cs.outline),
            ),
          ],
        ),
      ],
    );
  }
}
