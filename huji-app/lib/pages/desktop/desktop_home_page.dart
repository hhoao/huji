import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/desktop/desktop_library_toolbar.dart';
import 'package:path/path.dart' as p;
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

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
          _error = e.toString();
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
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.desktopLibraryTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
        ),
        SizedBox(height: 16),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        SizedBox(height: 16),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
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
        SizedBox(height: 16),
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
    final l10n = context.hujiL10n;
    return TpEmptyState(
      centered: true,
      icon: Icons.video_library_outlined,
      title: l10n.desktopLibraryEmptyTitle,
      hint: l10n.desktopLibraryEmptyHint,
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = context.hujiL10n;
    return TpEmptyState(
      centered: true,
      icon: Icons.error_outline,
      title: l10n.desktopLibraryLoadFailed(_error!),
      actionLabel: l10n.actionRetry,
      onAction: _loadRecords,
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
      separatorBuilder: (_, __) => SizedBox(height: 10),
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
    final styles = TpTextStyles.of(context);
    return TpHover(
      onTap: _isNavigable
          ? () => context.go(DesktopRoutes.clipPreviewPath(record.id))
          : null,
      borderRadius: BorderRadius.circular(10),
      pressScale: 0.97,
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
    final styles = TpTextStyles.of(context);
    return TpHover(
      onTap: _isNavigable
          ? () => context.go(DesktopRoutes.clipPreviewPath(record.id))
          : null,
      borderRadius: BorderRadius.circular(10),
      backgroundColor: cs.surfaceContainer,
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
              SizedBox(width: 14),
              Expanded(
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
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              _StatusBadge(status: record.processStatus),
            ],
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

class _StatusBadge extends StatelessWidget {
  final LocalVideoProcessStatusEnum status;
  const _StatusBadge({required this.status});

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
