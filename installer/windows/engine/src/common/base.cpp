#include "base.h"

#include <shellapi.h>
#include <shlobj.h>

#include <algorithm>
#include <cwctype>
#include <mutex>

namespace lf {

// --- Text -------------------------------------------------------------------

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) return std::wstring();
  const int length = ::MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                           static_cast<int>(text.size()),
                                           nullptr, 0);
  if (length <= 0) return std::wstring();
  std::wstring result(static_cast<size_t>(length), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        result.data(), length);
  return result;
}

std::string WideToUtf8(const std::wstring& text) {
  if (text.empty()) return std::string();
  const int length = ::WideCharToMultiByte(CP_UTF8, 0, text.data(),
                                           static_cast<int>(text.size()),
                                           nullptr, 0, nullptr, nullptr);
  if (length <= 0) return std::string();
  std::string result(static_cast<size_t>(length), '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        result.data(), length, nullptr, nullptr);
  return result;
}

std::wstring Lower(std::wstring text) {
  if (!text.empty()) {
    ::CharLowerBuffW(text.data(), static_cast<DWORD>(text.size()));
  }
  return text;
}

bool EqualsI(const std::wstring& a, const std::wstring& b) {
  return ::CompareStringOrdinal(a.c_str(), static_cast<int>(a.size()),
                                b.c_str(), static_cast<int>(b.size()),
                                TRUE) == CSTR_EQUAL;
}

bool StartsWithI(const std::wstring& text, const std::wstring& prefix) {
  if (prefix.size() > text.size()) return false;
  return ::CompareStringOrdinal(text.c_str(), static_cast<int>(prefix.size()),
                                prefix.c_str(), static_cast<int>(prefix.size()),
                                TRUE) == CSTR_EQUAL;
}

std::wstring Trim(const std::wstring& text) {
  size_t start = 0;
  size_t end = text.size();
  while (start < end && std::iswspace(text[start])) ++start;
  while (end > start && std::iswspace(text[end - 1])) --end;
  return text.substr(start, end - start);
}

std::string ToHex(const uint8_t* data, size_t size) {
  static const char kDigits[] = "0123456789abcdef";
  std::string result;
  result.reserve(size * 2);
  for (size_t i = 0; i < size; ++i) {
    result.push_back(kDigits[data[i] >> 4]);
    result.push_back(kDigits[data[i] & 0x0f]);
  }
  return result;
}

static int HexValue(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

bool FromHex(const std::string& hex, uint8_t* out, size_t size) {
  if (hex.size() != size * 2) return false;
  for (size_t i = 0; i < size; ++i) {
    const int hi = HexValue(hex[2 * i]);
    const int lo = HexValue(hex[2 * i + 1]);
    if (hi < 0 || lo < 0) return false;
    out[i] = static_cast<uint8_t>((hi << 4) | lo);
  }
  return true;
}

std::wstring FormatWin32Error(DWORD code) {
  wchar_t* buffer = nullptr;
  const DWORD length = ::FormatMessageW(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      nullptr, code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<wchar_t*>(&buffer), 0, nullptr);
  std::wstring text;
  if (length > 0 && buffer != nullptr) {
    text = Trim(std::wstring(buffer, length));
  }
  if (buffer != nullptr) ::LocalFree(buffer);
  return L"Win32-Fehler " + std::to_wstring(code) +
         (text.empty() ? L"" : L": " + text);
}

std::string JsonString(const std::wstring& text) {
  const std::string utf8 = WideToUtf8(text);
  std::string out = "\"";
  for (const unsigned char c : utf8) {
    switch (c) {
      case '"':
        out += "\\\"";
        break;
      case '\\':
        out += "\\\\";
        break;
      case '\n':
        out += "\\n";
        break;
      case '\r':
        out += "\\r";
        break;
      case '\t':
        out += "\\t";
        break;
      default:
        if (c < 0x20) {
          char buffer[8];
          ::wsprintfA(buffer, "\\u%04x", c);
          out += buffer;
        } else {
          out.push_back(static_cast<char>(c));
        }
    }
  }
  out += "\"";
  return out;
}

// --- Pfade ------------------------------------------------------------------

std::wstring NormalizePath(const std::wstring& path) {
  std::wstring out;
  out.reserve(path.size());
  for (wchar_t c : path) {
    if (c == L'/') c = L'\\';
    // Doppelte Trenner zusammenfassen, UNC-Anfang (\\) erhalten.
    if (c == L'\\' && !out.empty() && out.back() == L'\\' && out.size() > 1) {
      continue;
    }
    out.push_back(c);
  }
  while (out.size() > 3 && out.back() == L'\\') out.pop_back();
  return out;
}

std::wstring JoinPath(const std::wstring& base, const std::wstring& child) {
  if (base.empty()) return NormalizePath(child);
  std::wstring c = child;
  for (auto& ch : c) {
    if (ch == L'/') ch = L'\\';
  }
  while (!c.empty() && c.front() == L'\\') c.erase(c.begin());
  std::wstring b = base;
  if (b.back() != L'\\' && b.back() != L'/') b.push_back(L'\\');
  return NormalizePath(b + c);
}

std::wstring ParentDir(const std::wstring& path) {
  const std::wstring p = NormalizePath(path);
  const size_t pos = p.find_last_of(L'\\');
  if (pos == std::wstring::npos) return std::wstring();
  if (pos == 2 && p.size() > 1 && p[1] == L':') return p.substr(0, 3);
  return p.substr(0, pos);
}

std::wstring FileNamePart(const std::wstring& path) {
  const std::wstring p = NormalizePath(path);
  const size_t pos = p.find_last_of(L'\\');
  return pos == std::wstring::npos ? p : p.substr(pos + 1);
}

std::wstring FullPath(const std::wstring& path) {
  if (path.empty()) return std::wstring();
  const DWORD needed = ::GetFullPathNameW(path.c_str(), 0, nullptr, nullptr);
  if (needed == 0) return std::wstring();
  std::wstring buffer(needed, L'\0');
  const DWORD written =
      ::GetFullPathNameW(path.c_str(), needed, buffer.data(), nullptr);
  if (written == 0 || written >= needed) return std::wstring();
  buffer.resize(written);
  return NormalizePath(buffer);
}

std::wstring Quote(const std::wstring& path) { return L"\"" + path + L"\""; }

std::wstring QuoteArg(const std::wstring& arg) {
  if (!arg.empty() && arg.find_first_of(L" \t\n\v\"") == std::wstring::npos) {
    return arg;
  }
  std::wstring out = L"\"";
  for (size_t i = 0;; ++i) {
    size_t backslashes = 0;
    while (i < arg.size() && arg[i] == L'\\') {
      ++i;
      ++backslashes;
    }
    if (i == arg.size()) {
      out.append(backslashes * 2, L'\\');
      break;
    }
    if (arg[i] == L'"') {
      out.append(backslashes * 2 + 1, L'\\');
      out.push_back(L'"');
    } else {
      out.append(backslashes, L'\\');
      out.push_back(arg[i]);
    }
  }
  out.push_back(L'"');
  return out;
}

bool IsSubPathOf(const std::wstring& path, const std::wstring& root) {
  const std::wstring p = NormalizePath(path);
  std::wstring r = NormalizePath(root);
  if (r.empty()) return false;
  if (EqualsI(p, r)) return true;
  if (r.back() != L'\\') r.push_back(L'\\');
  return StartsWithI(p, r);
}

bool PathExists(const std::wstring& path) {
  return ::GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES;
}

bool DirExists(const std::wstring& path) {
  const DWORD attr = ::GetFileAttributesW(path.c_str());
  return attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY);
}

bool FileExists(const std::wstring& path) {
  const DWORD attr = ::GetFileAttributesW(path.c_str());
  return attr != INVALID_FILE_ATTRIBUTES &&
         (attr & FILE_ATTRIBUTE_DIRECTORY) == 0;
}

std::wstring KnownFolder(const GUID& id) {
  PWSTR raw = nullptr;
  std::wstring result;
  if (SUCCEEDED(::SHGetKnownFolderPath(id, KF_FLAG_DEFAULT, nullptr, &raw)) &&
      raw != nullptr) {
    result = NormalizePath(raw);
  }
  if (raw != nullptr) ::CoTaskMemFree(raw);
  return result;
}

std::wstring SelfPath() {
  std::wstring buffer(MAX_PATH, L'\0');
  for (;;) {
    const DWORD length = ::GetModuleFileNameW(
        nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length == 0) return std::wstring();
    if (length < buffer.size()) {
      buffer.resize(length);
      return buffer;
    }
    buffer.resize(buffer.size() * 2);
  }
}

std::wstring TempDir() {
  wchar_t buffer[MAX_PATH + 2] = {};
  const DWORD length = ::GetTempPathW(MAX_PATH + 1, buffer);
  if (length == 0 || length > MAX_PATH) return std::wstring();
  return NormalizePath(std::wstring(buffer, length));
}

// --- Prozess ----------------------------------------------------------------

bool IsProcessElevated() {
  HANDLE token = nullptr;
  if (!::OpenProcessToken(::GetCurrentProcess(), TOKEN_QUERY, &token)) {
    return false;
  }
  TOKEN_ELEVATION elevation = {};
  DWORD size = 0;
  const BOOL ok = ::GetTokenInformation(token, TokenElevation, &elevation,
                                        sizeof(elevation), &size);
  ::CloseHandle(token);
  return ok && elevation.TokenIsElevated != 0;
}

HANDLE StartProcess(const std::wstring& exe, const std::wstring& args,
                    bool wait_for_input_idle, DWORD* error) {
  std::wstring command = Quote(exe);
  if (!args.empty()) command += L" " + args;
  STARTUPINFOW si = {};
  si.cb = sizeof(si);
  PROCESS_INFORMATION pi = {};
  // Arbeitsverzeichnis = Ordner der EXE, nicht das (evtl. fremd beschreibbare)
  // aktuelle Verzeichnis.
  const std::wstring dir = ParentDir(exe);
  if (!::CreateProcessW(exe.c_str(), command.data(), nullptr, nullptr, FALSE,
                        0, nullptr, dir.empty() ? nullptr : dir.c_str(), &si,
                        &pi)) {
    if (error != nullptr) *error = ::GetLastError();
    return nullptr;
  }
  ::CloseHandle(pi.hThread);
  if (wait_for_input_idle) ::WaitForInputIdle(pi.hProcess, 5000);
  if (error != nullptr) *error = ERROR_SUCCESS;
  return pi.hProcess;
}

HANDLE StartProcessElevated(const std::wstring& exe, const std::wstring& args,
                            HWND owner, DWORD* error) {
  SHELLEXECUTEINFOW info = {};
  info.cbSize = sizeof(info);
  info.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NOASYNC |
               SEE_MASK_FLAG_NO_UI;
  info.hwnd = owner;
  info.lpVerb = L"runas";
  info.lpFile = exe.c_str();
  info.lpParameters = args.c_str();
  const std::wstring dir = ParentDir(exe);
  info.lpDirectory = dir.empty() ? nullptr : dir.c_str();
  info.nShow = SW_SHOWNORMAL;
  if (!::ShellExecuteExW(&info)) {
    if (error != nullptr) *error = ::GetLastError();
    return nullptr;
  }
  if (error != nullptr) *error = ERROR_SUCCESS;
  return info.hProcess;
}

// --- SHA-256 ----------------------------------------------------------------

Sha256::Sha256() {
  if (::BCryptOpenAlgorithmProvider(&alg_, BCRYPT_SHA256_ALGORITHM, nullptr,
                                    0) != 0) {
    alg_ = nullptr;
    return;
  }
  DWORD object_size = 0;
  ULONG written = 0;
  if (::BCryptGetProperty(alg_, BCRYPT_OBJECT_LENGTH,
                          reinterpret_cast<PUCHAR>(&object_size),
                          sizeof(object_size), &written, 0) != 0) {
    return;
  }
  object_.resize(object_size);
  if (::BCryptCreateHash(alg_, &hash_, object_.data(), object_size, nullptr, 0,
                         0) != 0) {
    hash_ = nullptr;
    return;
  }
  ok_ = true;
}

Sha256::~Sha256() {
  if (hash_ != nullptr) ::BCryptDestroyHash(hash_);
  if (alg_ != nullptr) ::BCryptCloseAlgorithmProvider(alg_, 0);
}

void Sha256::Update(const void* data, size_t size) {
  if (!ok_) return;
  const auto* bytes = static_cast<const uint8_t*>(data);
  while (size > 0) {
    const ULONG chunk = static_cast<ULONG>(std::min<size_t>(size, 1u << 30));
    if (::BCryptHashData(hash_, const_cast<PUCHAR>(bytes), chunk, 0) != 0) {
      ok_ = false;
      return;
    }
    bytes += chunk;
    size -= chunk;
  }
}

bool Sha256::Final(uint8_t out[32]) {
  if (!ok_) return false;
  ok_ = false;
  return ::BCryptFinishHash(hash_, out, 32, 0) == 0;
}

bool Sha256Buffer(const void* data, size_t size, uint8_t out[32]) {
  Sha256 sha;
  sha.Update(data, size);
  return sha.Final(out);
}

bool Sha256File(const std::wstring& path, uint8_t out[32]) {
  HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ,
                              nullptr, OPEN_EXISTING,
                              FILE_FLAG_SEQUENTIAL_SCAN, nullptr);
  if (file == INVALID_HANDLE_VALUE) return false;
  Sha256 sha;
  std::vector<uint8_t> buffer(1 << 20);
  bool ok = sha.ok();
  for (;;) {
    DWORD read = 0;
    if (!::ReadFile(file, buffer.data(), static_cast<DWORD>(buffer.size()),
                    &read, nullptr)) {
      ok = false;
      break;
    }
    if (read == 0) break;
    sha.Update(buffer.data(), read);
  }
  ::CloseHandle(file);
  return sha.Final(out) && ok;
}

