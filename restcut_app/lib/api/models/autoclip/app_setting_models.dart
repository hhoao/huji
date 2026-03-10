import 'package:json_annotation/json_annotation.dart';
import '../common/page.dart';

part 'app_setting_models.g.dart';

@JsonSerializable()
class AppSettingPageReqVO extends PageParam {
  final String? code;
  final String? name;
  final String? category;

  AppSettingPageReqVO({
    super.pageNo = 1,
    super.pageSize = 10,
    this.code,
    this.name,
    this.category,
  });

  factory AppSettingPageReqVO.fromJson(Map<String, dynamic> json) =>
      _$AppSettingPageReqVOFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AppSettingPageReqVOToJson(this);
}

@JsonSerializable()
class AppSettingRespVO {
  final String code;
  final String name;
  final String value;
  final int type;

  AppSettingRespVO({
    required this.code,
    required this.name,
    required this.value,
    required this.type,
  });

  factory AppSettingRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppSettingRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingRespVOToJson(this);
}
