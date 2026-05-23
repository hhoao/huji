// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_task_manager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IsolateDownloadParams _$IsolateDownloadParamsFromJson(
  Map<String, dynamic> json,
) => IsolateDownloadParams(
  rootToken: rootTokenFromJson(json['rootToken'] as RootIsolateToken),
  downloadTask: DownloadTask.fromJson(
    json['downloadTask'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$IsolateDownloadParamsToJson(
  IsolateDownloadParams instance,
) => <String, dynamic>{
  'rootToken': rootTokenToJson(instance.rootToken),
  'downloadTask': instance.downloadTask.toJson(),
};
