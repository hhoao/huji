// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TelemetryCreateReqVO _$TelemetryCreateReqVOFromJson(
  Map<String, dynamic> json,
) => TelemetryCreateReqVO(
  featureCode: json['featureCode'] as String?,
  featureName: json['featureName'] as String?,
  success: json['success'] as bool?,
  duration: (json['duration'] as num?)?.toInt(),
  extraData: json['extraData'] as String?,
  appVersion: json['appVersion'] as String?,
  systemVersion: json['systemVersion'] as String?,
  deviceInfo: json['deviceInfo'] as String?,
);

Map<String, dynamic> _$TelemetryCreateReqVOToJson(
  TelemetryCreateReqVO instance,
) => <String, dynamic>{
  'featureCode': instance.featureCode,
  'featureName': instance.featureName,
  'success': instance.success,
  'duration': instance.duration,
  'extraData': instance.extraData,
  'appVersion': instance.appVersion,
  'systemVersion': instance.systemVersion,
  'deviceInfo': instance.deviceInfo,
};
