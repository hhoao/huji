// 用户等级信息
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:restcut/api/models/member/auth_models.dart';

part 'user_models.freezed.dart';
part 'user_models.g.dart';

@JsonSerializable()
class Level {
  final int id;
  final String name;
  final int level;
  final String icon;

  Level({
    required this.id,
    required this.name,
    required this.level,
    required this.icon,
  });

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
  Map<String, dynamic> toJson() => _$LevelToJson(this);
}

// 用户信息
@JsonSerializable()
@freezed
class UserInfo with _$UserInfo {
  @override
  int? id;
  @override
  String? nickname;
  @override
  String? avatar;
  @override
  String? mobile;
  @override
  String? email;
  @override
  int? sex;
  @override
  int? point;
  @override
  int? experience;
  @override
  Level? level;
  @override
  bool? brokerageEnabled;

  UserInfo({
    this.id,
    this.nickname,
    this.avatar,
    this.mobile,
    this.email,
    this.sex,
    this.point,
    this.experience,
    this.level,
    this.brokerageEnabled,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

// 更新用户基本信息参数 - 对应后端 AppMemberUserUpdateReqVO
@JsonSerializable()
class UpdateUserBasicInfoParams {
  String? nickname;
  String? avatar;
  int? sex;

  UpdateUserBasicInfoParams({this.nickname, this.avatar, this.sex});

  factory UpdateUserBasicInfoParams.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserBasicInfoParamsFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserBasicInfoParamsToJson(this);
}

// 更新密码参数
@JsonSerializable()
class UpdateUserPasswordParams {
  final String password;
  final String code;
  final IdentifierType identifierType;

  UpdateUserPasswordParams({
    required this.password,
    required this.code,
    required this.identifierType,
  });

  factory UpdateUserPasswordParams.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserPasswordParamsFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserPasswordParamsToJson(this);
}

// 重置密码参数
@JsonSerializable()
class ResetUserPasswordParams {
  final String password;
  final String code;
  final String identifier;
  final IdentifierType identifierType;

  ResetUserPasswordParams({
    required this.password,
    required this.code,
    required this.identifier,
    required this.identifierType,
  });

  factory ResetUserPasswordParams.fromJson(Map<String, dynamic> json) =>
      _$ResetUserPasswordParamsFromJson(json);
  Map<String, dynamic> toJson() => _$ResetUserPasswordParamsToJson(this);
}

// 更新用户信息参数
@JsonSerializable()
class UpdateUserInfoParams {
  final String identifier;
  final IdentifierType identifierType;
  final String password;
  final String code;

  UpdateUserInfoParams({
    required this.identifier,
    required this.identifierType,
    required this.password,
    required this.code,
  });

  factory UpdateUserInfoParams.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserInfoParamsFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserInfoParamsToJson(this);
}

// 标识符参数
@JsonSerializable()
class IdentifierParams {
  final String identifier;
  final IdentifierType identifierType;

  IdentifierParams({required this.identifier, required this.identifierType});

  factory IdentifierParams.fromJson(Map<String, dynamic> json) =>
      _$IdentifierParamsFromJson(json);
  Map<String, dynamic> toJson() => _$IdentifierParamsToJson(this);
}
