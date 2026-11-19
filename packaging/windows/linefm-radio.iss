; Inno-Setup-Skript fuer LINEFM Radio (Windows x64).
;
; Vertrag mit .github/workflows/build.yml (P25). Der Workflow ruft ISCC mit
; diesen Defines auf:
;   /DAppVersion=<x.y.z>               Versionsnummer ohne Suffix
;   /DSourceDir=<Pfad>                 build\windows\x64\runner\Release
;   /DOutputDir=<Pfad>                 Zielordner (dist)
;   /DOutputBaseFilename=<Name>        Dateiname ohne .exe
;
; Lokal bauen (Inno Setup 6, https://jrsoftware.org/isinfo.php):
;   flutter build windows --release
;   iscc /DAppVersion=1.0.0 /DSourceDir=..\..\build\windows\x64\runner\Release ^
;        /DOutputDir=..\..\dist /DOutputBaseFilename=linefm-radio-setup linefm-radio.iss
;
; Signatur: Das Skript signiert nicht selbst. Die CI signiert Setup-EXE
; nachtraeglich per signtool, sobald ein Zertifikat hinterlegt ist.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif
#ifndef OutputBaseFilename
  #define OutputBaseFilename "linefm-radio-setup"
#endif

#define AppName "LINEFM Radio"
#define AppExeName "linefm_radio.exe"
#define AppPublisher "LINEFM"
#define AppURL "https://app.linefm.de"

[Setup]
; Feste GUID, darf sich nie aendern (identifiziert die Installation fuer Updates).
AppId={{6F3B1E52-8C4A-4D7E-9A21-5B0C7D3E91F4}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes
RestartApplications=no
; Siehe oben: die CI signiert die fertige EXE.

[Languages]
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

; Deep-Link-Schema linefm:// (nur fuer den aktuellen Benutzer, kein Admin noetig).
[Registry]
Root: HKA; Subkey: "Software\Classes\linefm"; ValueType: string; ValueName: ""; ValueData: "URL:LINEFM Radio"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\linefm"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\linefm\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExeName},0"
Root: HKA; Subkey: "Software\Classes\linefm\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
