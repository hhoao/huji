#include "native_splash_screen_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <wingdi.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <memory>
#include <sstream>
#include <string>

#include "include/native_splash_screen_windows/native_splash_screen_windows_plugin_c_api.h"

#ifndef max
#define max(a, b) (((a) > (b)) ? (a) : (b))
#endif

namespace native_splash_screen_windows {

// static
void NativeSplashScreenWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(),
          "djeddi-yacine.github.io/native_splash_screen",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NativeSplashScreenWindowsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NativeSplashScreenWindowsPlugin::NativeSplashScreenWindowsPlugin() {}

NativeSplashScreenWindowsPlugin::~NativeSplashScreenWindowsPlugin() {}

void NativeSplashScreenWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("close") == 0) {
    std::string effect;

    // Safely get the arguments map pointer
    const auto* arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());

    if (arguments) {
      auto it = arguments->find(flutter::EncodableValue("effect"));
      if (it != arguments->end()) {
        const std::string* effect_ptr = std::get_if<std::string>(&(it->second));
        if (effect_ptr) {
          effect = *effect_ptr;
        } else {
          result->Error("INVALID_ARGUMENT",
                        "'effect' argument must be a String, but received "
                        "non-String type.",
                        nullptr);
          return;
        }
      }
    }
    CloseSplashScreen(effect);
    result->Success();
  } else if (method_call.method_name().compare("ensureOnTop") == 0) {
    EnsureSplashOnTop();
    result->Success();
  } else {
    result->NotImplemented();
  }
}
}  // namespace native_splash_screen_windows

// Internal state
static HWND g_splash_window = nullptr;
static bool g_splash_shown = false;
static HBITMAP g_splash_bitmap = nullptr;
static void* g_bitmap_bits = nullptr;

// Overlay-mode state: a layered child window stacked over the Flutter view in
// the app's own window, used instead of the separate g_splash_window. Only one
// of the two is ever active. See AttachSplashOverlay().
static HWND g_overlay_window = nullptr;
static HBITMAP g_overlay_bitmap = nullptr;
static void* g_overlay_bits = nullptr;
static void CloseOverlay(const std::string& effect);

LRESULT CALLBACK SplashWndProc(HWND hwnd,
                               UINT uMsg,
                               WPARAM wParam,
                               LPARAM lParam) {
  switch (uMsg) {
    case WM_DESTROY:
      if (hwnd == g_splash_window) {
        g_splash_window = nullptr;
        g_splash_shown = false;
      }
      return 0;
    case WM_ERASEBKGND:
      return 1;
    default:
      return DefWindowProcW(hwnd, uMsg, wParam, lParam);
  }
}

static HBITMAP CreateSplashBitmap(HDC hdc,
                                  int width,
                                  int height,
                                  void** ppBits) {
  BITMAPINFO bmi = {0};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = width;
  bmi.bmiHeader.biHeight = -height;  // top-down
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;
  return CreateDIBSection(hdc, &bmi, DIB_RGB_COLORS, ppBits, nullptr, 0);
}

static uint32_t ConvertARGBtoPremultipliedBGRA(uint32_t argb) {
  BYTE a = (argb >> 24) & 0xFF;
  BYTE r = (argb >> 16) & 0xFF;
  BYTE g = (argb >> 8) & 0xFF;
  BYTE b = argb & 0xFF;

  if (a == 0)
    return 0;

  float alpha = a / 255.0f;
  return ((uint32_t)(b * alpha)) | ((uint32_t)(g * alpha) << 8) |
         ((uint32_t)(r * alpha) << 16) | ((uint32_t)a << 24);
}

static void RenderSplashContent(uint32_t* pixels) {
  if (!pixels || !native_splash_screen_image_pixels)
    return;

  int x_offset =
      (native_splash_screen_width - native_splash_screen_image_width) / 2;
  int y_offset =
      (native_splash_screen_height - native_splash_screen_image_height) / 2;
  if (x_offset < 0)
    x_offset = 0;
  if (y_offset < 0)
    y_offset = 0;

  for (int y = 0; y < native_splash_screen_image_height; y++) {
    for (int x = 0; x < native_splash_screen_image_width; x++) {
      int dst_x = x + x_offset;
      int dst_y = y + y_offset;
      if (dst_x >= native_splash_screen_width ||
          dst_y >= native_splash_screen_height)
        continue;

      int src_index = y * native_splash_screen_image_width + x;
      int dst_index = dst_y * native_splash_screen_width + dst_x;

      uint32_t srcPixel = native_splash_screen_image_pixels[src_index];
      if (((srcPixel >> 24) & 0xFF) == 0)
        continue;

      pixels[dst_index] = ConvertARGBtoPremultipliedBGRA(srcPixel);
    }
  }
}

