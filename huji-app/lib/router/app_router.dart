import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/routes.dart';
import 'package:restcut/router/modules/splash.dart';

final appRouter = GoRouter(
  initialLocation: SplashRoute.splash,
  routes: AppPages.getRoutes(),
);
