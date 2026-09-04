import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/router/modules/desktop.dart';

void main() {
  group('routeMatchesTemplate', () {
    test('param segment matches any single segment', () {
      expect(
        DesktopRoutes.routeMatchesTemplate(
          '/clip/abc-123/edit',
          DesktopRoutes.clipEdit,
        ),
        isTrue,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate(
          '/clip/foo%20bar/edit',
          DesktopRoutes.clipEdit,
        ),
        isTrue,
      );
    });

    test('mismatched literal segment, length, or null fails', () {
      expect(
        DesktopRoutes.routeMatchesTemplate('/clip/new', DesktopRoutes.clipEdit),
        isFalse,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate(
          '/clip/a/edit/extra',
          DesktopRoutes.clipEdit,
        ),
        isFalse,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate(null, DesktopRoutes.clipEdit),
        isFalse,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate('', DesktopRoutes.clipEdit),
        isFalse,
      );
    });
  });

  group('route shape predicates', () {
    test('isClipEditRoute', () {
      expect(DesktopRoutes.isClipEditRoute('/clip/abc/edit'), isTrue);
      expect(DesktopRoutes.isClipEditRoute('/clip/abc/preview'), isFalse);
      expect(DesktopRoutes.isClipEditRoute('/clip/new'), isFalse);
      expect(DesktopRoutes.isClipEditRoute(null), isFalse);
    });

    test('isClipPreviewRoute', () {
      expect(DesktopRoutes.isClipPreviewRoute('/clip/abc/preview'), isTrue);
      expect(DesktopRoutes.isClipPreviewRoute('/clip/abc/edit'), isFalse);
      expect(DesktopRoutes.isClipPreviewRoute(null), isFalse);
    });

    test('isVideoPlayerRoute', () {
      expect(DesktopRoutes.isVideoPlayerRoute(DesktopRoutes.videoPlayer), isTrue);
      expect(DesktopRoutes.isVideoPlayerRoute('/video/other'), isFalse);
      expect(DesktopRoutes.isVideoPlayerRoute(null), isFalse);
    });
  });

  group('isWorkspaceRoute', () {
    test('workspace-branch routes match, others do not', () {
      expect(DesktopRoutes.isWorkspaceRoute('/workspace'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute(DesktopRoutes.videoPlayer), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/video/player?videoUrl=x'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/clip/new'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/clip/abc/edit'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/clip/abc/preview'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute(DesktopRoutes.videoCompress), isTrue);
      // Legacy fallback shape: any /clip/... path.
      expect(DesktopRoutes.isWorkspaceRoute('/clip/type-selection'), isTrue);
      // Fixed-nav routes.
      expect(DesktopRoutes.isWorkspaceRoute('/'), isFalse);
      expect(DesktopRoutes.isWorkspaceRoute('/tasks'), isFalse);
      expect(DesktopRoutes.isWorkspaceRoute('/settings'), isFalse);
    });
  });
}
