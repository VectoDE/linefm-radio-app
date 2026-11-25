// Installations- und Deinstallations-Engine. Laeuft im Setup-Stub, entweder
// still (Kommandozeile) oder gesteuert von der Setup-Oberflaeche ueber eine
// Named Pipe. Dieselbe Engine fuer beide Wege: die CI-Tests der stillen
// Installation pruefen damit auch den Code hinter der Oberflaeche.
#pragma once

#include "../common/archive.h"
#include "../common/base.h"

#include <atomic>

namespace lf {

// Rueckmeldungen der Engine (Fortschritt, Fragen, Ergebnis).
class Reporter {
 public:
  virtual ~Reporter() = default;
  virtual void Phase(const char* name) = 0;
  virtual void Progress(uint64_t done, uint64_t total) = 0;
  // Laufende App gefunden. true = beenden erlaubt.
  virtual bool ConfirmCloseApps(const std::vector<std::wstring>& names) = 0;
  virtual bool Cancelled() = 0;
};

struct InstallRequest {
  bool per_machine = false;
  bool scope_given = false;
  std::wstring dir;  // leer = Vorgabe bzw. vorhandene Installation
  bool desktop = true;
  bool desktop_given = false;
  bool start_menu = true;
  bool start_menu_given = false;
  bool autostart = false;
  bool autostart_given = false;
  bool allow_downgrade = false;
};

struct UninstallRequest {
  bool per_machine = false;
  std::wstring dir;            // Installationsordner (aus der Registry)
  bool delete_user_data = false;
  bool keep_uninstaller = false;  // stiller Lauf: uninstall.exe zuletzt loeschen
};

// Vorhandene Installation (Registry + uninstall.dat).
struct InstalledInfo {
  bool found = false;
  bool per_machine = false;
  std::wstring dir;
  std::wstring version;
  bool desktop = false;
  bool start_menu = false;
  bool autostart = false;
};

// Inhalt von uninstall.dat im Installationsordner.
struct Manifest {
  std::string product_ini;  // Produktdaten der installierten Version
  std::wstring version;
  bool per_machine = false;
  bool desktop = false;
  bool start_menu = false;
  bool autostart = false;
  struct File {
    std::string sha256;   // hex
    std::wstring rel;     // relativ zum Installationsordner
  };
  struct UiFile {
    std::string sha256;
    std::wstring source;  // relativ zum Installationsordner
    std::wstring dest;    // relativ zum Ordner der Setup-Oberflaeche
  };
  std::vector<File> files;
  std::vector<UiFile> ui;
  std::vector<std::wstring> shortcuts;  // absolute Pfade der .lnk-Dateien
};

constexpr wchar_t kManifestName[] = L"uninstall.dat";
constexpr wchar_t kUninstallerName[] = L"uninstall.exe";
constexpr wchar_t kUiExeName[] = L"linefm_setup.exe";

bool ReadManifest(const std::wstring& dir, Manifest* manifest);

InstalledInfo FindInstalled(const Product& product, int scope /*0=user,1=machine*/);
// Sucht zuerst Benutzer-, dann Rechner-Installation.
InstalledInfo FindAnyInstalled(const Product& product);
// Liest die Produktdaten einer vorhandenen Installation (uninstall.dat).
bool ReadInstalledProduct(const std::wstring& dir, Product* product);

int RunInstall(Payload& payload, const Product& product,
               const InstallRequest& request, Reporter& reporter,
               std::wstring* message);

int RunUninstall(const Product& product, const UninstallRequest& request,
                 Reporter& reporter, std::wstring* message);

// Loescht die Nutzerdaten der App fuer den aktuellen Benutzer.
bool DeleteUserData(const Product& product, const std::wstring& exe_path);

}  // namespace lf
