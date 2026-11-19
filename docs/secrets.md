# Secrets und Variablen

Vollständige Liste aller GitHub-Secrets und -Variablen, die die automatischen Abläufe lesen. Ohne einen Eintrag wird der betroffene Schritt sauber übersprungen, die Job-Zusammenfassung nennt dann den fehlenden Namen (nie den Wert). Die Abläufe selbst sind in [stores-pipelines.md](stores-pipelines.md) beschrieben, die Schritt-für-Schritt-Einrichtung der Konten in [EINRICHTUNG.md](EINRICHTUNG.md).

## So trägst du etwas ein

- **Secret** (geheim, danach nicht mehr lesbar): Repository > Settings > Secrets and variables > Actions > Tab "Secrets" > "New repository secret". Name exakt übernehmen.
- **Variable** (nicht geheim, lesbar): derselbe Ort, Tab "Variables" > "New repository variable".
- **Umgebung `production`**: Repository > Settings > Environments > "New environment" > `production`. Dort "Required reviewers" eintragen, dann wartet jeder Web-Deploy auf deine Freigabe. Secrets für den Web-Deploy dürfen wahlweise im Repository oder in dieser Umgebung stehen.
- Werte, die aus Dateien stammen (Schlüssel, Zertifikate), als Base64 eintragen: `base64 -w0 datei` (Linux, macOS) oder `[Convert]::ToBase64String([IO.File]::ReadAllBytes("datei"))` (PowerShell).
- Wer legt an: In der Spalte "Wer" steht **jaybelife** (Konto-Inhaber, besorgt den Wert) oder **Entwickler** (kann es aus Repo-Angaben selbst setzen). Eingetragen wird immer von einer Person mit Schreibrecht auf die Repo-Einstellungen. Passwörter und Schlüssel gehören nie in Chat, E-Mail oder Issues.

## Google Play

