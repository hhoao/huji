// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChunkInfo _$ChunkInfoFromJson(Map<String, dynamic> json) => ChunkInfo(
  partNumber: (json['partNumber'] as num).toInt(),
  startByte: (json['startByte'] as num).toInt(),
  endByte: (json['endByte'] as num).toInt(),
  eTag: json['eTag'] as String?,
  isUploaded: json['isUploaded'] as bool? ?? false,
  uploadedAt: (json['uploadedAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChunkInfoToJson(ChunkInfo instance) => <String, dynamic>{
  'partNumber': instance.partNumber,
  'startByte': instance.startByte,
  'endByte': instance.endByte,
  'eTag': instance.eTag,
  'isUploaded': instance.isUploaded,
  'uploadedAt': instance.uploadedAt,
};

UploadTask _$UploadTaskFromJson(Map<String, dynamic> json) => UploadTask(
  id: json['id'] as String,
  filePath: json['filePath'] as String,
  fileName: json['fileName'] as String,
  directory: json['directory'] as String?,
  contentType: json['contentType'] as String?,
  fileSize: (json['fileSize'] as num).toInt(),
  chunkSize: (json['chunkSize'] as num).toInt(),
  chunks: (json['chunks'] as List<dynamic>)
      .map((e) => ChunkInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
  uploadId: json['uploadId'] as String?,
  path: json['path'] as String?,
  status:
      $enumDecodeNullable(_$UploadStatusEnumMap, json['status']) ??
      UploadStatus.pending,
  progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  error: json['error'] as String?,
  createdAt: (json['createdAt'] as num).toInt(),
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
  configId: (json['configId'] as num?)?.toInt(),
  uploadUrl: json['uploadUrl'] as String?,
  remotePath: json['remotePath'] as String?,
  multipartUploaded: json['multipartUploaded'] as bool? ?? false,
);

Map<String, dynamic> _$UploadTaskToJson(UploadTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'directory': instance.directory,
      'contentType': instance.contentType,
      'fileSize': instance.fileSize,
      'chunkSize': instance.chunkSize,
      'chunks': instance.chunks,
      'uploadId': instance.uploadId,
      'path': instance.path,
      'status': _$UploadStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'error': instance.error,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'retryCount': instance.retryCount,
      'maxRetries': instance.maxRetries,
      'multipartUploaded': instance.multipartUploaded,
      'configId': instance.configId,
      'uploadUrl': instance.uploadUrl,
      'remotePath': instance.remotePath,
    };

const _$UploadStatusEnumMap = {
  UploadStatus.pending: 0,
  UploadStatus.uploading: 1,
  UploadStatus.paused: 2,
  UploadStatus.completed: 3,
  UploadStatus.failed: 4,
  UploadStatus.cancelled: 5,
};
