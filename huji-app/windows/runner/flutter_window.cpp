#include "flutter_window.h"

#include <optional>

#include <native_splash_screen_windows/native_splash_screen_windows_plugin_c_api.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Overlay-mode boot splash: stack the splash over the Flutter view in THIS
  // window (instead of a separate top-level splash window). Dart fades it out
  // via close() once the app has painted. Matches the Linux runner.
  AttachSplashOverlay(GetHandle());

  // Drop the native caption so the first Show paints full-client surface+logo
  // (Linux starts undecorated). Dart/window_manager then owns the chrome.
  HWND hwnd = GetHandle();
  DWORD style = GetWindowLong(hwnd, GWL_STYLE);
  SetWindowLong(hwnd, GWL_STYLE, style & ~WS_CAPTION);
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  ResizeSplashOverlay(hwnd);

  // Show immediately so the overlay is visible during Dart bootstrap - do not
  // wait for the first Flutter frame (that would flash a blank window).
  Show();

  // Flutter can complete the first frame before plugins finish wiring. Keep a
  // pending frame so the engine stays warm under the splash.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (message == WM_SIZE) {
      // Keep the splash overlay covering the client when chrome/DPI changes,
      // even if Flutter/window_manager already handled the size message.
      ResizeSplashOverlay(hwnd);
    }
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_SIZE: {
      const LRESULT result =
          Win32Window::MessageHandler(hwnd, message, wparam, lparam);
      ResizeSplashOverlay(hwnd);
      return result;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
