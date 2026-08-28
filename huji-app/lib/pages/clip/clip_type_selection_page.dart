import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/clip/types.dart';
import 'package:huji_app/router/modules/clip.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

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
        leading: TpIconButton(
          icon: Icons.arrow_back,
          color: Colors.black87,
          onTap: () {
            Throttles.throttle(
              'clip_type_back',
              const Duration(milliseconds: 500),
              () => context.pop(),
            );
          },
        ),
        title: Text(context.hujiL10n.selectClipMode, style: TextStyle(
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
            Text(context.hujiL10n.selectClipMode, style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(context.hujiL10n.selectClipModeHint, style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 32),

            // 边拍边剪辑选项
            _buildClipTypeCard(
              clipMode: ClipMode.recordAndClip,
              title: context.hujiL10n.recordAndClip,
              subtitle: context.hujiL10n.recordAndClipSubtitle,
              icon: Icons.videocam,
              color: Colors.purple,
              description: context.hujiL10n.recordAndClipDescription,
              features: [
                context.hujiL10n.featureLiveRecording,
                context.hujiL10n.featureInstantSegmentMarking,
                context.hujiL10n.featureRecordAndClipEfficiency,
                context.hujiL10n.featureOnSiteRecording,
              ],
            ),

            SizedBox(height: 16),

            // 已有视频剪辑选项
            _buildClipTypeCard(
              clipMode: ClipMode.existingVideo,
              title: context.hujiL10n.existingVideoClip,
              subtitle: context.hujiL10n.existingVideoClipSubtitle,
              icon: Icons.video_library,
              color: Colors.blue,
              description: context.hujiL10n.existingVideoClipDescription,
              features: [
                context.hujiL10n.featureMultipleFormats,
                context.hujiL10n.featureSmartSegmentDetection,
                context.hujiL10n.featureBatchProcessing,
                context.hujiL10n.featureCloudAndLocalClip,
              ],
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
    return TpHover(
      onTap: () {
        Throttles.throttle(
          'clip_type_select_$clipMode',
          const Duration(milliseconds: 500),
          () => _selectClipType(clipMode),
        );
      },
      borderRadius: BorderRadius.circular(16),
      pressScale: 0.97,
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
                SizedBox(width: 16),
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
                      SizedBox(height: 4),
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
            SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            SizedBox(height: 12),
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

      try {
        final config = getDefaultConfig(_sportType!);
        final rawRecord = await createRawVideoRecord(
          selectedVideoPath ?? '', // 边拍边剪辑模式下可以为空
          _sportType!,
          config,
          clipMode: clipMode,
          l10n: context.hujiL10n,
        );
        if (clipMode == ClipMode.existingVideo) {
          await LocalVideoStorage().add(rawRecord);
        }
        if (mounted) {
          context.push(ClipRoute.videoEditConfig, extra: rawRecord);
        }
      } catch (e) {
        if (mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.prepareVideoFailed(e.toString()),
            variant: TpToastVariant.error,
          );
        }
      }
    } else {
      // 如果没有运动类型，跳转到运动类型选择页面，传递clipMode参数
      context.push(ClipRoute.sportSelection, extra: {'clipMode': clipMode});
    }
  }
}
