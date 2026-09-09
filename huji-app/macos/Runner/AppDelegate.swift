import Cocoa
import FlutterMacOS
import native_splash_screen_macos

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Show the native splash before any window appears, so the user never
    // sees the empty xib window while the Flutter engine boots. Dart fades
    // the splash away in completeBootSplashTransition() (boot_splash.dart).
    NativeSplashScreen.configurationProvider = NativeSplashScreenConfiguration()
    NativeSplashScreen.show()
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register the OpenGL framework bundle by URL, then force-load it.
    // media_kit_video's TextureHW.initMPV() resolves OpenGL function pointers on
    // a background Worker thread via CFBundleGetBundleWithIdentifier. When that
    // is the first lookup for a lazily-loaded framework (OpenGL is not loaded at
    // startup), CFBundle walks the dyld image list, which races with concurrent
    // dlopen (ffmpeg/media libs) and segfaults on an image entry with a null
    // path. CFBundleCreate registers the bundle in the ID table directly, so
    // later lookups are cache hits and never walk the image list.
    if let bundle = CFBundleCreate(
      kCFAllocatorDefault,
      URL(fileURLWithPath: "/System/Library/Frameworks/OpenGL.framework") as CFURL
    ) {
      // Force-load the framework now, on the main thread.
      _ = CFBundleGetFunctionPointerForName(bundle, "glGetString" as CFString)
    }
    super.applicationDidFinishLaunching(notification)
  }
}
