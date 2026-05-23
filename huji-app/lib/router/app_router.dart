import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/routes.dart';
import 'package:huji_app/router/modules/splash.dart';

final appRouter = GoRouter(
  initialLocation: SplashRoute.splash,
  routes: AppPages.getRoutes(),
);
