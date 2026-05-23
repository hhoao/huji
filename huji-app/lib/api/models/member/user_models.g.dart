// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level _$LevelFromJson(Map<String, dynamic> json) => Level(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  level: (json['level'] as num).toInt(),
  icon: json['icon'] as String,
);

Map<String, dynamic> _$LevelToJson(Level instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'level': instance.level,
  'icon': instance.icon,
};

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
  id: (json['id'] as num?)?.toInt(),
  nickname: json['nickname'] as String?,
  avatar: json['avatar'] as String?,
  mobile: json['mobile'] as String?,
  email: json['email'] as String?,
  sex: (json['sex'] as num?)?.toInt(),
  point: (json['point'] as num?)?.toInt(),
  experience: (json['experience'] as num?)?.toInt(),
  level: json['level'] == null
      ? null
      : Level.fromJson(json['level'] as Map<String, dynamic>),
  brokerageEnabled: json['brokerageEnabled'] as bool?,
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'mobile': instance.mobile,
  'email': instance.email,
  'sex': instance.sex,
  'point': instance.point,
  'experience': instance.experience,
  'level': instance.level,
  'brokerageEnabled': instance.brokerageEnabled,
};

UpdateUserBasicInfoParams _$UpdateUserBasicInfoParamsFromJson(
  Map<String, dynamic> json,
) => UpdateUserBasicInfoParams(
  nickname: json['nickname'] as String?,
  avatar: json['avatar'] as String?,
  sex: (json['sex'] as num?)?.toInt(),
);

Map<String, dynamic> _$UpdateUserBasicInfoParamsToJson(
  UpdateUserBasicInfoParams instance,
) => <String, dynamic>{
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'sex': instance.sex,
};

UpdateUserPasswordParams _$UpdateUserPasswordParamsFromJson(
  Map<String, dynamic> json,
) => UpdateUserPasswordParams(
  password: json['password'] as String,
  code: json['code'] as String,
  identifierType: $enumDecode(_$IdentifierTypeEnumMap, json['identifierType']),
);

Map<String, dynamic> _$UpdateUserPasswordParamsToJson(
  UpdateUserPasswordParams instance,
) => <String, dynamic>{
  'password': instance.password,
  'code': instance.code,
  'identifierType': _$IdentifierTypeEnumMap[instance.identifierType]!,
};

const _$IdentifierTypeEnumMap = {
  IdentifierType.mobile: 0,
  IdentifierType.mail: 1,
};

ResetUserPasswordParams _$ResetUserPasswordParamsFromJson(
  Map<String, dynamic> json,
) => ResetUserPasswordParams(
  password: json['password'] as String,
  code: json['code'] as String,
  identifier: json['identifier'] as String,
  identifierType: $enumDecode(_$IdentifierTypeEnumMap, json['identifierType']),
);

Map<String, dynamic> _$ResetUserPasswordParamsToJson(
  ResetUserPasswordParams instance,
) => <String, dynamic>{
  'password': instance.password,
  'code': instance.code,
  'identifier': instance.identifier,
  'identifierType': _$IdentifierTypeEnumMap[instance.identifierType]!,
};

UpdateUserInfoParams _$UpdateUserInfoParamsFromJson(
  Map<String, dynamic> json,
) => UpdateUserInfoParams(
  identifier: json['identifier'] as String,
  identifierType: $enumDecode(_$IdentifierTypeEnumMap, json['identifierType']),
  password: json['password'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$UpdateUserInfoParamsToJson(
  UpdateUserInfoParams instance,
) => <String, dynamic>{
  'identifier': instance.identifier,
  'identifierType': _$IdentifierTypeEnumMap[instance.identifierType]!,
  'password': instance.password,
  'code': instance.code,
};

IdentifierParams _$IdentifierParamsFromJson(Map<String, dynamic> json) =>
    IdentifierParams(
      identifier: json['identifier'] as String,
      identifierType: $enumDecode(
        _$IdentifierTypeEnumMap,
        json['identifierType'],
      ),
    );

Map<String, dynamic> _$IdentifierParamsToJson(IdentifierParams instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'identifierType': _$IdentifierTypeEnumMap[instance.identifierType]!,
    };
