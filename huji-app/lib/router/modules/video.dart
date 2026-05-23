import 'package:go_router/go_router.dart';
import 'package:restcut/pages/home/home_page.dart';
import 'package:restcut/pages/video/video_list_page.dart';
import 'package:restcut/pages/video/video_progress_page.dart';
import 'package:restcut/widgets/video_player/video_player_page.dart';
import 'package:restcut/router/types.dart';

class VideoRoute implements RouteModule {
  static const String home = '/home';
  static const String videoList = '/video/list';
  static const String videoPlayer = '/video/player';
  static const String videoProgress = '/video/progress';

  @override
  List<GoRoute> getRoutes() {
    return [
      // 首页
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // 视频列表页
      GoRoute(
        path: videoList,
        name: 'videoList',
        builder: (context, state) => const VideoListPage(),
      ),

      // 视频播放页
      GoRoute(
        path: videoPlayer,
        name: 'videoPlayer',
        builder: (context, state) {
          final videoUrl = state.uri.queryParameters['videoUrl'] ?? '';
          final fileName = state.uri.queryParameters['fileName'] ?? '';
          return VideoPlayerPage(videoUrl: videoUrl, fileName: fileName);
        },
      ),

      // 视频进度页
      GoRoute(
        path: videoProgress,
        name: 'videoProgress',
        builder: (context, state) => const VideoProgressPage(),
      ),
    ];
  }
}