static void UpdateSplashWindow(BYTE alpha) {
  if (!g_splash_window || !g_bitmap_bits)
    return;

  HDC hdcScreen = GetDC(nullptr);
  HDC hdcMem = CreateCompatibleDC(hdcScreen);

  if (hdcMem) {
    HBITMAP hOldBitmap = (HBITMAP)SelectObject(hdcMem, g_splash_bitmap);

    RECT rcWindow;
    GetWindowRect(g_splash_window, &rcWindow);

    POINT ptSrc = {0, 0};
    POINT ptDst = {rcWindow.left, rcWindow.top};
    SIZE sizeWnd = {native_splash_screen_width, native_splash_screen_height};

    BLENDFUNCTION blend = {AC_SRC_OVER, 0, alpha, AC_SRC_ALPHA};
    UpdateLayeredWindow(g_splash_window, hdcScreen, &ptDst, &sizeWnd, hdcMem,
                        &ptSrc, 0, &blend, ULW_ALPHA);

    SelectObject(hdcMem, hOldBitmap);
    DeleteDC(hdcMem);
  }

  ReleaseDC(nullptr, hdcScreen);
}

void ShowSplashScreen() {
  if (g_splash_shown)
    return;

  HINSTANCE hInstance = GetModuleHandle(nullptr);

  WNDCLASSW wc = {0};
  wc.lpfnWndProc = SplashWndProc;
  wc.hInstance = hInstance;
  wc.lpszClassName = native_splash_screen_window_class;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  RegisterClassW(&wc);

  DWORD exStyle = WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED;

  g_splash_window = CreateWindowExW(
      exStyle, native_splash_screen_window_class, native_splash_screen_title,
      WS_POPUP, CW_USEDEFAULT, CW_USEDEFAULT, native_splash_screen_width,
      native_splash_screen_height, nullptr, nullptr, hInstance, nullptr);

  if (!g_splash_window)
    return;

  RECT workArea;
  SystemParametersInfoW(SPI_GETWORKAREA, 0, &workArea, 0);
  int x = (workArea.right - workArea.left - native_splash_screen_width) / 2;
  int y = (workArea.bottom - workArea.top - native_splash_screen_height) / 2;

  SetWindowPos(g_splash_window, HWND_TOPMOST, x, y, native_splash_screen_width,
               native_splash_screen_height, SWP_NOACTIVATE);

  HDC hdcScreen = GetDC(nullptr);
  g_splash_bitmap =
      CreateSplashBitmap(hdcScreen, native_splash_screen_width,
                         native_splash_screen_height, &g_bitmap_bits);
  ReleaseDC(nullptr, hdcScreen);

  if (g_splash_bitmap && g_bitmap_bits) {
    RenderSplashContent((uint32_t*)g_bitmap_bits);
    ShowWindow(g_splash_window, SW_SHOWNOACTIVATE);

    if (native_splash_screen_with_animation) {
      // Fade in using 10 steps with 15ms delay between each step (~150ms total)
      for (int alpha = 0; alpha <= 255; alpha += 25) {
        UpdateSplashWindow((BYTE)alpha);
        Sleep(15);
      }
    } else {
      UpdateSplashWindow(255);
    }
    MSG msg;
    while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
      TranslateMessage(&msg);
      DispatchMessageW(&msg);
    }

    g_splash_shown = true;
  } else {
    CloseSplashWindowWithoutAnimation();
  }
}

void EnsureSplashOnTop() {
  // Overlay mode is already stacked over the Flutter view inside the host
  // window - nothing to restack when the main window maps.
  if (!g_splash_shown || g_splash_window == nullptr) {
    return;
  }

  RECT workArea;
  SystemParametersInfoW(SPI_GETWORKAREA, 0, &workArea, 0);
  int x = (workArea.right - workArea.left - native_splash_screen_width) / 2;
  int y = (workArea.bottom - workArea.top - native_splash_screen_height) / 2;

  SetWindowPos(g_splash_window, HWND_TOPMOST, x, y, native_splash_screen_width,
               native_splash_screen_height, SWP_NOACTIVATE | SWP_SHOWWINDOW);

  MSG msg;
  while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&msg);
    DispatchMessageW(&msg);
  }
}

