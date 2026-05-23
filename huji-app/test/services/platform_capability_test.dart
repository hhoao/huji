import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/platform_capability.dart';

void main() {
  group('PlatformCapability', () {
    test('Linux: no recording, no local detection, no gallery, no background service', () {
      if (!Platform.isLinux) return; // skip on other platforms
      expect(PlatformCapability.supportsRecording, isFalse);
      expect(PlatformCapability.supportsLocalDetection, isFalse);
      expect(PlatformCapability.supportsGalleryAccess, isFalse);
      expect(PlatformCapability.supportsBackgroundService, isFalse);
      expect(PlatformCapability.supportsCloudDetection, isTrue);
      expect(PlatformCapability.supportsFFmpegKit, isFalse);
    });

    test('Android: full feature support', () {
      if (!Platform.isAndroid) return; // skip on other platforms
      expect(PlatformCapability.supportsRecording, isTrue);
      expect(PlatformCapability.supportsLocalDetection, isTrue);
      expect(PlatformCapability.supportsGalleryAccess, isTrue);
      expect(PlatformCapability.supportsBackgroundService, isTrue);
      expect(PlatformCapability.supportsCloudDetection, isTrue);
      expect(PlatformCapability.supportsFFmpegKit, isTrue);
    });
  });
}
