import 'dart:io';

/// Centralized feature flags by platform.
///
/// Use these instead of scattering `Platform.isAndroid` checks throughout
/// the codebase. UI layers call these to decide whether to render entries
/// for unsupported features.
class PlatformCapability {
  PlatformCapability._();

  /// Recording / continuous shooting (uses camera + camerawesome).
  static bool get supportsRecording => Platform.isAndroid || Platform.isIOS;

  /// On-device YOLO inference (ultralytics_yolo).
  static bool get supportsLocalDetection =>
      Platform.isAndroid || Platform.isIOS || Platform.isLinux;

  /// Cloud-based detection (HTTP/WebSocket to backend).
  static bool get supportsCloudDetection => true;

  /// System gallery access (photo_manager / gal).
  static bool get supportsGalleryAccess => Platform.isAndroid || Platform.isIOS;

  /// Long-running background service (workmanager + flutter_background_service).
  static bool get supportsBackgroundService => Platform.isAndroid || Platform.isIOS;

  /// FFmpegKit Flutter plugin (Android/iOS only). On desktop we use Process.run.
  static bool get supportsFFmpegKit => Platform.isAndroid || Platform.isIOS;

  /// Native video trimmer plugin (Android/iOS). Desktop falls back to ffmpeg.
  static bool get supportsNativeTrimmer => Platform.isAndroid || Platform.isIOS;

  /// Native APK installer (Android only, used for self-update on mobile).
  static bool get supportsApkInstaller => Platform.isAndroid;

  /// Whether the platform is a desktop OS.
  static bool get isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  /// Video player — Android/iOS via video_player, desktop via media_kit.
  static bool get supportsVideoPlayer => true;
}
