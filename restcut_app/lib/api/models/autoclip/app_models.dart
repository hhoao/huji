import 'package:json_annotation/json_annotation.dart';

part 'app_models.g.dart';

@JsonEnum(valueField: 'value')
enum AppTypeEnum {
  mobile(1, 'Mobile'),
  desktop(2, 'Desktop'),
  web(3, 'Web');

  const AppTypeEnum(this.value, this.name);
  final int value;
  final String name;
}

@JsonEnum(valueField: 'value')
enum AppPlatformEnum {
  android(1, 'Android'),
  ios(2, 'iOS'),
  windows(3, 'Windows'),
  macos(4, 'macOS'),
  linux(5, 'Linux');

  const AppPlatformEnum(this.value, this.name);
  final int value;
  final String name;
}

@JsonEnum(valueField: 'value')
enum DownloadTypeEnum {
  direct(1, 'Direct'), // 直接下载
  redirect(2, 'Redirect'); // 跳转链接

  const DownloadTypeEnum(this.value, this.name);
  final int value;
  final String name;
}

@JsonSerializable()
class AppApplicationRespVO {
  final int? id;

  final String name;

  final String? description;

  final String version;

  final String? icon;

  final String? changelog;

  final AppTypeEnum? type;

  final AppPlatformEnum platform;

  final double? fileSize;

  final int? downloadCount;

  final bool? forceUpdate;

  final String? minVersion;

  final DownloadTypeEnum? downloadType; // 下载类型：1-直接下载，2-跳转链接

  final int? createTime;

  final int? updateTime;

  AppApplicationRespVO({
    this.id,
    required this.name,
    this.description,
    required this.version,
    this.icon,
    this.changelog,
    this.type,
    required this.platform,
    this.fileSize,
    this.downloadCount,
    this.forceUpdate,
    this.minVersion,
    this.downloadType,
    this.createTime,
    this.updateTime,
  });

  factory AppApplicationRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppApplicationRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppApplicationRespVOToJson(this);
}

@JsonSerializable()
class AppVersionRespVO {
  final int? id;

  final String? version;

  final int? buildNumber;

  final AppPlatformEnum? platform;

  final String? downloadUrl;

  final double? fileSize;

  final String? minVersion;

  final bool? forceUpdate;

  final String? changelog;

  final int? createTime;

  final int? updateTime;

  AppVersionRespVO({
    this.id,
    this.version,
    this.buildNumber,
    this.platform,
    this.downloadUrl,
    this.fileSize,
    this.forceUpdate,
    this.minVersion,
    this.changelog,
    this.createTime,
    this.updateTime,
  });

  factory AppVersionRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppVersionRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppVersionRespVOToJson(this);
}

@JsonSerializable()
class AppChangelogRespVO {
  final int? id;

  final String? name;

  final String? version;

  final String? changelog;

  final AppTypeEnum? type;

  final AppPlatformEnum? platform;

  final bool? forceUpdate;

  final String? minVersion;

  final int? createTime;

  final int? updateTime;

  AppChangelogRespVO({
    this.id,
    this.name,
    this.version,
    this.changelog,
    this.type,
    this.platform,
    this.forceUpdate,
    this.minVersion,
    this.createTime,
    this.updateTime,
  });

  factory AppChangelogRespVO.fromJson(Map<String, dynamic> json) =>
      _$AppChangelogRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppChangelogRespVOToJson(this);
}

// 请求参数模型
@JsonSerializable()
class AppPageReqVO {
  final int? pageNo;

  final int? pageSize;

  final String? name;

  final AppPlatformEnum? platform;

  final String? version;

  final AppTypeEnum? type;

  AppPageReqVO({
    this.pageNo,
    this.pageSize,
    this.name,
    this.platform,
    this.type,
    this.version,
  });

  factory AppPageReqVO.fromJson(Map<String, dynamic> json) =>
      _$AppPageReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppPageReqVOToJson(this);
}

@JsonSerializable()
class AppChangelogPageReqVO {
  final int? pageNo;

  final int? pageSize;

  final String? name;

  final AppPlatformEnum? platform;

  final String? startVersion;
  final String? endVersion;

  final int? createTime;

  AppChangelogPageReqVO({
    this.pageNo,
    this.pageSize,
    this.name,
    this.platform,
    this.startVersion,
    this.endVersion,
    this.createTime,
  });

  factory AppChangelogPageReqVO.fromJson(Map<String, dynamic> json) =>
      _$AppChangelogPageReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$AppChangelogPageReqVOToJson(this);
}

// 更新检查结果模型
@JsonSerializable()
class AppUpdateInfo {
  final bool hasUpdate;
  final AppApplicationRespVO? latestApp;
  final AppApplicationRespVO? currentApp;
  final AppVersionRespVO? latestVersion;
  final bool forceUpdate;
  final String? downloadUrl;
  final DownloadTypeEnum? downloadType; // 下载链接类型：直接下载或跳转
  final List<String>? changelogs;

  AppUpdateInfo({
    required this.hasUpdate,
    this.latestApp,
    this.currentApp,
    this.latestVersion,
    this.forceUpdate = false,
    this.downloadUrl,
    this.downloadType,
    this.changelogs,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) =>
      _$AppUpdateInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AppUpdateInfoToJson(this);
}
