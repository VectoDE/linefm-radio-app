# Windows-Paketierung

Drei Formen, alle aus demselben `flutter build windows --release`:

| Form | Quelle | Gebaut von |
|---|---|---|
| ZIP (portabel) | `build\windows\x64\runner\Release\*` | `.github/workflows/build.yml` (P25) |
| Installer (`*-setup.exe`) | `packaging/windows/linefm-radio.iss` (Inno Setup 6) | `build.yml`, Schritt "Installer erstellen" |
| MSIX (Sideload und Microsoft Store) | `msix_config` in `pubspec.yaml` | `build.yml`, Schritt "MSIX erstellen" |

Der Installer installiert ohne Administratorrechte pro Benutzer (Dialog erlaubt "fuer alle"), registriert das Schema `linefm://` und deinstalliert sauber. Er wird nicht selbst signiert, die CI signiert die fertige EXE per `signtool`, sobald `WINDOWS_CERT_PFX_BASE64` und `WINDOWS_CERT_PASSWORD` gesetzt sind.

## MSIX und Microsoft Store

Die MSIX-Konfiguration liegt bereits in `pubspec.yaml` (`msix_config`):

```yaml
msix_config:
  display_name: LINEFM Radio
  publisher_display_name: LINEFM
  identity_name: de.linefm.app
  msix_version: 1.0.0.0
  logo_path: assets/branding/icon_1024.png
  capabilities: internetClient
```

Platzhalter fuer den Store (Werte liefert das Partner Center von jaybelife, siehe Schritt "Product identity" der App-Reservierung):

| Feld | Wert aus dem Partner Center |
|---|---|
| `identity_name` | `Package/Identity/Name`, ersetzt `de.linefm.app`, falls der Store einen anderen Namen vergibt |
| `publisher` | `Package/Identity/Publisher`, z. B. `CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` |
| `publisher_display_name` | `Package/Properties/PublisherDisplayName` |

Store-Build (ohne eigene Signatur, der Store signiert selbst):

```powershell
dart run msix:create --store --identity-name "<Package/Identity/Name>" --publisher "<Package/Identity/Publisher>" --publisher-display-name "<PublisherDisplayName>"
```

`msix_version` wird von der CI aus der Release-Version gesetzt (`<x.y.z>.0`). Das vierte Segment bleibt fuer den Store `0`.

Die Pipeline `store-microsoft.yml` liest diese Werte aus den Repository-Variablen `MS_STORE_IDENTITY_NAME`, `MS_STORE_PUBLISHER` und `MS_STORE_PUBLISHER_DISPLAY_NAME` und baut das Store-MSIX selbst (das MSIX aus `build.yml` trägt die Sideload-Identität). Zugangsdaten: Secrets `MS_STORE_*`, Liste in `docs/secrets.md`.

## Logos

`logo_path` zeigt auf `assets/branding/icon_1024.png`. Das `msix`-Paket erzeugt daraus die Kachelgroessen. Fuer die Store-Einreichung zusaetzlich bereitzuhalten (Partner Center, Store-Eintrag): 300x300-Logo und mindestens ein Screenshot.

## Hinweise

- Ohne Zertifikat baut die CI ein unsigniertes MSIX. Es laesst sich erst nach Signatur sideloaden. Fuer den Store ist keine eigene Signatur noetig.
- `capabilities: internetClient` genuegt. Hintergrundwiedergabe laeuft als normaler Desktop-Prozess.
