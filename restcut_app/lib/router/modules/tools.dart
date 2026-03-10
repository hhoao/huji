import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:restcut/pages/test/test_page.dart';
import 'package:restcut/pages/tools/image_compress_page.dart';
import 'package:restcut/pages/tools/video_compress_page.dart';
import 'package:restcut/router/types.dart';

class ToolsRoute implements RouteModule {
  static const String imageCompress = '/tools/image-compress';
  static const String videoCompress = '/tools/video-compress';
  static const String test = '/tools/test';

  @override
  List<GoRoute> getRoutes() {
    return [
      // 图片压缩页
      GoRoute(
        path: imageCompress,
        name: 'imageCompress',
        builder: (context, state) {
          final initialFiles = state.extra as List<File>?;
          return ImageCompressPage(initialFiles: initialFiles);
        },
      ),

      // 视频压缩页
      GoRoute(
        path: videoCompress,
        name: 'videoCompress',
        builder: (context, state) {
          final initialFile = state.extra as File?;
          return VideoCompressPage(initialFile: initialFile);
        },
      ),

      // 测试页
      GoRoute(
        path: test,
        name: 'test',
        builder: (context, state) => const TestPage(),
      ),
    ];
  }
}
