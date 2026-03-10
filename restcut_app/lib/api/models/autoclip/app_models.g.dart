// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppApplicationRespVO _$AppApplicationRespVOFromJson(
  Map<String, dynamic> json,
) => AppApplicationRespVO(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  version: json['version'] as String,
  icon: json['icon'] as String?,
  changelog: json['changelog'] as String?,
  type: $enumDecodeNullable(_$AppTypeEnumEnumMap, json['type']),
  platform: $enumDecode(_$AppPlatformEnumEnumMap, json['platform']),
  fileSize: (json['fileSize'] as num?)?.toDouble(),
  downloadCount: (json['downloadCount'] as num?)?.toInt(),
  forceUpdate: json['forceUpdate'] as bool?,
  minVersion: json['minVersion'] as String?,
  downloadType: $enumDecodeNullable(
    _$DownloadTypeEnumEnumMap,
    json['downloadType'],
  ),
  createTime: (json['createTime'] as num?)?.toInt(),
  updateTime: (json['updateTime'] as num?)?.toInt(),
);

Map<String, dynamic> _$AppApplicationRespVOToJson(
  AppApplicationRespVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'version': instance.version,
  'icon': instance.icon,
  'changelog': instance.changelog,
  'type': _$AppTypeEnumEnumMap[instance.type],
  'platform': _$AppPlatformEnumEnumMap[instance.platform]!,
  'fileSize': instance.fileSize,
  'downloadCount': instance.downloadCount,
  'forceUpdate': instance.forceUpdate,
  'minVersion': instance.minVersion,
  'downloadType': _$DownloadTypeEnumEnumMap[instance.downloadType],
  'createTime': instance.createTime,
  'updateTime': instance.updateTime,
};

const _$AppTypeEnumEnumMap = {
  AppTypeEnum.mobile: 1,
  AppTypeEnum.desktop: 2,
  AppTypeEnum.web: 3,
};

const _$AppPlatformEnumEnumMap = {
  AppPlatformEnum.android: 1,
  AppPlatformEnum.ios: 2,
  AppPlatformEnum.windows: 3,
  AppPlatformEnum.macos: 4,
  AppPlatformEnum.linux: 5,
};

const _$DownloadTypeEnumEnumMap = {
  DownloadTypeEnum.direct: 1,
  DownloadTypeEnum.redirect: 2,
};

