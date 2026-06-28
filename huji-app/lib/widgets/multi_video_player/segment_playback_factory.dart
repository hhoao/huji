import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/widgets/multi_video_player/models/video_playback_item.dart';

List<VideoPlaybackItem> createPlaybackItemsFromSegments({
  required String recordId,
  required String videoPath,
  required List<SegmentInfo> segments,
}) {
  return [
    for (var i = 0; i < segments.length; i++)
      VideoPlaybackItem(
        id: '${recordId}_segment_$i',
        name: '回合 ${i + 1}',
        videoPath: videoPath,
        startTimeMs: (segments[i].startSeconds * 1000).round(),
        endTimeMs: (segments[i].endSeconds * 1000).round(),
        totalDurationMs: (segments[i].endSeconds * 1000).round(),
        enabled: true,
      ),
  ];
}
