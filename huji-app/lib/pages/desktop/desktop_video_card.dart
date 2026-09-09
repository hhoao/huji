import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:path/path.dart' as p;
import 'package:shared_ui/shared_ui.dart';

/// 视频库（桌面）网格模式的视频项卡片。
///
/// 渲染在 GridView 固定高度（mainAxisExtent: 220）的单元格里：缩略图区域
/// 用 [Expanded] 吸收单元格高度变化，文字区按内容自适应 —— 文字高度随
/// 自动字号基线（[autoTextScaleForSystem] = OS 缩放 × devicePixelRatio，
/// Retina 屏可达 ×2）增长时，压缩的是缩略图而不是溢出单元格。
///
/// 回归背景：旧实现用 flex 3:2 固定切分，×2 字号下两行文字需 ~72px 而分配
/// 只有 ~67px，线上报 "A RenderFlex overflowed by 4.8 pixels on the
/// bottom"（desktop_home_page 网格卡片）。
class DesktopVideoCard extends StatelessWidget {
  const DesktopVideoCard({
    super.key,
    required this.record,
    this.onSecondaryTapDown,
  });

  final LocalVideoRecord record;

  /// 右键菜单回调（压缩/删除），由宿主页面提供。
  final void Function(TapDownDetails details)? onSecondaryTapDown;

  bool get _isNavigable {
    if (record is ProcessVideoRecord) {
      return record.processStatus == LocalVideoProcessStatusEnum.completed;
    }
    return record is EdittingVideoRecord || record is SavedVideoRecord;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    return TpHover(
      onTap: _isNavigable
          ? () => context.go(DesktopRoutes.clipPreviewPath(record.id))
          : null,
      onSecondaryTapDown: onSecondaryTapDown,
      borderRadius: BorderRadius.circular(10),
      pressScale: 0.97,
      child: Container(
        decoration: workspaceCardDecoration(cs, radius: 10),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 视频缩略图：Expanded 吸收单元格高度变化，避免文字区在大
            // 字号基线（Retina ×2）下溢出卡片底部。
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DesktopVideoThumbnail(record: record),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DesktopVideoStatusBadge(
                      status: record.processStatus,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.filePath != null
                        ? p.basename(record.filePath!)
                        : context.hujiL10n.untitledName,
                    style: styles.mdSemibold.copyWith(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    record.sportType.title,
                    style: styles.xs.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DesktopVideoThumbnail extends StatelessWidget {
  const DesktopVideoThumbnail({super.key, required this.record});

  final LocalVideoRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final thumbPath = record.thumbnailPath;
    // No existsSync() here — build must stay free of sync disk IO (called per
    // card per rebuild, incl. every frame of pane animations). Missing files
    // fall through to errorBuilder, which renders the same placeholder.
    if (thumbPath != null) {
      return Image.file(
        File(thumbPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: cs.surfaceContainerHigh,
          child: Icon(Icons.videocam, size: 32, color: cs.outline),
        ),
      );
    }
    return ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Center(child: Icon(Icons.videocam, size: 32, color: cs.outline)),
    );
  }
}

class DesktopVideoStatusBadge extends StatelessWidget {
  const DesktopVideoStatusBadge({super.key, required this.status});

  final LocalVideoProcessStatusEnum status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      LocalVideoProcessStatusEnum.pending => (
        l10n.localVideoStatusPending,
        const Color(0xFFEAB308),
      ),
      LocalVideoProcessStatusEnum.processing => (
        l10n.localVideoStatusProcessing,
        cs.primary,
      ),
      LocalVideoProcessStatusEnum.completed => (
        l10n.taskStatusCompleted,
        const Color(0xFF22C55E),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(217),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TpTextStyles.of(context).xs.copyWith(color: cs.onPrimary),
      ),
    );
  }
}
