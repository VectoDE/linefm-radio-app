<#
.SYNOPSIS
  Builds LINEFM Radio locally (Windows PowerShell 5.1 or newer, no extra modules).

.DESCRIPTION
  Checks the prerequisites, fetches the packages, builds the requested target and shows
  where the result is. With -Oeffnen the result is started afterwards.
  No admin rights are needed and nothing is installed.

.PARAMETER Ziel
  windows | web | apk | aab   (linux and macos are built by tool/bauen.sh)

.PARAMETER Oeffnen
  Start after the build: windows = start the app, web = local server plus browser,
  apk and aab = open the folder in Explorer.

.PARAMETER Port
  Web only: desired start port for the local server (default 8090).
  If it is taken, the script uses the next free one.

.EXAMPLE
  powershell -File tool\bauen.ps1 -Ziel windows
  powershell -File tool\bauen.ps1 -Ziel web -Oeffnen

.NOTES
  Exit code 0 = done, 1 = prerequisite missing or build failed, 2 = invalid input.
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Ziel,
  [switch]$Oeffnen,
  [int]$Port = 8090,
  [switch]$Hilfe
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$gueltigeZiele = @('windows', 'web', 'apk', 'aab')
$nurBash = @('linux', 'macos')

function Show-Hilfe {
  Write-Host ''
  Write-Host 'Build LINEFM Radio (Windows)'
  Write-Host ''
  Write-Host 'Usage:'
  Write-Host '  powershell -File tool\bauen.ps1 -Ziel <target> [-Oeffnen] [-Port <number>]'
  Write-Host ''
  Write-Host 'Targets:'
  Write-Host '  windows   App for Windows (folder with linefm_radio.exe)'
  Write-Host '  web       Web version (folder build\web)'
  Write-Host '  apk       Android installation file'
  Write-Host '  aab       Android App Bundle (for the Play Store only)'
  Write-Host ''
  Write-Host 'Without -Oeffnen it only builds. With -Oeffnen the result is started afterwards.'
  Write-Host 'Linux and macOS are built by tool/bauen.sh.'
  Write-Host 'Guide: docs/BAUEN-UND-STARTEN.md'
  Write-Host ''
}

function Stop-Mit {
  param([string]$Text, [int]$Code = 1)
  Write-Host ''
  Write-Host ('bauen: ERROR: ' + $Text) -ForegroundColor Red
  exit $Code
}

function Write-Schritt {
  param([string]$Text)
  Write-Host ''
  Write-Host ('==> ' + $Text) -ForegroundColor Cyan
}

# Starts a program and aborts on an error code. Error output of the program
# stays text and does not trigger a script error in Windows PowerShell 5.1.
function Invoke-Programm {
  param([string]$Datei, [string[]]$Argumente, [string]$Beschreibung)
  $vorher = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & $Datei @Argumente
    $code = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $vorher
  }
  if ($code -ne 0) {
    Stop-Mit ($Beschreibung + ' failed (exit code ' + $code + '). The message is above. Help: docs/BAUEN-UND-STARTEN.md, section "Wenn etwas schiefgeht".') 1
  }
}

function Test-Programm {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-FreierPort {
  param([int]$Start)
  for ($p = $Start; $p -lt ($Start + 50); $p++) {
    $listener = $null
    try {
      $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $p)
      $listener.Start()
      $listener.Stop()
      return $p
    } catch {
      if ($listener) { try { $listener.Stop() } catch { } }
    }
  }
  Stop-Mit ('No free port found between ' + $Start + ' and ' + ($Start + 49) + '. Choose a different starting number with -Port.') 1
}

if ($Hilfe -or [string]::IsNullOrWhiteSpace($Ziel)) {
  Show-Hilfe
  if ($Hilfe) { exit 0 }
  Stop-Mit 'The target is missing. Example: powershell -File tool\bauen.ps1 -Ziel windows' 2
}

$Ziel = $Ziel.Trim().ToLowerInvariant()
if ($nurBash -contains $Ziel) {
  Stop-Mit ('This script does not build the target "' + $Ziel + '". Use tool/bauen.sh on a Linux or Mac machine.') 2
}
if ($gueltigeZiele -notcontains $Ziel) {
  Show-Hilfe
  Stop-Mit ('Unknown target "' + $Ziel + '". Allowed: ' + ($gueltigeZiele -join ', ') + '.') 2
}

