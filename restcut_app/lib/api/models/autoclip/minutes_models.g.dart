// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'minutes_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMinutesPackageRespVO _$AppMinutesPackageRespVOFromJson(
  Map<String, dynamic> json,
) => AppMinutesPackageRespVO(
  id: (json['id'] as num).toInt(),
  packageName: json['packageName'] as String,
  minutes: (json['minutes'] as num).toDouble(),
  price: (json['price'] as num).toDouble(),
  validDays: (json['validDays'] as num).toInt(),
  description: json['description'] as String,
  sort: (json['sort'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  createTime: (json['createTime'] as num).toInt(),
  updateTime: (json['updateTime'] as num).toInt(),
);

Map<String, dynamic> _$AppMinutesPackageRespVOToJson(
  AppMinutesPackageRespVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'packageName': instance.packageName,
  'minutes': instance.minutes,
  'price': instance.price,
  'validDays': instance.validDays,
  'description': instance.description,
  'sort': instance.sort,
  'status': instance.status,
  'createTime': instance.createTime,
  'updateTime': instance.updateTime,
};

AppMinutesPurchaseRespVO _$AppMinutesPurchaseRespVOFromJson(
  Map<String, dynamic> json,
) => AppMinutesPurchaseRespVO(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  minutes: (json['minutes'] as num).toDouble(),
  purchaseType: (json['purchaseType'] as num).toInt(),
  planId: (json['planId'] as num?)?.toInt(),
  validStartTime: json['validStartTime'] == null
      ? null
      : DateTime.parse(json['validStartTime'] as String),
  validEndTime: json['validEndTime'] == null
      ? null
      : DateTime.parse(json['validEndTime'] as String),
  usedMinutes: (json['usedMinutes'] as num).toDouble(),
  remainingMinutes: (json['remainingMinutes'] as num).toDouble(),
  status: (json['status'] as num).toInt(),
  orderId: json['orderId'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  remark: json['remark'] as String?,
  createTime: DateTime.parse(json['createTime'] as String),
  updateTime: DateTime.parse(json['updateTime'] as String),
);

Map<String, dynamic> _$AppMinutesPurchaseRespVOToJson(
  AppMinutesPurchaseRespVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'minutes': instance.minutes,
  'purchaseType': instance.purchaseType,
  'planId': instance.planId,
  'validStartTime': instance.validStartTime?.toIso8601String(),
  'validEndTime': instance.validEndTime?.toIso8601String(),
  'usedMinutes': instance.usedMinutes,
  'remainingMinutes': instance.remainingMinutes,
  'status': instance.status,
  'orderId': instance.orderId,
  'price': instance.price,
  'remark': instance.remark,
  'createTime': instance.createTime.toIso8601String(),
  'updateTime': instance.updateTime.toIso8601String(),
};

AppMinutesUsageRespVO _$AppMinutesUsageRespVOFromJson(
  Map<String, dynamic> json,
) => AppMinutesUsageRespVO(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  purchaseId: (json['purchaseId'] as num).toInt(),
  recordId: (json['recordId'] as num?)?.toInt(),
  usedMinutes: (json['usedMinutes'] as num).toDouble(),
  usageType: (json['usageType'] as num).toInt(),
  usageDescription: json['usageDescription'] as String,
  beforeRemaining: (json['beforeRemaining'] as num).toDouble(),
  afterRemaining: (json['afterRemaining'] as num).toDouble(),
  createTime: DateTime.parse(json['createTime'] as String),
  updateTime: DateTime.parse(json['updateTime'] as String),
);

Map<String, dynamic> _$AppMinutesUsageRespVOToJson(
  AppMinutesUsageRespVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'purchaseId': instance.purchaseId,
  'recordId': instance.recordId,
  'usedMinutes': instance.usedMinutes,
  'usageType': instance.usageType,
  'usageDescription': instance.usageDescription,
  'beforeRemaining': instance.beforeRemaining,
  'afterRemaining': instance.afterRemaining,
  'createTime': instance.createTime.toIso8601String(),
  'updateTime': instance.updateTime.toIso8601String(),
};

AppMinutesPackagePageReqVO _$AppMinutesPackagePageReqVOFromJson(
  Map<String, dynamic> json,
) => AppMinutesPackagePageReqVO(
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
  packageName: json['packageName'] as String?,
  status: (json['status'] as num?)?.toInt(),
  minMinutes: (json['minMinutes'] as num?)?.toDouble(),
  maxMinutes: (json['maxMinutes'] as num?)?.toDouble(),
  minPrice: (json['minPrice'] as num?)?.toDouble(),
  maxPrice: (json['maxPrice'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AppMinutesPackagePageReqVOToJson(
  AppMinutesPackagePageReqVO instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'packageName': instance.packageName,
  'status': instance.status,
  'minMinutes': instance.minMinutes,
  'maxMinutes': instance.maxMinutes,
  'minPrice': instance.minPrice,
  'maxPrice': instance.maxPrice,
};

AppMinutesPurchasePageReqVO _$AppMinutesPurchasePageReqVOFromJson(
  Map<String, dynamic> json,
) => AppMinutesPurchasePageReqVO(
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
  purchaseType: (json['purchaseType'] as num?)?.toInt(),
  status: (json['status'] as num?)?.toInt(),
  orderId: json['orderId'] as String?,
  beginTime: json['beginTime'] == null
      ? null
      : DateTime.parse(json['beginTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  minMinutes: (json['minMinutes'] as num?)?.toDouble(),
  maxMinutes: (json['maxMinutes'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AppMinutesPurchasePageReqVOToJson(
  AppMinutesPurchasePageReqVO instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'purchaseType': instance.purchaseType,
  'status': instance.status,
  'orderId': instance.orderId,
  'beginTime': instance.beginTime?.toIso8601String(),
  'endTime': instance.endTime?.toIso8601String(),
  'minMinutes': instance.minMinutes,
  'maxMinutes': instance.maxMinutes,
};

AppMinutesUsagePageReqVO _$AppMinutesUsagePageReqVOFromJson(
  Map<String, dynamic> json,
) => AppMinutesUsagePageReqVO(
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
  usageType: (json['usageType'] as num?)?.toInt(),
  recordId: (json['recordId'] as num?)?.toInt(),
  usageDescription: json['usageDescription'] as String?,
  beginTime: json['beginTime'] == null
      ? null
      : DateTime.parse(json['beginTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  minUsedMinutes: (json['minUsedMinutes'] as num?)?.toDouble(),
  maxUsedMinutes: (json['maxUsedMinutes'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AppMinutesUsagePageReqVOToJson(
  AppMinutesUsagePageReqVO instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'usageType': instance.usageType,
  'recordId': instance.recordId,
  'usageDescription': instance.usageDescription,
  'beginTime': instance.beginTime?.toIso8601String(),
  'endTime': instance.endTime?.toIso8601String(),
  'minUsedMinutes': instance.minUsedMinutes,
  'maxUsedMinutes': instance.maxUsedMinutes,
};
