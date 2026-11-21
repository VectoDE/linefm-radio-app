// Einstieg von setup.exe und uninstall.exe (dieselbe Binaerdatei).
//
// setup.exe (mit Nutzlast):
//   ohne Parameter       Oberflaeche entpacken (privater Temp-Ordner), starten
//   /S                   still installieren (Parameter: packaging/windows/README.md)
//   --engine install     intern: von der Oberflaeche gesteuert (Named Pipe)
// uninstall.exe (ohne Nutzlast, liegt im Installationsordner):
//   ohne Parameter       Oberflaeche aus dem Installationsordner kopieren, starten
//   /S                   still deinstallieren
//   --phase2             intern: Kopie im Temp-Ordner, damit der
//                        Installationsordner vollstaendig geloescht werden kann
//   --engine uninstall   intern: von der Oberflaeche gesteuert
// base.h zuerst: bindet <windows.h> vor den Shell-Headern ein.
#include "../common/base.h"

#include <shellapi.h>
#include <shlobj.h>

#include <knownfolders.h>

#include <atomic>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <thread>

#include "../common/archive.h"
#include "../common/base.h"
#include "../common/secure.h"
#include "engine.h"

using namespace lf;

namespace {

// --- Argumente --------------------------------------------------------------

struct Args {
  bool silent = false;
  bool help = false;
  bool all_users = false;
  bool current_user = false;
  std::wstring dir;
  int desktop = -1;
  int start_menu = -1;
  int autostart = -1;
  std::wstring log;
  bool no_close_apps = false;
  bool allow_downgrade = false;
  bool delete_user_data = false;
  // intern
  std::wstring engine;  // install | uninstall
  std::wstring pipe;
  bool phase2 = false;
  bool gui = false;
  std::wstring target;
  HANDLE parent_handle = nullptr;
  HANDLE result_handle = nullptr;
  std::wstring unknown;
  std::vector<std::wstring> raw;
};

bool ParseFlagValue(const std::wstring& value, int* out) {
  if (value == L"1" || EqualsI(value, L"true") || EqualsI(value, L"yes")) {
    *out = 1;
    return true;
  }
  if (value == L"0" || EqualsI(value, L"false") || EqualsI(value, L"no")) {
    *out = 0;
    return true;
  }
  return false;
}

HANDLE ParseHandle(const std::wstring& value) {
  return reinterpret_cast<HANDLE>(
      static_cast<uintptr_t>(_wcstoui64(value.c_str(), nullptr, 10)));
}

Args ParseArgs() {
  Args args;
  int argc = 0;
  LPWSTR* argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) return args;
  for (int i = 1; i < argc; ++i) {
    const std::wstring a = argv[i];
    args.raw.push_back(a);
    auto next = [&]() -> std::wstring {
      return i + 1 < argc ? std::wstring(argv[++i]) : std::wstring();
    };
    auto value_of = [&](const wchar_t* name, std::wstring* out) {
      const std::wstring prefix = std::wstring(name) + L"=";
      if (StartsWithI(a, prefix)) {
        *out = a.substr(prefix.size());
        return true;
      }
      return false;
    };
    std::wstring v;
    if (EqualsI(a, L"/S") || EqualsI(a, L"/SILENT") ||
        EqualsI(a, L"/VERYSILENT") || EqualsI(a, L"/QUIET")) {
      args.silent = true;
    } else if (a == L"/?" || EqualsI(a, L"/HELP") || EqualsI(a, L"--help")) {
      args.help = true;
    } else if (EqualsI(a, L"/ALLUSERS")) {
      args.all_users = true;
    } else if (EqualsI(a, L"/CURRENTUSER")) {
      args.current_user = true;
    } else if (value_of(L"/DIR", &v)) {
      args.dir = v;
    } else if (value_of(L"/DESKTOPSHORTCUT", &v)) {
      if (!ParseFlagValue(v, &args.desktop)) args.unknown = a;
    } else if (value_of(L"/STARTMENU", &v)) {
      if (!ParseFlagValue(v, &args.start_menu)) args.unknown = a;
    } else if (value_of(L"/AUTOSTART", &v)) {
      if (!ParseFlagValue(v, &args.autostart)) args.unknown = a;
    } else if (value_of(L"/LOG", &v)) {
      args.log = v;
    } else if (EqualsI(a, L"/NOCLOSEAPPS")) {
      args.no_close_apps = true;
    } else if (EqualsI(a, L"/ALLOWDOWNGRADE")) {
      args.allow_downgrade = true;
    } else if (EqualsI(a, L"/DELETEUSERDATA")) {
      args.delete_user_data = true;
    } else if (a == L"--engine") {
      args.engine = next();
    } else if (a == L"--pipe") {
      args.pipe = next();
    } else if (a == L"--phase2") {
      args.phase2 = true;
    } else if (a == L"--gui") {
      args.gui = true;
    } else if (a == L"--target") {
      args.target = next();
    } else if (a == L"--scope") {
      const std::wstring scope = next();
      args.all_users = scope == L"machine";
      args.current_user = scope == L"user";
    } else if (a == L"--dir") {
      args.dir = next();
    } else if (a == L"--desktop") {
      ParseFlagValue(next(), &args.desktop);
    } else if (a == L"--startmenu") {
      ParseFlagValue(next(), &args.start_menu);
    } else if (a == L"--autostart") {
      ParseFlagValue(next(), &args.autostart);
    } else if (a == L"--allow-downgrade") {
      args.allow_downgrade = true;
    } else if (a == L"--delete-user-data") {
      args.delete_user_data = true;
    } else if (a == L"--no-close-apps") {
      args.no_close_apps = true;
    } else if (a == L"--log") {
      args.log = next();
    } else if (a == L"--parent-handle") {
      args.parent_handle = ParseHandle(next());
    } else if (a == L"--result-handle") {
      args.result_handle = ParseHandle(next());
    } else {
      args.unknown = a;
    }
  }
  ::LocalFree(argv);
  return args;
}