| Name | Art | Wert / Herkunft | Wer | Wo besorgen |
|---|---|---|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON` | Secret | Kompletter Inhalt der JSON-Schlüsseldatei des Dienstkontos | jaybelife | EINRICHTUNG 2.4 (Google Cloud Console, Dienstkonto in der Play Console einladen) |
| `ANDROID_KEYSTORE_BASE64` | Secret | `upload-keystore.jks` als Base64 | jaybelife | `packaging/android/SIGNING.md` |
| `ANDROID_KEYSTORE_PASSWORD` | Secret | Store-Passwort | jaybelife | wie oben |
| `ANDROID_KEY_ALIAS` | Secret | z. B. `upload` | jaybelife | wie oben |
| `ANDROID_KEY_PASSWORD` | Secret | Schlüssel-Passwort | jaybelife | wie oben |
| `BUILD_NUMBER_OFFSET` | Variable, optional | Zahl, wird zur Lauf-Nummer addiert (`versionCode`). Standard 100 | Entwickler | nur anheben, wenn Play einen höheren `versionCode` verlangt |

Der Upload braucht ein **signiertes** AAB. Fehlt der Upload-Key beim Release-Build, bricht `store-google.yml` mit einer klaren Meldung ab.

## Microsoft Store

Werte aus dem Partner Center: Konto-Einstellungen > Benutzer > Azure-AD-Anwendung (Tenant-ID, Client-ID, Client-Secret) und Produktidentität der App.

| Name | Art | Wert / Herkunft | Wer |
|---|---|---|---|
| `MS_STORE_TENANT_ID` | Secret | Azure-AD-Verzeichnis-/Tenant-ID | jaybelife |
| `MS_STORE_SELLER_ID` | Secret | Händler-ID aus dem Partner Center (Konto-Einstellungen > Organisationsprofil > Legal info) | jaybelife |
| `MS_STORE_CLIENT_ID` | Secret | Anwendungs-(Client-)ID der Azure-AD-App mit Rolle "Manager" | jaybelife |
| `MS_STORE_CLIENT_SECRET` | Secret | Client-Secret dieser App | jaybelife |
| `MS_STORE_PRODUCT_ID` | Variable | Store-Produkt-ID der App (12 Zeichen, z. B. `9NXXXXXXXXXX`) | jaybelife |
| `MS_STORE_IDENTITY_NAME` | Variable | `Package/Identity/Name` | jaybelife |
| `MS_STORE_PUBLISHER` | Variable | `Package/Identity/Publisher` (`CN=...`) | jaybelife |
| `MS_STORE_PUBLISHER_DISPLAY_NAME` | Variable | `Package/Properties/PublisherDisplayName` | jaybelife |
| `WINDOWS_CERT_PFX_BASE64` | Secret, optional | Code-Signing-Zertifikat für den GitHub-Installer (nicht für den Store) | jaybelife |
| `WINDOWS_CERT_PASSWORD` | Secret, optional | Passwort dazu | jaybelife |

Der Store braucht keine eigene Signatur, Microsoft signiert selbst.

## Snap Store

| Name | Art | Wert / Herkunft | Wer |
|---|---|---|---|
| `SNAPCRAFT_STORE_CREDENTIALS` | Secret | Ausgabe von `snapcraft export-login --snaps linefm-radio --channels edge,beta,candidate --acls package_upload,package_release -` (Anmeldedaten mit Ablaufdatum, wiederholen, wenn sie ablaufen) | jaybelife |

## Flathub

Keine Secrets. `flathub-prep.yml` füllt nur das Manifest und legt es als Artefakt ab. Eingereicht wird von Hand, siehe [packaging/flathub/README.md](../packaging/flathub/README.md).

## Apple (standardmäßig aus)

Alles hinter der Variable `APPLE_PUBLISHING_ENABLED`. Solange sie nicht `true` ist, laufen `store-apple.yml` und die Signatur- und Notarisierungsschritte in `build.yml` nicht.

| Name | Art | Wert / Herkunft | Wer |
|---|---|---|---|
| `APPLE_PUBLISHING_ENABLED` | Variable | `true`, erst wenn alles andere vorliegt (Entscheidung 21) | jaybelife |
| `APPLE_TEAM_ID` | Secret | 10-stellige Team-ID (Account > Mitgliedschaft) | jaybelife |
| `APP_STORE_CONNECT_API_KEY_ID` | Secret | Schlüssel-ID des App-Store-Connect-API-Schlüssels | jaybelife |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Secret | Issuer-ID (Nutzer und Zugriff > Integrationen) | jaybelife |
| `APP_STORE_CONNECT_API_KEY_P8` | Secret | Inhalt der `.p8`-Datei (Text, nicht Base64) | jaybelife |
| `APPLE_DISTRIBUTION_CERT_P12_BASE64` | Secret | "Apple Distribution"-Zertifikat samt privatem Schlüssel als `.p12`, Base64 | jaybelife |
| `APPLE_DISTRIBUTION_CERT_PASSWORD` | Secret | Passwort der `.p12` | jaybelife |
| `APPLE_MAC_INSTALLER_CERT_P12_BASE64` | Secret | "Mac Installer Distribution"-Zertifikat (`.p12`, Base64), nur für das Mac-App-Store-Paket | jaybelife |
| `APPLE_MAC_INSTALLER_CERT_PASSWORD` | Secret | Passwort dazu | jaybelife |
| `APPLE_IOS_PROVISIONING_PROFILES_BASE64` | Secret | App-Store-Profile für `de.linefm.app` **und** `de.linefm.app.widget`, je Profil eine Zeile Base64 | jaybelife |
| `APPLE_MACOS_PROVISIONING_PROFILE_BASE64` | Secret | Mac-App-Store-Profil für `de.linefm.app` (`.provisionprofile`, Base64) | jaybelife |
| `APPLE_DEVELOPER_ID_CERT_P12_BASE64` | Secret | "Developer ID Application"-Zertifikat für das signierte DMG außerhalb des Stores | jaybelife |
| `APPLE_DEVELOPER_ID_CERT_PASSWORD` | Secret | Passwort dazu | jaybelife |

Der macOS-Gate in `build.yml` (Developer ID + Notarisierung) nutzt `APPLE_TEAM_ID`, die zwei `APPLE_DEVELOPER_ID_*`-Secrets und die drei `APP_STORE_CONNECT_*`-Secrets. Die Store-Pipeline `store-apple.yml` nutzt die `APPLE_DISTRIBUTION_*`-, `APPLE_MAC_INSTALLER_*`-, Profil- und `APP_STORE_CONNECT_*`-Secrets.

## Web-Deploy

Auslöser sind Release-Tag (nur Endversionen) oder manueller Start von `deploy-web.yml`. Welche Ziele laufen, bestimmt die Variable `WEB_DEPLOY_TARGETS` (oder die Eingabe `targets`).

| Name | Art | Wert / Herkunft | Wer |
|---|---|---|---|
| `WEB_DEPLOY_TARGETS` | Variable | Kommagetrennt: `cloudflare`, `ssh`, `plesk`. Leer = es wird nichts ausgerollt | jaybelife |

**Cloudflare Pages** ([hosting-cloudflare.md](hosting-cloudflare.md)):

| Name | Art | Wert / Herkunft | Wer |
|---|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Secret | API-Token mit Berechtigung "Cloudflare Pages: Edit" (Dashboard > Mein Profil > API-Tokens) | jaybelife |
| `CLOUDFLARE_ACCOUNT_ID` | Secret | Konto-ID (Dashboard, rechte Spalte der Übersicht) | jaybelife |
| `CLOUDFLARE_PAGES_PROJECT` | Variable | Projektname, `linefm-app` (siehe `deploy/cloudflare/wrangler.toml`) | Entwickler |

**Eigener Server mit nginx oder Traefik** ([hosting-nginx.md](hosting-nginx.md), [hosting-traefik.md](hosting-traefik.md)):

| Name | Art | Wert / Herkunft | Wer |
|---|---|---|---|
| `DEPLOY_HOST` | Secret | Hostname oder IP des Servers | jaybelife |
| `DEPLOY_USER` | Secret | SSH-Benutzer (eigener Deploy-Benutzer ohne Root, mit Schreibrecht auf `DEPLOY_PATH`) | jaybelife |
| `DEPLOY_SSH_KEY` | Secret | Privater Schlüssel (OpenSSH, ohne Passphrase), nur für diesen Zweck erzeugt: `ssh-keygen -t ed25519 -f deploy_key -C linefm-deploy`. Den öffentlichen Teil in `~/.ssh/authorized_keys` des Benutzers eintragen | jaybelife |
| `DEPLOY_KNOWN_HOSTS` | Secret | Host-Schlüssel des Servers: einmalig `ssh-keyscan -t ed25519 <host>` ausführen, den Fingerabdruck mit dem Server vergleichen (`ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` dort) und die Zeile eintragen. Die Pipeline prüft strikt dagegen, `StrictHostKeyChecking=no` gibt es nicht | jaybelife |
| `DEPLOY_PATH` | Variable | Absoluter Zielordner, z. B. `/var/www/linefm-app` (darunter `releases/`, `current`, `hosting/`) | Entwickler |
| `DEPLOY_PORT` | Variable, optional | SSH-Port, Standard 22 | Entwickler |
| `DEPLOY_RELOAD_COMMAND` | Variable, optional | Befehl, der nach dem Umschalten auf dem Server läuft, z. B. `sudo systemctl reload nginx` oder bei Traefik `cd /opt/linefm && docker compose up -d --build`. Muss ohne Passwortabfrage laufen (sudoers-Eintrag) | Entwickler |

**Plesk per SSH** ([hosting-plesk.md](hosting-plesk.md)): Plesk-Abonnement mit SSH-Zugang (Shell "/bin/bash (chrooted)" oder ohne Chroot) und Schlüssel-Login.

| Name | Art | Wert / Herkunft | Wer |
|---|---|---|---|
| `PLESK_SSH_HOST` | Secret | Plesk-Server | jaybelife |
| `PLESK_SSH_USER` | Secret | Systembenutzer des Abonnements | jaybelife |
| `PLESK_SSH_KEY` | Secret | Privater Schlüssel, wie bei `DEPLOY_SSH_KEY` | jaybelife |
| `PLESK_SSH_KNOWN_HOSTS` | Secret | Host-Schlüssel wie bei `DEPLOY_KNOWN_HOSTS` | jaybelife |
| `PLESK_DOCROOT` | Variable | Dokumentstamm relativ zum Home des Benutzers oder absolut, z. B. `httpdocs` | Entwickler |
| `PLESK_SSH_PORT` | Variable, optional | SSH-Port, Standard 22 | Entwickler |

## Konfiguration der App (nur öffentliche Werte)

Diese Variablen schreibt die CI in `config/app.json`. Sie landen im fertigen Programm und sind öffentlich lesbar, deshalb nur Variablen, keine Secrets.

| Name | Art | Bedeutung |
|---|---|---|
| `WEB_BASE_URL` | Variable | `https://app.linefm.de` |
| `UMAMI_URL`, `UMAMI_WEBSITE_ID` | Variable | Umami (optional), siehe [telemetry.md](telemetry.md) |
| `SENTRY_DSN`, `SENTRY_ENVIRONMENT` | Variable | Sentry/GlitchTip (optional) |
| `GSC_VERIFICATION` | Variable | Search-Console-Bestätigungscode (optional) |
| `TRUST_GRIDINSOFT_URL`, `TRUST_TRUSTPILOT_URL` | Variable | Profil-Links für die Vertrauens-Badges (optional) |
| `LEGAL_VALUES_JSON` | Variable | JSON mit den Impressums-/Datenschutz-Platzhaltern, siehe EINRICHTUNG Abschnitt 9 |
| `FIREBASE_CONFIG_JSON` | Secret, optional | JSON mit `FIREBASE_*`-Schlüsseln (aktiviert Firebase) |

## Sicherheitsregeln der Abläufe

- Alle Actions sind auf einen Commit-SHA festgelegt, `permissions` stehen auf `{}` und werden je Job minimal vergeben.
- Secrets werden nur über `env:` oder `with:` an einen Schritt gegeben, nie in Befehlszeilen interpoliert oder ausgegeben. Zertifikate und Schlüssel liegen nur kurz im temporären Runner-Ordner und werden am Ende gelöscht.
- Der Server-Host-Schlüssel kommt aus einem Secret und wird strikt geprüft.
- Wird ein Secret geändert oder gelöscht, gilt das ab dem nächsten Lauf. Wurde eines versehentlich offengelegt: sofort beim Anbieter widerrufen, dann neu eintragen.
