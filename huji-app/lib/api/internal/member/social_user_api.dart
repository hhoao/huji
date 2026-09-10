import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/member/social_user_models.dart';

part 'social_user_api.g.dart';

// 社交用户绑定 API（/member/social-user）
@RestApi()
abstract class SocialUserApi {
  factory SocialUserApi(Dio dio, {String? baseUrl}) = _SocialUserApi;

  // 绑定社交账号（需登录 token）
  @POST('/member/social-user/bind')
  Future<String> bind(@Body() SocialUserBindParams params);

  // 解绑（DELETE 带 body；服务端 AppSocialUserController 正是
  // @DeleteMapping + @RequestBody，dio 原生支持）
  @DELETE('/member/social-user/unbind')
  Future<bool> unbind(@Body() SocialUserUnbindParams params);

  // 查询绑定状态（未绑定返回 null）
  @GET('/member/social-user/get')
  Future<SocialUserInfo?> getSocialUser(@Query('type') int type);
}
