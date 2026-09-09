#ifndef FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace native_splash_screen_windows {

class NativeSplashScreenWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  NativeSplashScreenWindowsPlugin();

  virtual ~NativeSplashScreenWindowsPlugin();

  // Disallow copy and assign.
  NativeSplashScreenWindowsPlugin(const NativeSplashScreenWindowsPlugin&) =
      delete;
  NativeSplashScreenWindowsPlugin& operator=(
      const NativeSplashScreenWindowsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace native_splash_screen_windows

#endif  // FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_H_
