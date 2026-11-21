<#
.SYNOPSIS
  Baut LINEFM Radio lokal (Windows PowerShell 5.1 oder neuer, ohne Zusatzmodule).

.DESCRIPTION
  Prueft die Voraussetzungen, holt die Pakete, baut das gewuenschte Ziel und zeigt,
  wo das Ergebnis liegt. Mit -Oeffnen wird das Ergebnis danach gestartet.
  Es werden keine Admin-Rechte gebraucht und nichts installiert.

.PARAMETER Ziel
  windows | web | apk | aab   (linux und macos baut tool/bauen.sh)

.PARAMETER Oeffnen
  Nach dem Bauen starten: windows = App starten, web = lokaler Server plus Browser,
  apk und aab = Ordner im Explorer oeffnen.

.PARAMETER Port
  Nur Web: gewuenschter Startport fuer den lokalen Server (Standard 8090).
  Ist er belegt, nimmt das Skript den naechsten freien.

.EXAMPLE
  powershell -File tool\bauen.ps1 -Ziel windows
  powershell -File tool\bauen.ps1 -Ziel web -Oeffnen

.NOTES
  Exit-Code 0 = fertig, 1 = Voraussetzung fehlt oder Bau fehlgeschlagen, 2 = falsche Eingabe.
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
  Write-Host 'LINEFM Radio bauen (Windows)'
  Write-Host ''
  Write-Host 'Aufruf:'
  Write-Host '  powershell -File tool\bauen.ps1 -Ziel <ziel> [-Oeffnen] [-Port <zahl>]'
  Write-Host ''
  Write-Host 'Ziele:'
  Write-Host '  windows   App fuer Windows (Ordner mit linefm_radio.exe)'
  Write-Host '  web       Web-Version (Ordner build\web)'
  Write-Host '  apk       Android-Installationsdatei'
  Write-Host '  aab       Android App Bundle (nur fuer den Play Store)'
  Write-Host ''
  Write-Host 'Ohne -Oeffnen wird nur gebaut. Mit -Oeffnen wird das Ergebnis danach gestartet.'
  Write-Host 'Linux und macOS baut tool/bauen.sh.'
  Write-Host 'Anleitung: docs/BAUEN-UND-STARTEN.md'
  Write-Host ''
}

function Stop-Mit {
  param([string]$Text, [int]$Code = 1)
  Write-Host ''
  Write-Host ('FEHLER: ' + $Text) -ForegroundColor Red
  exit $Code
}

function Write-Schritt {
  param([string]$Text)
  Write-Host ''
  Write-Host ('==> ' + $Text) -ForegroundColor Cyan
}

# Startet ein Programm und bricht bei einem Fehlercode ab. Fehlerausgaben des Programms
# bleiben Text und loesen in Windows PowerShell 5.1 keinen Skriptfehler aus.
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
    Stop-Mit ($Beschreibung + ' ist fehlgeschlagen (Exit-Code ' + $code + '). Die Meldung steht oben. Hilfe: docs/BAUEN-UND-STARTEN.md, Abschnitt "Wenn etwas schiefgeht".') 1
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
  Stop-Mit ('Kein freier Port zwischen ' + $Start + ' und ' + ($Start + 49) + ' gefunden. Mit -Port eine andere Startzahl waehlen.') 1
}

if ($Hilfe -or [string]::IsNullOrWhiteSpace($Ziel)) {
  Show-Hilfe
  if ($Hilfe) { exit 0 }
  Stop-Mit 'Es fehlt das Ziel. Beispiel: powershell -File tool\bauen.ps1 -Ziel windows' 2
}

$Ziel = $Ziel.Trim().ToLowerInvariant()
if ($nurBash -contains $Ziel) {
  Stop-Mit ('Das Ziel "' + $Ziel + '" baut dieses Skript nicht. Nimm tool/bauen.sh auf einem Linux- bzw. Mac-Rechner.') 2
}
if ($gueltigeZiele -notcontains $Ziel) {
  Show-Hilfe
  Stop-Mit ('Unbekanntes Ziel "' + $Ziel + '". Erlaubt: ' + ($gueltigeZiele -join ', ') + '.') 2
}

