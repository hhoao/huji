import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/common/page.dart';
import '../../models/member/notify_models.dart';

part 'notify_api.g.dart';

// 消息通知相关API
@RestApi()
abstract class NotifyApi {
  factory NotifyApi(Dio dio, {String? baseUrl}) = _NotifyApi;

  // 获得我的站内信分页
  @GET('/system/notify-message/my-page')
  Future<BasicFetchPageResult<NotifyMessageVO>> getMyNotifyMessagePage(
    @Queries() PageParam params,
  );

  // 批量标记已读
  @PUT('/system/notify-message/update-read')
  Future<void> updateNotifyMessageRead(@Query('ids') List<int> ids);

  // 标记所有站内信为已读
  @PUT('/system/notify-message/update-all-read')
  Future<void> updateAllNotifyMessageRead();

  // 获取当前用户的最新站内信列表
  @GET('/system/notify-message/get-unread-list')
  Future<List<NotifyMessageVO>> getUnreadNotifyMessageList();

  // 获得当前用户的未读站内信数量
  @GET('/system/notify-message/get-unread-count')
  Future<int> getUnreadNotifyMessageCount();
}
