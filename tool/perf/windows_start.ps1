<#
  Windows measurement: startup, memory, CPU, audio start, package size.

  Prerequisite: release build with measurement points
    flutter build windows --release --dart-define-from-file=config/app.json `
      --dart-define=LINEFM_PERF_MARKS=true
  Usage:
    pwsh tool/perf/windows_start.ps1 -Exe build/windows/x64/runner/Release/linefm_radio.exe `
      -OutDir tool/perf/out -Runs 5 [-Audio]

  Measurement per run (after one warm-up run that is not counted):
    - Process start (creation time per the operating system) until the window
      exists and until the window is visible. The window is only shown with
      the first Flutter frame (windows/runner/flutter_window.cpp,
      SetNextFrameCallback -> Show), so "visible" means "first frame".
    - Dart measurement points from LINEFM_PERF_FILE (lib/core/perf/perf_marks.dart):
      main, audio-ready, desktop-ready, prefs-ready, telemetry-ready,
      run-app, first-frame (all relative to process start).
    - 30 s after visibility: working set, private bytes, CPU over 10 s
      (percent of ONE core). Autoplay is turned off in the settings for this,
      so the app plays nothing ("idle").
    - With -Audio: second program start with linefm://play?station=<slug>
      (single-instance forwarding, like a click from the Start menu/link).
      Time from play-request to player-connecting/-playing (Dart state,
      on the runner without a sound card; the "playing" display appears at the
      earliest 1 s after the start, minConnectDuration in audio_handler.dart).
      Afterwards CPU/memory during playback and a station switch.
  Result: <OutDir>/windows-perf.json
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [string]$OutDir = 'tool/perf/out',
  [int]$Runs = 5,
  [switch]$Audio
)

$ErrorActionPreference = 'Stop'
$Exe = (Resolve-Path $Exe).Path
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class LfWin {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  // 0 = no window, 1 = window exists (invisible), 2 = visible
  public static int State(int pid) {
    int state = 0;
    EnumWindows((h, l) => {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p != (uint)pid) return true;
      var sb = new StringBuilder(256); GetClassName(h, sb, 256);
      if (sb.ToString() != "FLUTTER_RUNNER_WIN32_WINDOW") return true;
      state = Math.Max(state, IsWindowVisible(h) ? 2 : 1);
      return true;
    }, IntPtr.Zero);
    return state;
  }
}
'@

function NowMicros { [long](([DateTime]::UtcNow - [DateTime]::UnixEpoch).Ticks / 10) }
function ToMicros([DateTime]$t) { [long](($t.ToUniversalTime() - [DateTime]::UnixEpoch).Ticks / 10) }

function Read-Marks([string]$file) {
  $marks = [ordered]@{}
  if (Test-Path $file) {
    foreach ($line in Get-Content $file) {
      $parts = $line -split "`t"
      if ($parts.Count -eq 2 -and -not $marks.Contains($parts[0])) { $marks[$parts[0]] = [long]$parts[1] }
    }
  }
  return $marks
}

function Wait-Mark([string]$file, [string]$prefix, [long]$afterMicros, [int]$timeoutMs) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.ElapsedMilliseconds -lt $timeoutMs) {
    if (Test-Path $file) {
      foreach ($line in Get-Content $file) {
        $parts = $line -split "`t"
        if ($parts.Count -eq 2 -and $parts[0].StartsWith($prefix) -and [long]$parts[1] -ge $afterMicros) {
          return @{ name = $parts[0]; t = [long]$parts[1] }
        }
      }
    }
    Start-Sleep -Milliseconds 20
  }
  return $null
}

function Cpu-Sample([Diagnostics.Process]$p, [int]$seconds) {
  $p.Refresh(); $c1 = $p.TotalProcessorTime; $w = [Diagnostics.Stopwatch]::StartNew()
  Start-Sleep -Seconds $seconds
  $p.Refresh(); $c2 = $p.TotalProcessorTime
  return [math]::Round(($c2 - $c1).TotalMilliseconds / $w.ElapsedMilliseconds * 100, 2)
}

# Settings up front: storage notice confirmed, autoplay off (idle measurable).
# Path of shared_preferences on Windows: %APPDATA%\<CompanyName>\<ProductName>
# (windows/runner/Runner.rc: LineFM Studios / LINEFM Radio; the app migrates the old de.linefm folder).
$prefsDir = Join-Path $env:APPDATA 'LineFM Studios\LINEFM Radio'
New-Item -ItemType Directory -Force -Path $prefsDir | Out-Null
$prefsFile = Join-Path $prefsDir 'shared_preferences.json'
function Write-Prefs {
  '{"flutter.linefm-storage-notice-dismissed":true,"flutter.linefm-setting-autoplay":false}' |
    Set-Content -Path $prefsFile -Encoding utf8NoBOM
}

