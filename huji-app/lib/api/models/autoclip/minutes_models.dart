import 'package:json_annotation/json_annotation.dart';
import '../common/page.dart';

part 'minutes_models.g.dart';

// 时长套餐 Response VO
@JsonSerializable()
class AppMinutesPackageRespVO {
  final int id;
  final String packageName;
  final double minutes;
  final double price;
  final int validDays;
  final String description;
  final int sort;
  final int status;
  final int createTime;
  final int updateTime;

  AppMinutesPackageRespVO({
    required this.id,
    required this.packageName,
    required this.minutes,
    required this.price,
    required this.validDays,
    required this.description,
    required this.sort,
    required this.status,
    required this.createTime,
    required this.updateTime,
  });

  factory AppMinutesPackageRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppMinutesPackageRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppMinutesPackageRespVOToJson(this);
}

// 时长购买记录 Response VO
@JsonSerializable()
class AppMinutesPurchaseRespVO {
  final int id;
  final int userId;
  final double minutes;
  final int purchaseType;
  final int? planId;
  final DateTime? validStartTime;
  final DateTime? validEndTime;
  final double usedMinutes;
  final double remainingMinutes;
  final int status;
  final String? orderId;
  final double? price;
  final String? remark;
  final DateTime createTime;
  final DateTime updateTime;

  AppMinutesPurchaseRespVO({
    required this.id,
    required this.userId,
    required this.minutes,
    required this.purchaseType,
    this.planId,
    this.validStartTime,
    this.validEndTime,
    required this.usedMinutes,
    required this.remainingMinutes,
    required this.status,
    this.orderId,
    this.price,
    this.remark,
    required this.createTime,
    required this.updateTime,
  });

  factory AppMinutesPurchaseRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppMinutesPurchaseRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppMinutesPurchaseRespVOToJson(this);
}

// 时长使用记录 Response VO
@JsonSerializable()
class AppMinutesUsageRespVO {
  final int id;
  final int userId;
  final int purchaseId;
  final int? recordId;
  final double usedMinutes;
  final int usageType;
  final String usageDescription;
  final double beforeRemaining;
  final double afterRemaining;
  final DateTime createTime;
  final DateTime updateTime;

  AppMinutesUsageRespVO({
    required this.id,
    required this.userId,
    required this.purchaseId,
    this.recordId,
    required this.usedMinutes,
    required this.usageType,
    required this.usageDescription,
    required this.beforeRemaining,
    required this.afterRemaining,
    required this.createTime,
    required this.updateTime,
  });

  factory AppMinutesUsageRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppMinutesUsageRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppMinutesUsageRespVOToJson(this);
}

// 时长套餐分页查询 Request VO
@JsonSerializable()
class AppMinutesPackagePageReqVO extends PageParam {
  final String? packageName;
  final int? status;
  final double? minMinutes;
  final double? maxMinutes;
  final double? minPrice;
  final double? maxPrice;

  AppMinutesPackagePageReqVO({
    super.pageNo,
    super.pageSize,
    this.packageName,
    this.status,
    this.minMinutes,
    this.maxMinutes,
    this.minPrice,
    this.maxPrice,
  });

  factory AppMinutesPackagePageReqVO.fromJson(Map<String, dynamic> json) =>
      _$AppMinutesPackagePageReqVOFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AppMinutesPackagePageReqVOToJson(this);
}

// 时长购买记录分页查询 Request VO
@JsonSerializable()
class AppMinutesPurchasePageReqVO extends PageParam {
  final int? purchaseType;
  final int? status;
  final String? orderId;
  final DateTime? beginTime;
  final DateTime? endTime;
  final double? minMinutes;
  final double? maxMinutes;

  AppMinutesPurchasePageReqVO({
    super.pageNo,
    super.pageSize,
    this.purchaseType,
    this.status,
    this.orderId,
    this.beginTime,
    this.endTime,
    this.minMinutes,
    this.maxMinutes,
  });

  factory AppMinutesPurchasePageReqVO.fromJson(Map<String, dynamic> json) =>
      _$AppMinutesPurchasePageReqVOFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AppMinutesPurchasePageReqVOToJson(this);
}

// 时长使用记录分页查询 Request VO
@JsonSerializable()
class AppMinutesUsagePageReqVO extends PageParam {
  final int? usageType;
  final int? recordId;
  final String? usageDescription;
  final DateTime? beginTime;
  final DateTime? endTime;
  final double? minUsedMinutes;
  final double? maxUsedMinutes;

  AppMinutesUsagePageReqVO({
    super.pageNo,
    super.pageSize,
    this.usageType,
    this.recordId,
    this.usageDescription,
    this.beginTime,
    this.endTime,
    this.minUsedMinutes,
    this.maxUsedMinutes,
  });

  factory AppMinutesUsagePageReqVO.fromJson(Map<String, dynamic> json) =>
      _$AppMinutesUsagePageReqVOFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AppMinutesUsagePageReqVOToJson(this);
}
