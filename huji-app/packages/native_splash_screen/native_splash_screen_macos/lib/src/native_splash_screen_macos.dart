import 'package:native_splash_screen_platform_interface/native_splash_screen_platform_interface.dart';

/// The Macos implementation of the [native_splash_screen] plugin.
///
/// This class registers itself as the platform-specific implementation of
/// [NativeSplashScreenPlatform] for Macos. It delegates the actual splash
/// screen closing logic to the native Macos code.
///
/// You do not need to use this class directly; it is automatically registered
/// when the plugin is used in a Flutter app on Macos.
class NativeSplashScreenMacos extends NativeSplashScreenPlatform {
  /// Registers this class as the default instance of [NativeSplashScreenPlatform].
  ///
  /// This method is called by the plugin's native registration logic
  /// and ensures that Macos-specific splash screen behavior is used.
  static void registerWith() {
    NativeSplashScreenPlatform.instance = NativeSplashScreenMacos();
  }

  /// Closes the splash screen with the given [animation] type.
  ///
  /// On Macos, this function triggers the native splash window to close
  /// using the specified [CloseAnimation] effect. If the splash screen is
  /// not currently visible, the method completes without throwing an error.
  ///
  /// See also:
  /// - [CloseAnimation] for available animation types.
  @override
  Future<void> close({required CloseAnimation animation}) {
    return NativeSplashScreenPlatform.instance.close(animation: animation);
  }
}
