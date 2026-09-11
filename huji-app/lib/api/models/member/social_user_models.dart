import 'package:json_annotation/json_annotation.dart';

part 'social_user_models.g.dart';

// 绑定社交账号参数（对应服务端 AppSocialUserBindReqVO）
@JsonSerializable()
class SocialUserBindParams {
  final int type;
  final String code;
  final String state;

  SocialUserBindParams({
    required this.type,
    required this.code,
    required this.state,
  });

  factory SocialUserBindParams.fromJson(Map<String, dynamic> json) =>
      _$SocialUserBindParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SocialUserBindParamsToJson(this);
}

// 解绑参数（对应服务端 AppSocialUserUnbindReqVO）
@JsonSerializable()
class SocialUserUnbindParams {
  final int type;
  final String openid;

  SocialUserUnbindParams({required this.type, required this.openid});

  factory SocialUserUnbindParams.fromJson(Map<String, dynamic> json) =>
      _$SocialUserUnbindParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SocialUserUnbindParamsToJson(this);
}

// 已绑定的社交用户信息（对应服务端 AppSocialUserRespVO）
@JsonSerializable()
class SocialUserInfo {
  final String openid;
  final String? nickname;
  final String? avatar;

  SocialUserInfo({required this.openid, this.nickname, this.avatar});

  factory SocialUserInfo.fromJson(Map<String, dynamic> json) =>
      _$SocialUserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SocialUserInfoToJson(this);
}