bool IsGerman() {
  return PRIMARYLANGID(::GetUserDefaultUILanguage()) == LANG_GERMAN;
}

void ShowMessage(const std::wstring& de, const std::wstring& en,
                 UINT icon = MB_ICONERROR) {
  ::MessageBoxW(nullptr, (IsGerman() ? de : en).c_str(), L"LINEFM Radio Setup",
                MB_OK | icon | MB_SETFOREGROUND);
}

// Schreibt in die Konsole des Aufrufers (falls vorhanden), z. B. cmd/PowerShell.
void ConsoleLine(const std::wstring& text) {
  static bool attached = ::AttachConsole(ATTACH_PARENT_PROCESS) != 0;
  if (!attached) return;
  HANDLE out = ::GetStdHandle(STD_OUTPUT_HANDLE);
  if (out == nullptr || out == INVALID_HANDLE_VALUE) return;
  const std::wstring line = text + L"\r\n";
  DWORD written = 0;
  if (!::WriteConsoleW(out, line.c_str(), static_cast<DWORD>(line.size()),
                       &written, nullptr)) {
    const std::string utf8 = WideToUtf8(line);
    ::WriteFile(out, utf8.data(), static_cast<DWORD>(utf8.size()), &written,
                nullptr);
  }
}

const wchar_t kUsage[] =
    L"setup.exe [/S] [/ALLUSERS | /CURRENTUSER] [/DIR=\"Ordner\"]\n"
    L"          [/DESKTOPSHORTCUT=0|1] [/STARTMENU=0|1] [/AUTOSTART=0|1]\n"
    L"          [/NOCLOSEAPPS] [/ALLOWDOWNGRADE] [/LOG=\"Datei\"]\n\n"
    L"uninstall.exe [/S] [/DELETEUSERDATA] [/NOCLOSEAPPS] [/LOG=\"Datei\"]\n\n"
    L"Exit-Codes: 0 ok, 1 Parameter, 2 abgebrochen, 3 Fehler, 4 Datei "
    L"beschaedigt, 5 App laeuft, 6 Downgrade, 7 Adminrechte, 8 Zielordner, "
    L"9 Rueckbau unvollstaendig, 10 nicht installiert, 11 Speicher, "
    L"12 anderer Installationsbereich.";

// --- Reporter ---------------------------------------------------------------

class SilentReporter : public Reporter {
 public:
  explicit SilentReporter(bool close_apps) : close_apps_(close_apps) {}
  void Phase(const char* name) override {
    Log::Line(L"Phase: " + Utf8ToWide(name));
  }
  void Progress(uint64_t done, uint64_t total) override {
    if (total == 0) return;
    const int percent = static_cast<int>(done * 100 / total);
    if (percent / 10 != last_ / 10) {
      last_ = percent;
      Log::Line(L"Fortschritt: " + std::to_wstring(percent) + L" %");
    }
  }
  bool ConfirmCloseApps(const std::vector<std::wstring>&) override {
    if (!close_apps_) Log::Line(L"/NOCLOSEAPPS: laufende App wird nicht beendet");
    return close_apps_;
  }
  bool Cancelled() override { return false; }

 private:
  bool close_apps_;
  int last_ = -1;
};

// Verbindung zur Setup-Oberflaeche. Die Oberflaeche ist Pipe-Server, die
// (ggf. erhoehte) Engine Client. SECURITY_IDENTIFICATION verhindert, dass der
// Server die erhoehte Engine voll impersonieren kann.
class PipeReporter : public Reporter {
 public:
  ~PipeReporter() override { Close(); }

