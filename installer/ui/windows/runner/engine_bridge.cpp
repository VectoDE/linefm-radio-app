#include "engine_bridge.h"

#include <bcrypt.h>
#include <sddl.h>
#include <shellapi.h>
#include <shobjidl.h>

#include <flutter/standard_method_codec.h>

namespace {

constexpr char kChannel[] = "linefm_setup/native";

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) return std::wstring();
  const int size = ::MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                         static_cast<int>(text.size()),
                                         nullptr, 0);
  std::wstring out(size, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        out.data(), size);
  return out;
}

std::string WideToUtf8(const std::wstring& text) {
  if (text.empty()) return std::string();
  const int size = ::WideCharToMultiByte(CP_UTF8, 0, text.data(),
                                         static_cast<int>(text.size()),
                                         nullptr, 0, nullptr, nullptr);
  std::string out(size, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        out.data(), size, nullptr, nullptr);
  return out;
}

// Quoten nach den Regeln von CommandLineToArgvW.
std::wstring QuoteArg(const std::wstring& arg) {
  if (!arg.empty() && arg.find_first_of(L" \t\n\v\"") == std::wstring::npos) {
    return arg;
  }
  std::wstring out = L"\"";
  for (auto it = arg.begin();; ++it) {
    size_t backslashes = 0;
    while (it != arg.end() && *it == L'\\') {
      ++it;
      ++backslashes;
    }
    if (it == arg.end()) {
      out.append(backslashes * 2, L'\\');
      break;
    }
    if (*it == L'"') {
      out.append(backslashes * 2 + 1, L'\\');
    } else {
      out.append(backslashes, L'\\');
    }
    out.push_back(*it);
  }
  out.push_back(L'"');
  return out;
}

std::wstring CurrentUserSid() {
  HANDLE token = nullptr;
  if (!::OpenProcessToken(::GetCurrentProcess(), TOKEN_QUERY, &token)) {
    return std::wstring();
  }
  DWORD size = 0;
  ::GetTokenInformation(token, TokenUser, nullptr, 0, &size);
  std::vector<uint8_t> buffer(size);
  std::wstring result;
  if (size > 0 && ::GetTokenInformation(token, TokenUser, buffer.data(), size,
                                        &size)) {
    auto* user = reinterpret_cast<TOKEN_USER*>(buffer.data());
    LPWSTR text = nullptr;
    if (::ConvertSidToStringSidW(user->User.Sid, &text)) {
      result = text;
      ::LocalFree(text);
    }
  }
  ::CloseHandle(token);
  return result;
}

std::wstring RandomHex(size_t bytes) {
  std::vector<uint8_t> buffer(bytes);
  if (::BCryptGenRandom(nullptr, buffer.data(), static_cast<ULONG>(bytes),
                        BCRYPT_USE_SYSTEM_PREFERRED_RNG) != 0) {
    return std::wstring();
  }
  static const wchar_t kDigits[] = L"0123456789abcdef";
  std::wstring out;
  for (uint8_t b : buffer) {
    out.push_back(kDigits[b >> 4]);
    out.push_back(kDigits[b & 15]);
  }
  return out;
}

bool EndsWithI(const std::wstring& text, const std::wstring& suffix) {
  return text.size() >= suffix.size() &&
         ::CompareStringOrdinal(text.c_str() + text.size() - suffix.size(),
                                static_cast<int>(suffix.size()),
                                suffix.c_str(),
                                static_cast<int>(suffix.size()),
                                TRUE) == CSTR_EQUAL;
}

std::wstring ParentDir(const std::wstring& path) {
  const size_t pos = path.find_last_of(L"\\/");
  return pos == std::wstring::npos ? std::wstring() : path.substr(0, pos);
}

const flutter::EncodableValue* Field(const flutter::EncodableMap& map,
                                     const char* name) {
  auto it = map.find(flutter::EncodableValue(name));
  return it == map.end() ? nullptr : &it->second;
}