$repo = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repo 'pubspec.yaml'))) {
  Stop-Mit ('pubspec.yaml not found under ' + $repo + '. The script must be in the project''s tool folder.') 1
}
Set-Location $repo

# Prerequisites
Write-Schritt 'Checking prerequisites'
if ($repo.Length -gt 40) {
  Write-Host ('Note: The project path is long (' + $repo.Length + ' characters). Windows aborts on paths over 260 characters. On errors, move the project to a short folder such as C:\linefm.') -ForegroundColor Yellow
}
if (-not (Test-Programm 'flutter')) {
  Stop-Mit 'Flutter was not found. Install Flutter 3.50.0 (https://docs.flutter.dev/get-started/install/windows), add the folder flutter\bin to the PATH and then open a new PowerShell window.' 1
}
if (-not (Test-Programm 'git')) {
  Write-Host 'Note: Git was not found. Flutter needs Git (https://git-scm.com/download/win).' -ForegroundColor Yellow
}
if ($Ziel -eq 'windows') {
  if (-not (Test-Programm 'cargo')) {
    Stop-Mit 'Rust was not found. The Windows build needs it (media control). Install it with rustup from https://rustup.rs and then open a new PowerShell window.' 1
  }
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (Test-Path $vswhere) {
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) {
      Stop-Mit 'Visual Studio is present, but without C++ tools. Open the Visual Studio Installer, choose "Modify" and tick "Desktop development with C++".' 1
    }
  } else {
    Write-Host 'Note: Visual Studio was not found. The Windows build needs Visual Studio (Build Tools) with "Desktop development with C++". Check with: flutter doctor' -ForegroundColor Yellow
  }
}
if (($Ziel -eq 'apk') -or ($Ziel -eq 'aab')) {
  if (-not ($env:JAVA_HOME -or (Test-Programm 'java'))) {
    Write-Host 'Note: Java (JDK 17) was not found. The Android build needs it. Check with: flutter doctor' -ForegroundColor Yellow
  }
}
if ($Ziel -eq 'web' -and $Oeffnen) {
  $python = $null
  foreach ($kandidat in @('python', 'py')) {
    if (Test-Programm $kandidat) { $python = $kandidat; break }
  }
  if (-not $python) {
    Stop-Mit 'Python was not found. It starts the local web server (-Oeffnen). Install Python from https://www.python.org/downloads/ (tick "Add python.exe to PATH") or build without -Oeffnen.' 1
  }
}

$defineArgs = @()
# config\app.yaml and config\features.yaml (YAML with comments) are
# validated and written as build values to config\app.json.
if ((Test-Path (Join-Path $repo 'config\app.yaml')) -or (Test-Path (Join-Path $repo 'config\features.yaml'))) {
  Write-Host 'config\app.yaml or features.yaml found, build values are being generated.'
  Push-Location $repo
  try { & dart run tool/check_config.dart --defines config/app.json } finally { Pop-Location }
  if ($LASTEXITCODE -ne 0) { throw 'Configuration in config is invalid, see the messages above.' }
}
if (Test-Path (Join-Path $repo 'config\app.json')) {
  Write-Host 'config\app.json found, it is used for the build.'
  $defineArgs = @('--dart-define-from-file=config/app.json')
} else {
  Write-Host 'No config\app.json, the app builds with default values.'
}
# Local builds show "development version" with the short commit ID.
$commit = ''
try { $commit = (& git -C $repo rev-parse --short HEAD 2>$null) } catch { $commit = '' }
if ($commit) { $defineArgs += "--dart-define=APP_COMMIT=$commit" }

$webPort = $Port
if ($Ziel -eq 'web') { $webPort = Get-FreierPort $Port }

Write-Schritt 'Fetching packages (flutter pub get)'
Invoke-Programm 'flutter' @('pub', 'get') 'flutter pub get'

$ergebnis = $null
$sw = [System.Diagnostics.Stopwatch]::StartNew()

