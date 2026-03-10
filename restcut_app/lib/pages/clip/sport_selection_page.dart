import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/pages/clip/types.dart';
import 'package:restcut/router/modules/clip.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';

class SportSelectionPage extends StatefulWidget {
  final String? videoPath;
  final String? videoName;
  final ClipMode? clipMode;

  const SportSelectionPage({
    super.key,
    this.videoPath,
    this.videoName,
    this.clipMode,
  });

  @override
  State<SportSelectionPage> createState() => _SportSelectionPageState();
}

class _SportSelectionPageState extends State<SportSelectionPage> {
  ClipMode? clipMode;

  @override
  void initState() {
    super.initState();
    // 优先使用构造函数参数，如果没有则尝试从 Get.arguments 读取（向后兼容）
    clipMode = widget.clipMode;
    if (clipMode == null) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        clipMode = args['clipMode'] as ClipMode?;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectSport(SportType sportType) async {
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

    final config = getDefaultConfig(sportType);
    final rawRecord = await createRawVideoRecord(
      selectedVideoPath ?? '', // 边拍边剪辑模式下可以为空
      sportType,
      config,
      clipMode: clipMode ?? ClipMode.existingVideo, // 使用传递的clipMode或默认值
    );
    if (clipMode == ClipMode.existingVideo) {
      await LocalVideoStorage().add(rawRecord);
    }
    if (mounted) {
      context.push(ClipRoute.videoEditConfig, extra: rawRecord);
    }
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
              'sport_selection_back',
              const Duration(milliseconds: 500),
              () => context.pop(),
            );
          },
        ),
        title: const Text(
          '选择运动类型',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 剪辑模式提示
              if (clipMode != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: clipMode == ClipMode.recordAndClip
                        ? Colors.purple[50]
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: clipMode == ClipMode.recordAndClip
                          ? Colors.purple[200]!
                          : Colors.blue[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        clipMode == ClipMode.recordAndClip
                            ? Icons.videocam
                            : Icons.video_library,
                        color: clipMode == ClipMode.recordAndClip
                            ? Colors.purple
                            : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        clipMode == ClipMode.recordAndClip
                            ? '边拍边剪辑模式'
                            : '已有视频剪辑模式',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: clipMode == ClipMode.recordAndClip
                              ? Colors.purple[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 运动类型选择
              const Text(
                '选择运动类型',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请选择您要剪辑的视频运动类型',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // 乒乓球选项
              _buildSportCard(
                sportType: SportType.pingpong,
                title: '乒乓球',
                subtitle: '乒乓球比赛视频自动剪辑',
                icon: Icons.sports_tennis,
                color: Colors.orange,
                description: '支持单打、双打比赛，自动识别精彩球片段',
              ),

              const SizedBox(height: 16),

              // 羽毛球选项
              _buildSportCard(
                sportType: SportType.badminton,
                title: '羽毛球',
                subtitle: '羽毛球比赛视频自动剪辑',
                icon: Icons.sports_tennis,
                color: Colors.green,
                description: '支持单打、双打比赛，自动识别精彩球片段',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportCard({
    required SportType sportType,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return GestureDetector(
      onTap: () {
        Throttles.throttle(
          'sport_select_$sportType',
          const Duration(milliseconds: 500),
          () => _selectSport(sportType),
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
        child: Row(
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
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}
