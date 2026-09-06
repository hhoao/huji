import 'package:go_router/go_router.dart';
import 'package:huji_app/main.dart';
import 'package:huji_app/router/types.dart';
import 'package:huji_app/store/task/clip_task_prompt_store.dart';

class MainRoute implements RouteModule {
  static const String main = '/main';
  static const String mainHome = '/main/home';
  static const String mainVideo = '/main/video';
  static const String mainTask = '/main/task';
  static const String mainProfile = '/main/profile';

  @override
  List<GoRoute> getRoutes() {
    return [
      // 主页面（包含底部导航）
      GoRoute(
        path: main,
        name: 'main',
        builder: (context, state) => const MainNavigation(),
      ),

      // 主页面任务标签页
      GoRoute(
        path: mainTask,
        name: 'mainTask',
        builder: (context, state) {
          final clipTaskId = state.uri.queryParameters['clipTaskId'];
          // 弹窗提示在 ClipTaskPromptStore 里按 taskId 一次性消费;
          // builder 重跑(主题切换等)是幂等的。
          ClipTaskPromptStore.instance.register(clipTaskId);
          final edittingRecordId =
              state.uri.queryParameters['edittingRecordId'];
          final arguments = <String, dynamic>{};
          if (clipTaskId != null) {
            arguments['clipTaskId'] = clipTaskId;
          }
          if (edittingRecordId != null) {
            arguments['edittingRecordId'] = edittingRecordId;
          }
          return MainNavigation(
            initialIndex: PageIndex.task.value,
            arguments: arguments.isNotEmpty ? arguments : null,
          );
        },
      ),

      // 主页面首页标签页
      GoRoute(
        path: mainHome,
        name: 'mainHome',
        builder: (context, state) =>
            MainNavigation(initialIndex: PageIndex.home.value),
      ),
    ];
  }
}
