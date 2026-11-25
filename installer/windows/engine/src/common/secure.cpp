#include "secure.h"

#include <aclapi.h>
#include <knownfolders.h>
#include <sddl.h>
#include <shlobj.h>

#include <memory>

namespace lf {

namespace {

constexpr wchar_t kTrustedInstallerSid[] =
    L"S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464";

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
    const auto* user = reinterpret_cast<const TOKEN_USER*>(buffer.data());
    LPWSTR text = nullptr;
    if (::ConvertSidToStringSidW(user->User.Sid, &text)) {
      result = text;
      ::LocalFree(text);
    }
  }
  ::CloseHandle(token);
  return result;
}

std::wstring PrivateSddl(bool admin_only) {
  // P = geschuetzt (keine Vererbung von oben), OICI = gilt fuer Inhalt.
  std::wstring sddl = L"D:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)";
  if (!admin_only) {
    const std::wstring user = CurrentUserSid();
    if (!user.empty()) sddl += L"(A;OICI;FA;;;" + user + L")";
  }
  return sddl;
}

struct LocalFreeDeleter {
  void operator()(void* p) const {
    if (p != nullptr) ::LocalFree(p);
  }
};
using SecurityDescriptor = std::unique_ptr<void, LocalFreeDeleter>;

SecurityDescriptor MakeDescriptor(const std::wstring& sddl) {
  PSECURITY_DESCRIPTOR sd = nullptr;
  if (!::ConvertStringSecurityDescriptorToSecurityDescriptorW(
          sddl.c_str(), SDDL_REVISION_1, &sd, nullptr)) {
    return SecurityDescriptor();
  }
  return SecurityDescriptor(sd);
}

bool IsTrustedSid(PSID sid) {
  if (sid == nullptr) return false;
  if (::IsWellKnownSid(sid, WinLocalSystemSid) ||
      ::IsWellKnownSid(sid, WinBuiltinAdministratorsSid) ||
      ::IsWellKnownSid(sid, WinCreatorOwnerSid)) {
    return true;
  }
  LPWSTR text = nullptr;
  bool trusted = false;
  if (::ConvertSidToStringSidW(sid, &text)) {
    trusted = EqualsI(text, kTrustedInstallerSid);
    ::LocalFree(text);
  }
  return trusted;
}

DWORD MapGeneric(DWORD mask) {
  GENERIC_MAPPING mapping = {FILE_GENERIC_READ, FILE_GENERIC_WRITE,
                             FILE_GENERIC_EXECUTE, FILE_ALL_ACCESS};
  ::MapGenericMask(&mask, &mapping);
  return mask;
}

// true, wenn ein nicht vertrauenswuerdiges Konto Besitzer ist oder eines der
// Rechte in `dangerous` hat.
bool AllowsUntrusted(const std::wstring& path, DWORD dangerous,
                     std::wstring* detail) {
  PSID owner = nullptr;
  PACL dacl = nullptr;
  PSECURITY_DESCRIPTOR sd = nullptr;
  const DWORD rc = ::GetNamedSecurityInfoW(
      path.c_str(), SE_FILE_OBJECT,
      OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION, &owner, nullptr,
      &dacl, nullptr, &sd);
  if (rc != ERROR_SUCCESS) {
    if (detail != nullptr) *detail = L"Rechte nicht lesbar: " + path;
    return true;
  }
  SecurityDescriptor guard(sd);
  if (!IsTrustedSid(owner)) {
    if (detail != nullptr) *detail = L"Besitzer ist kein Administrator: " + path;
    return true;
  }
  if (dacl == nullptr) {
    if (detail != nullptr) *detail = L"Ordner ohne Zugriffsschutz: " + path;
    return true;
  }
  for (DWORD i = 0; i < dacl->AceCount; ++i) {
    void* raw = nullptr;
    if (!::GetAce(dacl, i, &raw)) continue;
    const auto* header = static_cast<const ACE_HEADER*>(raw);
    if (header->AceFlags & INHERIT_ONLY_ACE) continue;
    if (header->AceType != ACCESS_ALLOWED_ACE_TYPE) continue;
    const auto* ace = static_cast<const ACCESS_ALLOWED_ACE*>(raw);
    PSID sid = const_cast<DWORD*>(&ace->SidStart);
    if (IsTrustedSid(sid)) continue;
    if (MapGeneric(ace->Mask) & dangerous) {
      if (detail != nullptr) {
        *detail = L"Ordner ist fuer normale Benutzer veraenderbar: " + path;
      }
      return true;
    }
  }
  return false;
}

