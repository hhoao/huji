import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/desktop/desktop_video_card.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/shell/workspace/workspace_tab_host.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/desktop_library_navigation.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/desktop/desktop_library_toolbar.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:shared_ui/shared_ui.dart';

/// Video library — Teampilot [HomeAllWorkspacesPane] layout in the main right pane.
class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});
  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  var _gridView = true;
  var _selectionMode = false;
  final _selectedIds = <String>{};

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
          _pruneSelection();
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

  void _pruneSelection() {
    final visibleIds = _records.map((r) => r.id).toSet();
    _selectedIds.removeWhere((id) => !visibleIds.contains(id));
    if (_selectionMode && _records.isEmpty) {
      _selectionMode = false;
      _selectedIds.clear();
    }
  }

  void _enterSelectionMode() {
    setState(() => _selectionMode = true);
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleRecordSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAllRecords() {
    setState(() => _selectedIds.addAll(_records.map((r) => r.id)));
  }

  void _deselectAllRecords() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _batchDeleteSelected() async {
    final selected = _records
        .where((record) => _selectedIds.contains(record.id))
        .toList(growable: false);
    if (selected.isEmpty) return;

    final deleted = await _confirmAndDeleteLocalVideos(context, selected);
    if (!mounted || !deleted) return;
    setState(() {
      _selectedIds.clear();
      if (_records.isEmpty) {
        _selectionMode = false;
      }
    });
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
          onNewClip: () => openClipNewTab(context),
          itemCount: _records.isEmpty ? null : _records.length,
          selectionMode: _selectionMode,
          selectedCount: _selectedIds.length,
          onEnterSelectionMode: _enterSelectionMode,
          onExitSelectionMode: _exitSelectionMode,
          onSelectAll: _selectAllRecords,
          onDeselectAll: _deselectAllRecords,
          onBatchDelete: _batchDeleteSelected,
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
      itemBuilder: (context, i) {
        final record = _records[i];
        final selected = _selectedIds.contains(record.id);
        return DesktopVideoCard(
          record: record,
          selectionMode: _selectionMode,
          selected: selected,
          onToggleSelect: () => _toggleRecordSelection(record.id),
          onSecondaryTapDown: (details) =>
              _showVideoContextMenu(context, record, details),
          actionMenu: _desktopLibraryVideoActionMenu(context, record),
        );
      },
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      itemCount: _records.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (context, i) {
        final record = _records[i];
        return _VideoListTile(
          record: record,
          selectionMode: _selectionMode,
          selected: _selectedIds.contains(record.id),
          onToggleSelect: () => _toggleRecordSelection(record.id),
        );
      },
    );
  }
}

List<TpActionMenuSpec> _desktopLibraryVideoMenuSpecs(
  BuildContext context,
  LocalVideoRecord record,
) {
  final l10n = context.hujiL10n;
  final hasVideoFile = record.filePath != null;
  final canOpenFolder =
      desktopLibraryRecordCanOpenContainingFolder(record);
  return [
    if (canOpenFolder)
      TpActionMenuSpec.item(
        value: 'openFolder',
        icon: Icons.folder_open_outlined,
        label: l10n.openFolder,
      ),
    TpActionMenuSpec.item(
      value: 'compress',
      icon: Icons.video_file_outlined,
      label: l10n.taskTypeVideoCompress,
      enabled: hasVideoFile,
    ),
    TpActionMenuSpec.item(
      value: 'delete',
      icon: Icons.delete_outline,
      label: l10n.actionDelete,
      destructive: true,
    ),
  ];
}

Widget _desktopLibraryVideoActionMenu(
  BuildContext context,
  LocalVideoRecord record,
) {
  return TpActionMenuButton(
    icon: Icon(Icons.more_horiz, size: context.tpIconSizes.md),
    specs: _desktopLibraryVideoMenuSpecs(context, record),
    onSelected: (action) =>
        _handleDesktopLibraryVideoAction(context, record, action),
  );
}

Future<void> _handleDesktopLibraryVideoAction(
  BuildContext context,
  LocalVideoRecord record,
  Object? action,
) async {
  switch (action) {
    case 'openFolder':
      await _openVideoContainingFolder(context, record);
    case 'compress':
      await _openVideoCompress(context, record);
    case 'delete':
      await _deleteLocalVideo(context, record);
  }
}

Future<void> _openVideoContainingFolder(
  BuildContext context,
  LocalVideoRecord record,
) async {
  final path = record.filePath;
  if (path == null) return;

  final dir = File(path).parent;
  try {
    if (!await dir.exists()) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.videoCompressInputNotFound(path),
          variant: TpToastVariant.warning,
        );
      }
      return;
    }
    await OpenFile.open(dir.path);
  } catch (e) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.openFolderFailed('$e'),
        variant: TpToastVariant.warning,
      );
    }
  }
}

