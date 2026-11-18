# Telemetrie: Konfiguration und Hosting

LINEFM Radio kann anonyme Statistik und Absturzberichte senden. Alles ist
optional und austauschbar. Ohne Konfiguration sendet die App nichts und zeigt
auch keinen Einwilligungsdialog.

## Wie es funktioniert

| Anbieter | Zweck | Schluessel in `config/app.json` | Aktiv, wenn |
|---|---|---|---|
| Umami (selbst gehostet oder Cloud) | Statistik | `UMAMI_URL`, `UMAMI_WEBSITE_ID` | beide gesetzt |
| GlitchTip oder Sentry | Absturzberichte | `SENTRY_DSN`, `SENTRY_ENVIRONMENT` | DSN gesetzt |
| Firebase (Analytics + Crashlytics) | beides | `FIREBASE_ENABLED` und `FIREBASE_*` | siehe unten |

Die Werte werden beim Build per `--dart-define-from-file=config/app.json`
eingebrannt und sind im Binary lesbar. Es gehoeren deshalb nur oeffentliche IDs
hinein (Website-ID, DSN, Firebase-Web-Config), keine Geheimnisse.

Einwilligung (DSGVO/TDDDG):

- Nichts konfiguriert: kein Dialog, keine Sinks, kein Netzwerkaufruf.
- Konfiguriert, aber nicht eingewilligt: Sinks werden nicht initialisiert, es
  geht nichts an die Telemetrie-Hosts. Fehler werden nur lokal geloggt.
- Einwilligung erteilt: Sinks starten. Widerruf stoppt sie sofort, leert die
  Umami-Warteschlange und beendet das Sentry-SDK.

Erfasste Ereignisse (keine personenbezogenen Daten, keine Cookies, keine
Geraete-IDs): `app_start`, Bildschirmaufrufe als `/screen/<name>`, `play`,
`stop`, `shuffle`, `favorite_add`, `favorite_remove`, `share_song`,
`export_favorites`, `sleep_timer_set`, `alarm_set`, `cast_start`,
`airplay_open`, `error_stream`. Umami sammelt zusaetzlich Sprache und
Bildschirmgroesse. Sentry/GlitchTip entfernt Geraetename, Server-Name, Nutzer
und IP (`sendDefaultPii: false`, kein Tracing, keine Screenshots).

Datenschutzerklaerung und Einwilligungstext muessen zu den aktivierten
Anbietern passen. Das ist eine technische Vorpruefung, keine Rechtsberatung;
bitte mit Anwalt abstimmen.

## Selbst hosten mit Docker Compose

Verzeichnis `deploy/telemetry/`. Voraussetzung: Docker mit Compose v2.24 oder
neuer.

```bash
cd deploy/telemetry
cp .env.example .env
# vier Zufallswerte eintragen:
#   openssl rand -hex 32   (je einmal fuer DB-Passwoerter, App-Secret, Secret-Key)
docker compose up -d
```

Danach lokal erreichbar (nur `127.0.0.1`, nicht von aussen):

- Umami: <http://localhost:3000>. Erste Anmeldung `admin` / `umami`, **sofort
  Passwort aendern**. Unter Einstellungen > Websites eine Website anlegen,
  `UMAMI_WEBSITE_ID` ist die angezeigte ID.
- GlitchTip: <http://localhost:8000>. Konto registrieren, Organisation und
  Projekt (Plattform Flutter) anlegen; der DSN steht in den Projekt-
  Einstellungen. Danach in `.env` `GLITCHTIP_ENABLE_USER_REGISTRATION=false`
  setzen und `docker compose up -d` erneut ausfuehren.

Sichere Defaults:

- Keine Secrets in der Compose-Datei. Fehlt ein Pflichtwert in `.env`, bricht
  `docker compose` mit einer Meldung ab. `.env` ist in `.gitignore`.
- Datenbanken und Valkey haengen nur in internen Netzen ohne Port-Freigabe.
- Web-Ports sind an `127.0.0.1` gebunden. Oeffentlich geht es nur ueber einen
  Reverse Proxy mit TLS.