void CloseSplashScreen(const std::string& effect) {
  if (!g_splash_shown)
    return;

  // Overlay mode: fade + destroy the in-window overlay instead of a top-level.
  if (g_overlay_window != nullptr) {
    CloseOverlay(effect);
    return;
  }

  if (effect.empty()) {
    CloseSplashWindowWithoutAnimation();
  }
  // If not empty, check against known effect strings
  else if (effect == "fade") {
    CloseSplashWindowWithFade();
  } else if (effect == "slide_up_fade") {
    CloseSplashWindowSlideUpFade();
  } else if (effect == "slide_down_fade") {
    CloseSplashWindowSlideDownFade();
  } else {
    CloseSplashWindowWithoutAnimation();
  }
}

void CloseSplashWindowWithoutAnimation() {
  if (!g_splash_shown)
    return;

  // Clean up resources
  if (g_splash_bitmap) {
    DeleteObject(g_splash_bitmap);
    g_splash_bitmap = nullptr;
    g_bitmap_bits = nullptr;
  }

  if (g_splash_window) {
    DestroyWindow(g_splash_window);
    g_splash_window = nullptr;
  }

  g_splash_shown = false;
}

void CloseSplashWindowWithFade() {
  if (!g_splash_window) {
    return;
  }

  const int fade_duration_ms = 300;
  const int steps = 30;
  const int sleep_per_step = fade_duration_ms / steps;

  // Get current position and size
  POINT ptSrc = {0, 0};
  POINT ptDst;
  SIZE sizeSplash;
  BLENDFUNCTION blend = {0};

  RECT rect;
  GetWindowRect(g_splash_window, &rect);
  ptDst.x = rect.left;
  ptDst.y = rect.top;
  sizeSplash.cx = native_splash_screen_width;
  sizeSplash.cy = native_splash_screen_height;

  HDC hdcScreen = GetDC(nullptr);
  HDC hdcMem = CreateCompatibleDC(hdcScreen);
  HBITMAP oldBitmap = (HBITMAP)SelectObject(hdcMem, g_splash_bitmap);

  blend.BlendOp = AC_SRC_OVER;
  blend.BlendFlags = 0;
  blend.SourceConstantAlpha = 255;  // start fully opaque
  blend.AlphaFormat = AC_SRC_ALPHA;

  for (int i = 0; i <= steps; ++i) {
    blend.SourceConstantAlpha = (BYTE)(255 * (steps - i) / steps);

    UpdateLayeredWindow(g_splash_window, hdcScreen, &ptDst, &sizeSplash, hdcMem,
                        &ptSrc, 0, &blend, ULW_ALPHA);

    Sleep(sleep_per_step);
  }

  // Clean up
  SelectObject(hdcMem, oldBitmap);
  DeleteDC(hdcMem);
  ReleaseDC(nullptr, hdcScreen);

  DestroyWindow(g_splash_window);
  g_splash_window = nullptr;
}

void CloseSplashWindowSlideUpFade() {
  if (!g_splash_window) {
    return;
  }

  const int fade_duration_ms = 300;
  const int steps = 30;
  const int sleep_per_step = fade_duration_ms / steps;
  const int move_distance = 50;  // move up by 50 pixels total

  POINT ptSrc = {0, 0};
  POINT ptDst;
  SIZE sizeSplash;
  BLENDFUNCTION blend = {0};

  RECT rect;
  GetWindowRect(g_splash_window, &rect);
  ptDst.x = rect.left;
  ptDst.y = rect.top;
  sizeSplash.cx = native_splash_screen_width;
  sizeSplash.cy = native_splash_screen_height;

  HDC hdcScreen = GetDC(nullptr);
  HDC hdcMem = CreateCompatibleDC(hdcScreen);
  HBITMAP oldBitmap = (HBITMAP)SelectObject(hdcMem, g_splash_bitmap);

  blend.BlendOp = AC_SRC_OVER;
  blend.BlendFlags = 0;
  blend.SourceConstantAlpha = 255;
  blend.AlphaFormat = AC_SRC_ALPHA;

  for (int i = 0; i <= steps; ++i) {
    blend.SourceConstantAlpha = (BYTE)(255 * (steps - i) / steps);
    ptDst.y = rect.top - (move_distance * i) / steps;

    UpdateLayeredWindow(g_splash_window, hdcScreen, &ptDst, &sizeSplash, hdcMem,
                        &ptSrc, 0, &blend, ULW_ALPHA);

    Sleep(sleep_per_step);
  }

  SelectObject(hdcMem, oldBitmap);
  DeleteDC(hdcMem);
  ReleaseDC(nullptr, hdcScreen);

  DestroyWindow(g_splash_window);
  g_splash_window = nullptr;
}