// --- Versionen --------------------------------------------------------------

namespace {

std::vector<std::string> Split(const std::string& text, char sep) {
  std::vector<std::string> parts;
  size_t start = 0;
  for (;;) {
    const size_t pos = text.find(sep, start);
    parts.push_back(text.substr(start, pos - start));
    if (pos == std::string::npos) break;
    start = pos + 1;
  }
  return parts;
}

bool IsNumber(const std::string& s) {
  if (s.empty()) return false;
  for (char c : s) {
    if (c < '0' || c > '9') return false;
  }
  return true;
}

int CompareNumbers(const std::string& a, const std::string& b) {
  // Fuehrende Nullen ignorieren, dann nach Laenge, dann lexikografisch.
  size_t ia = a.find_first_not_of('0');
  size_t ib = b.find_first_not_of('0');
  const std::string na = ia == std::string::npos ? "" : a.substr(ia);
  const std::string nb = ib == std::string::npos ? "" : b.substr(ib);
  if (na.size() != nb.size()) return na.size() < nb.size() ? -1 : 1;
  const int c = na.compare(nb);
  return c < 0 ? -1 : (c > 0 ? 1 : 0);
}

}  // namespace

int CompareVersions(const std::string& a, const std::string& b) {
  const size_t da = a.find_first_of("-+");
  const size_t db = b.find_first_of("-+");
  const std::string core_a = a.substr(0, da);
  const std::string core_b = b.substr(0, db);
  const auto pa = Split(core_a, '.');
  const auto pb = Split(core_b, '.');
  const size_t n = std::max(pa.size(), pb.size());
  for (size_t i = 0; i < n; ++i) {
    const std::string x = i < pa.size() ? pa[i] : "0";
    const std::string y = i < pb.size() ? pb[i] : "0";
    const int c = CompareNumbers(IsNumber(x) ? x : "0", IsNumber(y) ? y : "0");
    if (c != 0) return c;
  }
  auto pre = [](const std::string& v, size_t dash) -> std::string {
    if (dash == std::string::npos || v[dash] != '-') return std::string();
    const size_t plus = v.find('+', dash);
    return v.substr(dash + 1, plus == std::string::npos ? std::string::npos
                                                         : plus - dash - 1);
  };
  const std::string ra = pre(a, da);
  const std::string rb = pre(b, db);
  if (ra.empty() && rb.empty()) return 0;
  if (ra.empty()) return 1;   // Release > Vorabversion
  if (rb.empty()) return -1;
  const auto ia = Split(ra, '.');
  const auto ib = Split(rb, '.');
  const size_t m = std::min(ia.size(), ib.size());
  for (size_t i = 0; i < m; ++i) {
    const bool na = IsNumber(ia[i]);
    const bool nb = IsNumber(ib[i]);
    int c = 0;
    if (na && nb) {
      c = CompareNumbers(ia[i], ib[i]);
    } else if (na != nb) {
      c = na ? -1 : 1;
    } else {
      c = ia[i].compare(ib[i]);
      c = c < 0 ? -1 : (c > 0 ? 1 : 0);
    }
    if (c != 0) return c;
  }
  if (ia.size() == ib.size()) return 0;
  return ia.size() < ib.size() ? -1 : 1;
}

