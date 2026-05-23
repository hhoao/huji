import 'package:go_router/go_router.dart';
import 'package:huji_app/pages/message/message_page.dart';
import 'package:huji_app/router/types.dart';

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
