// 分页参数
import 'package:json_annotation/json_annotation.dart';

part 'page.g.dart';

@JsonSerializable()
class PageParam {
  final int pageNo;
  final int pageSize;

  PageParam({this.pageNo = 1, this.pageSize = 10});

  factory PageParam.fromJson(Map<String, dynamic> json) =>
      _$PageParamFromJson(json);
  Map<String, dynamic> toJson() => _$PageParamToJson(this);
}

// 分页结果
@JsonSerializable(genericArgumentFactories: true)
class BasicFetchPageResult<T> {
  final List<T> list;
  final int total;

  BasicFetchPageResult({required this.list, required this.total});

  factory BasicFetchPageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$BasicFetchPageResultFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$BasicFetchPageResultToJson(this, toJsonT);
}
