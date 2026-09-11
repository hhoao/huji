import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/services/demo_video_service.dart';
import 'package:huji_app/utils/video_utils.dart';
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

/// Bundled demo videos rendered as clickable thumbnail-only cards.
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
                _DemoThumbnailCard(
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

class _DemoThumbnailCard extends StatelessWidget {
  const _DemoThumbnailCard({
    required this.demo,
    required this.dense,
    required this.onTap,
  });

  final DemoVideo demo;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = dense ? 168.0 : 220.0;
    return Semantics(
      label: demoVideoTitle(context.hujiL10n, demo),
      button: true,
      enabled: onTap != null,
      child: TpHover(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        pressScale: 0.97,
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DemoVideoThumbnail(demo: demo),
            ),
          ),
        ),
      ),
    );
  }
}

/// Generates and caches a thumbnail for a bundled demo video.
class DemoVideoThumbnail extends StatefulWidget {
  const DemoVideoThumbnail({super.key, required this.demo});

  final DemoVideo demo;

  @override
  State<DemoVideoThumbnail> createState() => _DemoVideoThumbnailState();
}

class _DemoVideoThumbnailState extends State<DemoVideoThumbnail> {
  String? _thumbPath;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await DemoVideoService.materialize(widget.demo);
      final thumbPath = await VideoUtils.generateVideoThumbnail(
        file.path,
        fileName: 'demo_${widget.demo.id}_thumb.png',
        reuseExisting: true,
      );
      if (mounted) setState(() => _thumbPath = thumbPath);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final thumbPath = _thumbPath;
    if (thumbPath != null) {
      return Image.file(
        File(thumbPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(cs),
      );
    }
    return _placeholder(cs, loading: _error == null);
  }

  Widget _placeholder(ColorScheme cs, {bool loading = false}) {
    return ColoredBox(
      color: cs.onSurface.withValues(alpha: 0.06),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.videocam, color: cs.onSurfaceVariant, size: 28),
      ),
    );
  }
}
