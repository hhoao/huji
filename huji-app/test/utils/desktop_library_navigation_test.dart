import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/utils/desktop_library_navigation.dart';

void main() {
  group('desktopLibraryRecordRoute', () {
    test('SavedVideoRecord opens video player with encoded path', () {
      const path = '/home/user/Videos/export clip.mp4';
      final record = SavedVideoRecord(
        id: 'saved-1',
        sportType: SportType.pingpong,
        filePath: path,
        duration: 10,
        fileSize: 1000,
      );

      final route = desktopLibraryRecordRoute(record);
      expect(route, isNotNull);
      expect(route!.startsWith('${DesktopRoutes.videoPlayer}?'), isTrue);
      expect(
        route,
        contains('videoUrl=${Uri.encodeComponent(path)}'),
      );
      expect(
        route,
        contains('fileName=${Uri.encodeComponent('export clip.mp4')}'),
      );
    });

    test('SavedVideoRecord without filePath returns null', () {
      final record = SavedVideoRecord(
        id: 'saved-2',
        sportType: SportType.pingpong,
        duration: 0,
        fileSize: 0,
      );
      expect(desktopLibraryRecordRoute(record), isNull);
    });

    test('EdittingVideoRecord opens clip preview workflow', () {
      final record = EdittingVideoRecord(
        id: 'edit-1',
        processStatus: LocalVideoProcessStatusEnum.completed,
        sportType: SportType.pingpong,
        filePath: '/src.mp4',
        clipMode: ClipMode.existingVideo,
        allMatchSegments: const [],
        favoritesMatchSegments: const [],
      );

      expect(
        desktopLibraryRecordRoute(record),
        DesktopRoutes.clipPreviewPath('edit-1'),
      );
    });
  });
}
