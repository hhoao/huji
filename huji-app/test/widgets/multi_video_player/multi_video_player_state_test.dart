import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_state.dart';
import 'package:huji_app/widgets/multi_video_player/models/video_playback_item.dart';

VideoPlaybackItem _item({
  required int startTimeMs,
  required int totalDurationMs,
  int? endTimeMs,
  bool enabled = true,
}) {
  return VideoPlaybackItem(
    videoPath: '/tmp/clip.mp4',
    id: 'item-$startTimeMs-$totalDurationMs',
    name: 'clip',
    startTimeMs: startTimeMs,
    endTimeMs: endTimeMs,
    totalDurationMs: totalDurationMs,
    enabled: enabled,
  );
}

void main() {
  group('MultiVideoPlayerState.totalDurationMs', () {
    test('stays non-negative when an item duration is not known yet', () {
      // 播放项已知起点 5s，但视频总时长尚未探测到（0）——贡献值不能为负。
      final state = MultiVideoPlayerState(
        items: [_item(startTimeMs: 5000, totalDurationMs: 0)],
      );

      expect(state.totalDurationMs, 0);
      expect(state.totalDuration!.inMilliseconds, 0);
    });

    test('ignores negative contributions from a bad segment', () {
      final state = MultiVideoPlayerState(
        items: [_item(startTimeMs: 8000, totalDurationMs: 3000)],
      );

      expect(state.totalDurationMs, 0);
    });

    test('sums known durations normally', () {
      final state = MultiVideoPlayerState(
        items: [
          _item(startTimeMs: 0, totalDurationMs: 10000, endTimeMs: 4000),
          _item(startTimeMs: 2000, totalDurationMs: 10000, endTimeMs: 5000),
        ],
      );

      expect(state.totalDurationMs, 4000 + 3000);
    });

    test('clamping current time against total duration never throws', () {
      // 复现 fullscreen_video_page 的 `currentTime.clamp(0, totalDuration)`
      // 崩溃：totalDuration 为负时 int.clamp 抛 ArgumentError。
      final state = MultiVideoPlayerState(
        items: [_item(startTimeMs: 5000, totalDurationMs: 0)],
      );

      final total = state.totalDuration?.inMilliseconds ?? 1;
      expect(() => 0.clamp(0, total), returnsNormally);
    });
  });
}
