import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/shortcuts/command_scope.dart';

void main() {
  group('isPrecisionEditRoute', () {
    test('matches desktop precision-edit paths', () {
      expect(isPrecisionEditRoute('/clip/abc-123/edit'), isTrue);
      expect(isPrecisionEditRoute('/clip/foo%20bar/edit'), isTrue);
    });

    test('rejects other routes', () {
      expect(isPrecisionEditRoute(null), isFalse);
      expect(isPrecisionEditRoute(''), isFalse);
      expect(isPrecisionEditRoute('/'), isFalse);
      expect(isPrecisionEditRoute('/clip/new'), isFalse);
      expect(isPrecisionEditRoute('/clip/id/preview'), isFalse);
      expect(isPrecisionEditRoute('/clip/id/edit/extra'), isFalse);
    });
  });

  group('isPreviewExportRoute', () {
    test('matches preview paths', () {
      expect(isPreviewExportRoute('/clip/abc/preview'), isTrue);
    });

    test('rejects non-preview paths', () {
      expect(isPreviewExportRoute('/clip/abc/edit'), isFalse);
      expect(isPreviewExportRoute('/clip/new'), isFalse);
    });
  });

  group('isVideoPlaybackRoute', () {
    test('matches configured playback routes', () {
      expect(isVideoPlaybackRoute('/clip/a/preview'), isTrue);
      expect(isVideoPlaybackRoute('/clip/new'), isTrue);
      expect(isVideoPlaybackRoute('/tools/video-compress'), isTrue);
      expect(isVideoPlaybackRoute('/clip/a/edit'), isTrue);
      expect(isVideoPlaybackRoute('/video/player'), isTrue);
    });
  });

  group('commandScopeMatches', () {
    test('global scope always matches', () {
      expect(commandScopeMatches(CommandScope.global, '/'), isTrue);
      expect(commandScopeMatches(CommandScope.global, null), isTrue);
    });

    test('precision edit scope only matches edit route', () {
      expect(
        commandScopeMatches(CommandScope.precisionEdit, '/clip/x/edit'),
        isTrue,
      );
      expect(commandScopeMatches(CommandScope.precisionEdit, '/'), isFalse);
    });

    test('video playback scope matches all playback surfaces', () {
      expect(
        commandScopeMatches(CommandScope.videoPlayback, '/clip/x/preview'),
        isTrue,
      );
      expect(commandScopeMatches(CommandScope.videoPlayback, '/clip/new'), isTrue);
      expect(
        commandScopeMatches(CommandScope.videoPlayback, '/tools/video-compress'),
        isTrue,
      );
      expect(
        commandScopeMatches(CommandScope.videoPlayback, '/clip/x/edit'),
        isTrue,
      );
      expect(
        commandScopeMatches(CommandScope.videoPlayback, '/video/player'),
        isTrue,
      );
      expect(commandScopeMatches(CommandScope.videoPlayback, '/'), isFalse);
    });
  });

  group('playback route registration completeness', () {
    // Every desktop playback surface must be scope-registered. A new page
    // that plays video is added to DesktopRoutes AND this list; forgetting
    // the scope half fails here (the /video/player bug of 2026-09-04).
    const playbackSurfaces = <String, String>{
      'clipEdit': '/clip/sample-id/edit',
      'clipPreview': '/clip/sample-id/preview',
      'videoPlayer': '/video/player',
      'clipNew': '/clip/new',
      'videoCompress': '/tools/video-compress',
    };

    test('every playback surface route matches videoPlayback scope', () {
      for (final entry in playbackSurfaces.entries) {
        expect(
          commandScopeMatches(CommandScope.videoPlayback, entry.value),
          isTrue,
          reason:
              '${entry.key} (${entry.value}) is a playback surface but is '
              'not covered by CommandScope.videoPlayback — register it in '
              'isVideoPlaybackRoute (command_scope.dart).',
        );
      }
    });

    test('constants stay in sync with the instantiated sample routes', () {
      expect(DesktopRoutes.clipEditPath('sample-id'),
          playbackSurfaces['clipEdit']);
      expect(DesktopRoutes.clipPreviewPath('sample-id'),
          playbackSurfaces['clipPreview']);
      expect(DesktopRoutes.videoPlayer, playbackSurfaces['videoPlayer']);
      expect(DesktopRoutes.clipNew, playbackSurfaces['clipNew']);
      expect(DesktopRoutes.videoCompress, playbackSurfaces['videoCompress']);
    });
  });
}