bool HasReparsePoint(const std::wstring& path) {
  std::wstring current = NormalizePath(path);
  while (!current.empty()) {
    const DWORD attr = ::GetFileAttributesW(current.c_str());
    if (attr != INVALID_FILE_ATTRIBUTES &&
        (attr & FILE_ATTRIBUTE_REPARSE_POINT)) {
      return true;
    }
    const std::wstring parent = ParentDir(current);
    if (parent == current) break;
    current = parent;
  }
  return false;
}

bool IsDirEmpty(const std::wstring& dir) {
  WIN32_FIND_DATAW data = {};
  HANDLE find = ::FindFirstFileExW(JoinPath(dir, L"*").c_str(),
                                   FindExInfoBasic, &data,
                                   FindExSearchNameMatch, nullptr, 0);
  if (find == INVALID_HANDLE_VALUE) return true;
  bool empty = true;
  do {
    const std::wstring name = data.cFileName;
    if (name != L"." && name != L"..") {
      empty = false;
      break;
    }
  } while (::FindNextFileW(find, &data));
  ::FindClose(find);
  return empty;
}

}  // namespace

std::wstring RandomHex(size_t bytes) {
  std::vector<uint8_t> buffer(bytes);
  if (::BCryptGenRandom(nullptr, buffer.data(), static_cast<ULONG>(bytes),
                        BCRYPT_USE_SYSTEM_PREFERRED_RNG) != 0) {
    // Ersatz: Zeit und Prozess-ID. Nur Namensbildung, kein Geheimnis; die
    // DACL schuetzt den Ordner unabhaengig vom Namen.
    LARGE_INTEGER counter = {};
    ::QueryPerformanceCounter(&counter);
    for (size_t i = 0; i < bytes; ++i) {
      buffer[i] = static_cast<uint8_t>((counter.QuadPart >> (i % 8 * 8)) ^
                                       ::GetCurrentProcessId() ^ (i * 31));
    }
  }
  return Utf8ToWide(ToHex(buffer.data(), buffer.size()));
}

bool CreatePrivateDir(bool admin_only, const std::wstring& prefix,
                      std::wstring* out, std::wstring* error) {
  std::wstring base;
  if (admin_only) {
    const std::wstring windows = KnownFolder(FOLDERID_Windows);
    if (DirExists(JoinPath(windows, L"SystemTemp"))) {
      base = JoinPath(windows, L"SystemTemp");
    } else {
      base = JoinPath(windows, L"Temp");
    }
  } else {
    base = TempDir();
  }
  if (base.empty() || !DirExists(base)) {
    if (error != nullptr) *error = L"Kein Temp-Ordner verfuegbar";
    return false;
  }
  SecurityDescriptor sd = MakeDescriptor(PrivateSddl(admin_only));
  if (!sd) {
    if (error != nullptr) *error = L"Sicherheitsbeschreibung fehlgeschlagen";
    return false;
  }
  SECURITY_ATTRIBUTES sa = {sizeof(sa), sd.get(), FALSE};
  for (int attempt = 0; attempt < 8; ++attempt) {
    const std::wstring path = JoinPath(base, prefix + RandomHex(12));
    if (::CreateDirectoryW(path.c_str(), &sa)) {
      *out = path;
      return true;
    }
    if (::GetLastError() != ERROR_ALREADY_EXISTS) {
      if (error != nullptr) {
        *error = L"Temp-Ordner nicht anlegbar: " +
                 FormatWin32Error(::GetLastError());
      }
      return false;
    }
  }
  if (error != nullptr) *error = L"Temp-Ordner nicht anlegbar";
  return false;
}

HANDLE CreatePrivateFile(const std::wstring& path, bool admin_only,
                         DWORD* error) {
  SecurityDescriptor sd = MakeDescriptor(PrivateSddl(admin_only));
  SECURITY_ATTRIBUTES sa = {sizeof(sa), sd.get(), FALSE};
  HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ | GENERIC_WRITE, 0,
                              sd ? &sa : nullptr, CREATE_NEW,
                              FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE && error != nullptr) {
    *error = ::GetLastError();
  }
  return file;
}