switch ($Ziel) {
  'windows' {
    Write-Schritt 'Building Windows (takes about 5 to 10 minutes the first time)'
    Invoke-Programm 'flutter' (@('build', 'windows', '--release') + $defineArgs) 'flutter build windows'
    $ergebnis = Join-Path $repo 'build\windows\x64\runner\Release\linefm_radio.exe'
  }
  'apk' {
    Write-Schritt 'Building Android APK'
    Invoke-Programm 'flutter' (@('build', 'apk', '--release') + $defineArgs) 'flutter build apk'
    $ergebnis = Join-Path $repo 'build\app\outputs\flutter-apk\app-release.apk'
  }
  'aab' {
    Write-Schritt 'Building Android App Bundle'
    Invoke-Programm 'flutter' (@('build', 'appbundle', '--release') + $defineArgs) 'flutter build appbundle'
    $ergebnis = Join-Path $repo 'build\app\outputs\bundle\release\app-release.aab'
  }
  'web' {
    Write-Schritt 'Building web'
    # Map unfilled legal-text placeholders to themselves, otherwise flutter build web warns.
    $webDefines = @(Get-ChildItem -Path (Join-Path $repo 'web') -Recurse -Filter 'index.html' |
      Select-String -Pattern '\{\{([A-Z][A-Z0-9_]*)\}\}' -AllMatches |
      ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } |
      Sort-Object -Unique | ForEach-Object { '--web-define=' + $_ + '={{' + $_ + '}}' })
    Invoke-Programm 'flutter' (@('build', 'web', '--release', '--wasm', '--no-web-resources-cdn') + $defineArgs + $webDefines) 'flutter build web'

    # As in CI: start the tools outside the package, otherwise "dart run"
    # additionally builds the project's native asset hooks.
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('linefm-bauen-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
      Copy-Item (Join-Path $repo 'tool\fetch_font_fallback.dart') $tmp
      Copy-Item (Join-Path $repo 'tool\web_postbuild.dart') $tmp
      Write-Schritt 'Fetching fallback fonts (needs internet)'
      Invoke-Programm 'dart' @('run', (Join-Path $tmp 'fetch_font_fallback.dart'), 'build/web') 'Fetching fallback fonts'
      Write-Schritt 'Post-processing the web files'
      Invoke-Programm 'dart' @('run', (Join-Path $tmp 'web_postbuild.dart'), 'build/web', '--targets', 'none', '--no-precompress', '--base-url', ('http://localhost:' + $webPort)) 'Post-processing (web_postbuild)'
    } finally {
      Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
    $ergebnis = Join-Path $repo 'build\web\index.html'
  }
}

if (-not (Test-Path $ergebnis)) {
  Stop-Mit ('The build reported success, but the expected file is missing: ' + $ergebnis) 1
}

$sw.Stop()
Write-Host ''
Write-Host ('DONE after ' + [int]$sw.Elapsed.TotalSeconds + ' seconds.') -ForegroundColor Green
Write-Host ('Result: ' + $ergebnis)

if (-not $Oeffnen) {
  switch ($Ziel) {
    'windows' { Write-Host 'Start: double-click the file. The whole "Release" folder belongs together.' }
    'web'     { Write-Host ('View: run again with -Oeffnen or: python -m http.server ' + $webPort + ' --directory build/web') }
    'apk'     { Write-Host 'Copy the APK to the phone and open it there.' }
    'aab'     { Write-Host 'The App Bundle is meant for the Play Store only, not for installing.' }
  }
  exit 0
}

Write-Schritt 'Opening the result'
switch ($Ziel) {
  'windows' {
    Start-Process -FilePath $ergebnis -WorkingDirectory (Split-Path -Parent $ergebnis)
    Write-Host 'The app was started.'
  }
  'apk' {
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + (Split-Path -Parent $ergebnis) + '"')
  }
  'aab' {
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + (Split-Path -Parent $ergebnis) + '"')
  }
  'web' {
    $adresse = 'http://localhost:' + $webPort
    Write-Host ('Server running at ' + $adresse + ' . Press Ctrl+C or close the window to stop.')
    Start-Process $adresse
    $serverArgs = @()
    if ($python -eq 'py') { $serverArgs += '-3' }
    $serverArgs += @('-m', 'http.server', [string]$webPort, '--bind', '127.0.0.1', '--directory', 'build/web')
    $vorher = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $python @serverArgs } finally { $ErrorActionPreference = $vorher }
  }
}
exit 0
