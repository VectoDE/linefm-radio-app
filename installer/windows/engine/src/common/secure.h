// Sichere Ordner, Rechte und Pruefung des Zielordners.
#pragma once

#include "base.h"

namespace lf {

// Legt einen Ordner mit zufaelligem Namen und eigener, nicht vererbter DACL an.
//   admin_only = false: SYSTEM, Administratoren und der aktuelle Benutzer.
//   admin_only = true:  nur SYSTEM und Administratoren (fuer erhoehte Laeufe);
//                       Basis ist dann %SystemRoot%\SystemTemp bzw. \Temp, in
//                       dem normale Benutzer fremde Eintraege nicht umbenennen
//                       oder loeschen koennen.
bool CreatePrivateDir(bool admin_only, const std::wstring& prefix,
                      std::wstring* out, std::wstring* error);

// Erzeugt eine neue Datei (CREATE_NEW) mit derselben DACL wie oben.
HANDLE CreatePrivateFile(const std::wstring& path, bool admin_only,
                         DWORD* error);

// Setzt fuer einen neu angelegten Installationsordner "fuer alle Benutzer"
// ausserhalb von Program Files eine geschuetzte DACL (Admins/SYSTEM voll,
// Benutzer lesen und ausfuehren).
bool ProtectMachineDir(const std::wstring& dir, std::wstring* error);

// Loescht einen Ordner rekursiv (folgt keinen Reparse-Points).
bool DeleteTree(const std::wstring& dir);

// Zufaellige Hex-Zeichenkette (BCryptGenRandom).
std::wstring RandomHex(size_t bytes);

// Prueft den Zielordner. per_machine verlangt zusaetzlich, dass kein normaler
// Benutzer den Ordner oder seine Elternordner veraendern kann.
bool ValidateTargetDir(const std::wstring& dir, bool per_machine,
                       std::wstring* reason);

// Standard-Installationsorte.
std::wstring DefaultUserInstallDir(const std::wstring& dir_name);
std::wstring DefaultMachineInstallDir(const std::wstring& dir_name);

}  // namespace lf
