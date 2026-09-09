import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // Boot starts behind the native splash window (see AppDelegate).
    // Go fully transparent BEFORE the first map so the empty xib window is
    // never visible around/behind the splash while the Flutter engine boots
    // (alpha 0 keeps the window ordered-in, so frames/vsync stay alive).
    // Dart reveals the window in completeBootSplashTransition()
    // (setOpacity(1) + focus) once the app has painted.
    alphaValue = 0

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
