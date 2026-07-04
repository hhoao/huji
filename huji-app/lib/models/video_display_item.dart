import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/utils/file_utils.dart';

enum VideoSource { remote, local }

class VideoDisplayItem {
  final VideoSource source;
  final String fileName;
  final String playUrl;
  final String? thumbnailUrl;
  final String? thumbnailPath;
  final int size;
  final double duration;
  final int createTime;
  final VideoProcessType? videoProcessType;
  final SportType? sportType;
  final int? expireTime;

  /// 本地视频记录 ID，用于删除
  final String? localRecordId;

  VideoDisplayItem({
    required this.source,
    required this.fileName,
    required this.playUrl,
    this.thumbnailUrl,
    this.thumbnailPath,
    required this.size,
    required this.duration,
    required this.createTime,
    this.videoProcessType,
    this.sportType,
    this.expireTime,
    this.localRecordId,
  });

  bool get isLocal => source == VideoSource.local;

  bool get isExpired =>
      expireTime != null && expireTime! < DateTime.now().millisecondsSinceEpoch;

  factory VideoDisplayItem.fromRemote(VideoInfoRespVO video) {
    return VideoDisplayItem(
      source: VideoSource.remote,
      fileName: video.fileName,
      playUrl: video.fileUrl,
      thumbnailUrl: video.thumbnailUrl,
      size: video.size,
      duration: video.duration,
      createTime: video.createTime,
      videoProcessType: video.videoProcessType,
      sportType: video.sportType,
      expireTime: video.expireTime,
    );
  }

  factory VideoDisplayItem.fromLocal(SavedVideoRecord record) {
    return VideoDisplayItem(
      source: VideoSource.local,
      fileName: fileNameWithoutExtensionFromPath(record.filePath ?? ''),
      playUrl: record.filePath ?? '',
      thumbnailPath: record.thumbnailPath,
      size: record.fileSize,
      duration: record.duration,
      createTime: record.createdAt,
      videoProcessType: record.videoProcessType,
      sportType: record.sportType,
      localRecordId: record.id,
    );
  }
}
