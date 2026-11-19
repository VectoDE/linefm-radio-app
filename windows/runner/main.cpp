#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Single-Instance: benannter Mutex pro Benutzersitzung. Gleichen Titel und
// Fensterklasse wie die Flutter-Fenster nutzen (siehe win32_window.cpp und
// desktopWindowTitle in lib/platform/desktop/window_impl.dart).
constexpr wchar_t kInstanceMutexName[] = L"Local\\de.linefm.app.single-instance";
constexpr wchar_t kRunnerWindowClass[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr wchar_t kRunnerWindowTitle[] = L"LINEFM | Radio";

// Reicht die Kommandozeile (z. B. linefm://play?station=rap) per WM_COPYDATA
// an das erste Fenster weiter und holt es nach vorn. Gibt false zurueck, wenn
// kein Fenster gefunden wurde.
bool ForwardToRunningInstance(const std::vector<std::string> &arguments) {
  HWND existing = nullptr;
  // Das erste Fenster kann gerade erst entstehen: kurz warten.
  for (int attempt = 0; attempt < 30 && existing == nullptr; ++attempt) {
    existing = ::FindWindowW(kRunnerWindowClass, kRunnerWindowTitle);
    if (existing == nullptr) {
      ::Sleep(100);
    }
  }
  if (existing == nullptr) {
    return false;
  }

  DWORD process_id = 0;
  ::GetWindowThreadProcessId(existing, &process_id);
  ::AllowSetForegroundWindow(process_id);

  std::string payload;
  for (const std::string &argument : arguments) {
    payload += argument;
    payload.push_back('\n');
  }
  COPYDATASTRUCT data = {};
  data.dwData = kSingleInstanceCopyData;
  data.cbData = static_cast<DWORD>(payload.size());
  data.lpData = payload.empty() ? nullptr : const_cast<char *>(payload.data());
  ::SendMessageTimeoutW(existing, WM_COPYDATA, 0,
                        reinterpret_cast<LPARAM>(&data), SMTO_ABORTIFHUNG,
                        3000, nullptr);
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Single-Instance: Ein zweiter Start holt das erste Fenster in den
  // Vordergrund, reicht linefm://-Links dorthin weiter und beendet sich.
  HANDLE instance_mutex = ::CreateMutexW(nullptr, TRUE, kInstanceMutexName);
  if (instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    if (ForwardToRunningInstance(GetCommandLineArguments())) {
      ::CloseHandle(instance_mutex);
      return EXIT_SUCCESS;
    }
    // Kein Fenster gefunden (erste Instanz haengt oder beendet sich gerade):
    // normal weiterstarten.
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // Startposition: spaeter setzt window_manager (initDesktop) die gemerkte
  // Groesse und Position, bevor das Fenster mit dem ersten Frame erscheint.
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"LINEFM | Radio", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (instance_mutex != nullptr) {
    ::CloseHandle(instance_mutex);
  }
  return EXIT_SUCCESS;
}
