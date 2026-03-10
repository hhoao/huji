// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageParam _$PageParamFromJson(Map<String, dynamic> json) => PageParam(
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
);

Map<String, dynamic> _$PageParamToJson(PageParam instance) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
};

BasicFetchPageResult<T> _$BasicFetchPageResultFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => BasicFetchPageResult<T>(
  list: (json['list'] as List<dynamic>).map(fromJsonT).toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$BasicFetchPageResultToJson<T>(
  BasicFetchPageResult<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'list': instance.list.map(toJsonT).toList(),
  'total': instance.total,
};
