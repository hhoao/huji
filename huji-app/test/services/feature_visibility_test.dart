import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/feature_visibility.dart';
import 'package:huji_app/services/platform_capability.dart';

void main() {
  group('FeatureVisibility', () {
    test('defaults match mobile-friendly assumptions before load', () {
      final visibility = FeatureVisibility.instance;
      expect(visibility.enableCloudClip, isTrue);
      expect(visibility.showSubscriptionPage, isTrue);
      expect(visibility.showAdPage, isFalse);
      expect(visibility.cloudClipAvailable, isTrue);
      expect(
        visibility.localDetectionAvailable,
        PlatformCapability.supportsLocalDetection,
      );
      expect(
        visibility.recordingAvailable,
        PlatformCapability.supportsRecording,
      );
      expect(
        visibility.galleryAvailable,
        PlatformCapability.supportsGalleryAccess,
      );
    });
  });
}