$repo = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repo 'pubspec.yaml'))) {
  Stop-Mit ('pubspec.yaml nicht gefunden unter ' + $repo + '. Das Skript muss im Ordner tool des Projekts liegen.') 1
}
Set-Location $repo

# Voraussetzungen
Write-Schritt 'Voraussetzungen pruefen'
if ($repo.Length -gt 40) {
  Write-Host ('Hinweis: Der Projektpfad ist lang (' + $repo.Length + ' Zeichen). Windows bricht bei Pfaden ueber 260 Zeichen ab. Bei Fehlern das Projekt in einen kurzen Ordner wie C:\linefm legen.') -ForegroundColor Yellow
}
if (-not (Test-Programm 'flutter')) {
  Stop-Mit 'Flutter wurde nicht gefunden. Installiere Flutter 3.50.0 (https://docs.flutter.dev/get-started/install/windows), fuege den Ordner flutter\bin zum PATH hinzu und oeffne danach ein neues PowerShell-Fenster.' 1
}
if (-not (Test-Programm 'git')) {
  Write-Host 'Hinweis: Git wurde nicht gefunden. Flutter braucht Git (https://git-scm.com/download/win).' -ForegroundColor Yellow
}
if ($Ziel -eq 'windows') {
  if (-not (Test-Programm 'cargo')) {
    Stop-Mit 'Rust wurde nicht gefunden. Der Windows-Build braucht es (Mediensteuerung). Installiere es mit rustup von https://rustup.rs und oeffne danach ein neues PowerShell-Fenster.' 1
  }
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (Test-Path $vswhere) {
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) {
      Stop-Mit 'Visual Studio ist da, aber ohne C++-Werkzeuge. Oeffne den Visual Studio Installer, waehle "Aendern" und hake "Desktopentwicklung mit C++" an.' 1
    }
  } else {
    Write-Host 'Hinweis: Visual Studio wurde nicht gefunden. Der Windows-Build braucht Visual Studio (Build Tools) mit "Desktopentwicklung mit C++". Pruefe mit: flutter doctor' -ForegroundColor Yellow
  }
}
if (($Ziel -eq 'apk') -or ($Ziel -eq 'aab')) {
  if (-not ($env:JAVA_HOME -or (Test-Programm 'java'))) {
    Write-Host 'Hinweis: Java (JDK 17) wurde nicht gefunden. Der Android-Build braucht es. Pruefe mit: flutter doctor' -ForegroundColor Yellow
  }
}
if ($Ziel -eq 'web' -and $Oeffnen) {
  $python = $null
  foreach ($kandidat in @('python', 'py')) {
    if (Test-Programm $kandidat) { $python = $kandidat; break }
  }
  if (-not $python) {
    Stop-Mit 'Python wurde nicht gefunden. Es startet den lokalen Web-Server (-Oeffnen). Installiere Python von https://www.python.org/downloads/ (Haken "Add python.exe to PATH" setzen) oder baue ohne -Oeffnen.' 1
  }
}

$defineArgs = @()
if (Test-Path (Join-Path $repo 'config\app.json')) {
  Write-Host 'config\app.json gefunden, wird beim Bauen verwendet.'
  $defineArgs = @('--dart-define-from-file=config/app.json')
} else {
  Write-Host 'Keine config\app.json, die App baut mit Standardwerten.'
}

$webPort = $Port
if ($Ziel -eq 'web') { $webPort = Get-FreierPort $Port }

Write-Schritt 'Pakete holen (flutter pub get)'
Invoke-Programm 'flutter' @('pub', 'get') 'flutter pub get'

$ergebnis = $null
$sw = [System.Diagnostics.Stopwatch]::StartNew()

