import 'package:native_splash_screen_platform_interface/native_splash_screen_platform_interface.dart';

/// The Windows implementation of the [native_splash_screen] plugin.
///
/// This class registers itself as the platform-specific implementation of
/// [NativeSplashScreenPlatform] for Windows. It delegates the actual splash
/// screen closing logic to the native Windows code.
///
/// You do not need to use this class directly; it is automatically registered
/// when the plugin is used in a Flutter app on Windows.
class NativeSplashScreenWindows extends NativeSplashScreenPlatform {
  /// Registers this class as the default instance of [NativeSplashScreenPlatform].
  ///
  /// This method is called by the plugin's native registration logic
  /// and ensures that Windows-specific splash screen behavior is used.
  static void registerWith() {
    NativeSplashScreenPlatform.instance = NativeSplashScreenWindows();
  }

  /// Closes the splash screen with the given [animation] type.
  ///
  /// On Windows, this function triggers the native splash window to close
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
