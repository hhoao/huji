#ifndef FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_C_API_H_

#include <cstdint>
#include <string>

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

// External variables that will be set directly by the generator
extern int native_splash_screen_width;
extern int native_splash_screen_height;
extern const wchar_t* native_splash_screen_title;
extern bool native_splash_screen_with_animation;
extern const wchar_t* native_splash_screen_window_class;

// Pixel array externally defined (must be uint32_t* or uint8_t* casted)
extern const uint32_t* native_splash_screen_image_pixels;
extern int native_splash_screen_image_width;
extern int native_splash_screen_image_height;

// Function declarations for splash screen operations
FLUTTER_PLUGIN_EXPORT void ShowSplashScreen();
FLUTTER_PLUGIN_EXPORT void CloseSplashScreen(const std::string& effect);
// Re-center the separate splash window and raise it above the main window
// after the main maps. No-op in overlay mode (already stacked in-window).
FLUTTER_PLUGIN_EXPORT void EnsureSplashOnTop();

// Overlay mode: stack the splash over the Flutter view inside the app's own
// window instead of a separate top-level splash window. [host_window] is the
// runner's top-level HWND (passed as void* to keep this header windows.h-free).
// Call in the Win32 runner in place of ShowSplashScreen(); dismiss from Dart via
// close().
FLUTTER_PLUGIN_EXPORT void AttachSplashOverlay(void* host_window);
// Resize/re-raise the in-window overlay to the host client area (no-op if
// overlay mode is inactive). Call from the runner on WM_SIZE / chrome changes.
FLUTTER_PLUGIN_EXPORT void ResizeSplashOverlay(void* host_window);

void CloseSplashWindowWithoutAnimation();
void CloseSplashWindowWithFade();
void CloseSplashWindowSlideUpFade();
void CloseSplashWindowSlideDownFade();

// Plugin registration function
FLUTTER_PLUGIN_EXPORT void
NativeSplashScreenWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_C_API_H_