- Images sind per Digest gepinnt; `no-new-privileges` ist gesetzt; Umami sendet
  keine eigene Telemetrie (`DISABLE_TELEMETRY`).

### Betrieb hinter Traefik

```bash
# in .env: UMAMI_HOST, GLITCHTIP_HOST, GLITCHTIP_DOMAIN=https://<host>,
#          TRAEFIK_NETWORK, TRAEFIK_ENTRYPOINT, TRAEFIK_CERT_RESOLVER
docker compose -f compose.yml -f compose.traefik.yml up -d
```

Das Override entfernt die lokalen Ports und haengt Umami und GlitchTip an das
vorhandene Traefik-Netz. Der Proxy muss die Namen des Netzes, des Entrypoints
und des Certresolvers kennen.

Hinter nginx stattdessen `proxy_pass http://127.0.0.1:3000;` bzw. `:8000`
mit `proxy_set_header Host $host;` und `X-Forwarded-Proto $scheme` setzen und
`GLITCHTIP_DOMAIN` auf die oeffentliche HTTPS-URL stellen.

### Web-Build (CORS)

Die Web-App sendet an `{UMAMI_URL}/api/send` und GlitchTip. Beide muessen
Anfragen von `https://app.linefm.de` zulassen. Umami erlaubt das fuer
`/api/send` standardmaessig; bei GlitchTip gilt fuer den Ingest-Endpunkt
ebenfalls offenes CORS. Im Betrieb pruefen: Browser-Konsole der Web-App ohne
CORS-Fehler.

### Updates

1. Neuen Digest ermitteln (Registry-Seite des Images oder
   `docker buildx imagetools inspect <image>:<tag>`).
2. In `compose.yml` eintragen, `docker compose pull && docker compose up -d`.
3. Vorher Backup der Volumes `umami-db` und `glitchtip-db`
   (`docker compose exec umami-db pg_dump -U umami umami > umami.sql`).

## Konfiguration der App

`config/app.json` (nicht eingecheckt, Vorlage `config/app.example.json`):

```json
{
  "UMAMI_URL": "https://statistik.example.org",
  "UMAMI_WEBSITE_ID": "00000000-0000-0000-0000-000000000000",
  "SENTRY_DSN": "https://key@fehler.example.org/1",
  "SENTRY_ENVIRONMENT": "prod"
}
```

Build mit `flutter build <ziel> --dart-define-from-file=config/app.json`.
In CI schreibt der Workflow die Datei aus Secrets oder Variables.

Hinweis Umami: Native Plattformen senden den User-Agent
`LINEFM-Radio/<version> (<os>)`. Umami filtert bekannte Bot-Kennungen; falls
Ereignisse nicht ankommen, im Dashboard und Serverlog pruefen. Browser setzen
den User-Agent selbst.

## Firebase (optional, getrennt)

Standard-Builds enthalten keinen Firebase-Code. Das Paket
`packages/linefm_firebase` steht nicht in `pubspec.yaml` und wird nur bei Bedarf
aktiviert (Android, iOS, macOS, Web; nicht Windows/Linux):

```bash
dart run tool/enable_firebase.dart            # Paket hinzufuegen, Hook ersetzen
dart run tool/enable_firebase.dart --merge-config   # CI: FIREBASE_CONFIG_JSON einmischen
dart run tool/enable_firebase.dart --disable  # zurueck zum Stub
```

Benoetigte Werte in `config/app.json`: `FIREBASE_ENABLED=true`,
`FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`,
`FIREBASE_APP_ID_ANDROID|IOS|MACOS|WEB`. Es wird weder `google-services.json`
noch `GoogleService-Info.plist` benoetigt. `FIREBASE_CONFIG_JSON` ist ein
JSON-Objekt mit diesen Schluesseln. Die Aktivierung veraendert
`pubspec.yaml`, `pubspec.lock` und `firebase_hook.dart`; diese Aenderungen nicht
committen.
