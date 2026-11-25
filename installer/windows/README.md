# Windows-Installer

Eigener Installer für LINEFM Radio mit eigener Oberfläche im App-Design (Entscheidung des Inhabers vom 21.11.2026). Kein Inno Setup, kein NSIS, kein WiX und keine Fremdbibliotheken: nur Win32, BCrypt und die Windows-Compression-API für die Engine, Flutter für die Oberfläche.

Bedienung für Nutzer und Admins: [docs/BAUEN-UND-STARTEN.md](../../docs/BAUEN-UND-STARTEN.md), Abschnitt "Windows: Installer benutzen". Parameter, Exit-Codes und Produktdaten: [packaging/windows/README.md](../../packaging/windows/README.md).

## Aufbau

```
setup.exe = [setup_stub.exe][Archiv][Fußzeile 64 Byte][Authenticode-Signatur]
```

| Teil | Ort | Aufgabe |
|---|---|---|
| Stub und Engine | `engine/src/stub`, `engine/src/common` | C++17, statisch gelinkt (`/MT`). Prüft die Nutzlast, entpackt die Oberfläche in einen privaten Temp-Ordner, installiert und deinstalliert (Dateien, Registry, Verknüpfungen) mit vollständigem Rückbau bei Fehler oder Abbruch. Dieselbe Binärdatei ist auch `uninstall.exe`. |
| Packer | `engine/src/packer` | `lfpack.exe`, nur Build: hängt App, Oberfläche, Lizenzen und `packaging/windows/installer.ini` als LZMS-Archiv mit SHA-256 je Datei und über das ganze Archiv an den Stub. |
| Oberfläche | `../ui` (shared with macOS and Linux) | Flutter-App `linefm_setup.exe`: Schritte Willkommen, Lizenz, Optionen, Fortschritt, Fertig bzw. Bestätigen, Entfernen, Fertig. Deutsch/Englisch, Hell/Dunkel nach Windows, DPI pro Monitor, Tastatur, Screenreader, Kontrastmodus. |
| Bau | `build.ps1` | `-Stage prepare` (Engine + Oberfläche), `-Stage pack` (setup.exe). |
| Test | `test-installer.ps1` | Installation, Start, Update mit laufender App, Downgrade-Sperre, Oberfläche per UI Automation, Deinstallation, alle Benutzer. Läuft im Windows-Job von `build.yml`. |

### Ablauf mit Oberfläche

1. `setup.exe` prüft den SHA-256 des Archivs gegen die Fußzeile, liest die Produktdaten und entpackt `ui/*` in `%TEMP%\linefm-setup-<Zufall>` (eigene DACL: nur SYSTEM, Administratoren, aktueller Benutzer).
2. Der Stub schreibt `context.json` (Produkt, vorhandene Installationen, Vorgaben) und startet `linefm_setup.exe --context ...`.
3. Die Oberfläche fragt die Optionen ab und startet die Engine: `setup.exe --engine install --pipe <Name> --scope user|machine ...`. Nur bei "Alle Benutzer" mit UAC (`runas`), sonst normal.
4. Engine und Oberfläche sprechen über eine Named Pipe (Zeilenprotokoll unten). Die Engine meldet Phasen und Fortschritt, fragt nach laufenden Apps und schickt am Ende `result <Code> <Text>`.
5. Nach dem Schließen der Oberfläche löscht der Stub den Temp-Ordner und endet mit dem Exit-Code der Oberfläche.

Still (`/S`) läuft dieselbe Engine ohne Oberfläche und ohne Pipe. Die CI-Tests der stillen Installation prüfen damit auch den Code hinter der Oberfläche.

### Deinstallation

`uninstall.exe` kopiert sich in einen privaten Temp-Ordner (Prüfsumme der Kopie wird verglichen) und startet dort Phase 2, damit der Installationsordner samt `uninstall.exe` vollständig verschwindet. Die Oberfläche wird aus `<Installationsordner>\setup` kopiert und jede Datei gegen die SHA-256 aus `uninstall.dat` geprüft; fehlt sie, gibt es eine einfache Ja/Nein-Abfrage. Gelöscht wird nur, was in `uninstall.dat` steht. Registry-Einträge für Link-Schema, App Paths und Autostart werden nur entfernt, wenn sie auf diese Installation zeigen.

### Update

