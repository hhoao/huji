import 'package:go_router/go_router.dart';
import 'package:restcut/pages/message/message_page.dart';
import 'package:restcut/router/types.dart';

class MessageRoute implements RouteModule {
  static const String message = '/message';

  @override
  List<GoRoute> getRoutes() {
    return [
      // 消息页
      GoRoute(
        path: message,
        name: 'message',
        builder: (context, state) => const MessagePage(),
      ),
    ];
  }
}