AppVersionRespVO _$AppVersionRespVOFromJson(Map<String, dynamic> json) =>
    AppVersionRespVO(
      id: (json['id'] as num?)?.toInt(),
      version: json['version'] as String?,
      buildNumber: (json['buildNumber'] as num?)?.toInt(),
      platform: $enumDecodeNullable(_$AppPlatformEnumEnumMap, json['platform']),
      downloadUrl: json['downloadUrl'] as String?,
      fileSize: (json['fileSize'] as num?)?.toDouble(),
      forceUpdate: json['forceUpdate'] as bool?,
      minVersion: json['minVersion'] as String?,
      changelog: json['changelog'] as String?,
      createTime: (json['createTime'] as num?)?.toInt(),
      updateTime: (json['updateTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppVersionRespVOToJson(AppVersionRespVO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'buildNumber': instance.buildNumber,
      'platform': _$AppPlatformEnumEnumMap[instance.platform],
      'downloadUrl': instance.downloadUrl,
      'fileSize': instance.fileSize,
      'minVersion': instance.minVersion,
      'forceUpdate': instance.forceUpdate,
      'changelog': instance.changelog,
      'createTime': instance.createTime,
      'updateTime': instance.updateTime,
    };

AppChangelogRespVO _$AppChangelogRespVOFromJson(Map<String, dynamic> json) =>
    AppChangelogRespVO(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      version: json['version'] as String?,
      changelog: json['changelog'] as String?,
      type: $enumDecodeNullable(_$AppTypeEnumEnumMap, json['type']),
      platform: $enumDecodeNullable(_$AppPlatformEnumEnumMap, json['platform']),
      forceUpdate: json['forceUpdate'] as bool?,
      minVersion: json['minVersion'] as String?,
      createTime: (json['createTime'] as num?)?.toInt(),
      updateTime: (json['updateTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppChangelogRespVOToJson(AppChangelogRespVO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
      'changelog': instance.changelog,
      'type': _$AppTypeEnumEnumMap[instance.type],
      'platform': _$AppPlatformEnumEnumMap[instance.platform],
      'forceUpdate': instance.forceUpdate,
      'minVersion': instance.minVersion,
      'createTime': instance.createTime,
      'updateTime': instance.updateTime,
    };

AppPageReqVO _$AppPageReqVOFromJson(Map<String, dynamic> json) => AppPageReqVO(
  pageNo: (json['pageNo'] as num?)?.toInt(),
  pageSize: (json['pageSize'] as num?)?.toInt(),
  name: json['name'] as String?,
  platform: $enumDecodeNullable(_$AppPlatformEnumEnumMap, json['platform']),
  type: $enumDecodeNullable(_$AppTypeEnumEnumMap, json['type']),
  version: json['version'] as String?,
);

Map<String, dynamic> _$AppPageReqVOToJson(AppPageReqVO instance) =>
    <String, dynamic>{
      'pageNo': instance.pageNo,
      'pageSize': instance.pageSize,
      'name': instance.name,
      'platform': _$AppPlatformEnumEnumMap[instance.platform],
      'version': instance.version,
      'type': _$AppTypeEnumEnumMap[instance.type],
    };

AppChangelogPageReqVO _$AppChangelogPageReqVOFromJson(
  Map<String, dynamic> json,
) => AppChangelogPageReqVO(
  pageNo: (json['pageNo'] as num?)?.toInt(),
  pageSize: (json['pageSize'] as num?)?.toInt(),
  name: json['name'] as String?,
  platform: $enumDecodeNullable(_$AppPlatformEnumEnumMap, json['platform']),
  startVersion: json['startVersion'] as String?,
  endVersion: json['endVersion'] as String?,
  createTime: (json['createTime'] as num?)?.toInt(),
);

Map<String, dynamic> _$AppChangelogPageReqVOToJson(
  AppChangelogPageReqVO instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'name': instance.name,
  'platform': _$AppPlatformEnumEnumMap[instance.platform],
  'startVersion': instance.startVersion,
  'endVersion': instance.endVersion,
  'createTime': instance.createTime,
};

AppUpdateInfo _$AppUpdateInfoFromJson(Map<String, dynamic> json) =>
    AppUpdateInfo(
      hasUpdate: json['hasUpdate'] as bool,
      latestApp: json['latestApp'] == null
          ? null
          : AppApplicationRespVO.fromJson(
              json['latestApp'] as Map<String, dynamic>,
            ),
      currentApp: json['currentApp'] == null
          ? null
          : AppApplicationRespVO.fromJson(
              json['currentApp'] as Map<String, dynamic>,
            ),
      latestVersion: json['latestVersion'] == null
          ? null
          : AppVersionRespVO.fromJson(
              json['latestVersion'] as Map<String, dynamic>,
            ),
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      downloadUrl: json['downloadUrl'] as String?,
      downloadType: $enumDecodeNullable(
        _$DownloadTypeEnumEnumMap,
        json['downloadType'],
      ),
      changelogs: (json['changelogs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AppUpdateInfoToJson(AppUpdateInfo instance) =>
    <String, dynamic>{
      'hasUpdate': instance.hasUpdate,
      'latestApp': instance.latestApp,
      'currentApp': instance.currentApp,
      'latestVersion': instance.latestVersion,
      'forceUpdate': instance.forceUpdate,
      'downloadUrl': instance.downloadUrl,
      'downloadType': _$DownloadTypeEnumEnumMap[instance.downloadType],
      'changelogs': instance.changelogs,
    };