  bool Connect(const std::wstring& name) {
    for (wchar_t c : name) {
      if (!((c >= L'a' && c <= L'z') || (c >= L'A' && c <= L'Z') ||
            (c >= L'0' && c <= L'9') || c == L'-')) {
        return false;
      }
    }
    if (name.empty() || name.size() > 64) return false;
    const std::wstring path = L"\\\\.\\pipe\\" + name;
    for (int attempt = 0; attempt < 50; ++attempt) {
      pipe_ = ::CreateFileW(path.c_str(), GENERIC_READ | GENERIC_WRITE, 0,
                            nullptr, OPEN_EXISTING,
                            SECURITY_SQOS_PRESENT | SECURITY_IDENTIFICATION,
                            nullptr);
      if (pipe_ != INVALID_HANDLE_VALUE) break;
      if (::GetLastError() == ERROR_PIPE_BUSY) {
        ::WaitNamedPipeW(path.c_str(), 200);
      } else {
        ::Sleep(100);
      }
    }
    if (pipe_ == INVALID_HANDLE_VALUE) return false;
    answer_event_ = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
    reader_ = std::thread([this] { ReadLoop(); });
    Send("hello " + std::to_string(::GetCurrentProcessId()));
    return true;
  }

  void Send(const std::string& line) {
    std::lock_guard<std::mutex> lock(write_mutex_);
    if (pipe_ == INVALID_HANDLE_VALUE) return;
    std::string data = line;
    for (auto& c : data) {
      if (c == '\n' || c == '\r') c = ' ';
    }
    data.push_back('\n');
    DWORD written = 0;
    ::WriteFile(pipe_, data.data(), static_cast<DWORD>(data.size()), &written,
                nullptr);
  }

  void Phase(const char* name) override {
    Log::Line(L"Phase: " + Utf8ToWide(name));
    Send(std::string("phase ") + name);
  }
  void Progress(uint64_t done, uint64_t total) override {
    const ULONGLONG now = ::GetTickCount64();
    if (done != total && now - last_progress_ < 50) return;
    last_progress_ = now;
    Send("progress " + std::to_string(done) + " " + std::to_string(total));
  }
  bool ConfirmCloseApps(const std::vector<std::wstring>& names) override {
    std::string line = "running";
    for (const auto& n : names) line += "\t" + WideToUtf8(n);
    ::ResetEvent(answer_event_);
    Send(line);
    for (;;) {
      if (::WaitForSingleObject(answer_event_, 250) == WAIT_OBJECT_0) break;
      if (cancelled_ || disconnected_) return false;
    }
    std::lock_guard<std::mutex> lock(answer_mutex_);
    return answer_ == "close";
  }
  bool Cancelled() override { return cancelled_ || disconnected_; }

  void Result(int code, const std::wstring& message) {
    Send("result " + std::to_string(code) + " " + WideToUtf8(message));
  }

  void Close() {
    if (pipe_ != INVALID_HANDLE_VALUE) {
      {
        std::lock_guard<std::mutex> lock(write_mutex_);
        ::FlushFileBuffers(pipe_);
      }
      ::CancelIoEx(pipe_, nullptr);
      if (reader_.joinable()) reader_.join();
      ::CloseHandle(pipe_);
      pipe_ = INVALID_HANDLE_VALUE;
    }
    if (answer_event_ != nullptr) {
      ::CloseHandle(answer_event_);
      answer_event_ = nullptr;
    }
  }

 private:
  void ReadLoop() {
    std::string buffer;
    char chunk[512];
    for (;;) {
      DWORD read = 0;
      if (!::ReadFile(pipe_, chunk, sizeof(chunk), &read, nullptr) ||
          read == 0) {
        disconnected_ = true;
        ::SetEvent(answer_event_);
        return;
      }
      buffer.append(chunk, read);
      if (buffer.size() > 4096) buffer.clear();  // Schutz vor Muell
      size_t pos;
      while ((pos = buffer.find('\n')) != std::string::npos) {
        std::string line = buffer.substr(0, pos);
        buffer.erase(0, pos + 1);
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line == "cancel") {
          cancelled_ = true;
          ::SetEvent(answer_event_);
        } else if (line == "close" || line == "keep") {
          std::lock_guard<std::mutex> lock(answer_mutex_);
          answer_ = line;
          ::SetEvent(answer_event_);
        }
      }
    }
  }

  HANDLE pipe_ = INVALID_HANDLE_VALUE;
  HANDLE answer_event_ = nullptr;
  std::thread reader_;
  std::mutex write_mutex_;
  std::mutex answer_mutex_;
  std::string answer_;
  std::atomic<bool> cancelled_{false};
  std::atomic<bool> disconnected_{false};
  ULONGLONG last_progress_ = 0;
};

// --- Hilfen -----------------------------------------------------------------

