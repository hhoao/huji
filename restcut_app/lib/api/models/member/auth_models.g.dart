// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginPasswordParams _$LoginPasswordParamsFromJson(Map<String, dynamic> json) =>
    LoginPasswordParams(
      identifier: json['identifier'] as String,
      identifierType: $enumDecode(
        _$IdentifierTypeEnumMap,
        json['identifierType'],
      ),
      password: json['password'] as String,
      socialType: (json['socialType'] as num?)?.toInt(),
      socialCode: json['socialCode'] as String?,
    );

Map<String, dynamic> _$LoginPasswordParamsToJson(
  LoginPasswordParams instance,
) => <String, dynamic>{
  'identifier': instance.identifier,
  'identifierType': _$IdentifierTypeEnumMap[instance.identifierType]!,
  'password': instance.password,
  'socialType': instance.socialType,
  'socialCode': instance.socialCode,
};

const _$IdentifierTypeEnumMap = {
  IdentifierType.mobile: 0,
  IdentifierType.mail: 1,
};

LoginAuthCodeParams _$LoginAuthCodeParamsFromJson(Map<String, dynamic> json) =>
    LoginAuthCodeParams(
      identifier: json['identifier'] as String,
      identifierType: $enumDecode(
        _$IdentifierTypeEnumMap,
        json['identifierType'],
      ),
      code: json['code'] as String,
      socialType: (json['socialType'] as num?)?.toInt(),
      socialCode: json['socialCode'] as String?,
      socialState: json['socialState'] as String?,
    );

Map<String, dynamic> _$LoginAuthCodeParamsToJson(
  LoginAuthCodeParams instance,
) => <String, dynamic>{
  'identifier': instance.identifier,
  'identifierType': _$IdentifierTypeEnumMap[instance.identifierType]!,
  'code': instance.code,
  'socialType': instance.socialType,
  'socialCode': instance.socialCode,
  'socialState': instance.socialState,
};

AppAuthLoginRespVO _$AppAuthLoginRespVOFromJson(Map<String, dynamic> json) =>
    AppAuthLoginRespVO(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresTime: (json['expiresTime'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      openId: json['openId'] as String?,
    );

Map<String, dynamic> _$AppAuthLoginRespVOToJson(AppAuthLoginRespVO instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'userId': instance.userId,
      'expiresTime': instance.expiresTime,
      'openId': instance.openId,
    };

LoginResult _$LoginResultFromJson(Map<String, dynamic> json) => LoginResult(
  success: json['success'] as bool,
  message: json['message'] as String,
  token: json['token'] == null
      ? null
      : AppAuthLoginRespVO.fromJson(json['token'] as Map<String, dynamic>),
  user: json['user'] == null
      ? null
      : UserInfo.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LoginResultToJson(LoginResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'token': instance.token,
      'user': instance.user,
    };

SendAuthCodeParams _$SendAuthCodeParamsFromJson(Map<String, dynamic> json) =>
    SendAuthCodeParams(
      identifier: json['identifier'] as String,
      identifierType: $enumDecode(
        _$IdentifierTypeEnumMap,
        json['identifierType'],
      ),
      scene: $enumDecode(_$SmsSceneEnumEnumMap, json['scene']),
    );

Map<String, dynamic> _$SendAuthCodeParamsToJson(SendAuthCodeParams instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'identifierType': _$IdentifierTypeEnumMap[instance.identifierType]!,
      'scene': _$SmsSceneEnumEnumMap[instance.scene]!,
    };

const _$SmsSceneEnumEnumMap = {
  SmsSceneEnum.memberLogin: 1,
  SmsSceneEnum.memberUpdateMobile: 2,
  SmsSceneEnum.memberUpdatePassword: 3,
  SmsSceneEnum.memberResetPassword: 4,
};

LogoutParams _$LogoutParamsFromJson(Map<String, dynamic> json) =>
    LogoutParams(refreshToken: json['refreshToken'] as String?);

Map<String, dynamic> _$LogoutParamsToJson(LogoutParams instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

SocialAuthRedirectParams _$SocialAuthRedirectParamsFromJson(
  Map<String, dynamic> json,
) => SocialAuthRedirectParams(
  socialType: (json['socialType'] as num).toInt(),
  redirectUri: json['redirectUri'] as String?,
);

Map<String, dynamic> _$SocialAuthRedirectParamsToJson(
  SocialAuthRedirectParams instance,
) => <String, dynamic>{
  'socialType': instance.socialType,
  'redirectUri': instance.redirectUri,
};

SocialLoginParams _$SocialLoginParamsFromJson(Map<String, dynamic> json) =>
    SocialLoginParams(
      socialType: (json['socialType'] as num).toInt(),
      code: json['code'] as String,
      state: json['state'] as String?,
    );

Map<String, dynamic> _$SocialLoginParamsToJson(SocialLoginParams instance) =>
    <String, dynamic>{
      'socialType': instance.socialType,
      'code': instance.code,
      'state': instance.state,
    };

WeixinMiniAppLoginParams _$WeixinMiniAppLoginParamsFromJson(
  Map<String, dynamic> json,
) => WeixinMiniAppLoginParams(
  code: json['code'] as String,
  encryptedData: json['encryptedData'] as String?,
  iv: json['iv'] as String?,
);

Map<String, dynamic> _$WeixinMiniAppLoginParamsToJson(
  WeixinMiniAppLoginParams instance,
) => <String, dynamic>{
  'code': instance.code,
  'encryptedData': instance.encryptedData,
  'iv': instance.iv,
};

CreateWeixinJsapiSignatureParams _$CreateWeixinJsapiSignatureParamsFromJson(
  Map<String, dynamic> json,
) => CreateWeixinJsapiSignatureParams(url: json['url'] as String);

Map<String, dynamic> _$CreateWeixinJsapiSignatureParamsToJson(
  CreateWeixinJsapiSignatureParams instance,
) => <String, dynamic>{'url': instance.url};

SocialWxJsapiSignatureRespDTO _$SocialWxJsapiSignatureRespDTOFromJson(
  Map<String, dynamic> json,
) => SocialWxJsapiSignatureRespDTO(
  appId: json['appId'] as String,
  nonceStr: json['nonceStr'] as String,
  timestamp: (json['timestamp'] as num).toInt(),
  url: json['url'] as String,
  signature: json['signature'] as String,
);

Map<String, dynamic> _$SocialWxJsapiSignatureRespDTOToJson(
  SocialWxJsapiSignatureRespDTO instance,
) => <String, dynamic>{
  'appId': instance.appId,
  'nonceStr': instance.nonceStr,
  'timestamp': instance.timestamp,
  'url': instance.url,
  'signature': instance.signature,
};
