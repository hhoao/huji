#include "include/native_splash_screen_windows/native_splash_screen_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "native_splash_screen_windows_plugin.h"

void NativeSplashScreenWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  native_splash_screen_windows::NativeSplashScreenWindowsPlugin::
      RegisterWithRegistrar(
          flutter::PluginRegistrarManager::GetInstance()
              ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