InstallRequest RequestFrom(const Args& args) {
  InstallRequest r;
  r.scope_given = args.all_users || args.current_user;
  r.per_machine = args.all_users;
  r.dir = args.dir;
  r.desktop_given = args.desktop >= 0;
  r.desktop = args.desktop == 1;
  r.start_menu_given = args.start_menu >= 0;
  r.start_menu = args.start_menu == 1;
  r.autostart_given = args.autostart >= 0;
  r.autostart = args.autostart == 1;
  r.allow_downgrade = args.allow_downgrade;
  return r;
}

void StartLog(const Args& args) {
  if (!args.log.empty()) Log::OpenFile(FullPath(args.log));
}

int Finish(int code, const std::wstring& message, bool console) {
  Log::Line(L"Exit-Code " + std::to_wstring(code) +
            (message.empty() ? L"" : L": " + message));
  if (console) {
    ConsoleLine(L"LINEFM Radio Setup: Exit-Code " + std::to_wstring(code) +
                (message.empty() ? L"" : L" (" + message + L")"));
  }
  Log::Close();
  return code;
}

// Startet einen Prozess und vererbt nur die angegebenen Handles.
HANDLE StartWithHandles(const std::wstring& exe, const std::wstring& args,
                        std::vector<HANDLE> handles) {
  SIZE_T size = 0;
  ::InitializeProcThreadAttributeList(nullptr, 1, 0, &size);
  std::vector<uint8_t> buffer(size);
  auto* list = reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(buffer.data());
  if (!::InitializeProcThreadAttributeList(list, 1, 0, &size)) return nullptr;
  if (!handles.empty() &&
      !::UpdateProcThreadAttribute(list, 0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
                                   handles.data(),
                                   handles.size() * sizeof(HANDLE), nullptr,
                                   nullptr)) {
    ::DeleteProcThreadAttributeList(list);
    return nullptr;
  }
  STARTUPINFOEXW si = {};
  si.StartupInfo.cb = sizeof(si);
  si.lpAttributeList = list;
  PROCESS_INFORMATION pi = {};
  std::wstring command = Quote(exe) + L" " + args;
  const std::wstring dir = ParentDir(exe);
  const BOOL ok = ::CreateProcessW(
      exe.c_str(), command.data(), nullptr, nullptr, handles.empty() ? FALSE : TRUE,
      EXTENDED_STARTUPINFO_PRESENT, nullptr, dir.c_str(), &si.StartupInfo, &pi);
  ::DeleteProcThreadAttributeList(list);
  if (!ok) return nullptr;
  ::CloseHandle(pi.hThread);
  return pi.hProcess;
}

DWORD WaitExit(HANDLE process) {
  ::WaitForSingleObject(process, INFINITE);
  DWORD code = kExitFailed;
  ::GetExitCodeProcess(process, &code);
  ::CloseHandle(process);
  return code;
}

std::string BoolJson(bool v) { return v ? "true" : "false"; }

std::string InstalledJson(const InstalledInfo& info) {
  if (!info.found) return "null";
  return "{\"version\":" + JsonString(info.version) +
         ",\"scope\":" + (info.per_machine ? "\"machine\"" : "\"user\"") +
         ",\"dir\":" + JsonString(info.dir) +
         ",\"desktop\":" + BoolJson(info.desktop) +
         ",\"startMenu\":" + BoolJson(info.start_menu) +
         ",\"autostart\":" + BoolJson(info.autostart) + "}";
}

std::string ContextJson(const std::wstring& mode, const Product& p,
                        const std::wstring& engine, const InstalledInfo& user,
                        const InstalledInfo& machine, uint64_t size,
                        const std::wstring& target) {
  std::string json = "{";
  json += "\"mode\":" + JsonString(mode);
  json += ",\"engine\":" + JsonString(engine);
  json += ",\"product\":{\"name\":" + JsonString(p.name) +
          ",\"version\":" + JsonString(p.version) +
          ",\"publisher\":" + JsonString(p.publisher) +
          ",\"exe\":" + JsonString(p.exe_name) +
          ",\"url\":" + JsonString(p.url) + "}";
  json += ",\"installed\":{\"user\":" + InstalledJson(user) +
          ",\"machine\":" + InstalledJson(machine) + "}";
  json += ",\"defaults\":{\"scope\":" + JsonString(p.default_scope) +
          ",\"userDir\":" + JsonString(DefaultUserInstallDir(p.dir_name)) +
          ",\"machineDir\":" + JsonString(DefaultMachineInstallDir(p.dir_name)) +
          ",\"desktop\":" + BoolJson(p.default_desktop) +
          ",\"startMenu\":" + BoolJson(p.default_start_menu) +
          ",\"autostart\":" + BoolJson(p.default_autostart) + "}";
  json += ",\"elevated\":" + BoolJson(IsProcessElevated());
  json += ",\"sizeBytes\":" + std::to_string(size);
  json += ",\"target\":" + JsonString(target);
  json += "}";
  return json;
}

