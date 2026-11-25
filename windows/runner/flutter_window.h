#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "win32_window.h"

// Kennung der WM_COPYDATA-Nachricht, mit der ein zweiter Programmstart seine
// Kommandozeile an die erste Instanz uebergibt (Single-Instance, P18).
constexpr ULONG_PTR kSingleInstanceCopyData = 0x4C46;

// Fallback: reveal the cloaked window this long after the first frame even
// without the signal from Dart.
constexpr UINT_PTR kRevealTimerId = 0x4C47;
constexpr UINT kRevealFallbackMs = 2000;

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Kanal de.linefm.app/single_instance (Dart: desktop_runtime_io.dart).
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      single_instance_channel_;

  // Kanal de.linefm.app/window_reveal (Dart: window_reveal.dart).
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_reveal_channel_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
