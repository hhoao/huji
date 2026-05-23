import 'package:flutter/material.dart';
import '../models/ffmpeg.dart';
import '../api/api_manager.dart';
import '../api/models/autoclip/permission_models.dart';

/// 视频导出质量选择对话框
class VideoExportQualityDialog extends StatefulWidget {
  final VideoCompressQuality? initialQuality;

  const VideoExportQualityDialog({super.key, this.initialQuality});

  /// 显示质量选择对话框
  static Future<VideoCompressQuality?> show(
    BuildContext context, {
    VideoCompressQuality? initialQuality,
  }) async {
    return showDialog<VideoCompressQuality>(
      context: context,
      builder: (context) =>
          VideoExportQualityDialog(initialQuality: initialQuality),
    );
  }

  @override
  State<VideoExportQualityDialog> createState() =>
      _VideoExportQualityDialogState();
}

class _VideoExportQualityDialogState extends State<VideoExportQualityDialog> {
  VideoCompressQuality selectedQuality = VideoCompressQuality.medium;
  bool _hasHighQualityPermission = true;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    selectedQuality = widget.initialQuality ?? VideoCompressQuality.medium;
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final highQualityPermission = await Api.permission.checkPermission(
        PermissionEnum.highQuality.code,
      );

      if (mounted) {
        setState(() {
          _hasHighQualityPermission = highQualityPermission;
          _isCheckingPermissions = false;

          // 如果当前选择的质量没有权限，自动降级到中等质量
          if (selectedQuality == VideoCompressQuality.ultraHigh &&
              !_hasHighQualityPermission) {
            selectedQuality = VideoCompressQuality.medium;
          }
        });
      }
    } catch (e) {
      // 如果权限检查失败，默认不允许使用高质量和超高质量
      if (mounted) {
        setState(() {
          _hasHighQualityPermission = false;
          _isCheckingPermissions = false;
          // 如果当前选择的质量没有权限，自动降级到中等质量
          if (selectedQuality == VideoCompressQuality.ultraHigh) {
            selectedQuality = VideoCompressQuality.medium;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择导出质量'),
      content: _isCheckingPermissions
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQualityOption(
                  context,
                  VideoCompressQuality.ultraLow,
                  '超低质量',
                  '文件最小，画质较低',
                  selectedQuality,
                  (quality) => setState(() => selectedQuality = quality),
                  enabled: true,
                ),
                const SizedBox(height: 8),
                _buildQualityOption(
                  context,
                  VideoCompressQuality.low,
                  '低质量',
                  '文件较小，画质一般',
                  selectedQuality,
                  (quality) => setState(() => selectedQuality = quality),
                  enabled: true,
                ),
                const SizedBox(height: 8),
                _buildQualityOption(
                  context,
                  VideoCompressQuality.medium,
                  '中等质量',
                  '文件适中，画质良好（推荐）',
                  selectedQuality,
                  (quality) => setState(() => selectedQuality = quality),
                  enabled: true,
                ),
                const SizedBox(height: 8),
                _buildQualityOption(
                  context,
                  VideoCompressQuality.high,
                  '高质量',
                  '文件较大，画质优秀',
                  selectedQuality,
                  (quality) => setState(() => selectedQuality = quality),
                  enabled: true,
                ),
                const SizedBox(height: 8),
                _buildQualityOption(
                  context,
                  VideoCompressQuality.ultraHigh,
                  '超高质量',
                  '文件最大，画质最佳',
                  selectedQuality,
                  (quality) => setState(() => selectedQuality = quality),
                  enabled: _hasHighQualityPermission,
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(selectedQuality),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildQualityOption(
    BuildContext context,
    VideoCompressQuality quality,
    String title,
    String description,
    VideoCompressQuality selectedQuality,
    ValueChanged<VideoCompressQuality> onTap, {
    required bool enabled,
  }) {
    final isSelected = quality == selectedQuality;

    return InkWell(
      onTap: enabled ? () => onTap(quality) : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Radio<VideoCompressQuality>(
                value: quality,
                groupValue: selectedQuality,
                onChanged: enabled ? (value) => onTap(value!) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                          ),
                        ),
                        if (!enabled) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? description : '$description（专业版）',
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? Colors.grey[600] : Colors.orange[700],
                      ),
                    ),
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