void CloseSplashWindowSlideDownFade() {
  if (!g_splash_window) {
    return;
  }

  const int fade_duration_ms = 300;
  const int steps = 30;
  const int sleep_per_step = fade_duration_ms / steps;
  const int move_distance = 50;  // move up by 50 pixels total

  POINT ptSrc = {0, 0};
  POINT ptDst;
  SIZE sizeSplash;
  BLENDFUNCTION blend = {0};

  RECT rect;
  GetWindowRect(g_splash_window, &rect);
  ptDst.x = rect.left;
  ptDst.y = rect.top;
  sizeSplash.cx = native_splash_screen_width;
  sizeSplash.cy = native_splash_screen_height;

  HDC hdcScreen = GetDC(nullptr);
  HDC hdcMem = CreateCompatibleDC(hdcScreen);
  HBITMAP oldBitmap = (HBITMAP)SelectObject(hdcMem, g_splash_bitmap);

  blend.BlendOp = AC_SRC_OVER;
  blend.BlendFlags = 0;
  blend.SourceConstantAlpha = 255;
  blend.AlphaFormat = AC_SRC_ALPHA;

  for (int i = 0; i <= steps; ++i) {
    blend.SourceConstantAlpha = (BYTE)(255 * (steps - i) / steps);
    ptDst.y = rect.top + (move_distance * i) / steps;

    UpdateLayeredWindow(g_splash_window, hdcScreen, &ptDst, &sizeSplash, hdcMem,
                        &ptSrc, 0, &blend, ULW_ALPHA);

    Sleep(sleep_per_step);
  }

  SelectObject(hdcMem, oldBitmap);
  DeleteDC(hdcMem);
  ReleaseDC(nullptr, hdcScreen);

  DestroyWindow(g_splash_window);
  g_splash_window = nullptr;
}

// ---------------------------------------------------------------------------
// Overlay mode
// ---------------------------------------------------------------------------
// Paints the splash bitmap into the app's own window (over the Flutter view)
// instead of a separate top-level window. The baked image is the full splash
// (background + centered logo) and opaque, so it covers the client area.

static LRESULT CALLBACK OverlayWndProc(HWND hwnd,
                                       UINT uMsg,
                                       WPARAM wParam,
                                       LPARAM lParam) {
  switch (uMsg) {
    case WM_PAINT: {
      PAINTSTRUCT ps;
      HDC hdc = BeginPaint(hwnd, &ps);
      RECT rc;
      GetClientRect(hwnd, &rc);
      // Same overlay draw as TeamPilot: 1:1 blit, fill gutters with the
      // splash canvas color (TeamPilot uses white; huji's canvas is #1C1814).
      HBRUSH brush = CreateSolidBrush(RGB(0x1C, 0x18, 0x14));
      FillRect(hdc, &rc, brush);
      DeleteObject(brush);
      if (g_overlay_bitmap) {
        HDC hdcMem = CreateCompatibleDC(hdc);
        HBITMAP old = (HBITMAP)SelectObject(hdcMem, g_overlay_bitmap);
        int x = (rc.right - rc.left - native_splash_screen_image_width) / 2;
        int y = (rc.bottom - rc.top - native_splash_screen_image_height) / 2;
        if (x < 0)
          x = 0;
        if (y < 0)
          y = 0;
        BitBlt(hdc, x, y, native_splash_screen_image_width,
               native_splash_screen_image_height, hdcMem, 0, 0, SRCCOPY);
        SelectObject(hdcMem, old);
        DeleteDC(hdcMem);
      }
      EndPaint(hwnd, &ps);
      return 0;
    }
    case WM_ERASEBKGND:
      return 1;
    case WM_DESTROY:
      if (hwnd == g_overlay_window) {
        g_overlay_window = nullptr;
      }
      return 0;
    default:
      return DefWindowProcW(hwnd, uMsg, wParam, lParam);
  }
}

