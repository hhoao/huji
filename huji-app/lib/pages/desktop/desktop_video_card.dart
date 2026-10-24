import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/utils/desktop_library_navigation.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/utils/desktop_style.dart';
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
    this.actionMenu,
    this.selectionMode = false,
    this.selected = false,
    this.onToggleSelect,
  });

  final LocalVideoRecord record;

  /// 右键菜单回调（压缩/删除），由宿主页面提供。
  final void Function(TapDownDetails details)? onSecondaryTapDown;

  /// 标题行右侧的 ⋯ 操作菜单（删除、压缩等）。
  final Widget? actionMenu;

  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelect;

  bool get _isNavigable {
    if (record is ProcessVideoRecord) {
      return record.processStatus == LocalVideoProcessStatusEnum.completed;
    }
    return record is EdittingVideoRecord || record is SavedVideoRecord;
  }

  VoidCallback? _primaryTap(BuildContext context) {
    if (selectionMode) return onToggleSelect;
    if (_isNavigable) {
      return () => openDesktopLibraryRecord(context, record);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final decoration = selectionMode && selected
        ? workspaceCardDecoration(cs, radius: 10).copyWith(
            color: cs.primary.withAlpha(20),
            border: Border.all(color: cs.primary.withAlpha(102)),
          )
        : workspaceCardDecoration(cs, radius: 10);
    return TpHover(
      onTap: _primaryTap(context),
      onSecondaryTapDown: selectionMode ? null : onSecondaryTapDown,
      borderRadius: BorderRadius.circular(10),
      pressScale: 0.97,
      child: Container(
        decoration: decoration,
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
                  if (selectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DesktopLibrarySelectIndicator(selected: selected),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DesktopLibraryRecordBadge(record: record),
                  ),
                  if (localVideoRecordDurationSeconds(record) case final duration?)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: DesktopLibraryVideoDurationLabel(
                        durationSeconds: duration,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          record.filePath != null
                              ? p.basename(record.filePath!)
                              : context.hujiL10n.untitledName,
                          style: styles.mdSemibold.copyWith(color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!selectionMode && actionMenu != null) actionMenu!,
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.sportType.title,
                          style: styles.xs.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DesktopLibraryRecordMetaLine(record: record),
                    ],
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

/// 多选模式下的圆形勾选指示（与任务列表批量选择一致）。
class DesktopLibrarySelectIndicator extends StatelessWidget {
  const DesktopLibrarySelectIndicator({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? cs.primary : Colors.black.withAlpha(89),
        border: Border.all(
          color: selected ? cs.primary : cs.onPrimary.withAlpha(217),
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 14, color: cs.onPrimary)
          : null,
    );
  }
}

/// 列表/网格缩略图区域：底栏时长（有数据时）。
class DesktopVideoThumbnailFrame extends StatelessWidget {
  const DesktopVideoThumbnailFrame({super.key, required this.record});

  final LocalVideoRecord record;

  @override
  Widget build(BuildContext context) {
    final duration = localVideoRecordDurationSeconds(record);
    return Stack(
      fit: StackFit.expand,
      children: [
        DesktopVideoThumbnail(record: record),
        if (duration != null)
          Positioned(
            bottom: 4,
            right: 4,
            child: DesktopLibraryVideoDurationLabel(durationSeconds: duration),
          ),
      ],
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

@visibleForTesting
double? localVideoRecordDurationSeconds(LocalVideoRecord record) {
  if (record is SavedVideoRecord) {
    return record.duration > 0 ? record.duration : null;
  }
  if (record is EdittingVideoRecord) {
    final segments = record.allMatchSegments;
    if (segments.isEmpty) return null;
    var total = 0.0;
    for (final SegmentInfo seg in segments) {
      total += seg.endSeconds - seg.startSeconds;
    }
    return total > 0 ? total : null;
  }
  return null;
}

/// 卡片信息区右下角：创建月日（如 9月28日）。
class DesktopLibraryRecordMetaLine extends StatelessWidget {
  const DesktopLibraryRecordMetaLine({super.key, required this.record});

  final LocalVideoRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final text = desktopLibraryRecordCreatedDateLabel(
      record.createdAt,
      languageCode: locale.languageCode,
    );
    return Text(
      text,
      style: TpTextStyles.of(context).xs.copyWith(color: cs.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

@visibleForTesting
String desktopLibraryRecordCreatedDateLabel(
  int createdAtMs, {
  String languageCode = 'zh',
}) {
  final date = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  if (languageCode.startsWith('zh')) {
    return '${date.month}月${date.day}日';
  }
  return DateFormat.MMMd(languageCode).format(date);
}

class DesktopLibraryVideoDurationLabel extends StatelessWidget {
  const DesktopLibraryVideoDurationLabel({
    super.key,
    required this.durationSeconds,
  });

  final double durationSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(166),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        VideoUtils.formatDuration(durationSeconds),
        style: TpTextStyles.of(context).xs.copyWith(color: Colors.white),
      ),
    );
  }
}

/// 缩略图角标：进行中显示检测进度，完成后显示视频类型/用途（非笼统「已完成」）。
class DesktopLibraryRecordBadge extends StatelessWidget {
  const DesktopLibraryRecordBadge({super.key, required this.record});

  final LocalVideoRecord record;

  @override
  Widget build(BuildContext context) {
    final style = desktopLibraryRecordBadgeStyle(
      record,
      context.hujiL10n,
      Theme.of(context).colorScheme,
    );
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: style.color.withAlpha(217),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        style.label,
        style: TpTextStyles.of(context).xs.copyWith(color: cs.onPrimary),
      ),
    );
  }
}

@visibleForTesting
({String label, Color color}) desktopLibraryRecordBadgeStyle(
  LocalVideoRecord record,
  HujiLocalizations l10n,
  ColorScheme cs,
) {
  switch (record.processStatus) {
    case LocalVideoProcessStatusEnum.pending:
      return (
        label: l10n.desktopLibraryBadgePending,
        color: const Color(0xFFEAB308),
      );
    case LocalVideoProcessStatusEnum.processing:
      return (label: l10n.desktopLibraryBadgeProcessing, color: cs.primary);
    case LocalVideoProcessStatusEnum.cancelled:
      return (label: l10n.taskStatusCancelled, color: cs.outline);
    case LocalVideoProcessStatusEnum.failed:
      return (label: l10n.taskStatusFailed, color: cs.error);
    case LocalVideoProcessStatusEnum.completed:
      break;
  }

  if (record is SavedVideoRecord) {
    final type = record.videoProcessType;
    if (type != null) {
      return (
        label: l10n.desktopLibraryVideoProcessTypeBadgeLabel(type),
        color: type.color,
      );
    }
    return (label: l10n.desktopLibraryBadgeSaved, color: Colors.blue);
  }

  if (record is EdittingVideoRecord) {
    return (
      label: l10n.desktopLibraryBadgeClipProject,
      color: const Color(0xFF7C3AED),
    );
  }

  if (record is ProcessVideoRecord) {
    return (
      label: l10n.desktopLibraryBadgeDetectionComplete,
      color: const Color(0xFF22C55E),
    );
  }

  return (
    label: l10n.desktopLibraryBadgeRaw,
    color: VideoProcessType.raw.color,
  );
}