Die Engine findet eine vorhandene Installation über den Uninstall-Schlüssel (`app_id`), bleibt im bisherigen Bereich und Ordner und übernimmt die bisherigen Optionen. Laufende App-Prozesse findet sie über den Restart Manager, fragt (Oberfläche) bzw. beendet sie (still, außer `/NOCLOSEAPPS`). Dateien werden erst als `.lfnew` geschrieben und dann atomar ersetzt, alte Dateien als Sicherung umbenannt und erst nach Erfolg gelöscht. Die Nutzerdaten (`%APPDATA%\<CompanyName>\<ProductName>`) fasst ein Update nie an.

## Pipe-Protokoll

UTF-8, eine Nachricht pro Zeile.

| Richtung | Zeile | Bedeutung |
|---|---|---|
| Engine → Oberfläche | `hello <PID>` | verbunden |
| | `phase <Name>` | `prepare`, `closing`, `copying`, `registry`, `finalizing`, `rollback`, `removing` |
| | `progress <fertig> <gesamt>` | Bytes bzw. Dateien |
| | `running\t<App>\t...` | laufende App gefunden, Antwort nötig |
| | `log <Text>` | Protokollzeile (für "Details") |
| | `result <Code> <Text>` | Ergebnis; bei Erfolg ist der Text der Installationsordner |
| Oberfläche → Engine | `close` / `keep` | Antwort auf `running` |
| | `cancel` | abbrechen, die Engine nimmt alles zurück |

## Sicherheit

- **DLL-Planting im Download-Ordner**: `SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_SYSTEM32)` als erste Anweisung, `/DEPENDENTLOADFLAG:0x800` für statische Importe, alle Nicht-KnownDLLs (`cabinet`, `rstrtmgr`, `version`, `bcrypt` …) verzögert geladen, aktuelles Verzeichnis auf System32.
- **Manifest `asInvoker`** für Stub und Oberfläche: Windows erkennt "setup.exe" sonst heuristisch als Installer und fragt sofort nach Adminrechten. UAC kommt nur bei "Alle Benutzer" und nur für die Engine.
- **Nutzlast**: SHA-256 über das ganze Archiv (Fußzeile) vor jeder Aktion, SHA-256 je Datei beim Entpacken, Größen- und Pfadprüfung der Indexeinträge. Die Datei wird beim Lesen gegen Schreibzugriffe gesperrt. Mit Signatur deckt Authenticode Stub, Archiv und Fußzeile ab.
- **Temp-Ordner** mit zufälligem Namen (BCryptGenRandom) und eigener, nicht vererbter DACL; erhöhte Läufe nutzen `%SystemRoot%\SystemTemp` mit Zugriff nur für SYSTEM und Administratoren.
- **Named Pipe**: zufälliger Name, nur lokal (`PIPE_REJECT_REMOTE_CLIENTS`), eine Instanz, DACL nur SYSTEM/Administratoren/aktueller Benutzer. Die Oberfläche akzeptiert nur den selbst gestarteten Engine-Prozess (`GetNamedPipeClientProcessId`), die Engine verbindet mit `SECURITY_IDENTIFICATION` (keine Impersonation durch den Server).
- **Zielordner**: Längen-, Zeichen- und Reparse-Point-Prüfung. Bei "Alle Benutzer" darf kein normaler Benutzer den Ordner oder seine Elternordner ändern können; neue Ordner außerhalb von `Program Files` bekommen eine geschützte DACL.
- **Gequotete Pfade** in `UninstallString`, `QuietUninstallString`, Link-Schema (`"...exe" "%1"`), Autostart und allen Kommandozeilen (Quoting nach `CommandLineToArgvW`).
- **Härtung** beim Kompilieren: `/guard:cf`, `/Qspectre`, `/sdl`, `/GS`, ASLR (`/DYNAMICBASE /HIGHENTROPYVA`), DEP, CET (`/CETCOMPAT`), `/W4 /WX`.
- **Signatur**: Die CI signiert `setup_stub.exe` (damit auch `uninstall.exe`), `linefm_setup.exe` und die fertige `setup.exe` mit dem vorhandenen Zertifikat (`WINDOWS_CERT_*`) und prüft sie mit `signtool verify`. Ohne Zertifikat (PRs, fehlende Secrets) bleibt alles unsigniert, SmartScreen warnt dann.

## Grenzen

- Nur x64.
- Die Oberfläche braucht Windows 10 oder neuer. Startet sie nicht, nennt der Stub die stille Installation als Ausweg.
- Ohne Code-Signing-Zertifikat warnt SmartScreen beim ersten Start.
