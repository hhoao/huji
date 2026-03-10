// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_setting_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettingPageReqVO _$AppSettingPageReqVOFromJson(Map<String, dynamic> json) =>
    AppSettingPageReqVO(
      pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      code: json['code'] as String?,
      name: json['name'] as String?,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$AppSettingPageReqVOToJson(
  AppSettingPageReqVO instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'code': instance.code,
  'name': instance.name,
  'category': instance.category,
};

AppSettingRespVO _$AppSettingRespVOFromJson(Map<String, dynamic> json) =>
    AppSettingRespVO(
      code: json['code'] as String,
      name: json['name'] as String,
      value: json['value'] as String,
      type: (json['type'] as num).toInt(),
    );

Map<String, dynamic> _$AppSettingRespVOToJson(AppSettingRespVO instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'value': instance.value,
      'type': instance.type,
    };
