import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/desktop/desktop_video_card.dart';

void main() {
  late HujiLocalizations l10n;
  const cs = ColorScheme.dark();

  setUp(() async {
    l10n = await HujiLocalizations.delegate.load(const Locale('zh'));
  });

  test('processing record shows detecting label', () {
    final record = ProcessVideoRecord(
      id: 'p1',
      processStatus: LocalVideoProcessStatusEnum.processing,
      sportType: SportType.pingpong,
      filePath: '/a.mp4',
      videoClipConfigReqVo: PingPongVideoClipConfigReqVo(),
      taskId: 'task-1',
    );

    expect(
      desktopLibraryRecordBadgeStyle(record, l10n, cs).label,
      l10n.desktopLibraryBadgeProcessing,
    );
  });

  test('saved export shows exported type label', () {
    final record = SavedVideoRecord(
      id: 's1',
      sportType: SportType.pingpong,
      filePath: '/out.mp4',
      duration: 1,
      fileSize: 1,
      videoProcessType: VideoProcessType.exported,
    );

    expect(
      desktopLibraryRecordBadgeStyle(record, l10n, cs).label,
      l10n.desktopLibraryBadgeExported,
    );
  });

  test('editing record shows clip project label', () {
    final record = EdittingVideoRecord(
      id: 'e1',
      processStatus: LocalVideoProcessStatusEnum.completed,
      sportType: SportType.pingpong,
      filePath: '/src.mp4',
      clipMode: ClipMode.existingVideo,
      allMatchSegments: const [],
      favoritesMatchSegments: const [],
    );

    expect(
      desktopLibraryRecordBadgeStyle(record, l10n, cs).label,
      l10n.desktopLibraryBadgeClipProject,
    );
  });

  test('duration sums editing segments', () {
    final record = EdittingVideoRecord(
      id: 'e2',
      processStatus: LocalVideoProcessStatusEnum.completed,
      sportType: SportType.pingpong,
      filePath: '/src.mp4',
      clipMode: ClipMode.existingVideo,
      allMatchSegments: [
        SegmentInfo(
          actionType: ActionType.playBall,
          startSeconds: 0,
          endSeconds: 10,
        ),
        SegmentInfo(
          actionType: ActionType.playBall,
          startSeconds: 20,
          endSeconds: 25,
        ),
      ],
      favoritesMatchSegments: const [],
    );

    expect(localVideoRecordDurationSeconds(record), 15);
  });

  test('created date label uses month-day in Chinese', () {
    final ms = DateTime(2026, 9, 28).millisecondsSinceEpoch;
    expect(
      desktopLibraryRecordCreatedDateLabel(ms, languageCode: 'zh'),
      '9月28日',
    );
  });
}
