import 'package:native_splash_screen_platform_interface/native_splash_screen_platform_interface.dart';

/// The Base plugin implementation.
///
/// This class registers itself as the platform-specific implementation of
/// [NativeSplashScreenPlatform] for each platform. It delegates the actual splash
/// screen closing logic to the native platform code.
NativeSplashScreenPlatform get _platform => NativeSplashScreenPlatform.instance;

/// Closes the native splash screen with an optional animation.
///
/// This function should be called from your Flutter application once it has initialized
/// and is ready to present its UI. The splash screen will be dismissed using the specified
/// animation, depending on the platform implementation.
///
/// If the splash screen is already closed or was never shown, calling this method has no effect.
/// It is safe to call multiple times and will never throw.
///
/// Platform-specific implementations may vary, but all must support the [CloseAnimation] enum.
///
/// Example usage:
///
/// ```dart
/// // import the package.
/// import 'package:native_splash_screen/native_splash_screen.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   runApp(MyApp());
/// }
///
/// // Then in you first page add this so the splash screen close
/// // after flutter first frame renders.
/// @override
/// void initState() {
///   super.initState();
///   // Close splash screen with fade animation.
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     close(animation: CloseAnimation.fade);
///   });
/// }
///
/// ```
///
/// - [animation]: The animation style to use when closing the splash screen.
///   See [CloseAnimation] for supported values (e.g., fade).
Future<void> close({required CloseAnimation animation}) async {
  return _platform.close(animation: animation);
}

/// Keeps the native splash above the Flutter main window during startup.
Future<void> ensureOnTop() async {
  return _platform.ensureOnTop();
}
