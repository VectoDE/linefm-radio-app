<#
.SYNOPSIS
  Baut den Windows-Installer von LINEFM Radio (setup.exe mit eigener Oberflaeche).

.DESCRIPTION
  Zwei Stufen, damit die CI dazwischen signieren kann:

    -Stage prepare  Engine (setup_stub.exe, lfpack.exe) mit CMake/MSVC und die
                    Setup-Oberflaeche (Flutter, installer/ui) bauen.
    -Stage pack     App-Ordner, Oberflaeche, Lizenzen und Produktdaten an den
                    Stub haengen: setup.exe.
    -Stage all      beides (lokal, ohne Signatur).

  Voraussetzungen: Visual Studio 2022 mit "Desktopentwicklung mit C++",
  CMake (in VS enthalten), Flutter. Die App selbst vorher bauen:
  flutter build windows --release

.EXAMPLE
  pwsh installer/windows/build.ps1 -Version X.Y.Z -Out dist/linefm-radio-X.Y.Z-windows-x64-setup.exe
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Version,
  [ValidateSet('prepare', 'pack', 'all')][string]$Stage = 'all',
  [string]$AppDir = 'build/windows/x64/runner/Release',
  [string]$Out = 'dist/linefm-radio-setup.exe',
  [string]$WorkDir = 'build/installer'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location $repo
try {
  if ($Version -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$') {
    throw "Ungueltige Version '$Version' (expected SemVer x.y.z[-pre][+build])"
  }
  $numeric = ($Version -split '[-+]')[0]
  $engineBuild = Join-Path $WorkDir 'engine'
  $uiProject = 'installer/ui'
  $uiRelease = Join-Path $uiProject 'build/windows/x64/runner/Release'

  if ($Stage -in 'prepare', 'all') {
    Write-Host "== Engine bauen ($numeric)"
    & cmake -S installer/windows/engine -B $engineBuild -A x64 "-DLF_VERSION=$numeric"
    if ($LASTEXITCODE -ne 0) { throw 'cmake configure fehlgeschlagen' }
    & cmake --build $engineBuild --config Release --parallel
    if ($LASTEXITCODE -ne 0) { throw 'cmake build fehlgeschlagen' }

    Write-Host '== Setup-Oberflaeche bauen'
    Push-Location $uiProject
    try {
      & flutter pub get
      if ($LASTEXITCODE -ne 0) { throw 'flutter pub get (Oberflaeche) fehlgeschlagen' }
      & flutter build windows --release --build-name $numeric
      if ($LASTEXITCODE -ne 0) { throw 'flutter build windows (Oberflaeche) fehlgeschlagen' }
    } finally {
      Pop-Location
    }
  }

  if ($Stage -in 'pack', 'all') {
    $stub = Join-Path $engineBuild 'Release/setup_stub.exe'
    $packer = Join-Path $engineBuild 'Release/lfpack.exe'
    foreach ($p in @($stub, $packer, (Join-Path $uiRelease 'linefm_setup.exe'), (Join-Path $AppDir 'linefm_radio.exe'))) {
      if (-not (Test-Path $p)) { throw "Fehlt: $p (zuerst -Stage prepare bzw. die App bauen)" }
    }
    $outDir = Split-Path -Parent $Out
    if ($outDir) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    Write-Host "== setup.exe packen ($Version)"
    & $packer --stub $stub --uninstaller $stub `
      --app (Resolve-Path $AppDir).Path `
      --ui (Resolve-Path $uiRelease).Path `
      --ui-file "LICENSE.txt=$((Resolve-Path 'LICENSE').Path)" `
      --ui-file "licenses/OFL-Poppins.txt=$((Resolve-Path 'assets/fonts/OFL.txt').Path)" `
      --ui-file "licenses/Apache-2.0-Syncopate.txt=$((Resolve-Path 'assets/fonts/LICENSE-Syncopate-Apache2.txt').Path)" `
      --ui-file "licenses/LGPL-3.0.txt=$((Resolve-Path 'assets/licenses/LGPL-3.0.txt').Path)" `
      --ui-file "licenses/GPL-3.0.txt=$((Resolve-Path 'assets/licenses/GPL-3.0.txt').Path)" `
      --ui-file "licenses/NATIVE-LIBRARIES.txt=$((Resolve-Path 'assets/licenses/NATIVE-LIBRARIES.txt').Path)" `
      --product (Resolve-Path 'packaging/windows/installer.ini').Path `
      --version $Version `
      --out $Out
    if ($LASTEXITCODE -ne 0) { throw 'lfpack fehlgeschlagen' }
    Get-Item $Out | Select-Object Name, Length
  }
} finally {
  Pop-Location
}
