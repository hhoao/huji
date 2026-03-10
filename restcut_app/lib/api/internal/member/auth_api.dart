import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/member/auth_models.dart';

part 'auth_api.g.dart';

// 认证相关API
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  // 密码登录
  @POST('/member/auth/login')
  Future<AppAuthLoginRespVO> login(@Body() LoginPasswordParams params);

  // 验证码登录
  @POST('/member/auth/auth-code-login')
  Future<AppAuthLoginRespVO> authCodeLogin(@Body() LoginAuthCodeParams params);

  // 登出
  @POST('/member/auth/logout')
  Future<void> logout(@Body() LogoutParams? params);

  // 刷新token
  @POST('/member/auth/refresh-token')
  Future<AppAuthLoginRespVO> refreshToken(
    @Query("refreshToken") String refreshToken,
  );

  // 发送验证码
  @POST('/member/auth/send-auth-code')
  Future<void> sendAuthCode(@Body() SendAuthCodeParams params);

  // 社交授权跳转
  @GET('/member/auth/social-auth-redirect')
  Future<String> socialAuthRedirect(@Queries() SocialAuthRedirectParams params);

  // 社交登录
  @POST('/member/auth/social-login')
  Future<AppAuthLoginRespVO> socialLogin(@Body() SocialLoginParams params);

  // 微信小程序登录
  @POST('/member/auth/weixin-mini-app-login')
  Future<AppAuthLoginRespVO> weixinMiniAppLogin(
    @Body() WeixinMiniAppLoginParams params,
  );

  // 创建微信JS SDK签名
  @POST('/member/auth/create-weixin-jsapi-signature')
  Future<SocialWxJsapiSignatureRespDTO> createWeixinJsapiSignature(
    @Body() CreateWeixinJsapiSignatureParams params,
  );
}