std::wstring StringField(const flutter::EncodableMap& map, const char* name) {
  const auto* value = Field(map, name);
  if (value == nullptr) return std::wstring();
  const auto* text = std::get_if<std::string>(value);
  return text == nullptr ? std::wstring() : Utf8ToWide(*text);
}

bool BoolField(const flutter::EncodableMap& map, const char* name) {
  const auto* value = Field(map, name);
  if (value == nullptr) return false;
  const auto* flag = std::get_if<bool>(value);
  return flag != nullptr && *flag;
}

// Ordnerauswahl (Windows-Standarddialog, barrierefrei).
std::wstring PickFolder(HWND owner, const std::wstring& initial,
                        const std::wstring& title) {
  IFileOpenDialog* dialog = nullptr;
  if (FAILED(::CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&dialog)))) {
    return std::wstring();
  }
  DWORD options = 0;
  dialog->GetOptions(&options);
  dialog->SetOptions(options | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM |
                     FOS_PATHMUSTEXIST | FOS_NOCHANGEDIR);
  if (!title.empty()) dialog->SetTitle(title.c_str());
  std::wstring probe = initial;
  while (!probe.empty()) {
    const DWORD attr = ::GetFileAttributesW(probe.c_str());
    if (attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY)) {
      IShellItem* folder = nullptr;
      if (SUCCEEDED(::SHCreateItemFromParsingName(probe.c_str(), nullptr,
                                                  IID_PPV_ARGS(&folder)))) {
        dialog->SetFolder(folder);
        folder->Release();
      }
      break;
    }
    const std::wstring parent = ParentDir(probe);
    if (parent == probe) break;
    probe = parent;
  }
  std::wstring result;
  if (SUCCEEDED(dialog->Show(owner))) {
    IShellItem* item = nullptr;
    if (SUCCEEDED(dialog->GetResult(&item))) {
      PWSTR path = nullptr;
      if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &path))) {
        result = path;
        ::CoTaskMemFree(path);
      }
      item->Release();
    }
  }
  dialog->Release();
  return result;
}

}  // namespace

EngineBridge::EngineBridge(flutter::BinaryMessenger* messenger, HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannel, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    OnMethodCall(call, std::move(result));
  });
  stop_event_ = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
}

EngineBridge::~EngineBridge() {
  Stop();
  if (stop_event_ != nullptr) ::CloseHandle(stop_event_);
  channel_->SetMethodCallHandler(nullptr);
}

void EngineBridge::Stop() {
  if (stop_event_ != nullptr) ::SetEvent(stop_event_);
  if (worker_.joinable()) worker_.join();
  if (pipe_ != INVALID_HANDLE_VALUE) {
    ::CloseHandle(pipe_);
    pipe_ = INVALID_HANDLE_VALUE;
  }
  if (process_ != nullptr) {
    ::CloseHandle(process_);
    process_ = nullptr;
  }
}

void EngineBridge::RequestClose() {
  channel_->InvokeMethod("closeRequested", nullptr);
}

bool EngineBridge::HandleMessage(UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == kMsgLine) {
    std::unique_ptr<std::string> line(reinterpret_cast<std::string*>(lparam));
    channel_->InvokeMethod(
        "line", std::make_unique<flutter::EncodableValue>(*line));
    return true;
  }
  if (message == kMsgExit) {
    // Engine ist beendet: Ressourcen freigeben, damit ein neuer Versuch
    // (z. B. nach abgelehnter UAC-Abfrage oder Fehler) moeglich ist.
    Stop();
    channel_->InvokeMethod("engineExit",
                           std::make_unique<flutter::EncodableValue>(
                               static_cast<int64_t>(wparam)));
    return true;
  }
  return false;
}

void EngineBridge::PostLine(const std::string& line) {
  auto* copy = new std::string(line);
  if (!::PostMessageW(window_, kMsgLine, 0, reinterpret_cast<LPARAM>(copy))) {
    delete copy;
  }
}

