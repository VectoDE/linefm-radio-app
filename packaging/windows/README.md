# Windows-Paketierung

Drei Formen, alle aus demselben `flutter build windows --release`:

| Form | Quelle | Gebaut von |
|---|---|---|
| ZIP (portabel) | `build\windows\x64\runner\Release\*` | `.github/workflows/build.yml` |
| Installer (`*-setup.exe`) | `installer/windows` (eigene Engine und Oberfläche), Produktdaten in `packaging/windows/installer.ini` | `build.yml`, Schritte "Installer-Engine und Setup-Oberflaeche bauen" und "Installer packen" |
| MSIX (Sideload und Microsoft Store) | `msix_config` in `pubspec.yaml` | `build.yml`, Schritt "MSIX erstellen" |

Der Installer hat eine eigene Oberfläche im App-Design (Bedienung: `docs/BAUEN-UND-STARTEN.md`, Abschnitt "Windows: Installer benutzen"; Aufbau und Sicherheit: `installer/windows/README.md`). Standard ist die Installation pro Benutzer ohne Administratorrechte, "Alle Benutzer" fragt per UAC. Er registriert `linefm://`, App Paths, Verknüpfungen und den Eintrag in "Installierte Apps", aktualisiert ältere Versionen unter Erhalt der Einstellungen und deinstalliert mit eigenem Dialog. Die CI signiert Setup-Stub, Oberfläche und die fertige `setup.exe` per `signtool`, sobald `WINDOWS_CERT_PFX_BASE64` und `WINDOWS_CERT_PASSWORD` gesetzt sind.

### Produktdaten (`installer.ini`)

| Schlüssel | Bedeutung |
|---|---|
| `name` | Anzeigename (Verknüpfungen, "Installierte Apps") |
| `publisher` | Herausgeber, `LineFM Studios` |
| `manufacturer` | Hersteller, `Tim Hauke` (optional, erscheint in der Oberfläche) |
| `exe_name` | Programmdatei der App |
| `url` | Website (Support-Link in "Installierte Apps") |
| `app_id` | feste GUID, darf sich nie ändern (Update-Erkennung) |
| `scheme` | Link-Schema ohne `://` |
| `dir_name` | Ordnername unter `Programs` bzw. `Program Files` |
| `data_company`, `data_product` | Ersatz für den Datenordner, falls die EXE keine Versionsangaben hat |
| `default_scope` | `user` oder `machine` |
| `default_desktop_shortcut`, `default_start_menu`, `default_autostart` | Vorauswahl `1`/`0` |

Die Version hängt der Packer aus der CI an (Tag bzw. `x.y.z-dev.N`).

### Parameter von `setup.exe`

| Parameter | Wirkung |
|---|---|
| `/S` (auch `/SILENT`, `/VERYSILENT`, `/QUIET`) | still, ohne Fenster |
| `/CURRENTUSER` | nur für den angemeldeten Benutzer (Standard) |
| `/ALLUSERS` | für alle Benutzer, braucht eine Administrator-Konsole |
| `/DIR="Ordner"` | Zielordner (bei Updates gilt der bisherige Ordner) |
| `/DESKTOPSHORTCUT=0\|1`, `/STARTMENU=0\|1`, `/AUTOSTART=0\|1` | Optionen; ohne Angabe gelten die Vorgaben bzw. beim Update die bisherige Wahl |
| `/NOCLOSEAPPS` | laufende App nicht beenden (dann Exit-Code 5) |
| `/ALLOWDOWNGRADE` | ältere Version über eine neuere installieren |
| `/LOG="Datei"` | Protokoll schreiben |
| `/?` | Hilfe |

`uninstall.exe` (im Installationsordner): `/S`, `/DELETEUSERDATA` (auch Einstellungen, Favoriten und Wecker löschen), `/NOCLOSEAPPS`, `/LOG="Datei"`.

### Exit-Codes

| Code | Bedeutung |
|---|---|
| 0 | erfolgreich |
| 1 | ungültige Parameter |
| 2 | abgebrochen |
| 3 | Fehler |
| 4 | Setup-Datei beschädigt (Prüfsumme der Nutzlast stimmt nicht) |
| 5 | App läuft und wurde nicht beendet |
| 6 | neuere Version installiert (Downgrade nur mit `/ALLOWDOWNGRADE`) |
| 7 | Administratorrechte nötig |
| 8 | Zielordner ungeeignet |
| 9 | Rückbau nach Fehler unvollständig |
| 10 | nicht installiert |
| 11 | zu wenig Speicherplatz |
| 12 | bereits im anderen Bereich installiert (Benutzer bzw. alle Benutzer) |

## MSIX und Microsoft Store

Die MSIX-Konfiguration liegt bereits in `pubspec.yaml` (`msix_config`):

```yaml
msix_config:
  display_name: LINEFM Radio
  publisher_display_name: LineFM Studios
  identity_name: de.linefm.app
  msix_version: 1.0.0.0
  logo_path: assets/branding/icon_1024.png
  capabilities: internetClient
```

Platzhalter für den Store (Werte liefert das Partner Center von jaybelife, siehe Schritt "Product identity" der App-Reservierung):

| Feld | Wert aus dem Partner Center |
|---|---|
| `identity_name` | `Package/Identity/Name`, ersetzt `de.linefm.app`, falls der Store einen anderen Namen vergibt |
| `publisher` | `Package/Identity/Publisher`, z. B. `CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` |
| `publisher_display_name` | `Package/Properties/PublisherDisplayName` |

Store-Build (ohne eigene Signatur, der Store signiert selbst):

```powershell
dart run msix:create --store --identity-name "<Package/Identity/Name>" --publisher "<Package/Identity/Publisher>" --publisher-display-name "<PublisherDisplayName>"
```

`msix_version` wird von der CI aus der Release-Version gesetzt (`<x.y.z>.0`). Das vierte Segment bleibt für den Store `0`.

Die Pipeline `store-microsoft.yml` liest diese Werte aus den Repository-Variablen `MS_STORE_IDENTITY_NAME`, `MS_STORE_PUBLISHER` und `MS_STORE_PUBLISHER_DISPLAY_NAME` und baut das Store-MSIX selbst (das MSIX aus `build.yml` trägt die Sideload-Identität). Zugangsdaten: Secrets `MS_STORE_*`, Liste in `docs/secrets.md`.

## Logos

`logo_path` zeigt auf `assets/branding/icon_1024.png`. Das `msix`-Paket erzeugt daraus die Kachelgrößen. Für die Store-Einreichung zusätzlich bereitzuhalten (Partner Center, Store-Eintrag): 300x300-Logo und mindestens ein Screenshot.

## Hinweise

- Ohne Zertifikat baut die CI ein unsigniertes MSIX. Es lässt sich erst nach Signatur sideloaden. Für den Store ist keine eigene Signatur nötig.
- `capabilities: internetClient` genügt. Hintergrundwiedergabe läuft als normaler Desktop-Prozess.
