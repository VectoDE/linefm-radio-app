# linefm_setup

Setup-Oberfläche (Installer und Deinstaller) von LINEFM Radio für Windows. Wird nicht allein ausgeliefert, sondern vom Setup-Stub aus `setup.exe` entpackt und mit `--context <context.json>` gestartet. Aufbau, Protokoll und Sicherheit: [../README.md](../README.md).

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
