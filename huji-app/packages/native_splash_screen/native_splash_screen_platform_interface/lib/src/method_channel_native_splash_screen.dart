import 'package:flutter/services.dart';

import 'native_splash_screen_platform_interface.dart';
import 'enums.dart';

/// An implementation of [NativeSplashScreenPlatform] that uses method channels.
class MethodChannelNativeSplashScreen extends NativeSplashScreenPlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _channel = const MethodChannel(
    'djeddi-yacine.github.io/native_splash_screen',
  );

  @override
  Future<void> close({required CloseAnimation animation}) {
    return _channel.invokeMethod<void>('close', <String, String>{
      "effect": animation.name,
    });
  }

  @override
  Future<void> ensureOnTop() {
    return _channel.invokeMethod<void>('ensureOnTop');
  }
}