// Startet die Oberflaeche und wartet auf ihr Ende.
int RunUi(const std::wstring& ui_dir, const std::string& context) {
  const std::wstring context_path = JoinPath(ui_dir, L"context.json");
  if (!WriteWholeFile(context_path, context.data(), context.size())) {
    return -1;
  }
  const std::wstring exe = JoinPath(ui_dir, kUiExeName);
  DWORD error = 0;
  HANDLE process =
      StartProcess(exe, L"--context " + QuoteArg(context_path), false, &error);
  if (process == nullptr) {
    Log::Line(L"Oberflaeche startet nicht: " + FormatWin32Error(error));
    return -1;
  }
  const DWORD code = WaitExit(process);
  // 0xC0000135 u. ae.: fehlende DLL, die Oberflaeche lief nie.
  if (code >= 0xC0000000u) {
    Log::Line(L"Oberflaeche abgestuerzt: " + std::to_wstring(code));
    return -1;
  }
  return static_cast<int>(code);
}

// --- setup.exe --------------------------------------------------------------

int OpenSetupPayload(Payload& payload, Product* product, std::wstring* error) {
  if (!payload.has_payload()) {
    *error = L"Keine Nutzlast";
    return kExitCorrupt;
  }
  if (!payload.VerifyArchiveHash(error)) return kExitCorrupt;
  if (!payload.ReadProduct(product, error)) return kExitCorrupt;
  return kExitOk;
}

int SetupEngine(Payload& payload, const Args& args) {
  PipeReporter reporter;
  if (!reporter.Connect(args.pipe)) return kExitBadArgs;
  Log::SetSink([&reporter](const std::wstring& line) {
    reporter.Send("log " + WideToUtf8(line));
  });
  Product product;
  std::wstring message;
  int code = OpenSetupPayload(payload, &product, &message);
  if (code == kExitOk) {
    code = RunInstall(payload, product, RequestFrom(args), reporter, &message);
  }
  Log::SetSink(nullptr);
  reporter.Result(code, message);
  reporter.Close();
  return code;
}

int SetupSilent(Payload& payload, const Args& args) {
  StartLog(args);
  Product product;
  std::wstring message;
  int code = OpenSetupPayload(payload, &product, &message);
  if (code != kExitOk) return Finish(code, message, true);
  SilentReporter reporter(!args.no_close_apps);
  code = RunInstall(payload, product, RequestFrom(args), reporter, &message);
  return Finish(code, code == kExitOk ? std::wstring() : message, true);
}

int SetupGui(Payload& payload, const Args& args) {
  StartLog(args);
  Product product;
  std::wstring message;
  int code = OpenSetupPayload(payload, &product, &message);
  if (code != kExitOk) {
    ShowMessage(L"Die Setup-Datei ist beschaedigt. Bitte erneut herunterladen.\n\n" +
                    message,
                L"The setup file is damaged. Please download it again.\n\n" +
                    message);
    return Finish(code, message, false);
  }
  std::wstring temp;
  if (!CreatePrivateDir(false, L"linefm-setup-", &temp, &message)) {
    ShowMessage(L"Setup kann nicht starten: " + message,
                L"Setup cannot start: " + message);
    return Finish(kExitFailed, message, false);
  }
  const std::wstring ui_dir = JoinPath(temp, L"ui");
  bool ok = ::CreateDirectoryW(ui_dir.c_str(), nullptr) != 0;
  uint64_t app_size = 0;
  for (const auto& entry : payload.entries()) {
    if (StartsWithI(entry.path, L"app/")) app_size += entry.size;
    if (!ok || !StartsWithI(entry.path, L"ui/")) continue;
    std::wstring rel = entry.path.substr(3);
    for (auto& c : rel) {
      if (c == L'/') c = L'\\';
    }
    const std::wstring dest = JoinPath(ui_dir, rel);
    // Unterordner anlegen (data\flutter_assets\...).
    std::wstring parent = ParentDir(dest);
    std::vector<std::wstring> missing;
    while (IsSubPathOf(parent, ui_dir) && !DirExists(parent)) {
      missing.push_back(parent);
      parent = ParentDir(parent);
    }
    for (auto it = missing.rbegin(); it != missing.rend(); ++it) {
      ::CreateDirectoryW(it->c_str(), nullptr);
    }
    ok = payload.ExtractToFile(entry, dest, &message);
  }
  int result = -1;
  if (ok) {
    const std::string context = ContextJson(
        L"install", product, SelfPath(), FindInstalled(product, 0),
        FindInstalled(product, 1), app_size, std::wstring());
    result = RunUi(ui_dir, context);
  }
  DeleteTree(temp);
  if (result < 0) {
    ShowMessage(
        L"Die Setup-Oberflaeche konnte nicht starten. Die stille Installation "
        L"funktioniert weiterhin: setup.exe /S\n\n" + message,
        L"The setup window could not start. Silent installation still works: "
        L"setup.exe /S\n\n" + message);
    return Finish(kExitFailed, L"Oberflaeche nicht startbar", false);
  }
  return Finish(result, std::wstring(), false);
}