void EngineBridge::PostExit(DWORD code) {
  ::PostMessageW(window_, kMsgExit, static_cast<WPARAM>(code), 0);
}

void EngineBridge::OnMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* map = std::get_if<flutter::EncodableMap>(call.arguments());
  const std::string& method = call.method_name();
  if (method == "start") {
    if (map == nullptr) return result->Error("bad_args");
    std::vector<std::wstring> args;
    if (const auto* list = Field(*map, "args")) {
      if (const auto* items = std::get_if<flutter::EncodableList>(list)) {
        for (const auto& item : *items) {
          if (const auto* text = std::get_if<std::string>(&item)) {
            args.push_back(Utf8ToWide(*text));
          }
        }
      }
    }
    const std::string error =
        Start(StringField(*map, "exe"), args, BoolField(*map, "elevate"));
    if (error.empty()) {
      result->Success(flutter::EncodableValue(true));
    } else {
      result->Error(error);
    }
  } else if (method == "send") {
    const auto* text = std::get_if<std::string>(call.arguments());
    result->Success(flutter::EncodableValue(text != nullptr && Send(*text)));
  } else if (method == "pickFolder") {
    if (map == nullptr) return result->Error("bad_args");
    const std::wstring path = PickFolder(window_, StringField(*map, "initial"),
                                         StringField(*map, "title"));
    if (path.empty()) {
      result->Success();
    } else {
      result->Success(flutter::EncodableValue(WideToUtf8(path)));
    }
  } else if (method == "launch") {
    // Startet die installierte App (nicht erhoeht, ausser die Oberflaeche
    // selbst laeuft erhoeht). Nur .exe-Dateien.
    const auto* text = std::get_if<std::string>(call.arguments());
    const std::wstring exe = text == nullptr ? L"" : Utf8ToWide(*text);
    const DWORD attr = ::GetFileAttributesW(exe.c_str());
    if (exe.empty() || !EndsWithI(exe, L".exe") ||
        attr == INVALID_FILE_ATTRIBUTES || (attr & FILE_ATTRIBUTE_DIRECTORY)) {
      return result->Success(flutter::EncodableValue(false));
    }
    std::wstring command = QuoteArg(exe);
    const std::wstring dir = ParentDir(exe);
    STARTUPINFOW si = {sizeof(si)};
    PROCESS_INFORMATION pi = {};
    const BOOL ok = ::CreateProcessW(exe.c_str(), command.data(), nullptr,
                                     nullptr, FALSE, 0, nullptr, dir.c_str(),
                                     &si, &pi);
    if (ok) {
      ::CloseHandle(pi.hThread);
      ::CloseHandle(pi.hProcess);
    }
    result->Success(flutter::EncodableValue(ok != 0));
  } else if (method == "openUrl") {
    const auto* text = std::get_if<std::string>(call.arguments());
    const std::wstring url = text == nullptr ? L"" : Utf8ToWide(*text);
    bool ok = false;
    if (url.rfind(L"https://", 0) == 0 &&
        url.find_first_of(L" \"\r\n\t") == std::wstring::npos) {
      ok = reinterpret_cast<INT_PTR>(::ShellExecuteW(
               window_, L"open", url.c_str(), nullptr, nullptr,
               SW_SHOWNORMAL)) > 32;
    }
    result->Success(flutter::EncodableValue(ok));
  } else if (method == "window") {
    // Custom title bar (#88): move the window with the pressed mouse button
    // or minimize it. Only these two fixed actions exist.
    const auto* action = std::get_if<std::string>(call.arguments());
    HWND top = ::GetAncestor(window_, GA_ROOT);
    if (action != nullptr && *action == "startDrag") {
      ::ReleaseCapture();
      ::PostMessageW(top, WM_NCLBUTTONDOWN, HTCAPTION, 0);
    } else if (action != nullptr && *action == "minimize") {
      ::ShowWindow(top, SW_MINIMIZE);
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

std::string EngineBridge::Start(const std::wstring& exe,
                                const std::vector<std::wstring>& args,
                                bool elevate) {
  if (process_ != nullptr) return "already_running";
  const DWORD attr = ::GetFileAttributesW(exe.c_str());
  if (exe.empty() || !EndsWithI(exe, L".exe") ||
      attr == INVALID_FILE_ATTRIBUTES || (attr & FILE_ATTRIBUTE_DIRECTORY)) {
    return "engine_missing";
  }
  const std::wstring sid = CurrentUserSid();
  const std::wstring name = L"linefm-setup-" + RandomHex(16);
  if (sid.empty() || name.size() < 20) return "pipe_failed";
  const std::wstring sddl =
      L"D:P(A;;GA;;;SY)(A;;GA;;;BA)(A;;GA;;;" + sid + L")";
  PSECURITY_DESCRIPTOR sd = nullptr;
  if (!::ConvertStringSecurityDescriptorToSecurityDescriptorW(
          sddl.c_str(), SDDL_REVISION_1, &sd, nullptr)) {
    return "pipe_failed";
  }
  SECURITY_ATTRIBUTES sa = {sizeof(sa), sd, FALSE};
  const std::wstring path = L"\\\\.\\pipe\\" + name;
  pipe_ = ::CreateNamedPipeW(
      path.c_str(),
      PIPE_ACCESS_DUPLEX | FILE_FLAG_OVERLAPPED | FILE_FLAG_FIRST_PIPE_INSTANCE,
      PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT |
          PIPE_REJECT_REMOTE_CLIENTS,
      1, 64 * 1024, 64 * 1024, 0, &sa);
  ::LocalFree(sd);
  if (pipe_ == INVALID_HANDLE_VALUE) return "pipe_failed";

  std::wstring params = L"--engine";
  for (size_t i = 0; i < args.size(); ++i) {
    // Erstes Argument ist der Modus (install/uninstall), danach die Pipe.
    params += L" " + QuoteArg(args[i]);
    if (i == 0) params += L" --pipe " + name;
  }

  if (elevate) {
    SHELLEXECUTEINFOW info = {sizeof(info)};
    info.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NOASYNC;
    info.hwnd = window_;
    info.lpVerb = L"runas";
    info.lpFile = exe.c_str();
    info.lpParameters = params.c_str();
    const std::wstring dir = ParentDir(exe);
    info.lpDirectory = dir.c_str();
    info.nShow = SW_HIDE;
    if (!::ShellExecuteExW(&info) || info.hProcess == nullptr) {
      const DWORD error = ::GetLastError();
      ::CloseHandle(pipe_);
      pipe_ = INVALID_HANDLE_VALUE;
      return error == ERROR_CANCELLED ? "cancelled" : "start_failed";
    }
    process_ = info.hProcess;
  } else {
    std::wstring command = QuoteArg(exe) + L" " + params;
    const std::wstring dir = ParentDir(exe);
    STARTUPINFOW si = {sizeof(si)};
    PROCESS_INFORMATION pi = {};
    if (!::CreateProcessW(exe.c_str(), command.data(), nullptr, nullptr,
                          FALSE, CREATE_NO_WINDOW, nullptr, dir.c_str(), &si,
                          &pi)) {
      ::CloseHandle(pipe_);
      pipe_ = INVALID_HANDLE_VALUE;
      return "start_failed";
    }
    ::CloseHandle(pi.hThread);
    process_ = pi.hProcess;
  }
  ::ResetEvent(stop_event_);
  worker_ = std::thread([this] { Worker(); });
  return std::string();
}

void EngineBridge::Worker() {
  OVERLAPPED ov = {};
  ov.hEvent = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
  auto finish = [&]() {
    DWORD code = 3;  // kExitFailed
    // Engine bekommt Zeit, sauber zu enden (Rueckbau nach Abbruch).
    HANDLE wait[] = {process_, stop_event_};
    ::WaitForMultipleObjects(2, wait, FALSE, INFINITE);
    ::GetExitCodeProcess(process_, &code);
    if (code == STILL_ACTIVE) code = 3;
    connected_ = false;
    ::CloseHandle(ov.hEvent);
    PostExit(code);
  };

  // 1. Auf die Verbindung der Engine warten.
  BOOL ok = ::ConnectNamedPipe(pipe_, &ov);
  DWORD error = ok ? ERROR_PIPE_CONNECTED : ::GetLastError();
  if (error == ERROR_IO_PENDING) {
    HANDLE wait[] = {ov.hEvent, process_, stop_event_};
    const DWORD which = ::WaitForMultipleObjects(3, wait, FALSE, INFINITE);
    if (which != WAIT_OBJECT_0) {
      DWORD n = 0;
      ::CancelIoEx(pipe_, &ov);
      ::GetOverlappedResult(pipe_, &ov, &n, TRUE);
      return finish();
    }
    DWORD ignored = 0;
    error = ::GetOverlappedResult(pipe_, &ov, &ignored, FALSE)
                ? ERROR_PIPE_CONNECTED
                : ::GetLastError();
  }
  if (error != ERROR_PIPE_CONNECTED) return finish();

  // 2. Nur der selbst gestartete Engine-Prozess darf verbunden sein.
  ULONG client = 0;
  if (!::GetNamedPipeClientProcessId(pipe_, &client) ||
      client != ::GetProcessId(process_)) {
    ::DisconnectNamedPipe(pipe_);
    ::TerminateProcess(process_, 3);
    PostLine("log Verbindung von fremdem Prozess abgelehnt");
    return finish();
  }
  connected_ = true;

  // 3. Zeilen lesen, bis die Engine die Pipe schliesst.
  std::string buffer;
  char chunk[4096];
  for (;;) {
    ::ResetEvent(ov.hEvent);
    DWORD read = 0;
    ok = ::ReadFile(pipe_, chunk, sizeof(chunk), &read, &ov);
    if (!ok && ::GetLastError() == ERROR_IO_PENDING) {
      HANDLE wait[] = {ov.hEvent, stop_event_};
      if (::WaitForMultipleObjects(2, wait, FALSE, INFINITE) != WAIT_OBJECT_0) {
        ::CancelIoEx(pipe_, &ov);
        ::GetOverlappedResult(pipe_, &ov, &read, TRUE);
        break;
      }
      ok = ::GetOverlappedResult(pipe_, &ov, &read, FALSE);
    }
    if (!ok || read == 0) break;
    buffer.append(chunk, read);
    size_t pos;
    while ((pos = buffer.find('\n')) != std::string::npos) {
      std::string line = buffer.substr(0, pos);
      buffer.erase(0, pos + 1);
      if (!line.empty() && line.back() == '\r') line.pop_back();
      if (!line.empty()) PostLine(line);
    }
    if (buffer.size() > 1 << 20) buffer.clear();  // Schutz vor Muell
  }
  finish();
}

bool EngineBridge::Send(const std::string& line) {
  std::lock_guard<std::mutex> lock(write_mutex_);
  if (!connected_ || pipe_ == INVALID_HANDLE_VALUE) return false;
  std::string data;
  for (char c : line) data.push_back(c == '\n' || c == '\r' ? ' ' : c);
  data.push_back('\n');
  OVERLAPPED ov = {};
  ov.hEvent = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
  DWORD written = 0;
  BOOL ok = ::WriteFile(pipe_, data.data(), static_cast<DWORD>(data.size()),
                        &written, &ov);
  if (!ok && ::GetLastError() == ERROR_IO_PENDING) {
    ok = ::GetOverlappedResult(pipe_, &ov, &written, TRUE);
  }
  ::CloseHandle(ov.hEvent);
  return ok && written == data.size();
}
