// Bruecke zwischen der Setup-Oberflaeche (Dart) und der Setup-Engine
// (setup.exe --engine ...).
//
// Die Oberflaeche ist Pipe-Server, die (ggf. per UAC erhoehte) Engine Client.
// Protokoll: UTF-8-Zeilen, siehe installer/windows/README.md.
//
// Sicherheit:
// - Pipe nur lokal (PIPE_REJECT_REMOTE_CLIENTS), eine Instanz
//   (FILE_FLAG_FIRST_PIPE_INSTANCE), zufaelliger Name.
// - DACL: nur SYSTEM, Administratoren und der aktuelle Benutzer.
// - Der verbundene Client muss genau der gestartete Engine-Prozess sein
//   (GetNamedPipeClientProcessId), sonst wird getrennt.
#ifndef RUNNER_ENGINE_BRIDGE_H_
#define RUNNER_ENGINE_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

class EngineBridge {
 public:
  // Eigene Fenstermeldungen (Worker-Thread -> Plattform-Thread).
  static constexpr UINT kMsgLine = WM_APP + 41;
  static constexpr UINT kMsgExit = WM_APP + 42;

  EngineBridge(flutter::BinaryMessenger* messenger, HWND window);
  ~EngineBridge();
  EngineBridge(const EngineBridge&) = delete;
  EngineBridge& operator=(const EngineBridge&) = delete;

  // Aus FlutterWindow::MessageHandler. true = Meldung verarbeitet.
  bool HandleMessage(UINT message, WPARAM wparam, LPARAM lparam);

  // Schliessen-Knopf des Fensters: an Dart melden statt sofort zu beenden.
  void RequestClose();

 private:
  void OnMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  // Startet die Engine. Leerer Rueckgabewert = ok, sonst Fehlercode.
  std::string Start(const std::wstring& exe,
                    const std::vector<std::wstring>& args, bool elevate);
  void Worker();
  bool Send(const std::string& line);
  void PostLine(const std::string& line);
  void PostExit(DWORD code);
  void Stop();

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_;
  HANDLE pipe_ = INVALID_HANDLE_VALUE;
  HANDLE process_ = nullptr;
  HANDLE stop_event_ = nullptr;
  std::thread worker_;
  std::mutex write_mutex_;
  std::atomic<bool> connected_{false};
};

#endif  // RUNNER_ENGINE_BRIDGE_H_
