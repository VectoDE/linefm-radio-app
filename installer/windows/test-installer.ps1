<#
.SYNOPSIS
  Prueft den Windows-Installer auf einem echten Windows (CI-Runner):
  Installation, Start der App, Update mit laufender App und Erhalt der
  Einstellungen, Downgrade-Sperre, Oberflaeche, Deinstallation (mit und
  ohne Nutzerdaten), Installation fuer alle Benutzer.

.DESCRIPTION
  Veraendert das System (Registry HKCU/HKLM, Programme-Ordner). Nur auf
  Wegwerf-Maschinen wie GitHub-Runnern ausfuehren. "Alle Benutzer" braucht
  Administratorrechte (auf GitHub-Runnern vorhanden).

  Bildschirmfotos und Protokolle landen in -ArtifactDir.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Setup,
  [Parameter(Mandatory = $true)][string]$OldSetup,
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$ArtifactDir = 'build/installer-test'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Setup = (Resolve-Path $Setup).Path
$OldSetup = (Resolve-Path $OldSetup).Path
New-Item -ItemType Directory -Force -Path $ArtifactDir | Out-Null
$ArtifactDir = (Resolve-Path $ArtifactDir).Path
$shots = Join-Path $ArtifactDir 'screenshots'
$logs = Join-Path $ArtifactDir 'logs'
New-Item -ItemType Directory -Force -Path $shots, $logs | Out-Null

$appId = '{6F3B1E52-8C4A-4D7E-9A21-5B0C7D3E91F4}'
$exeName = 'linefm_radio.exe'
$product = 'LINEFM Radio'
$userKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$appId"
$machineKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$appId"
$userDir = Join-Path $env:LOCALAPPDATA "Programs\$product"
$machineDir = Join-Path $env:ProgramFiles $product

$results = [System.Collections.Generic.List[object]]::new()
$failed = 0

function Check([string]$name, [bool]$ok, [string]$detail = '') {
  $script:results.Add([pscustomobject]@{ Test = $name; Ok = $ok; Detail = $detail })
  if ($ok) {
    Write-Host "OK    $name $detail"
  } else {
    Write-Host "::error::FEHLER $name $detail"
    $script:failed++
  }
}

