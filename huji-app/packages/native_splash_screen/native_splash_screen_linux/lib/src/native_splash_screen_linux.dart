import 'package:flutter/services.dart';
import 'package:native_splash_screen_platform_interface/native_splash_screen_platform_interface.dart';

/// The Linux implementation of the [native_splash_screen] plugin.
///
/// This class registers itself as the platform-specific implementation of
/// [NativeSplashScreenPlatform] for Linux. It delegates the actual splash
/// screen closing logic to the native Linux code.
///
/// You do not need to use this class directly; it is automatically registered
/// when the plugin is used in a Flutter app on Linux.
class NativeSplashScreenLinux extends NativeSplashScreenPlatform {
  static const MethodChannel _channel = MethodChannel(
    'djeddi-yacine.github.io/native_splash_screen',
  );

  /// Registers this class as the default instance of [NativeSplashScreenPlatform].
  ///
  /// This method is called by the plugin's native registration logic
  /// and ensures that Linux-specific splash screen behavior is used.
  static void registerWith() {
    NativeSplashScreenPlatform.instance = NativeSplashScreenLinux();
  }

  /// Closes the splash screen with the given [animation] type.
  ///
  /// On Linux, this function triggers the native splash window to close
  /// using the specified [CloseAnimation] effect. If the splash screen is
  /// not currently visible, the method completes without throwing an error.
  ///
  /// See also:
  /// - [CloseAnimation] for available animation types.
  @override
  Future<void> close({required CloseAnimation animation}) {
    return _channel.invokeMethod<void>('close', <String, String>{
      'effect': animation.name,
    });
  }

  @override
  Future<void> ensureOnTop() {
    return _channel.invokeMethod<void>('ensureOnTop');
  }
}