// --- uninstall.exe ----------------------------------------------------------

int UninstallEngine(const Args& args) {
  PipeReporter reporter;
  if (!reporter.Connect(args.pipe)) return kExitBadArgs;
  Log::SetSink([&reporter](const std::wstring& line) {
    reporter.Send("log " + WideToUtf8(line));
  });
  const std::wstring dir = FullPath(args.target);
  Product product;
  Manifest manifest;
  std::wstring message;
  int code = kExitNotInstalled;
  if (!dir.empty() && ReadManifest(dir, &manifest) &&
      ParseProduct(manifest.product_ini, &product, &message)) {
    UninstallRequest request;
    request.dir = dir;
    request.per_machine = manifest.per_machine;
    request.delete_user_data = args.delete_user_data;
    code = RunUninstall(product, request, reporter, &message);
  } else {
    message = L"Keine Installation in " + args.target;
  }
  Log::SetSink(nullptr);
  reporter.Result(code, message);
  reporter.Close();
  return code;
}

// Kopiert die Setup-Oberflaeche aus dem Installationsordner und prueft jede
// Datei gegen die Pruefsumme aus uninstall.dat.
bool CopyUi(const std::wstring& app_dir, const Manifest& manifest,
            const std::wstring& ui_dir) {
  if (manifest.ui.empty()) return false;
  if (!::CreateDirectoryW(ui_dir.c_str(), nullptr)) return false;
  for (const auto& file : manifest.ui) {
    const std::wstring source = JoinPath(app_dir, file.source);
    const std::wstring dest = JoinPath(ui_dir, file.dest);
    if (!IsSubPathOf(source, app_dir) || !IsSubPathOf(dest, ui_dir)) {
      return false;
    }
    std::wstring parent = ParentDir(dest);
    std::vector<std::wstring> missing;
    while (IsSubPathOf(parent, ui_dir) && !DirExists(parent)) {
      missing.push_back(parent);
      parent = ParentDir(parent);
    }
    for (auto it = missing.rbegin(); it != missing.rend(); ++it) {
      ::CreateDirectoryW(it->c_str(), nullptr);
    }
    if (!::CopyFileW(source.c_str(), dest.c_str(), FALSE)) return false;
    uint8_t digest[32] = {};
    if (!Sha256File(dest, digest) || ToHex(digest, 32) != file.sha256) {
      Log::Line(L"Oberflaeche beschaedigt: " + file.dest);
      return false;
    }
  }
  return true;
}