$perfFile = Join-Path $OutDir 'perf-marks.tsv'
$results = @()
$total = $Runs + 1
for ($i = 0; $i -lt $total; $i++) {
  Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($Exe)) -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Seconds 2
  Write-Prefs
  Remove-Item $perfFile -ErrorAction SilentlyContinue
  $env:LINEFM_PERF_FILE = $perfFile
  $p = Start-Process -FilePath $Exe -PassThru -WorkingDirectory (Split-Path $Exe)
  $start = ToMicros $p.StartTime
  $tWindow = $null; $tVisible = $null
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.ElapsedMilliseconds -lt 90000 -and -not $tVisible) {
    $s = [LfWin]::State($p.Id)
    $now = NowMicros
    if ($s -ge 1 -and -not $tWindow) { $tWindow = $now }
    if ($s -eq 2) { $tVisible = $now }
    if ($p.HasExited) { break }
    Start-Sleep -Milliseconds 5
  }
  $null = Wait-Mark $perfFile 'first-frame' 0 15000
  $r = [ordered]@{
    run = $i; warmup = ($i -eq 0)
    windowCreatedMs = if ($tWindow) { ($tWindow - $start) / 1000 } else { $null }
    windowVisibleMs = if ($tVisible) { ($tVisible - $start) / 1000 } else { $null }
    exited = $p.HasExited
  }
  $marks = Read-Marks $perfFile
  $r.marksMs = [ordered]@{}
  foreach ($k in $marks.Keys) { $r.marksMs[$k] = ($marks[$k] - $start) / 1000 }
  $r.autoplayDuringIdle = [bool]($marks.Keys | Where-Object { $_ -like 'player-connecting*' })

  if (-not $p.HasExited -and $i -gt 0) {
    Start-Sleep -Seconds 30
    $p.Refresh()
    $r.idleWorkingSetMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
    $r.idlePrivateMB = [math]::Round($p.PrivateMemorySize64 / 1MB, 1)
    $r.idleCpuPct = Cpu-Sample $p 10

    if ($Audio) {
      $r.audio = @()
      foreach ($slug in @('linefmrap', 'linefmlofi')) {
        $t0 = NowMicros
        Start-Process -FilePath $Exe -ArgumentList "linefm://play?station=$slug" -WorkingDirectory (Split-Path $Exe) | Out-Null
        $req = Wait-Mark $perfFile "play-request:$slug" $t0 10000
        $con = Wait-Mark $perfFile "player-connecting:$slug" $t0 10000
        $url = Wait-Mark $perfFile 'stream-url' $t0 10000
        $end = $null
        $sw2 = [Diagnostics.Stopwatch]::StartNew()
        while ($sw2.ElapsedMilliseconds -lt 30000 -and -not $end) {
          $end = (Wait-Mark $perfFile "player-playing:$slug" $t0 200)
          if (-not $end) { $end = Wait-Mark $perfFile 'player-error' $t0 50 }
        }
        $base = if ($req) { $req.t } else { $t0 }
        $a = [ordered]@{
          station = $slug
          launchToRequestMs = if ($req) { ($req.t - $t0) / 1000 } else { $null }
          requestToConnectingMs = if ($con) { ($con.t - $base) / 1000 } else { $null }
          streamUrl = if ($url) { $url.name } else { $null }
          streamUrlMs = if ($url) { ($url.t - $base) / 1000 } else { $null }
          endState = if ($end) { $end.name } else { 'timeout' }
          requestToEndMs = if ($end) { ($end.t - $base) / 1000 } else { $null }
        }
        if ($end -and $end.name -like 'player-playing*') {
          Start-Sleep -Seconds 3
          $p.Refresh()
          $a.playingWorkingSetMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
          $a.playingCpuPct = Cpu-Sample $p 10
        }
        $r.audio += $a
      }
    }
  }
  $results += $r
  Write-Host ("Run {0}{1}: window visible {2} ms, first frame (Dart) {3} ms" -f $i, $(if ($i -eq 0) { ' (warm-up)' } else { '' }), $r.windowVisibleMs, $r.marksMs['first-frame'])
  if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
}
Remove-Item Env:\LINEFM_PERF_FILE -ErrorAction SilentlyContinue

# Package size: release folder and ZIP (as in build.yml).
$rel = Split-Path $Exe
$files = Get-ChildItem $rel -Recurse -File
$zip = Join-Path $env:RUNNER_TEMP 'perf-release.zip'
if (-not $env:RUNNER_TEMP) { $zip = Join-Path ([IO.Path]::GetTempPath()) 'perf-release.zip' }
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $rel '*') -DestinationPath $zip
$largest = $files | Sort-Object Length -Descending | Select-Object -First 10 |
  ForEach-Object { [ordered]@{ path = $_.FullName.Substring($rel.Length + 1); bytes = $_.Length } }

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$report = [ordered]@{
  tool = 'tool/perf/windows_start.ps1'
  environment = [ordered]@{
    commit = $env:GITHUB_SHA
    runUrl = if ($env:GITHUB_RUN_ID) { "$env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID" } else { $null }
    runner = [ordered]@{ name = $env:RUNNER_NAME; os = $env:RUNNER_OS; image = $env:ImageOS; imageVersion = $env:ImageVersion }
    cpu = [ordered]@{ model = $cpu.Name; cores = $cpu.NumberOfLogicalProcessors }
    memGiB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    os = [Environment]::OSVersion.VersionString
    at = (Get-Date).ToUniversalTime().ToString('o')
  }
  runs = $Runs
  audio = [bool]$Audio
  package = [ordered]@{
    releaseBytes = ($files | Measure-Object Length -Sum).Sum
    releaseFiles = $files.Count
    zipBytes = (Get-Item $zip).Length
    largest = $largest
  }
  results = $results
}
$report | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutDir 'windows-perf.json') -Encoding utf8NoBOM
Write-Host "windows-perf: $(Join-Path $OutDir 'windows-perf.json')"
