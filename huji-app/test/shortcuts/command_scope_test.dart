import 'package:flutter_test/flutter_test.dart';
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
      expect(commandScopeMatches(CommandScope.videoPlayback, '/'), isFalse);
    });
  });
}
