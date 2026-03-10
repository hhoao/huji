import 'package:go_router/go_router.dart';
import 'package:restcut/pages/splash/splash_page.dart';
import 'package:restcut/router/types.dart';

class SplashRoute implements RouteModule {
  static const String splash = '/splash';

  @override
  List<GoRoute> getRoutes() {
    return [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
    ];
  }
}
