import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/constants/file_extensions.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';

class DesktopDropZone extends StatefulWidget {
  final List<File> files;
  final ValueChanged<List<File>> onFilesAdded;
  final ValueChanged<int> onRemoveFile;

  const DesktopDropZone({
    super.key,
    required this.files,
    required this.onFilesAdded,
    required this.onRemoveFile,
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
    final borderColor = _isDragging ? DesktopTheme.primaryColor : DesktopTheme.borderMedium;
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
              ? DesktopTheme.primaryColor.withAlpha(15)
              : DesktopTheme.primaryColor.withAlpha(5),
        ),
        child: widget.files.isEmpty ? _buildEmptyState(context) : _buildFileList(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDragging ? Icons.file_open : Icons.upload_file,
            size: 48,
            color: _isDragging ? DesktopTheme.primaryColor : DesktopTheme.textMuted,
          ),
          const SizedBox(height: 14),
          const Text('拖拽视频到这里', style: TextStyle(fontSize: 15, color: DesktopTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('或者', style: TextStyle(fontSize: 12, color: DesktopTheme.textDim)),
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
              backgroundColor: DesktopTheme.primaryColor.withAlpha(38),
              foregroundColor: DesktopTheme.indigoText,
              side: BorderSide(color: DesktopTheme.primaryColor.withAlpha(77)),
            ),
            child: const Text('选择文件'),
          ),
          const SizedBox(height: 8),
          const Text(
            '支持常见视频格式',
            style: TextStyle(fontSize: 11, color: DesktopTheme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context) {
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
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
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
    final file = widget.files[i];
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toUpperCase();
    final parentDir = file.parent.path.split('/').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesktopTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesktopTheme.borderLight),
      ),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(
              color: DesktopTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.video_file, color: DesktopTheme.indigoText, size: 24),
          ),
          const SizedBox(width: 12),
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      ext,
                      style: const TextStyle(
                        fontSize: 10,
                        color: DesktopTheme.indigoText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      parentDir,
                      style: const TextStyle(fontSize: 10, color: DesktopTheme.textDim),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: DesktopTheme.textMuted),
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
