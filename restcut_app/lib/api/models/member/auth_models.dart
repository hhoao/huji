// 认证相关枚举
import 'package:json_annotation/json_annotation.dart';
import 'package:restcut/api/models/member/user_models.dart';

part 'auth_models.g.dart';

@JsonEnum(valueField: 'value')
enum IdentifierType {
  mobile(0),
  mail(1);

  const IdentifierType(this.value);
  final int value;
}

@JsonEnum(valueField: 'value')
enum SmsSceneEnum {
  memberLogin(1),
  memberUpdateMobile(2),
  memberUpdatePassword(3),
  memberResetPassword(4);

  const SmsSceneEnum(this.value);
  final int value;
}

// 登录参数
@JsonSerializable()
class LoginPasswordParams {
  final String identifier;
  final IdentifierType identifierType;
  final String password;
  final int? socialType;
  final String? socialCode;

  LoginPasswordParams({
    required this.identifier,
    required this.identifierType,
    required this.password,
    this.socialType,
    this.socialCode,
  });

  factory LoginPasswordParams.fromJson(Map<String, dynamic> json) =>
      _$LoginPasswordParamsFromJson(json);
  Map<String, dynamic> toJson() => _$LoginPasswordParamsToJson(this);
}

@JsonSerializable()
class LoginAuthCodeParams {
  final String identifier;
  final IdentifierType identifierType;
  final String code;
  final int? socialType;
  final String? socialCode;
  final String? socialState;

  LoginAuthCodeParams({
    required this.identifier,
    required this.identifierType,
    required this.code,
    this.socialType,
    this.socialCode,
    this.socialState,
  });

  factory LoginAuthCodeParams.fromJson(Map<String, dynamic> json) =>
      _$LoginAuthCodeParamsFromJson(json);
  Map<String, dynamic> toJson() => _$LoginAuthCodeParamsToJson(this);
}

// Token 信息
@JsonSerializable()
class AppAuthLoginRespVO {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final int expiresTime;
  final String? openId;

  AppAuthLoginRespVO({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresTime,
    required this.userId,
    this.openId,
  });

  factory AppAuthLoginRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppAuthLoginRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppAuthLoginRespVOToJson(this);
}

// 登录结果类
@JsonSerializable()
class LoginResult {
  final bool success;
  final String message;
  final AppAuthLoginRespVO? token;
  final UserInfo? user;

  LoginResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) =>
      _$LoginResultFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResultToJson(this);
}

// 发送验证码参数
@JsonSerializable()
class SendAuthCodeParams {
  final String identifier;
  final IdentifierType identifierType;
  final SmsSceneEnum scene;

  SendAuthCodeParams({
    required this.identifier,
    required this.identifierType,
    required this.scene,
  });

  factory SendAuthCodeParams.fromJson(Map<String, dynamic> json) =>
      _$SendAuthCodeParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SendAuthCodeParamsToJson(this);
}

// 登出参数
@JsonSerializable()
class LogoutParams {
  final String? refreshToken;

  LogoutParams({this.refreshToken});

  factory LogoutParams.fromJson(Map<String, dynamic> json) =>
      _$LogoutParamsFromJson(json);
  Map<String, dynamic> toJson() => _$LogoutParamsToJson(this);
}

// 社交授权跳转参数
@JsonSerializable()
class SocialAuthRedirectParams {
  final int socialType;
  final String? redirectUri;

  SocialAuthRedirectParams({required this.socialType, this.redirectUri});

  factory SocialAuthRedirectParams.fromJson(Map<String, dynamic> json) =>
      _$SocialAuthRedirectParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SocialAuthRedirectParamsToJson(this);
}

// 社交登录参数
@JsonSerializable()
class SocialLoginParams {
  final int socialType;
  final String code;
  final String? state;

  SocialLoginParams({required this.socialType, required this.code, this.state});

  factory SocialLoginParams.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SocialLoginParamsToJson(this);
}

// 微信小程序登录参数
@JsonSerializable()
class WeixinMiniAppLoginParams {
  final String code;
  final String? encryptedData;
  final String? iv;

  WeixinMiniAppLoginParams({required this.code, this.encryptedData, this.iv});

  factory WeixinMiniAppLoginParams.fromJson(Map<String, dynamic> json) =>
      _$WeixinMiniAppLoginParamsFromJson(json);
  Map<String, dynamic> toJson() => _$WeixinMiniAppLoginParamsToJson(this);
}

// 创建微信JS SDK签名参数
@JsonSerializable()
class CreateWeixinJsapiSignatureParams {
  final String url;

  CreateWeixinJsapiSignatureParams({required this.url});

  factory CreateWeixinJsapiSignatureParams.fromJson(
    Map<String, dynamic> json,
  ) => _$CreateWeixinJsapiSignatureParamsFromJson(json);
  Map<String, dynamic> toJson() =>
      _$CreateWeixinJsapiSignatureParamsToJson(this);
}

@JsonSerializable()
class SocialWxJsapiSignatureRespDTO {
  final String appId;
  final String nonceStr;
  final int timestamp;
  final String url;
  final String signature;

  SocialWxJsapiSignatureRespDTO({
    required this.appId,
    required this.nonceStr,
    required this.timestamp,
    required this.url,
    required this.signature,
  });

  factory SocialWxJsapiSignatureRespDTO.fromJson(Map<String, dynamic> json) =>
      _$SocialWxJsapiSignatureRespDTOFromJson(json);
  Map<String, dynamic> toJson() => _$SocialWxJsapiSignatureRespDTOToJson(this);
}
