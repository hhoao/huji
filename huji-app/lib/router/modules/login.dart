import 'package:go_router/go_router.dart';
import 'package:huji_app/pages/login/login_page.dart';
import 'package:huji_app/router/types.dart';

class LoginRoute implements RouteModule {
  static const String login = '/login';

  @override
  List<GoRoute> getRoutes() {
    return [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
    ];
  }
}
