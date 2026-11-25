#include "engine.h"

#include <knownfolders.h>
#include <objbase.h>
#include <restartmanager.h>
#include <shlobj.h>
#include <shobjidl.h>

#include <algorithm>
#include <cstdlib>
#include <cwchar>
#include <cstring>
#include <map>
#include <set>

#include "../common/secure.h"

namespace lf {

namespace {

constexpr wchar_t kUninstallRoot[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\";
constexpr wchar_t kAppPathsRoot[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\";
constexpr wchar_t kRunKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr wchar_t kClassesRoot[] = L"Software\\Classes\\";
constexpr wchar_t kUiDirName[] = L"setup";

HKEY RootFor(bool per_machine) {
  return per_machine ? HKEY_LOCAL_MACHINE : HKEY_CURRENT_USER;
}

std::wstring UninstallKey(const Product& p) { return kUninstallRoot + p.app_id; }

// --- Registry ---------------------------------------------------------------

bool RegGetString(HKEY root, const std::wstring& key, const wchar_t* name,
                  std::wstring* out) {
  DWORD type = 0;
  DWORD size = 0;
  if (::RegGetValueW(root, key.c_str(), name, RRF_RT_REG_SZ | RRF_RT_REG_EXPAND_SZ |
                                                  RRF_NOEXPAND,
                     &type, nullptr, &size) != ERROR_SUCCESS) {
    return false;
  }
  std::wstring buffer(size / sizeof(wchar_t) + 1, L'\0');
  size = static_cast<DWORD>(buffer.size() * sizeof(wchar_t));
  if (::RegGetValueW(root, key.c_str(), name,
                     RRF_RT_REG_SZ | RRF_RT_REG_EXPAND_SZ | RRF_NOEXPAND,
                     &type, buffer.data(), &size) != ERROR_SUCCESS) {
    return false;
  }
  buffer.resize(wcsnlen(buffer.c_str(), buffer.size()));
  *out = buffer;
  return true;
}

bool RegGetDword(HKEY root, const std::wstring& key, const wchar_t* name,
                 DWORD* out) {
  DWORD size = sizeof(DWORD);
  return ::RegGetValueW(root, key.c_str(), name, RRF_RT_REG_DWORD, nullptr,
                        out, &size) == ERROR_SUCCESS;
}

bool RegSetString(HKEY root, const std::wstring& key, const wchar_t* name,
                  const std::wstring& value) {
  return ::RegSetKeyValueW(root, key.c_str(), name, REG_SZ, value.c_str(),
                           static_cast<DWORD>((value.size() + 1) *
                                              sizeof(wchar_t))) ==
         ERROR_SUCCESS;
}

bool RegSetDword(HKEY root, const std::wstring& key, const wchar_t* name,
                 DWORD value) {
  return ::RegSetKeyValueW(root, key.c_str(), name, REG_DWORD, &value,
                           sizeof(value)) == ERROR_SUCCESS;
}

bool RegKeyExists(HKEY root, const std::wstring& key) {
  HKEY handle = nullptr;
  if (::RegOpenKeyExW(root, key.c_str(), 0, KEY_READ, &handle) !=
      ERROR_SUCCESS) {
    return false;
  }
  ::RegCloseKey(handle);
  return true;
}

void RegDeleteTreeKey(HKEY root, const std::wstring& key) {
  ::RegDeleteTreeW(root, key.c_str());
  ::RegDeleteKeyW(root, key.c_str());
}

struct RegNode {
  struct Value {
    std::wstring name;
    DWORD type = 0;
    std::vector<uint8_t> data;
  };
  std::vector<Value> values;
  std::vector<std::pair<std::wstring, RegNode>> children;
};

void ReadTree(HKEY key, RegNode* node, int depth) {
  if (depth > 16) return;
  for (DWORD i = 0;; ++i) {
    wchar_t name[16384];
    DWORD name_size = 16384;
    DWORD type = 0;
    DWORD data_size = 0;
    LONG rc = ::RegEnumValueW(key, i, name, &name_size, nullptr, &type,
                              nullptr, &data_size);
    if (rc != ERROR_SUCCESS) break;
    RegNode::Value value;
    value.name.assign(name, name_size);
    value.type = type;
    value.data.resize(data_size);
    name_size = 16384;
    rc = ::RegEnumValueW(key, i, name, &name_size, nullptr, &type,
                         value.data.empty() ? nullptr : value.data.data(),
                         &data_size);
    if (rc != ERROR_SUCCESS) break;
    value.data.resize(data_size);
    node->values.push_back(std::move(value));
  }
  for (DWORD i = 0;; ++i) {
    wchar_t name[256];
    DWORD name_size = 256;
    if (::RegEnumKeyExW(key, i, name, &name_size, nullptr, nullptr, nullptr,
                        nullptr) != ERROR_SUCCESS) {
      break;
    }
    HKEY child = nullptr;
    if (::RegOpenKeyExW(key, name, 0, KEY_READ, &child) == ERROR_SUCCESS) {
      RegNode sub;
      ReadTree(child, &sub, depth + 1);
      ::RegCloseKey(child);
      node->children.emplace_back(std::wstring(name, name_size),
                                  std::move(sub));
    }
  }
}

void WriteTree(HKEY key, const RegNode& node) {
  for (const auto& value : node.values) {
    ::RegSetValueExW(key, value.name.empty() ? nullptr : value.name.c_str(), 0,
                     value.type,
                     value.data.empty() ? nullptr : value.data.data(),
                     static_cast<DWORD>(value.data.size()));
  }
  for (const auto& [name, child] : node.children) {
    HKEY sub = nullptr;
    if (::RegCreateKeyExW(key, name.c_str(), 0, nullptr, 0, KEY_ALL_ACCESS,
                          nullptr, &sub, nullptr) == ERROR_SUCCESS) {
      WriteTree(sub, child);
      ::RegCloseKey(sub);
    }
  }
}

struct RegKeySnapshot {
  HKEY root = nullptr;
  std::wstring path;
  bool existed = false;
  RegNode node;
};

RegKeySnapshot SnapshotKey(HKEY root, const std::wstring& path) {
  RegKeySnapshot snap;
  snap.root = root;
  snap.path = path;
  HKEY key = nullptr;
  if (::RegOpenKeyExW(root, path.c_str(), 0, KEY_READ, &key) ==
      ERROR_SUCCESS) {
    snap.existed = true;
    ReadTree(key, &snap.node, 0);
    ::RegCloseKey(key);
  }
  return snap;
}

void RestoreKey(const RegKeySnapshot& snap) {
  RegDeleteTreeKey(snap.root, snap.path);
  if (!snap.existed) return;
  HKEY key = nullptr;
  if (::RegCreateKeyExW(snap.root, snap.path.c_str(), 0, nullptr, 0,
                        KEY_ALL_ACCESS, nullptr, &key,
                        nullptr) == ERROR_SUCCESS) {
    WriteTree(key, snap.node);
    ::RegCloseKey(key);
  }
}

struct RegValueSnapshot {
  HKEY root = nullptr;
  std::wstring key;
  std::wstring name;
  bool existed = false;
  DWORD type = 0;
  std::vector<uint8_t> data;
};

RegValueSnapshot SnapshotValue(HKEY root, const std::wstring& key,
                               const std::wstring& name) {
  RegValueSnapshot snap;
  snap.root = root;
  snap.key = key;
  snap.name = name;
  DWORD size = 0;
  if (::RegGetValueW(root, key.c_str(), name.c_str(),
                     RRF_RT_ANY | RRF_NOEXPAND, &snap.type, nullptr,
                     &size) == ERROR_SUCCESS) {
    snap.data.resize(size);
    if (::RegGetValueW(root, key.c_str(), name.c_str(),
                       RRF_RT_ANY | RRF_NOEXPAND, &snap.type,
                       snap.data.empty() ? nullptr : snap.data.data(),
                       &size) == ERROR_SUCCESS) {
      snap.data.resize(size);
      snap.existed = true;
    }
  }
  return snap;
}

void RestoreValue(const RegValueSnapshot& snap) {
  if (snap.existed) {
    ::RegSetKeyValueW(snap.root, snap.key.c_str(), snap.name.c_str(),
                      snap.type, snap.data.empty() ? nullptr : snap.data.data(),
                      static_cast<DWORD>(snap.data.size()));
  } else {
    ::RegDeleteKeyValueW(snap.root, snap.key.c_str(), snap.name.c_str());
  }
}

// --- Transaktion ------------------------------------------------------------

// Merkt sich jede Aenderung, damit Abbruch und Fehler alles zuruecknehmen.
class Txn {
 public:
  void CreatedDir(const std::wstring& path) { ops_.push_back({kDir, path, {}}); }
  void CreatedFile(const std::wstring& path) {
    ops_.push_back({kFile, path, {}});
  }
  // `path` wurde nach `backup` verschoben (und ggf. neu geschrieben).
  void Replaced(const std::wstring& path, const std::wstring& backup) {
    ops_.push_back({kReplaced, path, backup});
  }
  void Key(RegKeySnapshot snap) {
    keys_.push_back(std::move(snap));
    ops_.push_back({kKey, std::wstring(), std::wstring(), keys_.size() - 1});
  }
  void Value(RegValueSnapshot snap) {
    values_.push_back(std::move(snap));
    ops_.push_back(
        {kValue, std::wstring(), std::wstring(), values_.size() - 1});
  }

  // Nimmt alles in umgekehrter Reihenfolge zurueck. false, wenn etwas nicht
  // wiederhergestellt werden konnte.
  bool Rollback() {
    bool ok = true;
    for (auto it = ops_.rbegin(); it != ops_.rend(); ++it) {
      switch (it->kind) {
        case kFile:
          if (FileExists(it->path) && !::DeleteFileW(it->path.c_str())) {
            ok = false;
            Log::Line(L"Rueckbau: konnte nicht loeschen: " + it->path);
          }
          break;
        case kReplaced:
          if (FileExists(it->path)) ::DeleteFileW(it->path.c_str());
          if (!::MoveFileExW(it->backup.c_str(), it->path.c_str(),
                             MOVEFILE_REPLACE_EXISTING)) {
            ok = false;
            Log::Line(L"Rueckbau: konnte nicht wiederherstellen: " + it->path);
          }
          break;
        case kDir:
          ::RemoveDirectoryW(it->path.c_str());
          break;
        case kKey:
          RestoreKey(keys_[it->index]);
          break;
        case kValue:
          RestoreValue(values_[it->index]);
          break;
      }
    }
    ops_.clear();
    return ok;
  }

  void Commit() {
    for (const auto& op : ops_) {
      if (op.kind == kReplaced && FileExists(op.backup)) {
        if (!::DeleteFileW(op.backup.c_str())) {
          // Noch gesperrt: beim naechsten Neustart loeschen (nur mit
          // Adminrechten moeglich), sonst bleibt die Sicherung liegen.
          ::MoveFileExW(op.backup.c_str(), nullptr,
                        MOVEFILE_DELAY_UNTIL_REBOOT);
          Log::Line(L"Sicherung nicht loeschbar: " + op.backup);
        }
      }
    }
    ops_.clear();
  }

 private:
  enum Kind { kDir, kFile, kReplaced, kKey, kValue };
  struct Op {
    Kind kind;
    std::wstring path;
    std::wstring backup;
    size_t index = 0;
  };
  std::vector<Op> ops_;
  std::vector<RegKeySnapshot> keys_;
  std::vector<RegValueSnapshot> values_;
};

// Legt fehlende Ordner an (von oben nach unten) und vermerkt sie.
bool CreateDirs(const std::wstring& dir, Txn* txn, bool protect,
                std::wstring* error) {
  std::vector<std::wstring> missing;
  std::wstring current = NormalizePath(dir);
  while (!current.empty() && !DirExists(current)) {
    missing.push_back(current);
    const std::wstring parent = ParentDir(current);
    if (parent == current) break;
    current = parent;
  }
  for (auto it = missing.rbegin(); it != missing.rend(); ++it) {
    if (!::CreateDirectoryW(it->c_str(), nullptr) &&
        ::GetLastError() != ERROR_ALREADY_EXISTS) {
      if (error != nullptr) {
        *error = L"Ordner nicht anlegbar: " + *it + L" (" +
                 FormatWin32Error(::GetLastError()) + L")";
      }
      return false;
    }
    if (txn != nullptr) txn->CreatedDir(*it);
    // Nur der oberste neue Ordner braucht die geschuetzte DACL, alle
    // darunter erben sie.
    if (protect && it == missing.rbegin() &&
        !ProtectMachineDir(*it, error)) {
      return false;
    }
  }
  return true;
}

std::wstring BackupName(const std::wstring& path) {
  return path + L".lfold-" + RandomHex(4);
}

// --- Verknuepfungen ---------------------------------------------------------

bool CreateShortcut(const std::wstring& lnk, const std::wstring& target,
                    const std::wstring& description, std::wstring* error) {
  IShellLinkW* link = nullptr;
  HRESULT hr = ::CoCreateInstance(CLSID_ShellLink, nullptr,
                                  CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&link));
  if (FAILED(hr)) {
    if (error != nullptr) *error = L"Verknuepfung: COM nicht verfuegbar";
    return false;
  }
  // IShellLink speichert Pfade strukturiert; Leerzeichen brauchen hier keine
  // Anfuehrungszeichen.
  link->SetPath(target.c_str());
  link->SetWorkingDirectory(ParentDir(target).c_str());
  link->SetDescription(description.c_str());
  link->SetIconLocation(target.c_str(), 0);
  IPersistFile* file = nullptr;
  hr = link->QueryInterface(IID_PPV_ARGS(&file));
  if (SUCCEEDED(hr)) {
    hr = file->Save(lnk.c_str(), TRUE);
    file->Release();
  }
  link->Release();
  if (FAILED(hr) && error != nullptr) {
    *error = L"Verknuepfung nicht speicherbar: " + lnk;
  }
  return SUCCEEDED(hr);
}

// --- Restart Manager --------------------------------------------------------

// Beendet laufende Prozesse, die eine der Dateien nutzen. Fragt vorher ueber
// den Reporter. Rueckgabe: kExitOk oder kExitAppRunning.
int CloseRunningApps(const std::vector<std::wstring>& files,
                     Reporter& reporter) {
  if (files.empty()) return kExitOk;
  DWORD session = 0;
  wchar_t key[CCH_RM_SESSION_KEY + 1] = {};
  if (::RmStartSession(&session, 0, key) != ERROR_SUCCESS) {
    Log::Line(L"Restart Manager nicht verfuegbar");
    return kExitOk;
  }
  std::vector<LPCWSTR> names;
  for (const auto& f : files) names.push_back(f.c_str());
  int result = kExitOk;
  std::vector<RM_UNIQUE_PROCESS> procs;
  auto list = [&](std::vector<std::wstring>* apps) -> bool {
    procs.clear();
    UINT needed = 0;
    UINT count = 0;
    DWORD reasons = 0;
    DWORD rc = ::RmGetList(session, &needed, &count, nullptr, &reasons);
    if (rc == ERROR_SUCCESS) return true;
    if (rc != ERROR_MORE_DATA) return false;
    std::vector<RM_PROCESS_INFO> info(needed + 4);
    count = static_cast<UINT>(info.size());
    rc = ::RmGetList(session, &needed, &count, info.data(), &reasons);
    if (rc != ERROR_SUCCESS) {
      Log::Line(L"RmGetList: Fehler " + std::to_wstring(rc));
      return false;
    }
    for (UINT i = 0; i < count; ++i) {
      if (info[i].Process.dwProcessId == ::GetCurrentProcessId()) continue;
      // Der Restart Manager meldet beendete Prozesse teils noch eine Weile.
      // Nur zaehlen, was mit gleicher Startzeit wirklich noch laeuft.
      HANDLE h = ::OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE,
                               info[i].Process.dwProcessId);
      if (h != nullptr) {
        FILETIME created{}, exited{}, kernel{}, user{};
        DWORD code = 0;
        const bool alive =
            ::GetProcessTimes(h, &created, &exited, &kernel, &user) &&
            ::CompareFileTime(&created, &info[i].Process.ProcessStartTime) ==
                0 &&
            ::GetExitCodeProcess(h, &code) && code == STILL_ACTIVE;
        ::CloseHandle(h);
        if (!alive) continue;
      } else if (::GetLastError() == ERROR_INVALID_PARAMETER) {
        continue;  // PID existiert nicht mehr
      }
      apps->push_back(info[i].strAppName);
      procs.push_back(info[i].Process);
    }
    return true;
  };
  if (::RmRegisterResources(session, static_cast<UINT>(names.size()),
                            names.data(), 0, nullptr, 0,
                            nullptr) == ERROR_SUCCESS) {
    std::vector<std::wstring> apps;
    if (list(&apps) && !apps.empty()) {
      for (const auto& a : apps) Log::Line(L"Laeuft noch: " + a);
      reporter.Phase("closing");
      if (!reporter.ConfirmCloseApps(apps)) {
        result = kExitAppRunning;
      } else {
        // Erst freundlich (WM_QUERYENDSESSION/WM_ENDSESSION), dann hart.
        DWORD rc = ::RmShutdown(session, 0, nullptr);
        if (rc != ERROR_SUCCESS) {
          Log::Line(L"Freundliches Beenden fehlgeschlagen, erzwinge");
          rc = ::RmShutdown(session, RmForceShutdown, nullptr);
        }
        // RmShutdown kehrt zurueck, bevor der Prozess seine Dateien
        // freigegeben hat. Bis zu 10 s warten, dann einmal erzwingen.
        auto still_running = [&]() -> bool {
          for (int i = 0; i < 20; ++i) {
            std::vector<std::wstring> still;
            if (list(&still) && still.empty()) return false;
            ::Sleep(500);
          }
          return true;
        };
        bool running = rc != ERROR_SUCCESS || still_running();
        if (running) {
          Log::Line(L"App reagiert nicht, erzwinge Beenden");
          rc = ::RmShutdown(session, RmForceShutdown, nullptr);
          running = rc != ERROR_SUCCESS || still_running();
        }
        if (running) {
          // Letzte Stufe: die gemeldeten Prozesse direkt beenden. Die
          // Startzeit muss passen, sonst traefe es eine wiederverwendete PID.
          std::vector<std::wstring> ignored;
          list(&ignored);
          for (const auto& p : procs) {
            HANDLE h = ::OpenProcess(PROCESS_TERMINATE | SYNCHRONIZE |
                                         PROCESS_QUERY_LIMITED_INFORMATION,
                                     FALSE, p.dwProcessId);
            if (h == nullptr) continue;
            FILETIME created{}, exited{}, kernel{}, user{};
            if (::GetProcessTimes(h, &created, &exited, &kernel, &user) &&
                ::CompareFileTime(&created, &p.ProcessStartTime) == 0) {
              Log::Line(L"Beende Prozess " + std::to_wstring(p.dwProcessId));
              ::TerminateProcess(h, 1);
              ::WaitForSingleObject(h, 5000);
            }
            ::CloseHandle(h);
          }
          running = still_running();
        }
        if (running) {
          Log::Line(L"App laesst sich nicht beenden");
          result = kExitAppRunning;
        } else {
          Log::Line(L"Laufende App beendet");
        }
      }
    }
  }
  ::RmEndSession(session);
  return result;
}

// --- Manifest ---------------------------------------------------------------

std::string BuildManifest(const Manifest& m) {
  std::string out = "# LINEFM Setup, nicht von Hand aendern\n[product]\n";
  out += m.product_ini;
  if (!out.empty() && out.back() != '\n') out += "\n";
  out += "[install]\n";
  out += "version=" + WideToUtf8(m.version) + "\n";
  out += std::string("scope=") + (m.per_machine ? "machine" : "user") + "\n";
  out += std::string("desktop=") + (m.desktop ? "1" : "0") + "\n";
  out += std::string("start_menu=") + (m.start_menu ? "1" : "0") + "\n";
  out += std::string("autostart=") + (m.autostart ? "1" : "0") + "\n";
  out += "[files]\n";
  for (const auto& f : m.files) out += f.sha256 + "\t" + WideToUtf8(f.rel) + "\n";
  out += "[ui]\n";
  for (const auto& u : m.ui) {
    out += u.sha256 + "\t" + WideToUtf8(u.source) + "\t" + WideToUtf8(u.dest) +
           "\n";
  }
  out += "[shortcuts]\n";
  for (const auto& s : m.shortcuts) out += WideToUtf8(s) + "\n";
  return out;
}

std::vector<std::wstring> SplitTabs(const std::wstring& line) {
  std::vector<std::wstring> parts;
  size_t start = 0;
  for (;;) {
    const size_t pos = line.find(L'\t', start);
    parts.push_back(line.substr(start, pos - start));
    if (pos == std::wstring::npos) break;
    start = pos + 1;
  }
  return parts;
}

bool SafeRelative(const std::wstring& rel) {
  return !rel.empty() && rel.find(L"..") == std::wstring::npos &&
         rel.find(L':') == std::wstring::npos && rel.front() != L'\\' &&
         rel.front() != L'/';
}

// --- Nutzerdaten ------------------------------------------------------------

std::wstring SanitizeComponent(std::wstring s) {
  for (auto& c : s) {
    if (wcschr(L"<>:\"/\\|?*", c) != nullptr) c = L'_';
  }
  while (!s.empty() && (s.back() == L' ' || s.back() == L'\t')) s.pop_back();
  while (!s.empty() && s.back() == L'.') s.pop_back();
  return s;
}

std::wstring VersionString(const std::vector<uint8_t>& info,
                           const wchar_t* name) {
  struct Lang {
    WORD language;
    WORD codepage;
  };
  Lang* langs = nullptr;
  UINT size = 0;
  if (!::VerQueryValueW(info.data(), L"\\VarFileInfo\\Translation",
                        reinterpret_cast<void**>(&langs), &size) ||
      size < sizeof(Lang)) {
    return std::wstring();
  }
  wchar_t path[128];
  ::wsprintfW(path, L"\\StringFileInfo\\%04x%04x\\%s", langs[0].language,
              langs[0].codepage, name);
  wchar_t* value = nullptr;
  UINT length = 0;
  if (!::VerQueryValueW(info.data(), path, reinterpret_cast<void**>(&value),
                        &length) ||
      value == nullptr || length == 0) {
    return std::wstring();
  }
  return std::wstring(value, wcsnlen(value, length));
}

// Ordner wie path_provider_windows (CompanyName\ProductName aus der
// Versionsressource der App) plus der Ersatzordner von sentry-native.
std::vector<std::wstring> UserDataDirs(const Product& product,
                                       const std::wstring& exe_path) {
  std::wstring company = product.data_company;
  std::wstring name = product.data_product;
  DWORD handle = 0;
  const DWORD size = ::GetFileVersionInfoSizeW(exe_path.c_str(), &handle);
  if (size > 0) {
    std::vector<uint8_t> info(size);
    if (::GetFileVersionInfoW(exe_path.c_str(), 0, size, info.data())) {
      const std::wstring c = VersionString(info, L"CompanyName");
      const std::wstring p = VersionString(info, L"ProductName");
      if (!p.empty()) {
        company = c;
        name = p;
      }
    }
  }
  company = SanitizeComponent(company);
  name = SanitizeComponent(name);
  std::wstring stem = product.exe_name;
  const size_t dot = stem.find_last_of(L'.');
  if (dot != std::wstring::npos) stem = stem.substr(0, dot);
  if (name.empty()) name = stem;
  const std::wstring sub = company.empty() ? name : JoinPath(company, name);
  std::vector<std::wstring> dirs;
  const std::wstring roaming = KnownFolder(FOLDERID_RoamingAppData);
  const std::wstring local = KnownFolder(FOLDERID_LocalAppData);
  if (!roaming.empty()) dirs.push_back(JoinPath(roaming, sub));
  if (!local.empty()) {
    dirs.push_back(JoinPath(local, sub));
    dirs.push_back(JoinPath(local, stem));  // sentry-native-Ersatzordner
  }
  return dirs;
}

}  // namespace

// --- Oeffentliche Funktionen ------------------------------------------------

bool ReadManifest(const std::wstring& dir, Manifest* m) {
  std::vector<uint8_t> raw;
  if (!ReadWholeFile(JoinPath(dir, kManifestName), &raw)) return false;
  const std::wstring text = Utf8ToWide(std::string(raw.begin(), raw.end()));
  std::wstring section;
  size_t start = 0;
  while (start < text.size()) {
    size_t end = text.find(L'\n', start);
    if (end == std::wstring::npos) end = text.size();
    std::wstring line = text.substr(start, end - start);
    start = end + 1;
    if (!line.empty() && line.back() == L'\r') line.pop_back();
    if (line.empty() || line[0] == L'#') continue;
    if (line[0] == L'[') {
      section = line;
      continue;
    }
    if (section == L"[product]") {
      m->product_ini += WideToUtf8(line) + "\n";
    } else if (section == L"[install]") {
      const size_t eq = line.find(L'=');
      if (eq == std::wstring::npos) continue;
      const std::wstring k = line.substr(0, eq);
      const std::wstring v = line.substr(eq + 1);
      if (k == L"version") m->version = v;
      else if (k == L"scope") m->per_machine = v == L"machine";
      else if (k == L"desktop") m->desktop = v == L"1";
      else if (k == L"start_menu") m->start_menu = v == L"1";
      else if (k == L"autostart") m->autostart = v == L"1";
    } else if (section == L"[files]") {
      const auto parts = SplitTabs(line);
      if (parts.size() == 2 && SafeRelative(parts[1])) {
        m->files.push_back({WideToUtf8(parts[0]), parts[1]});
      }
    } else if (section == L"[ui]") {
      const auto parts = SplitTabs(line);
      if (parts.size() == 3 && SafeRelative(parts[1]) &&
          SafeRelative(parts[2])) {
        m->ui.push_back({WideToUtf8(parts[0]), parts[1], parts[2]});
      }
    } else if (section == L"[shortcuts]") {
      if (line.size() > 4 &&
          EqualsI(line.substr(line.size() - 4), L".lnk")) {
        m->shortcuts.push_back(line);
      }
    }
  }
  return !m->version.empty();
}

bool ReadInstalledProduct(const std::wstring& dir, Product* product) {
  Manifest m;
  if (!ReadManifest(dir, &m)) return false;
  return ParseProduct(m.product_ini, product, nullptr);
}

InstalledInfo FindInstalled(const Product& product, int scope) {
  InstalledInfo info;
  const bool per_machine = scope == 1;
  const HKEY root = RootFor(per_machine);
  const std::wstring key = UninstallKey(product);
  std::wstring location;
  if (!RegGetString(root, key, L"InstallLocation", &location)) return info;
  info.found = true;
  info.per_machine = per_machine;
  info.dir = NormalizePath(location);
  RegGetString(root, key, L"DisplayVersion", &info.version);
  DWORD value = 0;
  if (RegGetDword(root, key, L"LinefmDesktopShortcut", &value)) {
    info.desktop = value != 0;
  }
  if (RegGetDword(root, key, L"LinefmStartMenu", &value)) {
    info.start_menu = value != 0;
  }
  if (RegGetDword(root, key, L"LinefmAutostart", &value)) {
    info.autostart = value != 0;
  }
  return info;
}

InstalledInfo FindAnyInstalled(const Product& product) {
  InstalledInfo user = FindInstalled(product, 0);
  if (user.found) return user;
  return FindInstalled(product, 1);
}

bool DeleteUserData(const Product& product, const std::wstring& exe_path) {
  bool ok = true;
  for (const auto& dir : UserDataDirs(product, exe_path)) {
    if (DirExists(dir)) {
      Log::Line(L"Loesche Nutzerdaten: " + dir);
      ok = DeleteTree(dir) && ok;
      // Leeren Firmenordner (z. B. de.linefm) mit entfernen.
      ::RemoveDirectoryW(ParentDir(dir).c_str());
    }
  }
  return ok;
}

int RunInstall(Payload& payload, const Product& product,
               const InstallRequest& request, Reporter& reporter,
               std::wstring* message) {
  auto fail = [&](int code, const std::wstring& text) {
    if (message != nullptr) *message = text;
    Log::Line(L"Fehler: " + text);
    return code;
  };
  reporter.Phase("prepare");
  Log::Line(L"Installation " + product.name + L" " + product.version);

  // 1. Bereich (Benutzer/Rechner) und vorhandene Installation.
  const InstalledInfo user = FindInstalled(product, 0);
  const InstalledInfo machine = FindInstalled(product, 1);
  bool per_machine = product.default_scope == L"machine";
  InstalledInfo existing;
  if (request.scope_given) {
    per_machine = request.per_machine;
    existing = per_machine ? machine : user;
    const InstalledInfo& other = per_machine ? user : machine;
    if (!existing.found && other.found) {
      return fail(kExitOtherScope,
                  other.per_machine
                      ? L"Bereits fuer alle Benutzer installiert. Bitte "
                        L"zuerst deinstallieren."
                      : L"Bereits fuer diesen Benutzer installiert. Bitte "
                        L"zuerst deinstallieren.");
    }
  } else if (user.found) {
    existing = user;
    per_machine = false;
  } else if (machine.found) {
    existing = machine;
    per_machine = true;
  }
  if (per_machine && !IsProcessElevated()) {
    return fail(kExitElevation,
                L"Installation fuer alle Benutzer braucht Administratorrechte.");
  }

  // 2. Version.
  if (existing.found) {
    const int cmp = CompareVersions(WideToUtf8(product.version),
                                    WideToUtf8(existing.version));
    Log::Line(L"Vorhanden: " + existing.version + L" in " + existing.dir);
    if (cmp < 0 && !request.allow_downgrade) {
      return fail(kExitDowngrade, L"Neuere Version " + existing.version +
                                      L" ist installiert (Downgrade nur mit "
                                      L"/ALLOWDOWNGRADE).");
    }
  }

  // 3. Zielordner.
  std::wstring dir;
  if (existing.found && !existing.dir.empty()) {
    dir = existing.dir;
    if (!request.dir.empty() && !EqualsI(FullPath(request.dir), dir)) {
      Log::Line(L"Update: der bisherige Ordner bleibt (" + dir + L")");
    }
  } else if (!request.dir.empty()) {
    dir = FullPath(request.dir);
  } else {
    dir = per_machine ? DefaultMachineInstallDir(product.dir_name)
                      : DefaultUserInstallDir(product.dir_name);
  }
  std::wstring reason;
  if (!ValidateTargetDir(dir, per_machine, &reason)) {
    return fail(kExitBadTarget, reason);
  }
  Log::Line(L"Ziel: " + dir + (per_machine ? L" (alle Benutzer)"
                                           : L" (dieser Benutzer)"));

  // 4. Optionen (Update uebernimmt die Wahl der Erstinstallation).
  const bool desktop = request.desktop_given
                           ? request.desktop
                           : (existing.found ? existing.desktop
                                             : product.default_desktop);
  const bool start_menu = request.start_menu_given
                              ? request.start_menu
                              : (existing.found ? existing.start_menu
                                                : product.default_start_menu);
  const bool autostart = request.autostart_given
                             ? request.autostart
                             : (existing.found ? existing.autostart
                                               : product.default_autostart);

  // 5. Dateiliste planen.
  struct Planned {
    const ArchiveEntry* entry;
    std::wstring rel;
  };
  std::vector<Planned> planned;
  Manifest manifest;
  const ArchiveEntry* app_flutter = payload.Find(L"app/flutter_windows.dll");
  uint64_t total = 0;
  for (const auto& entry : payload.entries()) {
    std::wstring rel;
    if (StartsWithI(entry.path, L"app/")) {
      rel = entry.path.substr(4);
    } else if (StartsWithI(entry.path, L"ui/")) {
      const std::wstring ui_rel = entry.path.substr(3);
      std::wstring source = JoinPath(kUiDirName, ui_rel);
      bool shared = false;
      if (app_flutter != nullptr && EqualsI(ui_rel, L"flutter_windows.dll") &&
          std::memcmp(app_flutter->sha256, entry.sha256, 32) == 0) {
        // Gleiche Engine wie die App: nicht doppelt ablegen.
        source = L"flutter_windows.dll";
        shared = true;
      }
      std::wstring dest = ui_rel;
      for (auto& c : dest) {
        if (c == L'/') c = L'\\';
      }
      manifest.ui.push_back(
          {ToHex(entry.sha256, 32), NormalizePath(source), dest});
      if (shared) continue;
      rel = source;
    } else if (EqualsI(entry.path, L"meta/uninstall.exe")) {
      rel = kUninstallerName;
    } else {
      continue;
    }
    for (auto& c : rel) {
      if (c == L'/') c = L'\\';
    }
    rel = NormalizePath(rel);
    planned.push_back({&entry, rel});
    manifest.files.push_back({ToHex(entry.sha256, 32), rel});
    total += entry.size;
  }
  if (payload.Find(L"app/" + product.exe_name) == nullptr) {
    return fail(kExitCorrupt, L"Programmdatei fehlt in der Nutzlast");
  }

  // 6. Speicherplatz (mit 10 % Reserve).
  {
    std::wstring probe = dir;
    while (!probe.empty() && !DirExists(probe)) {
      const std::wstring parent = ParentDir(probe);
      if (parent == probe) break;
      probe = parent;
    }
    ULARGE_INTEGER free_bytes = {};
    if (::GetDiskFreeSpaceExW(probe.c_str(), &free_bytes, nullptr, nullptr) &&
        free_bytes.QuadPart < total + total / 10) {
      return fail(kExitDiskFull, L"Nicht genug Speicherplatz auf dem Laufwerk.");
    }
  }

  // 7. Laufende App beenden.
  Manifest old;
  const bool has_old = existing.found && ReadManifest(dir, &old);
  {
    std::vector<std::wstring> locked;
    std::set<std::wstring> seen;
    auto add = [&](const std::wstring& rel) {
      const std::wstring lower = Lower(rel);
      if ((lower.size() > 4 && (lower.compare(lower.size() - 4, 4, L".exe") == 0 ||
                                lower.compare(lower.size() - 4, 4, L".dll") == 0)) &&
          seen.insert(lower).second) {
        const std::wstring full = JoinPath(dir, rel);
        if (FileExists(full)) locked.push_back(full);
      }
    };
    if (has_old) {
      for (const auto& f : old.files) add(f.rel);
    }
    for (const auto& p : planned) add(p.rel);
    const int rc = CloseRunningApps(locked, reporter);
    if (rc != kExitOk) {
      return fail(rc, L"LINEFM Radio laeuft noch und wurde nicht beendet.");
    }
  }

  // 8. Dateien schreiben.
  Txn txn;
  const std::wstring program_files = KnownFolder(FOLDERID_ProgramFiles);
  const bool protect = per_machine && !IsSubPathOf(dir, program_files);
  std::wstring error;
  auto rollback = [&](int code, const std::wstring& text) {
    reporter.Phase("rollback");
    Log::Line(L"Rueckbau: " + text);
    const bool clean = txn.Rollback();
    if (message != nullptr) *message = text;
    return clean ? code : kExitRollbackIncomplete;
  };
  if (!CreateDirs(dir, &txn, protect, &error)) {
    return rollback(kExitFailed, error);
  }
  reporter.Phase("copying");
  uint64_t done = 0;
  reporter.Progress(0, total);
  std::vector<uint8_t> data;
  for (const auto& p : planned) {
    if (reporter.Cancelled()) return rollback(kExitCancelled, L"Abgebrochen");
    if (!payload.Extract(*p.entry, &data, &error)) {
      return rollback(kExitCorrupt, error);
    }
    const std::wstring dest = JoinPath(dir, p.rel);
    if (!CreateDirs(ParentDir(dest), &txn, false, &error)) {
      return rollback(kExitFailed, error);
    }
    const std::wstring temp = dest + L".lfnew";
    ::DeleteFileW(temp.c_str());
    HANDLE file = ::CreateFileW(temp.c_str(), GENERIC_WRITE, 0, nullptr,
                                CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) {
      return rollback(kExitFailed, L"Datei nicht anlegbar: " + temp + L" (" +
                                    FormatWin32Error(::GetLastError()) + L")");
    }
    txn.CreatedFile(temp);
    size_t offset = 0;
    bool write_ok = true;
    bool cancelled = false;
    while (offset < data.size()) {
      if (reporter.Cancelled()) {
        cancelled = true;
        break;
      }
      const DWORD chunk =
          static_cast<DWORD>(std::min<size_t>(data.size() - offset, 1u << 20));
      DWORD written = 0;
      if (!::WriteFile(file, data.data() + offset, chunk, &written, nullptr) ||
          written != chunk) {
        write_ok = false;
        break;
      }
      offset += chunk;
      done += chunk;
      reporter.Progress(done, total);
    }
    if (write_ok && !cancelled) write_ok = ::FlushFileBuffers(file) != 0;
    const DWORD write_error = ::GetLastError();
    ::CloseHandle(file);
    if (cancelled) return rollback(kExitCancelled, L"Abgebrochen");
    if (!write_ok) {
      return rollback(write_error == ERROR_DISK_FULL ? kExitDiskFull : kExitFailed,
                   L"Schreiben fehlgeschlagen: " + dest + L" (" +
                       FormatWin32Error(write_error) + L")");
    }
    if (FileExists(dest)) {
      const std::wstring backup = BackupName(dest);
      if (!::MoveFileExW(dest.c_str(), backup.c_str(), 0)) {
        return rollback(kExitFailed, L"Datei in Benutzung: " + dest + L" (" +
                                      FormatWin32Error(::GetLastError()) +
                                      L")");
      }
      txn.Replaced(dest, backup);
    } else {
      txn.CreatedFile(dest);
    }
    if (!::MoveFileExW(temp.c_str(), dest.c_str(), MOVEFILE_WRITE_THROUGH)) {
      return rollback(kExitFailed, L"Datei nicht ersetzbar: " + dest);
    }
  }

  // 9. Dateien der alten Version, die es nicht mehr gibt.
  if (has_old) {
    std::set<std::wstring> keep;
    for (const auto& f : manifest.files) keep.insert(Lower(f.rel));
    for (const auto& f : old.files) {
      if (keep.count(Lower(f.rel)) != 0) continue;
      const std::wstring path = JoinPath(dir, f.rel);
      if (!FileExists(path)) continue;
      const std::wstring backup = BackupName(path);
      if (::MoveFileExW(path.c_str(), backup.c_str(), 0)) {
        txn.Replaced(path, backup);
      }
    }
  }

  reporter.Phase("registry");
  // 10. Manifest.
  const std::wstring exe = JoinPath(dir, product.exe_name);
  manifest.version = product.version;
  manifest.per_machine = per_machine;
  manifest.desktop = desktop;
  manifest.start_menu = start_menu;
  manifest.autostart = autostart;
  {
    const ArchiveEntry* meta = payload.Find(L"meta/product.ini");
    std::vector<uint8_t> ini;
    if (meta == nullptr || !payload.Extract(*meta, &ini, &error)) {
      return rollback(kExitCorrupt, L"Produktdaten nicht lesbar");
    }
    manifest.product_ini.assign(ini.begin(), ini.end());
  }

  // 11. Verknuepfungen.
  const std::wstring programs =
      KnownFolder(per_machine ? FOLDERID_CommonPrograms : FOLDERID_Programs);
  const std::wstring desktop_dir =
      KnownFolder(per_machine ? FOLDERID_PublicDesktop : FOLDERID_Desktop);
  struct Link {
    bool wanted;
    std::wstring path;
  };
  const Link links[] = {
      {start_menu, JoinPath(programs, product.name + L".lnk")},
      {desktop, JoinPath(desktop_dir, product.name + L".lnk")},
  };
  std::set<std::wstring> old_links;
  for (const auto& s : old.shortcuts) old_links.insert(Lower(s));
  for (const auto& link : links) {
    if (link.path.size() <= 4 || ParentDir(link.path).empty()) continue;
    const bool exists = FileExists(link.path);
    const bool ours = old_links.count(Lower(link.path)) != 0;
    // Abgewaehlt: nur eine eigene, frueher angelegte Verknuepfung entfernen.
    if (!link.wanted && !(exists && ours)) continue;
    if (exists) {
      const std::wstring backup = BackupName(link.path);
      if (::MoveFileExW(link.path.c_str(), backup.c_str(), 0)) {
        txn.Replaced(link.path, backup);
      }
    }
    if (!link.wanted) continue;
    if (!exists) txn.CreatedFile(link.path);
    if (!CreateDirs(ParentDir(link.path), &txn, false, &error) ||
        !CreateShortcut(link.path, exe, product.name, &error)) {
      return rollback(kExitFailed, error);
    }
    manifest.shortcuts.push_back(link.path);
  }

  // 12. Manifest schreiben.
  {
    const std::string text = BuildManifest(manifest);
    const std::wstring path = JoinPath(dir, kManifestName);
    const std::wstring temp = path + L".lfnew";
    DWORD code = 0;
    txn.CreatedFile(temp);
    if (!WriteWholeFile(temp, text.data(), text.size(), &code)) {
      return rollback(kExitFailed, L"uninstall.dat nicht schreibbar");
    }
    if (FileExists(path)) {
      const std::wstring backup = BackupName(path);
      if (!::MoveFileExW(path.c_str(), backup.c_str(), 0)) {
        return rollback(kExitFailed, L"uninstall.dat in Benutzung");
      }
      txn.Replaced(path, backup);
    } else {
      txn.CreatedFile(path);
    }
    if (!::MoveFileExW(temp.c_str(), path.c_str(), MOVEFILE_WRITE_THROUGH)) {
      return rollback(kExitFailed, L"uninstall.dat nicht ersetzbar");
    }
  }

  // 13. Registry: Apps & Features, Link-Schema, App Paths, Autostart.
  const HKEY root = RootFor(per_machine);
  bool reg_ok = true;
  {
    const std::wstring key = UninstallKey(product);
    txn.Key(SnapshotKey(root, key));
    RegDeleteTreeKey(root, key);
    const std::wstring uninstaller = JoinPath(dir, kUninstallerName);
    uint64_t size_kb = (total + 1023) / 1024;
    SYSTEMTIME now = {};
    ::GetLocalTime(&now);
    wchar_t date[16];
    ::wsprintfW(date, L"%04u%02u%02u", now.wYear, now.wMonth, now.wDay);
    DWORD major = 0;
    DWORD minor = 0;
    {
      const std::string v = WideToUtf8(product.version);
      major = static_cast<DWORD>(strtoul(v.c_str(), nullptr, 10));
      const size_t dot = v.find('.');
      if (dot != std::string::npos) {
        minor = static_cast<DWORD>(strtoul(v.c_str() + dot + 1, nullptr, 10));
      }
    }
    reg_ok = RegSetString(root, key, L"DisplayName", product.name) &&
             RegSetString(root, key, L"DisplayVersion", product.version) &&
             RegSetString(root, key, L"Publisher", product.publisher) &&
             RegSetString(root, key, L"DisplayIcon", exe + L",0") &&
             RegSetString(root, key, L"InstallLocation", dir) &&
             RegSetString(root, key, L"UninstallString", Quote(uninstaller)) &&
             RegSetString(root, key, L"QuietUninstallString",
                          Quote(uninstaller) + L" /S") &&
             RegSetString(root, key, L"InstallDate", date) &&
             RegSetDword(root, key, L"EstimatedSize",
                         static_cast<DWORD>(std::min<uint64_t>(size_kb,
                                                               0xffffffffu))) &&
             RegSetDword(root, key, L"VersionMajor", major) &&
             RegSetDword(root, key, L"VersionMinor", minor) &&
             RegSetDword(root, key, L"NoModify", 1) &&
             RegSetDword(root, key, L"NoRepair", 1) &&
             RegSetDword(root, key, L"LinefmDesktopShortcut", desktop ? 1 : 0) &&
             RegSetDword(root, key, L"LinefmStartMenu", start_menu ? 1 : 0) &&
             RegSetDword(root, key, L"LinefmAutostart", autostart ? 1 : 0);
    if (!product.url.empty()) {
      RegSetString(root, key, L"URLInfoAbout", product.url);
      RegSetString(root, key, L"HelpLink", product.url);
    }
  }
  if (reg_ok && !product.scheme.empty()) {
    // Link-Schema wie bisher im Inno-Skript und im MSIX (protocol_activation).
    const std::wstring key = kClassesRoot + product.scheme;
    txn.Key(SnapshotKey(root, key));
    RegDeleteTreeKey(root, key);
    reg_ok = RegSetString(root, key, nullptr, L"URL:" + product.name) &&
             RegSetString(root, key, L"URL Protocol", L"") &&
             RegSetString(root, key + L"\\DefaultIcon", nullptr,
                          Quote(exe) + L",0") &&
             RegSetString(root, key + L"\\shell\\open\\command", nullptr,
                          Quote(exe) + L" \"%1\"");
  }
  if (reg_ok) {
    const std::wstring key = kAppPathsRoot + product.exe_name;
    txn.Key(SnapshotKey(root, key));
    RegDeleteTreeKey(root, key);
    reg_ok = RegSetString(root, key, nullptr, exe) &&
             RegSetString(root, key, L"Path", dir);
  }
  if (reg_ok) {
    txn.Value(SnapshotValue(root, kRunKey, product.name));
    if (autostart) {
      reg_ok = RegSetString(root, kRunKey, product.name.c_str(), Quote(exe));
    } else {
      ::RegDeleteKeyValueW(root, kRunKey, product.name.c_str());
    }
  }
  if (!reg_ok) return rollback(kExitFailed, L"Registry nicht schreibbar");

  if (reporter.Cancelled()) return rollback(kExitCancelled, L"Abgebrochen");

  // 14. Abschluss: ab hier kein Rueckbau mehr.
  reporter.Phase("finalizing");
  txn.Commit();
  if (has_old) {
    // Leere Ordner entfernter Dateien aufraeumen.
    std::vector<std::wstring> dirs;
    for (const auto& f : old.files) {
      std::wstring d = ParentDir(JoinPath(dir, f.rel));
      while (IsSubPathOf(d, dir) && !EqualsI(d, dir)) {
        dirs.push_back(d);
        d = ParentDir(d);
      }
    }
    std::sort(dirs.begin(), dirs.end(),
              [](const std::wstring& a, const std::wstring& b) {
                return a.size() > b.size();
              });
    for (const auto& d : dirs) ::RemoveDirectoryW(d.c_str());
  }
  ::SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);
  reporter.Progress(total, total);
  Log::Line(L"Installation abgeschlossen");
  if (message != nullptr) *message = dir;
  return kExitOk;
}

