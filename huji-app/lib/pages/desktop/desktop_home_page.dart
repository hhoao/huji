import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/desktop/desktop_library_toolbar.dart';
import 'package:path/path.dart' as p;
import 'package:shared_ui/shell/workspace_surface_layers.dart';
import 'package:shared_ui/theme/app_icon_sizes.dart';
import 'package:shared_ui/theme/app_text_styles.dart';

/// Video library — Teampilot [HomeAllWorkspacesPane] layout in the main right pane.
class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});
  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  var _gridView = true;

  List<LocalVideoRecord> _records = [];
  bool _loading = true;
  String? _error;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    LocalVideoStorage().addListener(_onDataChanged);
    _loadRecords();
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    LocalVideoStorage().removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadRecords() async {
    try {
      setState(() => _loading = true);
      final records = await LocalVideoStorage().load();
      if (mounted) {
        setState(() {
          _records = records;
          _loading = false;
          _error = null;
        });
      }
    } catch (e, st) {
      AppLogger().e('Failed to load video records: $e', st, e);
      debugPrint('[desktop-home] Failed to load video records: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载失败：$e';
        });
      }
    }
  }

  void _onDataChanged() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 100), _loadRecords);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ColoredBox(
      color: cs.workspaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '视频库',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopLibraryToolbar(
          gridView: _gridView,
          onToggleView: (grid) => setState(() => _gridView = grid),
          onNewClip: () => context.go('/clip/new'),
          itemCount: _records.isEmpty ? null : _records.length,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _records.isEmpty
              ? _buildEmptyState(context)
              : _gridView
              ? _buildGrid(context)
              : _buildList(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: context.appIconSizes.md,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          Text('暂无视频', style: styles.body.copyWith(color: cs.onSurfaceVariant)),
          Text(
            '点击「新建剪辑」上传比赛视频',
            style: styles.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: context.appIconSizes.md,
            color: cs.outline,
          ),
          const SizedBox(height: 14),
          Text(
            _error!,
            style: styles.body.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadRecords,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 220,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _records.length,
      itemBuilder: (context, i) => _VideoCard(record: _records[i]),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      itemCount: _records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _VideoListTile(record: _records[i]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final LocalVideoRecord record;
  const _VideoCard({required this.record});

  bool get _isNavigable {
    if (record is ProcessVideoRecord) {
      return record.processStatus == LocalVideoProcessStatusEnum.completed;
    }
    return record is EdittingVideoRecord || record is SavedVideoRecord;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);
    return InkWell(
      onTap: _isNavigable
          ? () => context.go('/clip/${record.id}/preview')
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: workspaceCardDecoration(cs, radius: 10),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _VideoThumbnail(record: record),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _StatusBadge(status: record.processStatus),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.filePath != null
                          ? p.basename(record.filePath!)
                          : '未命名',
                      style: styles.bodyStrong.copyWith(color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.sportType.title,
                      style: styles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoListTile extends StatelessWidget {
  const _VideoListTile({required this.record});

  final LocalVideoRecord record;

  bool get _isNavigable {
    if (record is ProcessVideoRecord) {
      return record.processStatus == LocalVideoProcessStatusEnum.completed;
    }
    return record is EdittingVideoRecord || record is SavedVideoRecord;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = AppTextStyles.of(context);
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isNavigable
            ? () => context.go('/clip/${record.id}/preview')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 54,
                  child: _VideoThumbnail(record: record),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.filePath != null
                          ? p.basename(record.filePath!)
                          : '未命名',
                      style: styles.bodyStrong.copyWith(color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.sportType.title,
                      style: styles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: record.processStatus),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.record});

  final LocalVideoRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final thumbPath = record.thumbnailPath;
    if (thumbPath != null && File(thumbPath).existsSync()) {
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

class _StatusBadge extends StatelessWidget {
  final LocalVideoProcessStatusEnum status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      LocalVideoProcessStatusEnum.pending => ('待检测', const Color(0xFFEAB308)),
      LocalVideoProcessStatusEnum.processing => ('检测中', cs.primary),
      LocalVideoProcessStatusEnum.completed => ('已完成', const Color(0xFF22C55E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(217),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTextStyles.of(context).caption.copyWith(color: cs.onPrimary),
      ),
    );
  }
}
