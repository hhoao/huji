import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/ffmpeg.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/storage_service.dart' show storage;
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/utils/video_compress_utils.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/widgets/desktop/desktop_drop_zone.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:path/path.dart' as p;
import 'package:shared_ui/shared_ui.dart';
import 'package:uuid/uuid.dart';

/// Desktop video compression: left config panel + right upload area.
/// Layout mirrors [DesktopClipConfigPage].
class DesktopVideoCompressPage extends StatefulWidget {
  final File? initialFile;

  /// Owning workspace-tab id — anchors the drop zone's command ownership.
  final String tabId;

  /// Closes the hosting workspace tab once the task is submitted.
  final void Function()? onSubmitted;

  /// Closes the hosting workspace tab when the user cancels.
  final void Function()? onCancel;

  const DesktopVideoCompressPage({
    super.key,
    required this.tabId,
    this.initialFile,
    this.onSubmitted,
    this.onCancel,
  });

  @override
  State<DesktopVideoCompressPage> createState() =>
      _DesktopVideoCompressPageState();
}

class _DesktopVideoCompressPageState extends State<DesktopVideoCompressPage> {
  File? _selectedFile;
  VideoCompressConfig _compressConfig = const VideoCompressConfig();
  String? _customFileName;
  String? _thumbnailPath;
  VideoInfo? _videoInfo;

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      _selectedFile = widget.initialFile;
      _customFileName = p.basename(_selectedFile!.path);
      _loadVideoInfo();
      _generateThumbnail(_selectedFile!);
    }
  }

  Future<void> _loadVideoInfo() async {
    final file = _selectedFile;
    if (file == null) return;
    final info = await VideoCompressUtils.getVideoInfo(file.path);
    if (mounted) {
      setState(() => _videoInfo = info);
    }
  }

  Future<void> _generateThumbnail(File videoFile) async {
    try {
      final dir = storage.getApplicationDocumentsDirectory();
      final thumbPath = await VideoUtils.generateVideoThumbnail(
        videoFile.path,
        dirPath: dir.path,
      );
      if (mounted) {
        setState(() => _thumbnailPath = thumbPath);
      }
    } catch (e, stackTrace) {
      AppLogger().e('Failed to generate thumbnail: $e', stackTrace);
    }
  }

  void _onFileSelected(File file) {
    setState(() {
      _selectedFile = file;
      _customFileName = p.basename(file.path);
      _thumbnailPath = null;
      _videoInfo = null;
    });
    _loadVideoInfo();
    _generateThumbnail(file);
  }

  void _onClearFile() {
    setState(() {
      _selectedFile = null;
      _customFileName = null;
      _thumbnailPath = null;
      _videoInfo = null;
    });
  }

  void _updateConfig(VideoCompressConfig config) {
    setState(() => _compressConfig = config);
  }

  Future<void> _startCompress() async {
    final file = _selectedFile;
    if (file == null) {
      TpToast.show(
        context,
        message: context.hujiL10n.selectVideoFileFirst,
        variant: TpToastVariant.warning,
      );
      return;
    }

    final task = VideoCompressTask(
      id: const Uuid().v4(),
      name: _customFileName ?? p.basename(file.path),
      videoPath: file.path,
      outputPath: '',
      compressConfig: _compressConfig,
      image: _thumbnailPath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await TaskStorage().addAndAsyncProcessTask(task);

    if (!mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.taskSubmittedWaiting,
      variant: TpToastVariant.success,
    );
    widget.onSubmitted?.call();
    if (mounted) context.go('/tasks');
  }

  String _qualityLabel(VideoCompressQuality quality) {
    return switch (quality) {
      VideoCompressQuality.ultraLow => '超低',
      VideoCompressQuality.low => '低',
      VideoCompressQuality.medium => '中等',
      VideoCompressQuality.high => '高',
      VideoCompressQuality.ultraHigh => '超高',
      VideoCompressQuality.custom => '自定义',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    return DesktopPageShell(
      currentRoute: '/tools/video-compress',
      title: l10n.taskTypeVideoCompress,
      backgroundColor: Colors.transparent,
      breadcrumbs: [l10n.desktopNavLibrary, l10n.taskTypeVideoCompress],
      actions: [
        TpButton(
          variant: TpButtonVariant.outline,
          onPressed: widget.onCancel ?? () => context.go('/'),
          child: Text(l10n.taskStatusCancelledShort),
        ),
        SizedBox(width: 8),
        TpButton(
          variant: TpButtonVariant.primary,
          onPressed: () {
            Throttles.throttle(
              'desktop_start_compress',
              const Duration(seconds: 2),
              _startCompress,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.compress, size: 16),
              const SizedBox(width: 6),
              Text('开始压缩'),
            ],
          ),
        ),
      ],
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _buildConfigHeader(),
                SizedBox(height: 18),
                _buildQualitySection(),
                SizedBox(height: 22),
                _buildPresetSection(),
                if (_compressConfig.quality == VideoCompressQuality.custom) ...[
                  SizedBox(height: 22),
                  _buildCustomSection(),
                ],
                SizedBox(height: 22),
                _buildAdvancedSection(),
                if (_selectedFile != null) ...[
                  SizedBox(height: 22),
                  _buildFileInfoSection(),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeVideoCompress,
                    style: TpTextStyles.of(context).mdMedium.copyWith(
                      color: context.desktopOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    l10n.homeVideoCompressDesc,
                    style: TpTextStyles.of(context).mutedMd,
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: DesktopDropZone(
                      tabId: widget.tabId,
                      file: _selectedFile,
                      onFileSelected: _onFileSelected,
                      onClearFile: _onClearFile,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigHeader() {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return Row(
      children: [
        Icon(Icons.tune, size: 16, color: cs.onSurface),
        SizedBox(width: 8),
        Text(
          context.hujiL10n.taskTypeVideoCompress,
          style: styles.mdSemibold.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }

  Widget _buildQualitySection() {
    return _ConfigSection(
      label: '压缩质量',
      child: TpCompactSelect<VideoCompressQuality>(
        value: _compressConfig.quality,
        entries: VideoCompressQuality.values
            .map((q) => (q, _qualityLabel(q)))
            .toList(),
        onChanged: (quality) {
          if (quality == null) return;
          _updateConfig(
            VideoCompressConfig(
              quality: quality,
              preset: _compressConfig.preset,
              customBitrate: _compressConfig.customBitrate,
              customWidth: _compressConfig.customWidth,
              customHeight: _compressConfig.customHeight,
              includeAudio: _compressConfig.includeAudio,
              keepAspectRatio: _compressConfig.keepAspectRatio,
              optimizeForWeb: _compressConfig.optimizeForWeb,
              maxFileSize: _compressConfig.maxFileSize,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetSection() {
    return _ConfigSection(
      label: '压缩速度',
      child: TpCompactSelect<VideoCompressPreset>(
        value: _compressConfig.preset,
        entries: VideoCompressPreset.values
            .map((p) => (p, p.name))
            .toList(),
        onChanged: (preset) {
          if (preset == null) return;
          _updateConfig(
            VideoCompressConfig(
              quality: _compressConfig.quality,
              preset: preset,
              customBitrate: _compressConfig.customBitrate,
              customWidth: _compressConfig.customWidth,
              customHeight: _compressConfig.customHeight,
              includeAudio: _compressConfig.includeAudio,
              keepAspectRatio: _compressConfig.keepAspectRatio,
              optimizeForWeb: _compressConfig.optimizeForWeb,
              maxFileSize: _compressConfig.maxFileSize,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomSection() {
    return _ConfigSection(
      label: '自定义设置',
      child: Column(
        children: [
          TpInput(
            initialValue: _compressConfig.customBitrate?.toString() ?? '1000',
            decoration: const InputDecoration(
              labelText: '比特率',
              suffixText: 'kbps',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateConfig(
                VideoCompressConfig(
                  quality: _compressConfig.quality,
                  preset: _compressConfig.preset,
                  customBitrate: int.tryParse(value),
                  customWidth: _compressConfig.customWidth,
                  customHeight: _compressConfig.customHeight,
                  includeAudio: _compressConfig.includeAudio,
                  keepAspectRatio: _compressConfig.keepAspectRatio,
                  optimizeForWeb: _compressConfig.optimizeForWeb,
                  maxFileSize: _compressConfig.maxFileSize,
                ),
              );
            },
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TpInput(
                  initialValue: _compressConfig.customWidth?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: '宽度',
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateConfig(
                      VideoCompressConfig(
                        quality: _compressConfig.quality,
                        preset: _compressConfig.preset,
                        customBitrate: _compressConfig.customBitrate,
                        customWidth: int.tryParse(value),
                        customHeight: _compressConfig.customHeight,
                        includeAudio: _compressConfig.includeAudio,
                        keepAspectRatio: _compressConfig.keepAspectRatio,
                        optimizeForWeb: _compressConfig.optimizeForWeb,
                        maxFileSize: _compressConfig.maxFileSize,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TpInput(
                  initialValue: _compressConfig.customHeight?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: '高度',
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateConfig(
                      VideoCompressConfig(
                        quality: _compressConfig.quality,
                        preset: _compressConfig.preset,
                        customBitrate: _compressConfig.customBitrate,
                        customWidth: _compressConfig.customWidth,
                        customHeight: int.tryParse(value),
                        includeAudio: _compressConfig.includeAudio,
                        keepAspectRatio: _compressConfig.keepAspectRatio,
                        optimizeForWeb: _compressConfig.optimizeForWeb,
                        maxFileSize: _compressConfig.maxFileSize,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return _ConfigSection(
      label: '高级选项',
      child: Column(
        children: [
          _CheckOption(
            label: '包含音频',
            help: '压缩后保留音轨',
            value: _compressConfig.includeAudio,
            onChanged: (value) {
              _updateConfig(
                VideoCompressConfig(
                  quality: _compressConfig.quality,
                  preset: _compressConfig.preset,
                  customBitrate: _compressConfig.customBitrate,
                  customWidth: _compressConfig.customWidth,
                  customHeight: _compressConfig.customHeight,
                  includeAudio: value ?? true,
                  keepAspectRatio: _compressConfig.keepAspectRatio,
                  optimizeForWeb: _compressConfig.optimizeForWeb,
                  maxFileSize: _compressConfig.maxFileSize,
                ),
              );
            },
          ),
          _CheckOption(
            label: '保持宽高比',
            help: '缩放时保持原始比例',
            value: _compressConfig.keepAspectRatio,
            onChanged: (value) {
              _updateConfig(
                VideoCompressConfig(
                  quality: _compressConfig.quality,
                  preset: _compressConfig.preset,
                  customBitrate: _compressConfig.customBitrate,
                  customWidth: _compressConfig.customWidth,
                  customHeight: _compressConfig.customHeight,
                  includeAudio: _compressConfig.includeAudio,
                  keepAspectRatio: value ?? true,
                  optimizeForWeb: _compressConfig.optimizeForWeb,
                  maxFileSize: _compressConfig.maxFileSize,
                ),
              );
            },
          ),
          _CheckOption(
            label: '优化网络播放',
            help: '启用 faststart 等流媒体优化',
            value: _compressConfig.optimizeForWeb,
            onChanged: (value) {
              _updateConfig(
                VideoCompressConfig(
                  quality: _compressConfig.quality,
                  preset: _compressConfig.preset,
                  customBitrate: _compressConfig.customBitrate,
                  customWidth: _compressConfig.customWidth,
                  customHeight: _compressConfig.customHeight,
                  includeAudio: _compressConfig.includeAudio,
                  keepAspectRatio: _compressConfig.keepAspectRatio,
                  optimizeForWeb: value ?? true,
                  maxFileSize: _compressConfig.maxFileSize,
                ),
              );
            },
          ),
          SizedBox(height: 8),
          TpInput(
            initialValue: _compressConfig.maxFileSize?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: '最大文件大小',
              suffixText: 'MB',
              helperText: '留空则不限制',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateConfig(
                VideoCompressConfig(
                  quality: _compressConfig.quality,
                  preset: _compressConfig.preset,
                  customBitrate: _compressConfig.customBitrate,
                  customWidth: _compressConfig.customWidth,
                  customHeight: _compressConfig.customHeight,
                  includeAudio: _compressConfig.includeAudio,
                  keepAspectRatio: _compressConfig.keepAspectRatio,
                  optimizeForWeb: _compressConfig.optimizeForWeb,
                  maxFileSize: int.tryParse(value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoSection() {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    final info = _videoInfo;
    return _ConfigSection(
      label: '视频信息',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.desktopBorderLight,
          borderRadius: BorderRadius.circular(desktopRadiusMd),
          border: Border.all(color: cs.outline.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _customFileName ?? p.basename(_selectedFile!.path),
              style: styles.smSemibold.copyWith(color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (info != null) ...[
              SizedBox(height: 8),
              Text(
                '${info.width}x${info.height} · ${info.duration ~/ 60}:${(info.duration % 60).toString().padLeft(2, '0')}',
                style: styles.sm.copyWith(color: cs.onSurfaceVariant),
              ),
              SizedBox(height: 4),
              Text(
                '${info.bitrate} kbps · ${info.format}',
                style: styles.sm.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _ConfigSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: styles.sm.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CheckOption extends StatelessWidget {
  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckOption({
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TpHover(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(desktopRadiusMd),
        pressScale: 0.97,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value
                ? cs.primary.withAlpha(20)
                : context.desktopBorderLight,
            border: Border.all(
              color: value ? cs.primary : context.desktopBorderLight,
              width: value ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  fillColor: WidgetStateProperty.resolveWith((s) {
                    if (s.contains(WidgetState.selected)) return cs.primary;
                    return Colors.transparent;
                  }),
                  side: BorderSide(
                    color: value ? cs.primary : cs.outline,
                    width: 1.5,
                  ),
                  checkColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: styles.md.copyWith(color: cs.onSurface),
                    ),
                    SizedBox(height: 2),
                    Text(help, style: styles.sm.copyWith(color: cs.outline)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
