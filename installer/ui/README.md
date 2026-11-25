# linefm_setup

Setup-Oberfläche (Installer und Deinstaller) von LINEFM Radio für Windows. Wird nicht allein ausgeliefert, sondern vom Setup-Stub aus `setup.exe` entpackt und mit `--context <context.json>` gestartet. Shared by all desktop installers (Windows engine: [../windows/README.md](../windows/README.md)). Aufbau, Protokoll und Sicherheit: [../windows/README.md](../windows/README.md).

```powershell
flutter pub get
flutter analyze --fatal-infos
flutter test                 # schreibt Bildschirmfotos nach build/screenshots
flutter build windows --release
```

- `lib/src/controller.dart`: Ablauf und Zustand, ohne Widgets testbar.
- `lib/src/engine.dart`: Pipe-Protokoll und MethodChannel `linefm_setup/native`.
- `windows/runner/engine_bridge.cpp`: Named-Pipe-Server, Engine-Start (UAC nur bei "Alle Benutzer"), Ordnerauswahl, App-Start.
- Farben und Schriften wie die App (`lib/ui/theme/tokens.dart`, `assets/fonts`).

## macOS and Linux

The same UI is the installer and uninstaller on macOS and Linux. Only OS-specific wording changes (`HostOs` in `lib/src/context.dart`). The steps and the design are the same as on Windows.

- `lib/src/posix.dart`: starts `installer/posix/engine.sh` as a child process. Same line protocol as the Windows pipe, on stdout, with answers on stdin. Also contains the folder picker and the CI autopilot (`LF_SETUP_AUTOPILOT=<dir>`: walks through every step and saves one PNG per step).
- `installer/posix/engine.sh`: install, update and uninstall with the Windows exit codes:
  - payload SHA-256 check
  - no privilege escalation
  - validated paths (absolute, normalized, allowed roots, no symlinks)
  - rollback
- `installer/linux/build.sh`: AppImage (`*-linux-x64-setup.AppImage`), with appimagetool and runtime pinned by SHA-256.
- `installer/macos/build.sh`: `LINEFM Radio Setup.app` in a designed DMG (`*-macos-setup.dmg`), built with dmgbuild pinned by hash.
- `installer/posix/test-installer.sh`: the CI test on the Linux (xvfb) and macOS runners.
