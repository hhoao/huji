import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/video.dart'
    show RawVideoRecord, ClipMode, EdittingVideoRecord;
import 'package:restcut/pages/clip/autoclip_page.dart';
import 'package:restcut/pages/clip/clip_type_selection_page.dart';
import 'package:restcut/pages/clip/round_clip_page.dart';
import 'package:restcut/pages/clip/sport_selection_page.dart';
import 'package:restcut/pages/clip/video_post_edit_page.dart';
import 'package:restcut/router/types.dart';

class ClipRoute implements RouteModule {
  static const String clipTypeSelection = '/clip/type-selection';
  static const String sportSelection = '/clip/sport-selection';
  static const String videoEditConfig = '/video/edit-config';
  static const String videoPostEdit = '/clip/post-edit';
  static const String roundClip = '/clip/round-clip';

  @override
  List<GoRoute> getRoutes() {
    return [
      // 视频编辑配置页
      GoRoute(
        path: videoEditConfig,
        name: 'videoEditConfig',
        builder: (context, state) {
          final rawVideoRecord = state.extra as RawVideoRecord?;
          if (rawVideoRecord == null) {
            return const Scaffold(
              body: Center(child: Text('Missing rawVideoRecord parameter')),
            );
          }
          return VideoEditConfigPage(rawVideoRecord: rawVideoRecord);
        },
      ),

      // 剪辑类型选择页
      GoRoute(
        path: clipTypeSelection,
        name: 'clipTypeSelection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final sportType = extra?['sportType'] as SportType?;
          return ClipTypeSelectionPage(sportType: sportType);
        },
      ),

      // 运动类型选择页
      GoRoute(
        path: sportSelection,
        name: 'sportSelection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SportSelectionPage(
            videoPath: extra?['videoPath'] as String?,
            videoName: extra?['videoName'] as String?,
            clipMode: extra?['clipMode'] as ClipMode?,
          );
        },
      ),

      // 视频后期编辑页
      GoRoute(
        path: videoPostEdit,
        name: 'videoPostEdit',
        builder: (context, state) {
          final videoUrl = state.uri.queryParameters['videoUrl'] ?? '';
          return VideoPostEditPage(videoUrl: videoUrl);
        },
      ),

      // 回合剪辑页
      GoRoute(
        path: roundClip,
        name: 'roundClip',
        builder: (context, state) {
          final videoRecord = state.extra as EdittingVideoRecord?;
          return RoundClipPage(videoRecord: videoRecord);
        },
      ),
    ];
  }
}
