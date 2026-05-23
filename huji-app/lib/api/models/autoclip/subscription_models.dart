import 'package:json_annotation/json_annotation.dart';

part 'subscription_models.g.dart';

@JsonEnum(valueField: 'value')
enum SubscriptionPlanEnum {
  free(0),
  pro(1),
  max(2);

  const SubscriptionPlanEnum(this.value);
  final int value;
}

@JsonSerializable()
class PermissionFeatureRespVO {
  final int id;
  final String code;
  final String name;
  final String description;
  final String category;
  final String value;
  final int sort;
  final int status;

  PermissionFeatureRespVO({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.value,
    required this.sort,
    required this.status,
  });

  factory PermissionFeatureRespVO.fromJson(Map<String, dynamic> json) =>
      _$PermissionFeatureRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionFeatureRespVOToJson(this);
}

@JsonSerializable()
class SubscriptionPlanRespVO {
  final int id;
  final SubscriptionPlanEnum planType;
  final String planCode;
  final String planName;
  final double monthlyPrice;
  final String description;
  final int sort;
  final int status;
  final List<PermissionFeatureRespVO> features;
  final bool recommended;
  final bool popular;

  SubscriptionPlanRespVO({
    required this.id,
    required this.planType,
    required this.planCode,
    required this.planName,
    required this.monthlyPrice,
    required this.description,
    required this.sort,
    required this.status,
    required this.features,
    required this.recommended,
    required this.popular,
  });

  factory SubscriptionPlanRespVO.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionPlanRespVOToJson(this);
}

@JsonSerializable()
class UserSubscriptionRespVO {
  final int id;
  final int userId;
  final SubscriptionPlanEnum planType;
  final int startTime;
  final int endTime;
  final int resetTime;
  final int status;
  final String planName;
  final double monthlyPrice;
  final List<PermissionFeatureRespVO> features;

  UserSubscriptionRespVO({
    required this.id,
    required this.userId,
    required this.planType,
    required this.startTime,
    required this.endTime,
    required this.resetTime,
    required this.status,
    required this.planName,
    required this.monthlyPrice,
    required this.features,
  });

  factory UserSubscriptionRespVO.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$UserSubscriptionRespVOToJson(this);
}

@JsonSerializable()
class CreateSubscriptionReqVO {
  final int planId;
  final String? remark;

  CreateSubscriptionReqVO({required this.planId, this.remark});

  factory CreateSubscriptionReqVO.fromJson(Map<String, dynamic> json) =>
      _$CreateSubscriptionReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$CreateSubscriptionReqVOToJson(this);
}