bool ProtectMachineDir(const std::wstring& dir, std::wstring* error) {
  // 0x1200a9 = Lesen und Ausfuehren.
  SecurityDescriptor sd = MakeDescriptor(
      L"D:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;BU)");
  if (!sd) {
    if (error != nullptr) *error = L"Sicherheitsbeschreibung fehlgeschlagen";
    return false;
  }
  BOOL present = FALSE;
  BOOL defaulted = FALSE;
  PACL dacl = nullptr;
  ::GetSecurityDescriptorDacl(sd.get(), &present, &dacl, &defaulted);
  PSID admins = nullptr;
  SID_IDENTIFIER_AUTHORITY nt = SECURITY_NT_AUTHORITY;
  ::AllocateAndInitializeSid(&nt, 2, SECURITY_BUILTIN_DOMAIN_RID,
                             DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
                             &admins);
  const DWORD rc = ::SetNamedSecurityInfoW(
      const_cast<LPWSTR>(dir.c_str()), SE_FILE_OBJECT,
      DACL_SECURITY_INFORMATION | PROTECTED_DACL_SECURITY_INFORMATION |
          OWNER_SECURITY_INFORMATION,
      admins, nullptr, dacl, nullptr);
  if (admins != nullptr) ::FreeSid(admins);
  if (rc != ERROR_SUCCESS) {
    if (error != nullptr) {
      *error = L"Rechte fuer " + dir + L" nicht setzbar: " +
               FormatWin32Error(rc);
    }
    return false;
  }
  return true;
}

bool DeleteTree(const std::wstring& dir) {
  const DWORD attr = ::GetFileAttributesW(dir.c_str());
  if (attr == INVALID_FILE_ATTRIBUTES) return true;
  if (attr & FILE_ATTRIBUTE_REPARSE_POINT) {
    // Nur den Link entfernen, nie dem Ziel folgen.
    return ::RemoveDirectoryW(dir.c_str()) != 0;
  }
  bool ok = true;
  WIN32_FIND_DATAW data = {};
  HANDLE find = ::FindFirstFileExW(JoinPath(dir, L"*").c_str(),
                                   FindExInfoBasic, &data,
                                   FindExSearchNameMatch, nullptr, 0);
  if (find != INVALID_HANDLE_VALUE) {
    do {
      const std::wstring name = data.cFileName;
      if (name == L"." || name == L"..") continue;
      const std::wstring path = JoinPath(dir, name);
      if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
        ok = DeleteTree(path) && ok;
      } else {
        if (data.dwFileAttributes & FILE_ATTRIBUTE_READONLY) {
          ::SetFileAttributesW(path.c_str(), FILE_ATTRIBUTE_NORMAL);
        }
        ok = ::DeleteFileW(path.c_str()) != 0 && ok;
      }
    } while (::FindNextFileW(find, &data));
    ::FindClose(find);
  }
  return ::RemoveDirectoryW(dir.c_str()) != 0 && ok;
}

std::wstring DefaultUserInstallDir(const std::wstring& dir_name) {
  std::wstring base = KnownFolder(FOLDERID_UserProgramFiles);
  if (base.empty()) {
    base = JoinPath(KnownFolder(FOLDERID_LocalAppData), L"Programs");
  }
  return JoinPath(base, dir_name);
}

std::wstring DefaultMachineInstallDir(const std::wstring& dir_name) {
  return JoinPath(KnownFolder(FOLDERID_ProgramFiles), dir_name);
}

