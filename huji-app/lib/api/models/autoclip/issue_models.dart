import 'package:json_annotation/json_annotation.dart';

part 'issue_models.g.dart';

enum IssueTypeEnum {
  @JsonValue(1)
  bug,
  @JsonValue(2)
  requirement,
}

enum IssueStatusEnum {
  @JsonValue(1)
  pending,
  @JsonValue(2)
  processing,
  @JsonValue(3)
  resolved,
  @JsonValue(4)
  closed,
}

@JsonSerializable()
class IssueCreateReqVO {
  final String title;
  final String description;
  final IssueTypeEnum type;
  final int? videoId;

  IssueCreateReqVO({
    required this.title,
    required this.description,
    required this.type,
    this.videoId,
  });

  factory IssueCreateReqVO.fromJson(Map<String, dynamic> json) =>
      _$IssueCreateReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$IssueCreateReqVOToJson(this);
}

@JsonSerializable()
class IssueRespVO {
  final int id;
  final String title;
  final String description;
  final IssueTypeEnum type;
  final String typeName;
  final IssueStatusEnum status;
  final String statusName;
  final int? videoId;
  final String? videoName;
  final String? closedTime;
  final String? closedByName;
  final String createTime;
  final String updateTime;
  final String? resolution;

  IssueRespVO({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.typeName,
    required this.status,
    required this.statusName,
    this.videoId,
    this.videoName,
    this.closedTime,
    this.closedByName,
    required this.createTime,
    required this.updateTime,
    this.resolution,
  });

  factory IssueRespVO.fromJson(Map<String, dynamic> json) =>
      _$IssueRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$IssueRespVOToJson(this);
}

@JsonSerializable(genericArgumentFactories: true)
class PageResult<T> {
  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  PageResult({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PageResultFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PageResultToJson(this, toJsonT);
}