function Run([string]$exe, [string[]]$arguments, [string]$log) {
  $all = @($arguments) + @("/LOG=`"$(Join-Path $logs $log)`"")
  $p = Start-Process -FilePath $exe -ArgumentList $all -Wait -PassThru -WindowStyle Hidden
  return $p.ExitCode
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
function Shot([string]$name) {
  try {
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $path = Join-Path $shots "$name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "Bildschirmfoto: $path"
  } catch {
    Write-Host "::warning::Bildschirmfoto $name nicht moeglich: $($_.Exception.Message)"
  }
}

function DataDir([string]$exe) {
  # Wie path_provider_windows: %APPDATA%\CompanyName\ProductName der EXE.
  $info = (Get-Item $exe).VersionInfo
  return Join-Path $env:APPDATA (Join-Path $info.CompanyName $info.ProductName)
}

function RegValue([string]$key, [string]$name) {
  try { return (Get-ItemProperty -Path $key -Name $name -ErrorAction Stop).$name } catch { return $null }
}

function Get-AppProcess { Get-Process -Name 'linefm_radio' -ErrorAction SilentlyContinue }

# --- 1. Parameter und Integritaet ------------------------------------------
Check 'Unbekannter Parameter -> Exit 1' ((Run $Setup @('/S', '/GIBTESNICHT') 'badargs.log') -eq 1)

$corrupt = Join-Path $env:RUNNER_TEMP 'setup-corrupt.exe'
if (-not $env:RUNNER_TEMP) { $corrupt = Join-Path $env:TEMP 'setup-corrupt.exe' }
$bytes = [System.IO.File]::ReadAllBytes($Setup)
$bytes[[int]($bytes.Length * 0.6)] = $bytes[[int]($bytes.Length * 0.6)] -bxor 0xFF
[System.IO.File]::WriteAllBytes($corrupt, $bytes)
$code = Run $corrupt @('/S') 'corrupt.log'
Check 'Manipulierte Nutzlast -> Exit 4 (Hash-Pruefung)' ($code -eq 4) "Exit $code"
Check 'Manipulierte Nutzlast installiert nichts' (-not (Test-Path $userKey))
Remove-Item $corrupt -Force

# --- 2. Erstinstallation (alte Version, nur fuer mich) ----------------------
$code = Run $OldSetup @('/S') 'install-old.log'
Check 'Installation 0.0.1 still, pro Benutzer -> Exit 0' ($code -eq 0) "Exit $code"
$exe = Join-Path $userDir $exeName
Check 'Programmdatei vorhanden' (Test-Path $exe) $exe
Check 'uninstall.exe vorhanden' (Test-Path (Join-Path $userDir 'uninstall.exe'))
Check 'Kein Admin-Eintrag (HKLM)' (-not (Test-Path $machineKey))
Check 'Apps & Features: Version' ((RegValue $userKey 'DisplayVersion') -eq '0.0.1')
Check 'Apps & Features: Herausgeber LineFM Studios' ((RegValue $userKey 'Publisher') -eq 'LineFM Studios')
$uninstallString = RegValue $userKey 'UninstallString'
Check 'UninstallString in Anfuehrungszeichen' ($uninstallString -like '"*uninstall.exe"') $uninstallString
Check 'QuietUninstallString /S' ((RegValue $userKey 'QuietUninstallString') -like '"*uninstall.exe" /S')
$command = RegValue 'HKCU:\Software\Classes\linefm\shell\open\command' '(default)'
Check 'Link-Schema linefm:// registriert' ($command -eq "`"$exe`" `"%1`"") $command
Check 'URL Protocol gesetzt' ($null -ne (RegValue 'HKCU:\Software\Classes\linefm' 'URL Protocol'))
Check 'App Paths' ((RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$exeName" '(default)') -eq $exe)
$startLnk = Join-Path ([Environment]::GetFolderPath('Programs')) "$product.lnk"
$deskLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) "$product.lnk"
Check 'Startmenue-Verknuepfung' (Test-Path $startLnk)
Check 'Desktop-Verknuepfung' (Test-Path $deskLnk)
Check 'Kein Autostart (Standard)' ($null -eq (RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' $product))

# Einstellungen simulieren (Datei im Datenordner der App).
$dataDir = DataDir $exe
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$marker = Join-Path $dataDir 'installer-test-marker.json'
'{"favorites":["main"]}' | Set-Content -Path $marker -Encoding utf8
Write-Host "Datenordner der App: $dataDir"

# --- 3. Start der App --------------------------------------------------------
$app = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 15
$alive = -not $app.HasExited
Check 'App startet und laeuft nach 15 s' ($alive -or $app.ExitCode -eq 0) ($(if ($alive) { 'laeuft' } else { "beendet mit $($app.ExitCode)" }))
Shot '10-app-gestartet'

# --- 4. Update mit laufender App --------------------------------------------
$code = Run $Setup @('/S') 'update.log'
Check "Update auf $Version (App lief) -> Exit 0" ($code -eq 0) "Exit $code"
Check 'Update: neue Version eingetragen' ((RegValue $userKey 'DisplayVersion') -eq $Version) (RegValue $userKey 'DisplayVersion')
Check 'Update: laufende App wurde beendet' ($null -eq (Get-AppProcess))
Check 'Update: Einstellungen erhalten' (Test-Path $marker)
Check 'Update: gleicher Ordner' ((RegValue $userKey 'InstallLocation') -eq $userDir)
Check 'Update: Verknuepfungen bleiben' ((Test-Path $startLnk) -and (Test-Path $deskLnk))
Check 'Update: keine Sicherungsdateien uebrig' (@(Get-ChildItem $userDir -Recurse -Filter '*.lf*' -ErrorAction SilentlyContinue).Count -eq 0)

# --- 5. Downgrade-Sperre -----------------------------------------------------
$code = Run $OldSetup @('/S') 'downgrade.log'
Check 'Downgrade ohne /ALLOWDOWNGRADE -> Exit 6' ($code -eq 6) "Exit $code"
Check 'Downgrade aendert nichts' ((RegValue $userKey 'DisplayVersion') -eq $Version)

# --- 6. Anderer Bereich gesperrt --------------------------------------------
$code = Run $Setup @('/S', '/ALLUSERS') 'otherscope.log'
Check 'Alle Benutzer bei vorhandener Benutzer-Installation -> Exit 12' ($code -eq 12) "Exit $code"

# --- 7. Oberflaeche ----------------------------------------------------------
$gui = Start-Process -FilePath $Setup -PassThru
$window = $null
for ($i = 0; $i -lt 60 -and -not $window; $i++) {
  Start-Sleep -Milliseconds 500
  $window = Get-Process -Name 'linefm_setup' -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}
Check 'Oberflaeche oeffnet ein Fenster' ($null -ne $window) ($(if ($window) { $window.MainWindowTitle } else { 'kein Fenster' }))
Start-Sleep -Seconds 2
Shot '20-setup-willkommen'

$guiExit = $null
if ($window) {
  try {
    Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($window.MainWindowHandle)
    function FindButton([string[]]$names) {
      for ($t = 0; $t -lt 20; $t++) {
        foreach ($n in $names) {
          $cond = New-Object System.Windows.Automation.AndCondition(
            (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $n)),
            (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
          $el = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
          if ($el) { return $el }
        }
        Start-Sleep -Milliseconds 500
      }
      return $null
    }
    function Invoke-El($el) {
      $el.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
    }
    $next = FindButton @('Next', 'Weiter')
    Check 'Screenreader/UIA: Knopf "Weiter" auffindbar' ($null -ne $next)
    if ($next) {
      Invoke-El $next
      Start-Sleep -Seconds 2
      Shot '21-setup-lizenz'
    }
    $cancel = FindButton @('Cancel', 'Abbrechen')
    if ($cancel) {
      Invoke-El $cancel
      Start-Sleep -Seconds 1
      Shot '22-setup-abbrechen-frage'
      $yes = FindButton @('Yes, cancel', 'Ja, abbrechen')
      if ($yes) { Invoke-El $yes }
    }
    if ($gui.WaitForExit(20000)) { $guiExit = $gui.ExitCode }
  } catch {
    Write-Host "::warning::UI-Automation: $($_.Exception.Message)"
  }
}
Check 'Oberflaeche: Abbrechen beendet mit Exit 2' ($guiExit -eq 2) "Exit $guiExit"
if (-not $gui.HasExited) {
  Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue
  Get-Process -Name 'linefm_setup' -ErrorAction SilentlyContinue | Stop-Process -Force
}
Check 'Abbruch in der Oberflaeche aendert nichts' ((RegValue $userKey 'DisplayVersion') -eq $Version)

# --- 8. Deinstallation, Daten bleiben ---------------------------------------
$uninstaller = Join-Path $userDir 'uninstall.exe'
$code = Run $uninstaller @('/S') 'uninstall.log'
Check 'Deinstallation still -> Exit 0' ($code -eq 0) "Exit $code"
Start-Sleep -Seconds 2
Check 'Deinstallation: Ordner entfernt' (-not (Test-Path $userDir)) $userDir
Check 'Deinstallation: Apps-&-Features-Eintrag entfernt' (-not (Test-Path $userKey))
Check 'Deinstallation: Link-Schema entfernt' (-not (Test-Path 'HKCU:\Software\Classes\linefm'))
Check 'Deinstallation: App Paths entfernt' (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$exeName"))
Check 'Deinstallation: Verknuepfungen entfernt' (-not (Test-Path $startLnk) -and -not (Test-Path $deskLnk))
Check 'Deinstallation ohne Wunsch: Einstellungen bleiben' (Test-Path $marker)

# --- 9. Neu installieren, Deinstallation mit Nutzerdaten --------------------
$code = Run $Setup @('/S', '/DESKTOPSHORTCUT=0', '/AUTOSTART=1') 'reinstall.log'
Check 'Neuinstallation mit Optionen -> Exit 0' ($code -eq 0) "Exit $code"
Check 'Option: keine Desktop-Verknuepfung' (-not (Test-Path $deskLnk))
Check 'Option: Autostart eingetragen' ((RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' $product) -eq "`"$exe`"")
$code = Run $uninstaller @('/S', '/DELETEUSERDATA') 'uninstall-data.log'
Check 'Deinstallation /DELETEUSERDATA -> Exit 0' ($code -eq 0) "Exit $code"
Start-Sleep -Seconds 2
Check 'Nutzerdaten geloescht' (-not (Test-Path $marker))
Check 'Autostart entfernt' ($null -eq (RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' $product))

# --- 10. Alle Benutzer (Admin) ----------------------------------------------
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($admin) {
  $code = Run $Setup @('/S', '/ALLUSERS') 'install-machine.log'
  Check 'Installation fuer alle Benutzer -> Exit 0' ($code -eq 0) "Exit $code"
  Check 'Alle Benutzer: Program Files' (Test-Path (Join-Path $machineDir $exeName))
  Check 'Alle Benutzer: HKLM-Eintrag' ((RegValue $machineKey 'DisplayVersion') -eq $Version)
  Check 'Alle Benutzer: Link-Schema in HKLM' (Test-Path 'HKLM:\Software\Classes\linefm\shell\open\command')
  $code = Run (Join-Path $machineDir 'uninstall.exe') @('/S') 'uninstall-machine.log'
  Check 'Alle Benutzer: Deinstallation -> Exit 0' ($code -eq 0) "Exit $code"
  Start-Sleep -Seconds 2
  Check 'Alle Benutzer: Ordner und Eintrag entfernt' (-not (Test-Path $machineDir) -and -not (Test-Path $machineKey))
} else {
  Write-Host '::warning::Keine Administratorrechte, Test "alle Benutzer" uebersprungen'
}

# --- Bericht -----------------------------------------------------------------
$report = Join-Path $ArtifactDir 'bericht.md'
$lines = @('# Installer-Test', '', "setup.exe: $Version", '', '| Test | Ergebnis | Detail |', '|---|---|---|')
foreach ($r in $results) {
  $lines += "| $($r.Test) | $(if ($r.Ok) { 'OK' } else { 'FEHLER' }) | $($r.Detail -replace '\|', '/') |"
}
$lines | Set-Content -Path $report -Encoding utf8
if ($env:GITHUB_STEP_SUMMARY) {
  "### Windows-Installer: $($results.Count - $failed) von $($results.Count) Pruefungen OK" | Out-File -Append -FilePath $env:GITHUB_STEP_SUMMARY -Encoding utf8
}
Write-Host "$($results.Count - $failed) von $($results.Count) Pruefungen OK"
if ($failed -gt 0) { exit 1 }
