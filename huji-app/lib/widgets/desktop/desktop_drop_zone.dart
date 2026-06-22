import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:huji_app/constants/file_extensions.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/demo_video_picker.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:shared_ui/shared_ui.dart';

class DesktopDropZone extends StatefulWidget {
  final List<File> files;
  final ValueChanged<List<File>> onFilesAdded;
  final ValueChanged<int> onRemoveFile;
  final DemoVideoTap? onDemoVideoSelected;
  final bool demoLoading;
  final String? demoSportLabel;

  const DesktopDropZone({
    super.key,
    required this.files,
    required this.onFilesAdded,
    required this.onRemoveFile,
    this.onDemoVideoSelected,
    this.demoLoading = false,
    this.demoSportLabel,
  });

  @override
  State<DesktopDropZone> createState() => _DesktopDropZoneState();
}

class _DesktopDropZoneState extends State<DesktopDropZone> {
  bool _isDragging = false;

  bool _isVideoFile(String path) {
    final ext = '.${path.split('.').last.toLowerCase()}';
    return FileExtensions.videoExtensions.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final borderColor =
        _isDragging ? cs.primary : context.desktopBorderMedium;
    final borderWidth = _isDragging ? 2.5 : 2.0;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        final newFiles = detail.files
            .map((f) => File(f.path))
            .where((f) => _isVideoFile(f.path))
            .toList();
        if (newFiles.isNotEmpty) widget.onFilesAdded(newFiles);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(10),
          color: _isDragging
              ? cs.primary.withAlpha(15)
              : cs.primary.withAlpha(5),
        ),
        child: widget.files.isEmpty
            ? _buildEmptyState(context)
            : _buildFileList(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDragging ? Icons.file_open : Icons.upload_file,
            size: 48,
            color: _isDragging ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            '拖拽视频到这里',
            style: styles.sectionTitle.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text('或者', style: styles.mutedBodySmall.copyWith(color: cs.outline)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final result = await FileSelection.selectVideos(
                context: context,
                allowMultiple: true,
                initialTab: TabType.fileSystem,
              );
              if (result != null && context.mounted) {
                widget.onFilesAdded(result.whereType<File>().toList());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary.withAlpha(38),
              foregroundColor: cs.onPrimaryContainer,
              side: BorderSide(color: cs.primary.withAlpha(77)),
            ),
            child: const Text('选择文件'),
          ),
          const SizedBox(height: 8),
          Text(
            '支持常见视频格式',
            style: styles.caption.copyWith(color: cs.outline),
          ),
          if (widget.onDemoVideoSelected != null) ...[
            const SizedBox(height: 20),
            DemoVideoPicker(
              dense: true,
              loading: widget.demoLoading,
              filterSportLabel: widget.demoSportLabel,
              onDemoSelected: widget.onDemoVideoSelected!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context) {
    final styles = AppTextStyles.of(context);
    final cs = context.desktopColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已选择 ${widget.files.length} 个文件',
                style: styles.bodyStrong.copyWith(color: cs.onSurface),
              ),
              TextButton(
                onPressed: () async {
                  final result = await FileSelection.selectVideos(
                    context: context,
                    allowMultiple: true,
                    initialTab: TabType.fileSystem,
                  );
                  if (result != null && context.mounted) {
                    widget.onFilesAdded(result.whereType<File>().toList());
                  }
                },
                child: const Text('+ 添加更多'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.files.length,
              itemBuilder: (context, i) => _buildFileCard(context, i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, int i) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    final file = widget.files[i];
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toUpperCase();
    final parentDir = file.parent.path.split('/').last;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.desktopBorderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(Icons.video_file, color: cs.onPrimaryContainer, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: styles.body.copyWith(color: cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      ext,
                      style: styles.caption.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parentDir,
                        style: styles.caption.copyWith(color: cs.outline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
            onPressed: () => widget.onRemoveFile(i),
            splashRadius: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