// Erste Phase: laeuft aus dem Installationsordner. Kopiert sich in einen
// privaten Temp-Ordner und startet dort Phase 2, damit der
// Installationsordner samt uninstall.exe geloescht werden kann.
int UninstallFirstPhase(const Args& args) {
  StartLog(args);
  const std::wstring app_dir = ParentDir(SelfPath());
  Manifest manifest;
  Product product;
  std::wstring message;
  if (!ReadManifest(app_dir, &manifest) ||
      !ParseProduct(manifest.product_ini, &product, &message)) {
    if (!args.silent) {
      ShowMessage(L"LINEFM Radio ist hier nicht (mehr) installiert.",
                  L"LINEFM Radio is not installed here (anymore).",
                  MB_ICONINFORMATION);
    }
    return Finish(kExitNotInstalled, L"uninstall.dat fehlt", args.silent);
  }
  const bool elevated = IsProcessElevated();
  if (manifest.per_machine && !elevated) {
    if (args.silent) {
      return Finish(kExitElevation, L"Administratorrechte noetig", true);
    }
    // Oberflaeche: sich selbst erhoeht neu starten und sofort enden, damit
    // uninstall.exe nicht gesperrt bleibt.
    std::wstring raw;
    for (const auto& a : args.raw) raw += QuoteArg(a) + L" ";
    DWORD error = 0;
    HANDLE process = StartProcessElevated(SelfPath(), raw, nullptr, &error);
    if (process == nullptr) {
      return Finish(error == ERROR_CANCELLED ? kExitCancelled : kExitElevation,
                    L"Erhoehung abgelehnt", false);
    }
    ::CloseHandle(process);
    return Finish(kExitOk, std::wstring(), false);
  }

  std::wstring temp;
  if (!CreatePrivateDir(elevated, L"linefm-uninstall-", &temp, &message)) {
    if (!args.silent) ShowMessage(message, message);
    return Finish(kExitFailed, message, args.silent);
  }
  const std::wstring copy = JoinPath(temp, kUninstallerName);
  uint8_t self_digest[32] = {};
  uint8_t copy_digest[32] = {};
  if (!::CopyFileW(SelfPath().c_str(), copy.c_str(), FALSE) ||
      !Sha256File(SelfPath(), self_digest) || !Sha256File(copy, copy_digest) ||
      std::memcmp(self_digest, copy_digest, 32) != 0) {
    DeleteTree(temp);
    return Finish(kExitFailed, L"Kopie in Temp fehlgeschlagen", args.silent);
  }
  bool gui = !args.silent;
  if (gui && !CopyUi(app_dir, manifest, JoinPath(temp, L"ui"))) {
    // Ohne Oberflaeche: einfache Rueckfrage, dann wie still.
    DeleteTree(JoinPath(temp, L"ui"));
    const int answer = ::MessageBoxW(
        nullptr,
        IsGerman() ? L"LINEFM Radio deinstallieren? Deine Einstellungen und "
                     L"Favoriten bleiben erhalten."
                   : L"Uninstall LINEFM Radio? Your settings and favourites "
                     L"are kept.",
        L"LINEFM Radio", MB_YESNO | MB_ICONQUESTION | MB_SETFOREGROUND);
    if (answer != IDYES) {
      DeleteTree(temp);
      return Finish(kExitCancelled, std::wstring(), false);
    }
    gui = false;
  }

  // Eigener Prozess-Handle (zum Warten) und Ergebnis-Pipe fuer Phase 2.
  HANDLE self = nullptr;
  ::DuplicateHandle(::GetCurrentProcess(), ::GetCurrentProcess(),
                    ::GetCurrentProcess(), &self, SYNCHRONIZE, TRUE, 0);
  SECURITY_ATTRIBUTES sa = {sizeof(sa), nullptr, TRUE};
  HANDLE result_read = nullptr;
  HANDLE result_write = nullptr;
  ::CreatePipe(&result_read, &result_write, &sa, 0);
  ::SetHandleInformation(result_read, HANDLE_FLAG_INHERIT, 0);

  std::wstring child_args = L"--phase2 --target " + QuoteArg(app_dir);
  child_args += L" --parent-handle " +
                std::to_wstring(reinterpret_cast<uintptr_t>(self));
  child_args += L" --result-handle " +
                std::to_wstring(reinterpret_cast<uintptr_t>(result_write));
  if (gui) child_args += L" --gui";
  if (args.delete_user_data) child_args += L" --delete-user-data";
  if (args.no_close_apps) child_args += L" --no-close-apps";
  if (!args.log.empty()) child_args += L" --log " + QuoteArg(FullPath(args.log));
  Log::Close();  // Phase 2 schreibt in dieselbe Datei weiter.

  HANDLE child = StartWithHandles(copy, child_args, {self, result_write});
  ::CloseHandle(result_write);
  if (child == nullptr) {
    ::CloseHandle(result_read);
    ::CloseHandle(self);
    DeleteTree(temp);
    return kExitFailed;
  }
  ::CloseHandle(child);
  int code = kExitOk;
  if (!gui) {
    // Still: auf das Ergebnis von Phase 2 warten (sie loescht uninstall.exe
    // erst, wenn dieser Prozess beendet ist).
    std::string text;
    char buffer[64];
    DWORD read = 0;
    while (::ReadFile(result_read, buffer, sizeof(buffer), &read, nullptr) &&
           read > 0) {
      text.append(buffer, read);
    }
    code = text.empty() ? kExitFailed : atoi(text.c_str());
    ConsoleLine(L"LINEFM Radio Uninstall: Exit-Code " + std::to_wstring(code));
  }
  ::CloseHandle(result_read);
  ::CloseHandle(self);
  return code;
}

void ScheduleSelfCleanup(const std::wstring& temp_dir) {
  if (IsProcessElevated()) {
    // Laufende EXE und ihr Ordner werden beim naechsten Neustart entfernt.
    ::MoveFileExW(SelfPath().c_str(), nullptr, MOVEFILE_DELAY_UNTIL_REBOOT);
    ::MoveFileExW(temp_dir.c_str(), nullptr, MOVEFILE_DELAY_UNTIL_REBOOT);
  }
  // Ohne Adminrechte bleibt nur die kleine Kopie (uninstall.exe) im eigenen
  // Temp-Ordner; Windows raeumt Temp-Dateien bei der Speicherbereinigung ab.
}

