import Cocoa
import FlutterMacOS

public class NativeSplashScreenMacosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "djeddi-yacine.github.io/native_splash_screen", binaryMessenger: registrar.messenger)
        let instance = NativeSplashScreenMacosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "close":
                var effect = ""
                if let args = call.arguments as? [String: Any], let effectArg = args["effect"] as? String {
                    effect = effectArg
                }
                NativeSplashScreen.close(effect: effect)
                result(nil)
            case "ensureOnTop":
                NativeSplashScreen.ensureOnTop()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
        }
    }
}