int RunUninstall(const Product& product, const UninstallRequest& request,
                 Reporter& reporter, std::wstring* message) {
  auto fail = [&](int code, const std::wstring& text) {
    if (message != nullptr) *message = text;
    Log::Line(L"Fehler: " + text);
    return code;
  };
  reporter.Phase("prepare");
  const std::wstring dir = NormalizePath(request.dir);
  const HKEY root = RootFor(request.per_machine);
  Log::Line(L"Deinstallation aus " + dir);
  if (request.per_machine && !IsProcessElevated()) {
    return fail(kExitElevation, L"Administratorrechte noetig");
  }
  const InstalledInfo info = FindInstalled(product, request.per_machine ? 1 : 0);
  if (!info.found || !EqualsI(info.dir, dir)) {
    return fail(kExitNotInstalled, L"Keine passende Installation gefunden");
  }
  Manifest manifest;
  const bool has_manifest = ReadManifest(dir, &manifest);
  if (!has_manifest) Log::Line(L"uninstall.dat fehlt, entferne nur Eintraege");
  const std::wstring exe = JoinPath(dir, product.exe_name);

  // 1. Laufende App beenden.
  {
    std::vector<std::wstring> locked;
    for (const auto& f : manifest.files) {
      const std::wstring lower = Lower(f.rel);
      if (lower.size() > 4 &&
          (lower.compare(lower.size() - 4, 4, L".exe") == 0 ||
           lower.compare(lower.size() - 4, 4, L".dll") == 0) &&
          !EqualsI(f.rel, kUninstallerName)) {
        const std::wstring full = JoinPath(dir, f.rel);
        if (FileExists(full)) locked.push_back(full);
      }
    }
    if (locked.empty() && FileExists(exe)) locked.push_back(exe);
    const int rc = CloseRunningApps(locked, reporter);
    if (rc != kExitOk) {
      return fail(rc, L"LINEFM Radio laeuft noch und wurde nicht beendet.");
    }
  }
  const std::vector<std::wstring> data_dirs = UserDataDirs(product, exe);

  // 2. Verknuepfungen.
  reporter.Phase("removing");
  for (const auto& lnk : manifest.shortcuts) {
    if (FileExists(lnk)) ::DeleteFileW(lnk.c_str());
  }

  // 3. Dateien.
  std::vector<std::wstring> failed;
  const uint64_t total = manifest.files.size() + 1;
  uint64_t done = 0;
  const bool elevated = IsProcessElevated();
  auto remove = [&](const std::wstring& path) {
    if (!FileExists(path)) return;
    ::SetFileAttributesW(path.c_str(), FILE_ATTRIBUTE_NORMAL);
    if (::DeleteFileW(path.c_str())) return;
    if (elevated &&
        ::MoveFileExW(path.c_str(), nullptr, MOVEFILE_DELAY_UNTIL_REBOOT)) {
      Log::Line(L"Wird beim Neustart geloescht: " + path);
      return;
    }
    failed.push_back(path);
  };
  std::vector<std::wstring> dirs;
  for (const auto& f : manifest.files) {
    const std::wstring path = JoinPath(dir, f.rel);
    if (!IsSubPathOf(path, dir)) continue;
    std::wstring d = ParentDir(path);
    while (IsSubPathOf(d, dir) && !EqualsI(d, dir)) {
      dirs.push_back(d);
      d = ParentDir(d);
    }
    if (request.keep_uninstaller && EqualsI(f.rel, kUninstallerName)) continue;
    remove(path);
    reporter.Progress(++done, total);
  }
  remove(JoinPath(dir, kManifestName));
  // Laufzeitdaten, die die App selbst im Programmordner anlegt
  // (sentry-native legt ".sentry-native" im Arbeitsverzeichnis an).
  DeleteTree(JoinPath(dir, L".sentry-native"));
  std::sort(dirs.begin(), dirs.end(),
            [](const std::wstring& a, const std::wstring& b) {
              return a.size() > b.size();
            });
  for (const auto& d : dirs) ::RemoveDirectoryW(d.c_str());
  if (!request.keep_uninstaller) ::RemoveDirectoryW(dir.c_str());
  reporter.Progress(total, total);

  if (!failed.empty()) {
    for (const auto& f : failed) Log::Line(L"Nicht loeschbar: " + f);
    return fail(kExitFailed, L"Einige Dateien sind noch in Benutzung: " +
                                 failed.front());
  }

  // 4. Registry (erst jetzt, damit ein Fehlschlag oben erneut deinstallierbar
  // bleibt). Fremde Eintraege bleiben unangetastet.
  reporter.Phase("registry");
  RegDeleteTreeKey(root, UninstallKey(product));
  if (!product.scheme.empty()) {
    const std::wstring key = kClassesRoot + product.scheme;
    std::wstring command;
    if (RegGetString(root, key + L"\\shell\\open\\command", nullptr,
                     &command) &&
        StartsWithI(command, Quote(exe))) {
      RegDeleteTreeKey(root, key);
    }
  }
  {
    const std::wstring key = kAppPathsRoot + product.exe_name;
    std::wstring path;
    if (RegGetString(root, key, nullptr, &path) && EqualsI(path, exe)) {
      RegDeleteTreeKey(root, key);
    }
  }
  {
    std::wstring value;
    if (RegGetString(root, kRunKey, product.name.c_str(), &value) &&
        EqualsI(value, Quote(exe))) {
      ::RegDeleteKeyValueW(root, kRunKey, product.name.c_str());
    }
  }
  ::SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);

  // 5. Nutzerdaten (nur auf Wunsch).
  if (request.delete_user_data) {
    bool ok = true;
    for (const auto& d : data_dirs) {
      if (!DirExists(d)) continue;
      Log::Line(L"Loesche Nutzerdaten: " + d);
      ok = DeleteTree(d) && ok;
      ::RemoveDirectoryW(ParentDir(d).c_str());
    }
    if (!ok) Log::Line(L"Nutzerdaten nicht vollstaendig geloescht");
  }
  Log::Line(L"Deinstallation abgeschlossen");
  return kExitOk;
}

}  // namespace lf
