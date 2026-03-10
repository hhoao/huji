import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/pages/clip/types.dart';
import 'package:restcut/router/modules/clip.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';

class ClipTypeSelectionPage extends StatefulWidget {
  final SportType? sportType;

  const ClipTypeSelectionPage({super.key, this.sportType});

  @override
  State<ClipTypeSelectionPage> createState() => _ClipTypeSelectionPageState();
}

class _ClipTypeSelectionPageState extends State<ClipTypeSelectionPage> {
  SportType? _sportType;

  @override
  void initState() {
    super.initState();
    _sportType = widget.sportType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Throttles.throttle(
              'clip_type_back',
              const Duration(milliseconds: 500),
              () => context.pop(),
            );
          },
        ),
        title: const Text(
          '选择剪辑方式',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题和描述
            const Text(
              '选择剪辑方式',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请选择您想要的剪辑方式',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 边拍边剪辑选项
            _buildClipTypeCard(
              clipMode: ClipMode.recordAndClip,
              title: '边拍边剪辑',
              subtitle: '实时录制并剪辑视频',
              icon: Icons.videocam,
              color: Colors.purple,
              description: '使用摄像头实时录制视频，同时进行片段标记和剪辑',
              features: ['实时录制视频', '即时片段标记', '边拍边剪，效率更高', '适合现场比赛录制'],
            ),

            const SizedBox(height: 16),

            // 已有视频剪辑选项
            _buildClipTypeCard(
              clipMode: ClipMode.existingVideo,
              title: '已有视频剪辑',
              subtitle: '剪辑本地视频文件',
              icon: Icons.video_library,
              color: Colors.blue,
              description: '选择本地视频文件进行自动剪辑和片段提取',
              features: ['支持多种视频格式', '智能片段识别', '批量处理能力', '云端和本地剪辑'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipTypeCard({
    required ClipMode clipMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String description,
    required List<String> features,
  }) {
    return GestureDetector(
      onTap: () {
        Throttles.throttle(
          'clip_type_select_$clipMode',
          const Duration(milliseconds: 500),
          () => _selectClipType(clipMode),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            // 功能特点列表
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: features
                  .map(
                    (feature) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectClipType(ClipMode clipMode) async {
    // 如果已经有运动类型，直接跳转到配置页面
    if (_sportType != null) {
      // 如果是已有视频剪辑模式，需要选择视频文件
      String? selectedVideoPath;
      if (clipMode == ClipMode.existingVideo) {
        final result = await FileSelection.selectVideos(
          context: context,
          allowMultiple: false,
        );
        if (result == null || result.isEmpty) {
          return;
        }
        selectedVideoPath = result.first.path;
      }

      final config = getDefaultConfig(_sportType!);
      final rawRecord = await createRawVideoRecord(
        selectedVideoPath ?? '', // 边拍边剪辑模式下可以为空
        _sportType!,
        config,
        clipMode: clipMode,
      );
      if (clipMode == ClipMode.existingVideo) {
        await LocalVideoStorage().add(rawRecord);
      }
      if (mounted) {
        context.push(ClipRoute.videoEditConfig, extra: rawRecord);
      }
    } else {
      // 如果没有运动类型，跳转到运动类型选择页面，传递clipMode参数
      context.push(ClipRoute.sportSelection, extra: {'clipMode': clipMode});
    }
  }
}
