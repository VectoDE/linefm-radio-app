#include "flutter_window.h"

#include <dwmapi.h>

#include <optional>
#include <string>

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
  single_instance_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "de.linefm.app/single_instance",
          &flutter::StandardMethodCodec::GetInstance());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // The window is created cloaked (Win32Window::Create). On the first frame it
  // is shown but stays cloaked: the frame callback fires before the Flutter
  // surface reaches the screen, which showed an empty window for ~200 ms.
  // Dart reports when the loader has really been presented
  // (de.linefm.app/window_reveal, lib/platform/desktop/window_reveal.dart);
  // a timer reveals the window anyway if that signal never comes.
  window_reveal_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "de.linefm.app/window_reveal",
          &flutter::StandardMethodCodec::GetInstance());
  window_reveal_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "reveal") {
          DwmFlush();
          Reveal();
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
    SetTimer(GetHandle(), kRevealTimerId, kRevealFallbackMs, nullptr);
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  single_instance_channel_ = nullptr;
  window_reveal_channel_ = nullptr;
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
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_COPYDATA: {
      // Zweiter Programmstart: Fenster zeigen, Argumente an Dart geben.
      const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
      if (data != nullptr && data->dwData == kSingleInstanceCopyData) {
        Reveal();
        ::ShowWindow(hwnd, ::IsIconic(hwnd) ? SW_RESTORE : SW_SHOW);
        ::SetForegroundWindow(hwnd);
        if (single_instance_channel_) {
          flutter::EncodableList arguments;
          if (data->lpData != nullptr && data->cbData > 0) {
            const std::string payload(static_cast<const char*>(data->lpData),
                                      data->cbData);
            size_t start = 0;
            while (start < payload.size()) {
              size_t end = payload.find('\n', start);
              if (end == std::string::npos) {
                end = payload.size();
              }
              if (end > start) {
                arguments.emplace_back(payload.substr(start, end - start));
              }
              start = end + 1;
            }
          }
          single_instance_channel_->InvokeMethod(
              "secondInstance",
              std::make_unique<flutter::EncodableValue>(std::move(arguments)));
        }
        return TRUE;
      }
      break;
    }
    case WM_TIMER:
      if (wparam == kRevealTimerId) {
        KillTimer(hwnd, kRevealTimerId);
        Reveal();
        return 0;
      }
      break;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
