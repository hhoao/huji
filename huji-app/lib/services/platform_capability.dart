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

  /// On-device inference (ncnn via huji_ncnn).
  static bool get supportsLocalDetection =>
      Platform.isAndroid || Platform.isIOS || isDesktop;

  /// Cloud-based detection (HTTP/WebSocket to backend).
  static bool get supportsCloudDetection => true;

  /// System gallery access (photo_manager / gal).
  static bool get supportsGalleryAccess => Platform.isAndroid || Platform.isIOS;

  /// Long-running background service (workmanager + flutter_background_service).
  static bool get supportsBackgroundService => Platform.isAndroid || Platform.isIOS;

  /// FFmpegKit Flutter plugin (Android/iOS/macOS). Linux/Windows desktop use
  /// the bundled static ffmpeg binary instead (no ffmpegkit native layer on
  /// those platforms for the pinned 4.3.2 version).
  ///
  /// Test VM (`flutter test`): macOS reports false as well — the test VM
  /// has no FFmpegKit platform channel, so the PATH-ffmpeg fallback keeps
  /// desktop integration tests working with a plain `ffmpeg` binary (same
  /// convention as GpuDeviceSelector's FLUTTER_TEST probe guard).
  static bool get supportsFFmpegKit =>
      (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) &&
      Platform.environment['FLUTTER_TEST'] != 'true';

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
