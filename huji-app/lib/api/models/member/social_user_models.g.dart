// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_user_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialUserBindParams _$SocialUserBindParamsFromJson(
  Map<String, dynamic> json,
) => SocialUserBindParams(
  type: (json['type'] as num).toInt(),
  code: json['code'] as String,
  state: json['state'] as String,
);

Map<String, dynamic> _$SocialUserBindParamsToJson(
  SocialUserBindParams instance,
) => <String, dynamic>{
  'type': instance.type,
  'code': instance.code,
  'state': instance.state,
};

SocialUserUnbindParams _$SocialUserUnbindParamsFromJson(
  Map<String, dynamic> json,
) => SocialUserUnbindParams(
  type: (json['type'] as num).toInt(),
  openid: json['openid'] as String,
);

Map<String, dynamic> _$SocialUserUnbindParamsToJson(
  SocialUserUnbindParams instance,
) => <String, dynamic>{'type': instance.type, 'openid': instance.openid};

SocialUserInfo _$SocialUserInfoFromJson(Map<String, dynamic> json) =>
    SocialUserInfo(
      openid: json['openid'] as String,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$SocialUserInfoToJson(SocialUserInfo instance) =>
    <String, dynamic>{
      'openid': instance.openid,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
    };