// --- Produktdaten -----------------------------------------------------------

bool ParseProduct(const std::string& ini_text, Product* out,
                  std::wstring* error) {
  Product p;
  const std::wstring text = Utf8ToWide(ini_text);
  size_t start = 0;
  while (start <= text.size()) {
    size_t end = text.find(L'\n', start);
    if (end == std::wstring::npos) end = text.size();
    std::wstring line = Trim(text.substr(start, end - start));
    start = end + 1;
    if (line.empty() || line[0] == L';' || line[0] == L'#' || line[0] == L'[') {
      if (end == text.size()) break;
      continue;
    }
    const size_t eq = line.find(L'=');
    if (eq == std::wstring::npos) continue;
    const std::wstring key = Lower(Trim(line.substr(0, eq)));
    const std::wstring value = Trim(line.substr(eq + 1));
    auto flag = [&](bool* target) {
      *target = value == L"1" || EqualsI(value, L"true") ||
                EqualsI(value, L"yes");
    };
    if (key == L"name") p.name = value;
    else if (key == L"version") p.version = value;
    else if (key == L"publisher") p.publisher = value;
    else if (key == L"exe_name") p.exe_name = value;
    else if (key == L"url") p.url = value;
    else if (key == L"app_id") p.app_id = value;
    else if (key == L"scheme") p.scheme = value;
    else if (key == L"dir_name") p.dir_name = value;
    else if (key == L"data_company") p.data_company = value;
    else if (key == L"data_product") p.data_product = value;
    else if (key == L"default_scope") p.default_scope = Lower(value);
    else if (key == L"default_desktop_shortcut") flag(&p.default_desktop);
    else if (key == L"default_start_menu") flag(&p.default_start_menu);
    else if (key == L"default_autostart") flag(&p.default_autostart);
    if (end == text.size()) break;
  }
  std::wstring missing;
  if (p.name.empty()) missing += L" name";
  if (p.version.empty()) missing += L" version";
  if (p.publisher.empty()) missing += L" publisher";
  if (p.exe_name.empty()) missing += L" exe_name";
  if (p.app_id.empty()) missing += L" app_id";
  if (p.dir_name.empty()) missing += L" dir_name";
  if (!missing.empty()) {
    if (error != nullptr) *error = L"Produktdaten unvollstaendig:" + missing;
    return false;
  }
  // Ordner- und Dateinamen duerfen keine Pfadanteile enthalten.
  auto bad_name = [](const std::wstring& v) {
    return v.find_first_of(L"\\/:*?\"<>|") != std::wstring::npos ||
           v == L"." || v == L"..";
  };
  if (bad_name(p.exe_name) || bad_name(p.dir_name) ||
      (!p.scheme.empty() && bad_name(p.scheme))) {
    if (error != nullptr) *error = L"Produktdaten enthalten ungueltige Namen";
    return false;
  }
  if (p.default_scope != L"user" && p.default_scope != L"machine") {
    p.default_scope = L"user";
  }
  *out = p;
  return true;
}