int UninstallSecondPhase(const Args& args) {
  StartLog(args);
  const std::wstring temp_dir = ParentDir(SelfPath());
  const std::wstring app_dir = FullPath(args.target);
  auto report = [&](int code) {
    if (args.result_handle != nullptr) {
      const std::string text = std::to_string(code);
      DWORD written = 0;
      ::WriteFile(args.result_handle, text.data(),
                  static_cast<DWORD>(text.size()), &written, nullptr);
      ::CloseHandle(args.result_handle);
    }
  };
  auto wait_parent = [&]() {
    if (args.parent_handle != nullptr) {
      ::WaitForSingleObject(args.parent_handle, 30000);
      ::CloseHandle(args.parent_handle);
    }
  };
  Manifest manifest;
  Product product;
  std::wstring message;
  if (app_dir.empty() || !ReadManifest(app_dir, &manifest) ||
      !ParseProduct(manifest.product_ini, &product, &message)) {
    report(kExitNotInstalled);
    wait_parent();
    return Finish(kExitNotInstalled, L"uninstall.dat fehlt", false);
  }

  if (args.gui) {
    report(kExitOk);
    wait_parent();
    InstalledInfo none;
    InstalledInfo installed = FindInstalled(product, manifest.per_machine ? 1 : 0);
    const std::string context = ContextJson(
        L"uninstall", product, SelfPath(),
        manifest.per_machine ? none : installed,
        manifest.per_machine ? installed : none, 0, app_dir);
    Log::Close();
    const int code = RunUi(JoinPath(temp_dir, L"ui"), context);
    StartLog(args);
    DeleteTree(JoinPath(temp_dir, L"ui"));
    ScheduleSelfCleanup(temp_dir);
    return Finish(code < 0 ? kExitFailed : code, std::wstring(), false);
  }

  // Still.
  SilentReporter reporter(!args.no_close_apps);
  UninstallRequest request;
  request.dir = app_dir;
  request.per_machine = manifest.per_machine;
  request.delete_user_data = args.delete_user_data;
  request.keep_uninstaller = true;
  const int code = RunUninstall(product, request, reporter, &message);
  report(code);
  wait_parent();
  if (code == kExitOk) {
    // Jetzt ist Phase 1 beendet: uninstall.exe und den Ordner entfernen.
    const std::wstring uninstaller = JoinPath(app_dir, kUninstallerName);
    for (int i = 0; i < 20 && FileExists(uninstaller); ++i) {
      if (::DeleteFileW(uninstaller.c_str())) break;
      ::Sleep(250);
    }
    ::RemoveDirectoryW(app_dir.c_str());
  }
  ScheduleSelfCleanup(temp_dir);
  return Finish(code, message, false);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE, _In_opt_ HINSTANCE, _In_ wchar_t*,
                      _In_ int) {
  // Schutz gegen DLL-Planting: nachgeladene DLLs nur aus System32, nie aus
  // dem (Download-)Ordner der EXE oder dem aktuellen Verzeichnis. Statische
  // Importe deckt /DEPENDENTLOADFLAG:0x800 ab (CMakeLists.txt).
  ::SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_SYSTEM32);
  ::SetDllDirectoryW(L"");
  ::HeapSetInformation(nullptr, HeapEnableTerminationOnCorruption, nullptr, 0);
  ::SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOOPENFILEERRORBOX);
  // Aktuelles Verzeichnis weg vom Download-Ordner.
  {
    const std::wstring system32 = KnownFolder(FOLDERID_System);
    if (!system32.empty()) ::SetCurrentDirectoryW(system32.c_str());
  }
  const HRESULT com = ::CoInitializeEx(
      nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

  const Args args = ParseArgs();
  int code = kExitBadArgs;
  if (args.help) {
    ::MessageBoxW(nullptr, kUsage, L"LINEFM Radio Setup",
                  MB_OK | MB_ICONINFORMATION);
    code = kExitOk;
  } else if (!args.unknown.empty()) {
    ConsoleLine(L"Unbekannter Parameter: " + args.unknown);
    if (!args.silent) {
      ShowMessage(L"Unbekannter Parameter: " + args.unknown + L"\n\n" + kUsage,
                  L"Unknown parameter: " + args.unknown + L"\n\n" + kUsage);
    }
    code = kExitBadArgs;
  } else {
    Payload payload;
    std::wstring error;
    if (!payload.Open(SelfPath(), &error)) {
      if (!args.silent) {
        ShowMessage(L"Die Setup-Datei ist beschaedigt. Bitte erneut "
                    L"herunterladen.\n\n" + error,
                    L"The setup file is damaged. Please download it "
                    L"again.\n\n" + error);
      }
      ConsoleLine(error);
      code = kExitCorrupt;
    } else if (payload.has_payload()) {
      if (args.engine == L"install") {
        code = SetupEngine(payload, args);
      } else if (args.silent) {
        code = SetupSilent(payload, args);
      } else {
        code = SetupGui(payload, args);
      }
    } else {
      if (args.engine == L"uninstall") {
        code = UninstallEngine(args);
      } else if (args.phase2) {
        code = UninstallSecondPhase(args);
      } else {
        code = UninstallFirstPhase(args);
      }
    }
  }
  if (SUCCEEDED(com)) ::CoUninitialize();
  return code;
}
