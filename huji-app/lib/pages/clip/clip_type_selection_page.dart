import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/clip/types.dart';
import 'package:huji_app/router/modules/clip.dart';
import 'package:huji_app/services/demo_video_service.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/widgets/demo_video_picker.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

class ClipTypeSelectionPage extends StatefulWidget {
  final SportType? sportType;

  const ClipTypeSelectionPage({super.key, this.sportType});

  @override
  State<ClipTypeSelectionPage> createState() => _ClipTypeSelectionPageState();
}

class _ClipTypeSelectionPageState extends State<ClipTypeSelectionPage> {
  SportType? _sportType;
  bool _demoLoading = false;

  @override
  void initState() {
    super.initState();
    _sportType = widget.sportType;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: TpIconButton(
          icon: Icons.arrow_back,
          color: cs.onSurface,
          onTap: () {
            Throttles.throttle(
              'clip_type_back',
              const Duration(milliseconds: 500),
              () => context.pop(),
            );
          },
        ),
        title: Text(
          context.hujiL10n.selectClipMode,
          style: styles.xl.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
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
              Text(
                context.hujiL10n.selectClipMode,
                style: styles.xl.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.hujiL10n.selectClipModeHint,
                style: styles.md.copyWith(color: cs.mutedForeground),
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

              // 快速体验（内置样例视频）
              SizedBox(height: 32),
              const Divider(),
              SizedBox(height: 24),
              Text(
                context.hujiL10n.quickTry,
                textScaler: kLegacySectionTitleTextScaler,
                style: styles.xl.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.hujiL10n.quickTryHint,
                style: styles.md.copyWith(color: cs.mutedForeground),
              ),
              SizedBox(height: 12),
              if (_demoLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              // 不用 crossAxisAlignment.stretch:外层 Column 在滚动视图中高度
              // 无界,stretch 会把无穷高度传给卡片导致布局失败
              Row(
                children: [
                  for (final (index, demo) in demoVideos.indexed) ...[
                    if (index > 0) const SizedBox(width: 12),
                    Expanded(child: _buildDemoCard(demo)),
                  ],
                ],
              ),
            ],
          ),
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
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

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
          color: cs.cardFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.softShadow,
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
                        textScaler: kLegacySectionTitleTextScaler,
                        style: styles.xl.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: styles.md.copyWith(color: cs.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: cs.mutedForeground,
                  size: 16,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: styles.sm.copyWith(color: cs.mutedForeground),
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

  /// 快速体验卡片：缩略图铺满 + 左下/右下角标，
  /// 样式对齐主页视频栏(HomeVideoListWidget)的视频卡片。
  Widget _buildDemoCard(DemoVideo demo) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return TpHover(
      onTap: _demoLoading ? null : () => _startDemoClip(demo),
      borderRadius: BorderRadius.circular(12),
      pressScale: 0.97,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: cs.subtleFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // 缩略图区域
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _DemoThumbnail(demo: demo),
              ),
              // 左下角标题
              Positioned(
                bottom: 4,
                left: 4,
                child: _demoBadge(
                  styles,
                  demoVideoTitle(context.hujiL10n, demo),
                ),
              ),
              // 右下角时长(取描述中"·"前的时长段)
              Positioned(
                bottom: 4,
                right: 4,
                child: _demoBadge(
                  styles,
                  demoVideoSubtitle(context.hujiL10n, demo)
                      .split('·')
                      .first
                      .trim(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoBadge(TpTextStyles styles, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        textScaler: kLegacyCaptionTextScaler,
        style: styles.xsMediumColored(Colors.white),
      ),
    );
  }

  Future<void> _startDemoClip(DemoVideo demo) async {
    final l10n = context.hujiL10n;
    setState(() => _demoLoading = true);
    try {
      final file = await DemoVideoService.materialize(demo);
      final sportType = demo.sportTypeKey == 'ping_pong'
          ? SportType.pingpong
          : SportType.badminton;
      final config = getDefaultConfig(sportType);
      final rawRecord = await createRawVideoRecord(
        file.path,
        sportType,
        config,
        clipMode: ClipMode.existingVideo,
        l10n: l10n,
      );
      await LocalVideoStorage().add(rawRecord);
      if (mounted) {
        context.push(ClipRoute.videoEditConfig, extra: rawRecord);
      }
    } catch (e) {
      if (mounted) {
        TpToast.show(
          context,
          message: l10n.loadDemoVideoFailed(e.toString()),
          variant: TpToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _demoLoading = false);
    }
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

/// 样例视频缩略图：落盘 demo 视频后用 FFmpeg 抽一帧并缓存复用。
class _DemoThumbnail extends StatefulWidget {
  const _DemoThumbnail({required this.demo});

  final DemoVideo demo;

  @override
  State<_DemoThumbnail> createState() => _DemoThumbnailState();
}

class _DemoThumbnailState extends State<_DemoThumbnail> {
  String? _thumbPath;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await DemoVideoService.materialize(widget.demo);
      final thumbPath = await VideoUtils.generateVideoThumbnail(
        file.path,
        fileName: 'demo_${widget.demo.id}_thumb.png',
        reuseExisting: true,
      );
      if (mounted) setState(() => _thumbPath = thumbPath);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final thumbPath = _thumbPath;
    if (thumbPath != null) {
      return Image.file(
        File(thumbPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(cs),
      );
    }
    return _placeholder(cs, loading: _error == null);
  }

  Widget _placeholder(ColorScheme cs, {bool loading = false}) {
    return Container(
      color: cs.onSurface.withValues(alpha: 0.06),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.videocam, color: cs.mutedForeground, size: 28),
      ),
    );
  }
}
