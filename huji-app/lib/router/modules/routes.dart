import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/clip.dart';
import 'package:restcut/router/modules/login.dart';
import 'package:restcut/router/modules/main.dart';
import 'package:restcut/router/modules/message.dart';
import 'package:restcut/router/modules/profile.dart';
import 'package:restcut/router/modules/splash.dart';
import 'package:restcut/router/modules/subscription.dart';
import 'package:restcut/router/modules/tools.dart';
import 'package:restcut/router/modules/video.dart';

/// 聚合所有路由模块
/// 这个类用于聚合所有路由模块的 GoRoute
class AppPages {
  static List<GoRoute> getRoutes() {
    final List<GoRoute> routes = [];

    // 按顺序添加各个路由模块
    routes.addAll(SplashRoute().getRoutes());
    routes.addAll(LoginRoute().getRoutes());
    routes.addAll(MainRoute().getRoutes());
    routes.addAll(VideoRoute().getRoutes());
    routes.addAll(ClipRoute().getRoutes());
    routes.addAll(ProfileRoute().getRoutes());
    routes.addAll(MessageRoute().getRoutes());
    routes.addAll(ToolsRoute().getRoutes());
    routes.addAll(SubscriptionRoute().getRoutes());

    return routes;
  }
}
