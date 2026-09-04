import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'enums.dart';
import 'method_channel_native_splash_screen.dart';

abstract class NativeSplashScreenPlatform extends PlatformInterface {
  NativeSplashScreenPlatform() : super(token: _token);

  static final Object _token = Object();
  static NativeSplashScreenPlatform _instance =
      MethodChannelNativeSplashScreen();

  /// The default instance of [NativeSplashScreenPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeSplashScreen].
  static NativeSplashScreenPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [NativeSplashScreenPlatform] when they register themselves.
  static set instance(NativeSplashScreenPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Call this function to close your app splash screen
  /// with a animation.
  Future<void> close({required CloseAnimation animation}) {
    throw UnimplementedError('close() has not been implemented.');
  }

  /// Re-center and raise the native splash above the main window.
  Future<void> ensureOnTop() {
    throw UnimplementedError('ensureOnTop() has not been implemented.');
  }
}