switch ($Ziel) {
  'windows' {
    Write-Schritt 'Windows bauen (dauert beim ersten Mal rund 5 bis 10 Minuten)'
    Invoke-Programm 'flutter' (@('build', 'windows', '--release') + $defineArgs) 'flutter build windows'
    $ergebnis = Join-Path $repo 'build\windows\x64\runner\Release\linefm_radio.exe'
  }
  'apk' {
    Write-Schritt 'Android-APK bauen'
    Invoke-Programm 'flutter' (@('build', 'apk', '--release') + $defineArgs) 'flutter build apk'
    $ergebnis = Join-Path $repo 'build\app\outputs\flutter-apk\app-release.apk'
  }
  'aab' {
    Write-Schritt 'Android App Bundle bauen'
    Invoke-Programm 'flutter' (@('build', 'appbundle', '--release') + $defineArgs) 'flutter build appbundle'
    $ergebnis = Join-Path $repo 'build\app\outputs\bundle\release\app-release.aab'
  }
  'web' {
    Write-Schritt 'Web bauen'
    Invoke-Programm 'flutter' (@('build', 'web', '--release', '--wasm', '--no-web-resources-cdn') + $defineArgs) 'flutter build web'

    # Wie in der CI: die Werkzeuge ausserhalb des Pakets starten, sonst baut "dart run"
    # zusaetzlich die Native-Asset-Hooks des Projekts.
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('linefm-bauen-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
      Copy-Item (Join-Path $repo 'tool\fetch_font_fallback.dart') $tmp
      Copy-Item (Join-Path $repo 'tool\web_postbuild.dart') $tmp
      Write-Schritt 'Ersatzschriften holen (braucht Internet)'
      Invoke-Programm 'dart' @('run', (Join-Path $tmp 'fetch_font_fallback.dart'), 'build/web') 'Ersatzschriften holen'
      Write-Schritt 'Nachbearbeitung der Web-Dateien'
      Invoke-Programm 'dart' @('run', (Join-Path $tmp 'web_postbuild.dart'), 'build/web', '--targets', 'none', '--base-url', ('http://localhost:' + $webPort)) 'Nachbearbeitung (web_postbuild)'
    } finally {
      Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
    $ergebnis = Join-Path $repo 'build\web\index.html'
  }
}

if (-not (Test-Path $ergebnis)) {
  Stop-Mit ('Der Bau meldete Erfolg, aber die erwartete Datei fehlt: ' + $ergebnis) 1
}

$sw.Stop()
Write-Host ''
Write-Host ('FERTIG nach ' + [int]$sw.Elapsed.TotalSeconds + ' Sekunden.') -ForegroundColor Green
Write-Host ('Ergebnis: ' + $ergebnis)

if (-not $Oeffnen) {
  switch ($Ziel) {
    'windows' { Write-Host 'Starten: Doppelklick auf die Datei. Der ganze Ordner "Release" gehoert zusammen.' }
    'web'     { Write-Host ('Ansehen: erneut mit -Oeffnen starten oder: python -m http.server ' + $webPort + ' --directory build/web') }
    'apk'     { Write-Host 'Die APK aufs Handy kopieren und dort oeffnen.' }
    'aab'     { Write-Host 'Das App Bundle ist nur fuer den Play Store gedacht, nicht zum Installieren.' }
  }
  exit 0
}

Write-Schritt 'Ergebnis oeffnen'
switch ($Ziel) {
  'windows' {
    Start-Process -FilePath $ergebnis -WorkingDirectory (Split-Path -Parent $ergebnis)
    Write-Host 'Die App wurde gestartet.'
  }
  'apk' {
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + (Split-Path -Parent $ergebnis) + '"')
  }
  'aab' {
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + (Split-Path -Parent $ergebnis) + '"')
  }
  'web' {
    $adresse = 'http://localhost:' + $webPort
    Write-Host ('Server laeuft auf ' + $adresse + ' . Zum Beenden Strg+C druecken oder das Fenster schliessen.')
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