// --- Protokoll --------------------------------------------------------------

namespace {
std::mutex g_log_mutex;
HANDLE g_log_file = INVALID_HANDLE_VALUE;
std::function<void(const std::wstring&)> g_log_sink;
}  // namespace

void Log::OpenFile(const std::wstring& path) {
  std::lock_guard<std::mutex> lock(g_log_mutex);
  if (g_log_file != INVALID_HANDLE_VALUE) ::CloseHandle(g_log_file);
  // Kein Folgen von Reparse-Points ist hier nicht noetig: der Pfad kommt vom
  // Aufrufer (Admin/CI). Erhoehte GUI-Laeufe protokollieren ueber die Pipe.
  g_log_file = ::CreateFileW(path.c_str(), FILE_APPEND_DATA, FILE_SHARE_READ,
                             nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL,
                             nullptr);
}

void Log::SetSink(std::function<void(const std::wstring&)> sink) {
  std::lock_guard<std::mutex> lock(g_log_mutex);
  g_log_sink = std::move(sink);
}

void Log::Line(const std::wstring& text) {
  SYSTEMTIME t = {};
  ::GetLocalTime(&t);
  wchar_t stamp[32];
  ::wsprintfW(stamp, L"%04u-%02u-%02u %02u:%02u:%02u ", t.wYear, t.wMonth,
              t.wDay, t.wHour, t.wMinute, t.wSecond);
  const std::wstring line = stamp + text;
  std::lock_guard<std::mutex> lock(g_log_mutex);
  if (g_log_file != INVALID_HANDLE_VALUE) {
    const std::string utf8 = WideToUtf8(line) + "\r\n";
    DWORD written = 0;
    ::WriteFile(g_log_file, utf8.data(), static_cast<DWORD>(utf8.size()),
                &written, nullptr);
  }
  if (g_log_sink) g_log_sink(line);
}

void Log::Close() {
  std::lock_guard<std::mutex> lock(g_log_mutex);
  if (g_log_file != INVALID_HANDLE_VALUE) ::CloseHandle(g_log_file);
  g_log_file = INVALID_HANDLE_VALUE;
  g_log_sink = nullptr;
}

}  // namespace lf
