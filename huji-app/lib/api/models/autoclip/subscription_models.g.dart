// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PermissionFeatureRespVO _$PermissionFeatureRespVOFromJson(
  Map<String, dynamic> json,
) => PermissionFeatureRespVO(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  value: json['value'] as String,
  sort: (json['sort'] as num).toInt(),
  status: (json['status'] as num).toInt(),
);

Map<String, dynamic> _$PermissionFeatureRespVOToJson(
  PermissionFeatureRespVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'value': instance.value,
  'sort': instance.sort,
  'status': instance.status,
};

SubscriptionPlanRespVO _$SubscriptionPlanRespVOFromJson(
  Map<String, dynamic> json,
) => SubscriptionPlanRespVO(
  id: (json['id'] as num).toInt(),
  planType: $enumDecode(_$SubscriptionPlanEnumEnumMap, json['planType']),
  planCode: json['planCode'] as String,
  planName: json['planName'] as String,
  monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
  description: json['description'] as String,
  sort: (json['sort'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  features: (json['features'] as List<dynamic>)
      .map((e) => PermissionFeatureRespVO.fromJson(e as Map<String, dynamic>))
      .toList(),
  recommended: json['recommended'] as bool,
  popular: json['popular'] as bool,
);

Map<String, dynamic> _$SubscriptionPlanRespVOToJson(
  SubscriptionPlanRespVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'planType': _$SubscriptionPlanEnumEnumMap[instance.planType]!,
  'planCode': instance.planCode,
  'planName': instance.planName,
  'monthlyPrice': instance.monthlyPrice,
  'description': instance.description,
  'sort': instance.sort,
  'status': instance.status,
  'features': instance.features,
  'recommended': instance.recommended,
  'popular': instance.popular,
};

const _$SubscriptionPlanEnumEnumMap = {
  SubscriptionPlanEnum.free: 0,
  SubscriptionPlanEnum.pro: 1,
  SubscriptionPlanEnum.max: 2,
};

UserSubscriptionRespVO _$UserSubscriptionRespVOFromJson(
  Map<String, dynamic> json,
) => UserSubscriptionRespVO(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  planType: $enumDecode(_$SubscriptionPlanEnumEnumMap, json['planType']),
  startTime: (json['startTime'] as num).toInt(),
  endTime: (json['endTime'] as num).toInt(),
  resetTime: (json['resetTime'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  planName: json['planName'] as String,
  monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
  features: (json['features'] as List<dynamic>)
      .map((e) => PermissionFeatureRespVO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserSubscriptionRespVOToJson(
  UserSubscriptionRespVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'planType': _$SubscriptionPlanEnumEnumMap[instance.planType]!,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'resetTime': instance.resetTime,
  'status': instance.status,
  'planName': instance.planName,
  'monthlyPrice': instance.monthlyPrice,
  'features': instance.features,
};

CreateSubscriptionReqVO _$CreateSubscriptionReqVOFromJson(
  Map<String, dynamic> json,
) => CreateSubscriptionReqVO(
  planId: (json['planId'] as num).toInt(),
  remark: json['remark'] as String?,
);

Map<String, dynamic> _$CreateSubscriptionReqVOToJson(
  CreateSubscriptionReqVO instance,
) => <String, dynamic>{'planId': instance.planId, 'remark': instance.remark};
