import 'package:flutter/foundation.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/constants/app_setting_constants.dart';
import 'package:huji_app/services/platform_capability.dart';

/// Centralized remote + platform feature visibility.
///
/// Remote toggles are loaded once at startup via [load] and can be refreshed.
/// UI should combine these with [PlatformCapability] for hardware-gated features.
class FeatureVisibility extends ChangeNotifier {
  FeatureVisibility._();

  static final FeatureVisibility instance = FeatureVisibility._();

  bool _enableCloudClip = true;
  bool _showSubscriptionPage = true;
  bool _showAdPage = false;
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get enableCloudClip => _enableCloudClip;
  bool get showSubscriptionPage => _showSubscriptionPage;
  bool get showAdPage => _showAdPage;

  bool get cloudClipAvailable =>
      _enableCloudClip && PlatformCapability.supportsCloudDetection;

  bool get localDetectionAvailable => PlatformCapability.supportsLocalDetection;

  bool get recordingAvailable => PlatformCapability.supportsRecording;

  bool get galleryAvailable => PlatformCapability.supportsGalleryAccess;

  Future<void> load() async {
    try {
      final results = await Future.wait<bool>([
        Api.appSetting.getSettingValueAsBoolean(
          AppSettingCodes.enableCloudClip,
        ),
        Api.appSetting.getSettingValueAsBoolean(
          AppSettingCodes.showSubscriptionPage,
        ),
        Api.appSetting.getSettingValueAsBoolean(AppSettingCodes.showAdPage),
      ]);
      _enableCloudClip = results[0];
      _showSubscriptionPage = results[1];
      _showAdPage = results[2];
    } catch (_) {
      // Keep defaults when offline or API unavailable.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() => load();
}
