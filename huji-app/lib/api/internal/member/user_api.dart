import 'package:dio/dio.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/member/user_models.dart';

part 'user_api.g.dart';

// 用户相关API
@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String? baseUrl}) = _UserApi;
  // 获取用户信息
  @GET('/member/user/get')
  Future<UserInfo> getUserInfo();

  // 更新用户基本信息 - 对应后端 /member/user/update
  @PUT('/member/user/update')
  Future<void> updateUser(@Body() UpdateUserBasicInfoParams data);

  // 检查用户是否存在
  @GET('/member/user/exists')
  Future<bool> isUserExists(@Queries() IdentifierParams params);

  // 更新用户手机
  @PUT('/member/user/update-mobile')
  Future<void> updateUserMobile(@Body() UpdateUserInfoParams data);

  // 基于微信小程序授权码更新手机
  @PUT('/member/user/update-mobile-by-weixin')
  Future<void> updateUserMobileByWeixin(@Body() UpdateUserInfoParams data);

  // 更新密码
  @PUT('/member/user/update-password')
  Future<void> updateUserPassword(@Body() UpdateUserPasswordParams data);

  // 重置密码
  @PUT('/member/user/reset-password')
  Future<void> resetUserPassword(@Body() ResetUserPasswordParams data);

  // 获取用户文件上传预签名
  @GET('/member/user/presigned-url')
  Future<PresignedUrlResponse> getPresignedUrl(@Query('name') String name);
}
