import 'package:flutter/material.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/models/autoclip_models.dart';

/// Simple display-only timeline bar showing a segment's time range.
/// Phase 3: no drag handles yet — just a visual highlight of start..end.
class DesktopTimelineEditor extends StatelessWidget {
  final SegmentInfo segment;

  const DesktopTimelineEditor({super.key, required this.segment});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: DesktopTheme.cardBg,
            border: Border.all(color: DesktopTheme.borderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              // Background track
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: DesktopTheme.subMainBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Segment range highlighted
              Positioned(
                top: 16,
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: DesktopTheme.primaryColor.withAlpha(89),
                    border: Border.all(
                        color: DesktopTheme.primaryColor.withAlpha(179),
                        width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Center label showing segment duration
              Positioned.fill(
                child: Center(
                  child: Text(
                    segment.actionType.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: DesktopTheme.primaryColor.withAlpha(200),
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
            Text('${segment.startSeconds.toStringAsFixed(1)}s',
                style: const TextStyle(
                    fontSize: 10,
                    color: DesktopTheme.textDim,
                    fontFamily: 'monospace')),
            Text('${segment.endSeconds.toStringAsFixed(1)}s',
                style: const TextStyle(
                    fontSize: 10,
                    color: DesktopTheme.textDim,
                    fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }
}