bool ValidateTargetDir(const std::wstring& raw, bool per_machine,
                       std::wstring* reason) {
  auto fail = [&](const std::wstring& text) {
    if (reason != nullptr) *reason = text;
    return false;
  };
  const std::wstring input = Trim(raw);
  if (input.size() < 4 || input.size() > 180) {
    return fail(L"Pfad fehlt oder ist zu lang (hoechstens 180 Zeichen)");
  }
  // Nur lokale Laufwerkspfade "X:\...", keine UNC-, Geraete- oder
  // relativen Pfade.
  if (!(((input[0] >= L'A' && input[0] <= L'Z') ||
         (input[0] >= L'a' && input[0] <= L'z')) &&
        input[1] == L':' && (input[2] == L'\\' || input[2] == L'/'))) {
    return fail(L"Bitte einen Ordner auf einem lokalen Laufwerk waehlen");
  }
  if (input.find_first_of(L"*?\"<>|", 0) != std::wstring::npos ||
      input.find(L':', 2) != std::wstring::npos) {
    return fail(L"Der Pfad enthaelt unzulaessige Zeichen");
  }
  const std::wstring dir = FullPath(input);
  if (dir.empty() || dir.size() <= 3) {
    return fail(L"Das Stammverzeichnis eines Laufwerks ist nicht erlaubt");
  }
  // Keine Bestandteile mit Punkt/Leerzeichen am Ende, keine reservierten Namen.
  {
    size_t start = 3;
    while (start < dir.size()) {
      size_t end = dir.find(L'\\', start);
      if (end == std::wstring::npos) end = dir.size();
      const std::wstring part = dir.substr(start, end - start);
      if (part.empty() || part.back() == L'.' || part.back() == L' ') {
        return fail(L"Ordnernamen duerfen nicht auf Punkt oder Leerzeichen enden");
      }
      static const wchar_t* kReserved[] = {L"CON", L"PRN", L"AUX", L"NUL",
                                           L"COM1", L"COM2", L"COM3", L"COM4",
                                           L"LPT1", L"LPT2", L"LPT3"};
      const std::wstring stem = part.substr(0, part.find(L'.'));
      for (const wchar_t* name : kReserved) {
        if (EqualsI(stem, name)) return fail(L"Reservierter Ordnername: " + part);
      }
      start = end + 1;
    }
  }
  const std::wstring root = dir.substr(0, 3);
  const UINT type = ::GetDriveTypeW(root.c_str());
  if (type != DRIVE_FIXED && !(type == DRIVE_REMOVABLE && !per_machine)) {
    return fail(L"Bitte ein lokales, fest eingebautes Laufwerk waehlen");
  }
  const std::wstring windows = KnownFolder(FOLDERID_Windows);
  if (!windows.empty() && IsSubPathOf(dir, windows)) {
    return fail(L"Der Windows-Ordner ist nicht erlaubt");
  }
  const std::wstring program_files = KnownFolder(FOLDERID_ProgramFiles);
  const std::wstring program_files_x86 = KnownFolder(FOLDERID_ProgramFilesX86);
  const std::wstring program_data = KnownFolder(FOLDERID_ProgramData);
  const std::wstring profile = KnownFolder(FOLDERID_Profile);
  // Ordner, die selbst nie Installationsziel sein duerfen.
  const std::wstring forbidden[] = {
      program_files,
      program_files_x86,
      program_data,
      profile,
      KnownFolder(FOLDERID_Desktop),
      KnownFolder(FOLDERID_Documents),
      KnownFolder(FOLDERID_Downloads),
      KnownFolder(FOLDERID_RoamingAppData),
      KnownFolder(FOLDERID_LocalAppData),
      KnownFolder(FOLDERID_UserProgramFiles),
      KnownFolder(FOLDERID_PublicDesktop),
  };
  for (const auto& f : forbidden) {
    if (!f.empty() && EqualsI(dir, f)) {
      return fail(L"Bitte einen eigenen Unterordner waehlen, nicht " + f);
    }
  }
  if (per_machine) {
    // Nutzerprofile sind fuer den jeweiligen Benutzer beschreibbar.
    const std::wstring users = ParentDir(profile);
    if (!users.empty() && IsSubPathOf(dir, users)) {
      return fail(
          L"Fuer alle Benutzer bitte nicht in ein Benutzerprofil installieren");
    }
    if (HasReparsePoint(dir)) {
      return fail(L"Der Pfad enthaelt eine Verknuepfung (Junction/Symlink)");
    }
    // Vorhandener Zielordner: muss Admins gehoeren, darf nicht fremd
    // beschreibbar sein. Nicht-leere fremde Ordner prueft die Engine.
    const DWORD target_danger = FILE_ADD_FILE | FILE_ADD_SUBDIRECTORY |
                                DELETE | WRITE_DAC | WRITE_OWNER |
                                FILE_DELETE_CHILD | FILE_WRITE_ATTRIBUTES;
    const DWORD parent_danger =
        DELETE | WRITE_DAC | WRITE_OWNER | FILE_DELETE_CHILD;
    std::wstring detail;
    std::wstring current = dir;
    bool first = true;
    while (!current.empty()) {
      if (DirExists(current)) {
        if (AllowsUntrusted(current, first ? target_danger : parent_danger,
                            &detail)) {
          // Ein eigener, frisch angelegter Ordner wird spaeter geschuetzt;
          // ein vorhandener, fremd veraenderbarer Zielordner nicht.
          return fail(detail);
        }
      }
      first = false;
      const std::wstring parent = ParentDir(current);
      if (parent.empty() || parent == current) break;
      current = parent;
    }
  } else {
    if ((!program_files.empty() && IsSubPathOf(dir, program_files)) ||
        (!program_files_x86.empty() && IsSubPathOf(dir, program_files_x86))) {
      return fail(
          L"Dieser Ordner braucht Administratorrechte. Waehle \"Fuer alle "
          L"Benutzer\" oder einen anderen Ordner");
    }
  }
  if (DirExists(dir) && !IsDirEmpty(dir) &&
      !FileExists(JoinPath(dir, L"uninstall.dat"))) {
    if (per_machine) {
      return fail(L"Der Ordner ist nicht leer. Bitte einen leeren Ordner waehlen");
    }
  }
  return true;
}

}  // namespace lf