Future<void> _showVideoContextMenu(
  BuildContext context,
  LocalVideoRecord record,
  TapDownDetails details,
) async {
  final action = await showTpActionMenuFromSpecsAtTap<String>(
    context: context,
    tapDetails: details,
    specs: _desktopLibraryVideoMenuSpecs(context, record),
  );

  if (!context.mounted || action == null) return;
  await _handleDesktopLibraryVideoAction(context, record, action);
}

Future<void> _openVideoCompress(
  BuildContext context,
  LocalVideoRecord record,
) async {
  final path = record.filePath;
  if (path == null) return;

  final file = File(path);
  if (!await file.exists()) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.videoCompressInputNotFound(path),
        variant: TpToastVariant.warning,
      );
    }
    return;
  }

  if (!context.mounted) return;
  context.go(DesktopRoutes.videoCompress, extra: file);
}

Future<void> _deleteLocalVideo(
  BuildContext context,
  LocalVideoRecord record,
) async {
  await _confirmAndDeleteLocalVideos(context, [record]);
}

class _LocalVideoDeleteChoice {
  const _LocalVideoDeleteChoice({required this.deleteLocalFiles});

  final bool deleteLocalFiles;
}

Future<bool> _confirmAndDeleteLocalVideos(
  BuildContext context,
  List<LocalVideoRecord> records,
) async {
  if (records.isEmpty) return false;

  final l10n = context.hujiL10n;
  final message = records.length == 1
      ? l10n.confirmDeleteLocalVideoMessage
      : l10n.confirmDeleteLocalVideosMessage(records.length);
  final canDeleteFiles = records.any((r) => r.filePath != null);

  final choice = await showTpDialog<_LocalVideoDeleteChoice>(
    context: context,
    builder: (ctx) {
      var deleteLocalFiles = true;
      final cs = Theme.of(ctx).colorScheme;
      final styles = TpTextStyles.of(ctx);

      return StatefulBuilder(
        builder: (ctx, setState) => TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: l10n.confirmDelete),
              SizedBox(height: ctx.tpSpacing.lg),
              Text(message),
              if (canDeleteFiles) ...[
                SizedBox(height: ctx.tpSpacing.md),
                TpHover(
                  onTap: () =>
                      setState(() => deleteLocalFiles = !deleteLocalFiles),
                  borderRadius: BorderRadius.circular(6),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: deleteLocalFiles,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => deleteLocalFiles = value);
                          },
                          fillColor: WidgetStateProperty.resolveWith((s) {
                            if (s.contains(WidgetState.selected)) {
                              return cs.primary;
                            }
                            return Colors.transparent;
                          }),
                          side: BorderSide(
                            color: deleteLocalFiles ? cs.primary : cs.outline,
                            width: 1.5,
                          ),
                          checkColor: cs.onPrimary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.deleteLocalVideoAlsoDeleteFiles,
                          style: styles.sm.copyWith(color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10n.taskStatusCancelledShort),
                  ),
                  TpButton(
                    variant: TpButtonVariant.destructive,
                    onPressed: () => Navigator.of(ctx).pop(
                      _LocalVideoDeleteChoice(
                        deleteLocalFiles: deleteLocalFiles,
                      ),
                    ),
                    child: Text(l10n.actionDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (choice == null || !context.mounted) return false;

  for (final record in records) {
    if (choice.deleteLocalFiles) {
      final path = record.filePath;
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          AppLogger().w('Failed to delete video file: $path, $e');
        }
      }
    }
    await LocalVideoStorage().removeById(record.id);
  }
  return true;
}

class _VideoListTile extends StatelessWidget {
  const _VideoListTile({
    required this.record,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
  });

  final LocalVideoRecord record;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelect;

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
    final backgroundColor = selectionMode && selected
        ? cs.primary.withAlpha(20)
        : cs.surfaceContainer;
    final borderColor = selectionMode && selected
        ? cs.primary.withAlpha(102)
        : null;

    return TpHover(
      onTap: selectionMode
          ? onToggleSelect
          : (_isNavigable
                ? () => openDesktopLibraryRecord(context, record)
                : null),
      onSecondaryTapDown: selectionMode
          ? null
          : (details) => _showVideoContextMenu(context, record, details),
      borderRadius: BorderRadius.circular(10),
      backgroundColor: backgroundColor,
      border: borderColor != null ? Border.all(color: borderColor) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
            children: [
              if (selectionMode) ...[
                DesktopLibrarySelectIndicator(selected: selected),
                SizedBox(width: 12),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 54,
                  child: DesktopVideoThumbnailFrame(record: record),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
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
                            style: styles.mdSemibold.copyWith(
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!selectionMode) ...[
                          SizedBox(width: 4),
                          _desktopLibraryVideoActionMenu(context, record),
                          SizedBox(width: 8),
                          DesktopLibraryRecordBadge(record: record),
                        ],
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
