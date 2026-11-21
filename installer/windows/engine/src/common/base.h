// Gemeinsame Grundlagen fuer Setup-Stub, Engine, Packer und die Setup-Oberflaeche.
//
// Bewusst ohne Fremdbibliotheken: nur Win32, BCrypt (SHA-256) und die
// Windows-Compression-API (cabinet.dll).
#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <bcrypt.h>

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace lf {

// Exit-Codes von setup.exe und uninstall.exe. Dokumentiert in
// packaging/windows/README.md, dort und hier gleich halten.
enum ExitCode : int {
  kExitOk = 0,
  kExitBadArgs = 1,
  kExitCancelled = 2,
  kExitFailed = 3,
  kExitCorrupt = 4,
  kExitAppRunning = 5,
  kExitDowngrade = 6,
  kExitElevation = 7,
  kExitBadTarget = 8,
  kExitRollbackIncomplete = 9,
  kExitNotInstalled = 10,
  kExitDiskFull = 11,
  kExitOtherScope = 12,
};

// --- Text -------------------------------------------------------------------

std::wstring Utf8ToWide(const std::string& text);
std::string WideToUtf8(const std::wstring& text);
std::wstring Lower(std::wstring text);
bool EqualsI(const std::wstring& a, const std::wstring& b);
bool StartsWithI(const std::wstring& text, const std::wstring& prefix);
std::wstring Trim(const std::wstring& text);
std::string ToHex(const uint8_t* data, size_t size);
bool FromHex(const std::string& hex, uint8_t* out, size_t size);
std::wstring FormatWin32Error(DWORD code);
// JSON-String inkl. Anfuehrungszeichen, UTF-8.
std::string JsonString(const std::wstring& text);

// --- Pfade ------------------------------------------------------------------

std::wstring JoinPath(const std::wstring& base, const std::wstring& child);
std::wstring ParentDir(const std::wstring& path);
std::wstring FileNamePart(const std::wstring& path);
// Normalisiert Trenner auf '\', entfernt doppelte und abschliessende
// Trenner (ausser bei "C:\").
std::wstring NormalizePath(const std::wstring& path);
// Vollstaendiger Pfad (GetFullPathNameW), ohne abschliessenden Trenner.
std::wstring FullPath(const std::wstring& path);
// Setzt einen Pfad in Anfuehrungszeichen (Registry, Verknuepfungen,
// Kommandozeilen). Verhindert "unquoted path"-Fehler.
std::wstring Quote(const std::wstring& path);
// Kommandozeilen-Argument nach den Regeln von CommandLineToArgvW quoten.
std::wstring QuoteArg(const std::wstring& arg);
bool IsSubPathOf(const std::wstring& path, const std::wstring& root);
bool PathExists(const std::wstring& path);
bool DirExists(const std::wstring& path);
bool FileExists(const std::wstring& path);
std::wstring KnownFolder(const GUID& id);
std::wstring SelfPath();
std::wstring TempDir();

// --- Prozess ----------------------------------------------------------------

bool IsProcessElevated();
// Startet einen Prozess und gibt den Handle zurueck (oder nullptr).
HANDLE StartProcess(const std::wstring& exe, const std::wstring& args,
                    bool wait_for_input_idle = false, DWORD* error = nullptr);
// Startet erhoeht (UAC, Verb "runas"). error = ERROR_CANCELLED bei Ablehnung.
HANDLE StartProcessElevated(const std::wstring& exe, const std::wstring& args,
                            HWND owner, DWORD* error = nullptr);

// --- SHA-256 ----------------------------------------------------------------

class Sha256 {
 public:
  Sha256();
  ~Sha256();
  Sha256(const Sha256&) = delete;
  Sha256& operator=(const Sha256&) = delete;
  bool ok() const { return ok_; }
  void Update(const void* data, size_t size);
  bool Final(uint8_t out[32]);

 private:
  BCRYPT_ALG_HANDLE alg_ = nullptr;
  BCRYPT_HASH_HANDLE hash_ = nullptr;
  std::vector<uint8_t> object_;
  bool ok_ = false;
};

bool Sha256Buffer(const void* data, size_t size, uint8_t out[32]);
bool Sha256File(const std::wstring& path, uint8_t out[32]);

// --- Versionen --------------------------------------------------------------

// Vergleich nach SemVer-Vorrang (1.2.3 < 1.2.4, 1.2.3-rc.1 < 1.2.3).
// Ergebnis < 0, 0 oder > 0.
int CompareVersions(const std::string& a, const std::string& b);

// --- Produktdaten -----------------------------------------------------------

// Produktdaten aus packaging/windows/installer.ini (Packer bettet sie ein).
struct Product {
  std::wstring name;          // Anzeigename, z. B. "LINEFM Radio"
  std::wstring version;       // Versionslabel, z. B. "1.2.3" oder "1.2.3-rc.1"
  std::wstring publisher;     // Herausgeber in "Apps & Features"
  std::wstring exe_name;      // Programmdatei, z. B. "linefm_radio.exe"
  std::wstring url;           // Website
  std::wstring app_id;        // feste GUID, z. B. "{6F3B...}"
  std::wstring scheme;        // Link-Schema ohne "://", z. B. "linefm"
  std::wstring dir_name;      // Ordnername unter Programs/Program Files
  std::wstring data_company;  // Ersatzwert, falls die EXE keine Angabe hat
  std::wstring data_product;  // Ersatzwert, falls die EXE keine Angabe hat
  std::wstring default_scope = L"user";
  bool default_desktop = true;
  bool default_start_menu = true;
  bool default_autostart = false;
};

bool ParseProduct(const std::string& ini_text, Product* out, std::wstring* error);

// --- Protokoll --------------------------------------------------------------

// Zeilenweises Protokoll (UTF-8). Optional Datei und/oder Rueckruf (Pipe).
class Log {
 public:
  static void OpenFile(const std::wstring& path);
  static void SetSink(std::function<void(const std::wstring&)> sink);
  static void Line(const std::wstring& text);
  static void Close();
};

}  // namespace lf
