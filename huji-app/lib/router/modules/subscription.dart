import 'package:go_router/go_router.dart';
import 'package:huji_app/pages/plan/subscription_page.dart';
import 'package:huji_app/router/types.dart';

class SubscriptionRoute implements RouteModule {
  static const String subscription = '/subscription';

  @override
  List<GoRoute> getRoutes() {
    return [
      // 订阅页
      GoRoute(
        path: subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
    ];
  }
}
