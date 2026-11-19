# Hosting mit Traefik und Docker Compose

Für Server, auf denen bereits Traefik (v3) mit Docker-Provider und Let's-Encrypt-Resolver läuft. Überblick: [hosting-uebersicht.md](hosting-uebersicht.md).

## Aufbau

Ein nginx-Container (`nginxinc/nginx-unprivileged`, Version und SHA-256-Digest gepinnt) liefert die Web-Dateien aus. Traefik terminiert TLS und leitet an Port 8080 des Containers weiter. Cache-Regeln und Security-Header kommen ausschließlich aus dem Container, und zwar aus denselben Snippets wie beim nativen nginx. Der Container läuft schreibgeschützt, ohne Linux-Capabilities und mit `no-new-privileges`.

## Start

```bash
# im Repo-Wurzelordner
flutter build web --release --wasm --no-web-resources-cdn --dart-define-from-file=config/app.json --base-href /
dart run tool/web_postbuild.dart build/web

cd deploy/traefik
cp .env.example .env     # Host, Netzwerk- und Resolver-Namen anpassen
docker compose up -d --build
```

In `.env` stehen nur Namen, keine Zugangsdaten:

| Variable | Bedeutung | Standard |
|---|---|---|
| `APP_HOST` | Domain | `app.linefm.de` |
| `TRAEFIK_NETWORK` | externes Docker-Netzwerk von Traefik | `traefik` |
| `TRAEFIK_ENTRYPOINT_SECURE` / `_HTTP` | Entrypoints | `websecure` / `web` |
| `TRAEFIK_CERTRESOLVER` | Name des certresolvers in der Traefik-Konfiguration | `letsencrypt` |
| `WEB_IMAGE` | Image-Name, z. B. `ghcr.io/vectode/linefm-radio-app-web:1.0.0` | `linefm-app-web:local` |

Traefik darf nur das Netzwerk `TRAEFIK_NETWORK` mit dem Container teilen. Der HTTP-Router leitet per `redirectscheme` auf HTTPS um. Wer das schon global in Traefik macht, löscht die Labels `linefm-app-http` und `linefm-https`.

## Update und Rollback

Neuer Build, dann `docker compose up -d --build`. Für Rollbacks Images mit Versions-Tag bauen (`WEB_IMAGE=...:1.0.1`) und den alten Tag wieder eintragen.

Basisimage aktualisieren: neuen Digest holen (`docker buildx imagetools inspect nginxinc/nginx-unprivileged:1.30-alpine`), in `deploy/traefik/Dockerfile` ersetzen, neu bauen. Dependabot kann das für Dockerfiles übernehmen.

## Kompression

nginx komprimiert mit gzip. Das Label `linefm-compress` (Traefik-Middleware) bleibt aktiv, Traefik fasst bereits kodierte Antworten aber nicht erneut an. Wer Brotli will, nutzt das Brotli-Modul im Image oder schaltet gzip in `linefm-locations.conf` ab und lässt Traefik komprimieren. Traefik v3 kann in der Compress-Middleware auch Brotli und zstd. Die Typliste von nginx enthält `application/octet-stream` und Schriften, damit `NOTICES` und `AssetManifest.bin` mitkomprimiert werden. Danach ETag und `Vary: Accept-Encoding` mit `curl -sI -H 'Accept-Encoding: br'` prüfen.

## Traefik vor nativem nginx

Läuft die Seite nativ (siehe [hosting-nginx.md](hosting-nginx.md)), kann Traefik davor sitzen:

1. In der nginx-Konfiguration einen zusätzlichen Klartext-Server auf `listen 127.0.0.1:8080;` anlegen, der dieselbe `root` und `include snippets/linefm-locations.conf;` nutzt.
2. `deploy/traefik/traefik-native-nginx.dynamic.yml` in das Verzeichnis des File-Providers legen. Router, Resolver und Ziel-URL (`host.docker.internal:8080` oder die Docker-Gateway-IP) anpassen.

TLS-Zertifikate verwaltet dann Traefik, der nginx braucht keine.

## Prüfen

```bash
docker compose ps                       # web: healthy
curl -sI https://app.linefm.de/ | grep -iE 'content-security|etag|cache-control'
```
