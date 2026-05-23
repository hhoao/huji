// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssueCreateReqVO _$IssueCreateReqVOFromJson(Map<String, dynamic> json) =>
    IssueCreateReqVO(
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$IssueTypeEnumEnumMap, json['type']),
      videoId: (json['videoId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IssueCreateReqVOToJson(IssueCreateReqVO instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'type': _$IssueTypeEnumEnumMap[instance.type]!,
      'videoId': instance.videoId,
    };

const _$IssueTypeEnumEnumMap = {
  IssueTypeEnum.bug: 1,
  IssueTypeEnum.requirement: 2,
};

IssueRespVO _$IssueRespVOFromJson(Map<String, dynamic> json) => IssueRespVO(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$IssueTypeEnumEnumMap, json['type']),
  typeName: json['typeName'] as String,
  status: $enumDecode(_$IssueStatusEnumEnumMap, json['status']),
  statusName: json['statusName'] as String,
  videoId: (json['videoId'] as num?)?.toInt(),
  videoName: json['videoName'] as String?,
  closedTime: json['closedTime'] as String?,
  closedByName: json['closedByName'] as String?,
  createTime: json['createTime'] as String,
  updateTime: json['updateTime'] as String,
  resolution: json['resolution'] as String?,
);

Map<String, dynamic> _$IssueRespVOToJson(IssueRespVO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$IssueTypeEnumEnumMap[instance.type]!,
      'typeName': instance.typeName,
      'status': _$IssueStatusEnumEnumMap[instance.status]!,
      'statusName': instance.statusName,
      'videoId': instance.videoId,
      'videoName': instance.videoName,
      'closedTime': instance.closedTime,
      'closedByName': instance.closedByName,
      'createTime': instance.createTime,
      'updateTime': instance.updateTime,
      'resolution': instance.resolution,
    };

const _$IssueStatusEnumEnumMap = {
  IssueStatusEnum.pending: 1,
  IssueStatusEnum.processing: 2,
  IssueStatusEnum.resolved: 3,
  IssueStatusEnum.closed: 4,
};

PageResult<T> _$PageResultFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PageResult<T>(
  list: (json['list'] as List<dynamic>).map(fromJsonT).toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
);

Map<String, dynamic> _$PageResultToJson<T>(
  PageResult<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'list': instance.list.map(toJsonT).toList(),
  'total': instance.total,
  'page': instance.page,
  'pageSize': instance.pageSize,
};