// Builds an opaque BGRA DIB the size of the baked image.
static HBITMAP CreateOverlayBitmap(HDC hdc, void** ppBits) {
  BITMAPINFO bmi = {0};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = native_splash_screen_image_width;
  bmi.bmiHeader.biHeight = -native_splash_screen_image_height;  // top-down
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  HBITMAP bitmap =
      CreateDIBSection(hdc, &bmi, DIB_RGB_COLORS, ppBits, nullptr, 0);
  if (bitmap && *ppBits && native_splash_screen_image_pixels) {
    uint32_t* dst = static_cast<uint32_t*>(*ppBits);
    const int count =
        native_splash_screen_image_width * native_splash_screen_image_height;
    for (int i = 0; i < count; i++) {
      const uint32_t argb = native_splash_screen_image_pixels[i];
      const BYTE r = (argb >> 16) & 0xFF;
      const BYTE g = (argb >> 8) & 0xFF;
      const BYTE b = argb & 0xFF;
      // Opaque BGRA; a uniform fade is applied later via the layered window.
      dst[i] = (uint32_t)b | ((uint32_t)g << 8) | ((uint32_t)r << 16) |
               (0xFFu << 24);
    }
  }
  return bitmap;
}

// Stacks the splash over the Flutter view inside [host_window] (an HWND). Call
// this in the Win32 runner after the window is created, in place of
// ShowSplashScreen(). Dismiss it later from Dart via close().
void AttachSplashOverlay(void* host_window) {
  if (g_splash_shown || host_window == nullptr)
    return;

  HWND host = static_cast<HWND>(host_window);
  HINSTANCE hInstance = GetModuleHandle(nullptr);

  static const wchar_t* kOverlayClass = L"native_splash_screen_overlay";
  WNDCLASSW wc = {0};
  wc.lpfnWndProc = OverlayWndProc;
  wc.hInstance = hInstance;
  wc.lpszClassName = kOverlayClass;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  RegisterClassW(&wc);  // harmless if already registered

  RECT rc;
  GetClientRect(host, &rc);

  g_overlay_window = CreateWindowExW(
      WS_EX_LAYERED | WS_EX_NOACTIVATE, kOverlayClass, L"",
      WS_CHILD | WS_VISIBLE, 0, 0, rc.right - rc.left, rc.bottom - rc.top, host,
      nullptr, hInstance, nullptr);
  if (!g_overlay_window)
    return;

  HDC hdcScreen = GetDC(nullptr);
  g_overlay_bitmap = CreateOverlayBitmap(hdcScreen, &g_overlay_bits);
  ReleaseDC(nullptr, hdcScreen);

  SetLayeredWindowAttributes(g_overlay_window, 0, 255, LWA_ALPHA);
  SetWindowPos(g_overlay_window, HWND_TOP, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
  ShowWindow(g_overlay_window, SW_SHOWNOACTIVATE);
  g_splash_shown = true;
}

void ResizeSplashOverlay(void* host_window) {
  if (!g_splash_shown || g_overlay_window == nullptr || host_window == nullptr) {
    return;
  }
  HWND host = static_cast<HWND>(host_window);
  RECT rc;
  GetClientRect(host, &rc);
  MoveWindow(g_overlay_window, 0, 0, rc.right - rc.left, rc.bottom - rc.top,
             TRUE);
  SetWindowPos(g_overlay_window, HWND_TOP, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
  InvalidateRect(g_overlay_window, nullptr, FALSE);
}

static void CloseOverlay(const std::string& effect) {
  if (!g_overlay_window) {
    g_splash_shown = false;
    return;
  }

  if (!effect.empty()) {
    const int steps = 18;  // ~290ms total
    const int sleep_per_step = 16;
    for (int i = 1; i <= steps; ++i) {
      const BYTE alpha = (BYTE)(255 * (steps - i) / steps);
      SetLayeredWindowAttributes(g_overlay_window, 0, alpha, LWA_ALPHA);
      MSG msg;
      while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
      }
      Sleep(sleep_per_step);
    }
  }

  if (g_overlay_bitmap) {
    DeleteObject(g_overlay_bitmap);
    g_overlay_bitmap = nullptr;
    g_overlay_bits = nullptr;
  }
  DestroyWindow(g_overlay_window);
  g_overlay_window = nullptr;
  g_splash_shown = false;
}