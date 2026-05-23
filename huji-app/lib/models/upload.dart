import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload.g.dart';
part 'upload.freezed.dart';

@JsonEnum(valueField: 'value')
enum UploadStatus {
  pending(0), // 等待上传
  uploading(1), // 上传中
  paused(2), // 暂停
  completed(3), // 完成
  failed(4), // 失败
  cancelled(5); // 取消

  const UploadStatus(this.value);
  final int value;
}

@freezed
@JsonSerializable()
class ChunkInfo with _$ChunkInfo {
  @override
  final int partNumber;
  @override
  final int startByte;
  @override
  final int endByte;
  @override
  final String? eTag;
  @override
  final bool isUploaded;
  @override
  final int? uploadedAt;

  ChunkInfo({
    required this.partNumber,
    required this.startByte,
    required this.endByte,
    this.eTag,
    this.isUploaded = false,
    this.uploadedAt,
  });

  factory ChunkInfo.fromJson(Map<String, dynamic> json) =>
      _$ChunkInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ChunkInfoToJson(this);
}

@freezed
@JsonSerializable()
class UploadTask with _$UploadTask {
  @override
  final String id;
  @override
  final String filePath;
  @override
  final String fileName;
  @override
  final String? directory;
  @override
  final String? contentType;
  @override
  final int fileSize;
  @override
  final int chunkSize;
  @override
  final List<ChunkInfo> chunks;
  @override
  String? uploadId;
  @override
  String? path;
  @override
  UploadStatus status;
  @override
  double progress;
  @override
  String? error;
  @override
  final int createdAt;
  @override
  int? updatedAt;
  @override
  int retryCount;
  @override
  final int maxRetries;
  @override
  bool multipartUploaded;

  // after upload
  @override
  int? configId;
  @override
  String? uploadUrl;
  @override
  String? remotePath;

  UploadTask({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.directory,
    this.contentType,
    required this.fileSize,
    required this.chunkSize,
    required this.chunks,
    this.uploadId,
    this.path,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.error,
    required this.createdAt,
    this.updatedAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.configId,
    this.uploadUrl,
    this.remotePath,
    this.multipartUploaded = false,
  });

  factory UploadTask.fromJson(Map<String, dynamic> json) =>
      _$UploadTaskFromJson(json);
  Map<String, dynamic> toJson() => _$UploadTaskToJson(this);

  // 获取已上传的分片数量
  int get uploadedChunksCount => chunks.where((c) => c.isUploaded).length;

  // 获取总分片数量
  int get totalChunksCount => chunks.length;

  // 检查是否可以重试
  bool get canRetry =>
      retryCount < maxRetries && status != UploadStatus.completed;

  // 检查是否所有分片都已上传
  bool get allChunksUploaded => uploadedChunksCount == totalChunksCount;
}
