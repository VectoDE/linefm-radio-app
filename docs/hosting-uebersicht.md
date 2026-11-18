# Web-Hosting: Überblick

Die Web-Variante von LINEFM Radio läuft unter **https://app.linefm.de** und besteht aus statischen Dateien. Es braucht keinen Anwendungsserver und keine Datenbank. Diese Seite erklärt Build, Cache-Strategie und Header. Die Anleitung für das jeweilige Ziel steht in:

- [hosting-nginx.md](hosting-nginx.md): eigener Ubuntu-/Debian-Server mit nginx
- [hosting-traefik.md](hosting-traefik.md): Docker Compose hinter Traefik (oder Traefik vor nativem nginx)
- [hosting-cloudflare.md](hosting-cloudflare.md): Cloudflare Pages
- [hosting-plesk.md](hosting-plesk.md): Plesk (Apache oder nginx)

## Build

```bash
flutter build web --release --wasm --no-web-resources-cdn \
  --dart-define-from-file=config/app.json --base-href /
dart run tool/web_postbuild.dart build/web
```

- `--wasm`: Browser mit WasmGC laden `main.<hash>.dart.wasm`, alle anderen fallen automatisch auf `main.<hash>.dart.js` zurück.
- `--no-web-resources-cdn`: CanvasKit und Schriften kommen vom eigenen Server, nicht von `gstatic.com`. Dadurch gehen keine IP-Adressen an Google, und die CSP braucht keine Fremd-Skripte.
- `web_postbuild.dart` macht Folgendes (Details im Kopf der Datei):
  1. Hängt einen Inhalts-Hash an `main.dart.js/.wasm/.mjs` und trägt die neuen Namen im Bootstrap ein.
  2. Verschiebt `canvaskit/` nach `canvaskit/<engineRevision>/`, damit auch diese Dateien dauerhaft gecacht werden dürfen.
  3. Setzt Basis-URL, Search-Console-Token (`GSC_VERIFICATION`) und Build-ID des Service Workers.
  4. Schreibt die Hosting-Dateien mit der fertigen CSP: `_headers`, `_redirects`, `.htaccess` in `build/web`, alle übrigen nach `build/hosting/`.
  5. Erzeugt `asset-manifest.txt` mit SHA-256 und Größe jeder Datei.

Optionen: `--config`, `--csp-connect-extra`, `--targets cloudflare,plesk|none`, `--deploy-dir`, `--hosting-out`, `--base-url`, `--gsc`. Ohne `--csp-connect-extra` werden die Telemetrie-Domains aus `config/app.json` abgeleitet (`UMAMI_URL`, `SENTRY_DSN`, `FIREBASE_ENABLED`). Wer die Server-Konfiguration einmal ohne Build rendern will, setzt `CSP_CONNECT_EXTRA` als Umgebungsvariable.

Wichtig: **Nach jeder Änderung der Telemetrie-Einstellungen neu bauen und die gerenderten Header-Dateien neu ausrollen.** Sonst blockiert die CSP die neuen Domains.

## Cache-Strategie

| Pfad | Cache-Control | Grund |
|---|---|---|
| `/`, `/index.html`, `/flutter_bootstrap.js`, `/sw.js`, `/manifest.webmanifest`, `/version.json`, `/asset-manifest.txt`, `/impressum/`, `/datenschutz/` | `no-cache` | Immer beim Server nachfragen. Mit ETag ist die Antwort meist ein billiges 304. |
| `/main.<hash>.dart.js|mjs|wasm`, `/canvaskit/<revision>/**` | `public, max-age=31536000, immutable` | Der Hash steht im Dateinamen. Neue Version heißt neuer Name. |
| `/assets/**`, `/icons/**`, `/favicon.png` | `public, max-age=86400, stale-while-revalidate=604800` | Nicht gehasht, ändert sich selten. |
| `/robots.txt`, `/sitemap.xml`, `/llms.txt` | `public, max-age=3600` | Crawler sollen Änderungen innerhalb einer Stunde sehen. |

ETag setzen nginx (`etag on`), Apache (`FileETag MTime Size`) und Cloudflare Pages selbst. Komprimiert werden `html`, `js`, `mjs`, `wasm`, `json`, `css`, `svg`, `txt`, `xml` und das Manifest. Wichtig sind die MIME-Typen `application/wasm` für `.wasm` und ein JavaScript-Typ für `.mjs`. Die mitgelieferten Konfigurationen setzen beides.

## Routing

Die App nutzt Pfad-URLs. Alle Pfade ohne Dateiendung liefern `index.html`. Pfade mit Dateiendung, die es nicht gibt, liefern 404. Eine Ausnahme sind die statischen Rechtstext-Seiten unter `/impressum/` und `/datenschutz/` (jeweils mit `en/`): Sie sind eigene Dateien und fallen nie auf `index.html` zurück. Bei Cloudflare Pages ist das nicht vollständig machbar, siehe [hosting-cloudflare.md](hosting-cloudflare.md).

## Security-Header (alle Ziele identisch)

| Header | Wert |
|---|---|
| Content-Security-Policy | siehe unten |
| Strict-Transport-Security | `max-age=63072000; includeSubDomains; preload` |
| X-Content-Type-Options | `nosniff` |
| Referrer-Policy | `strict-origin-when-cross-origin` |
| Permissions-Policy | `camera=(), microphone=(), geolocation=(), payment=(), usb=()` |
| Cross-Origin-Opener-Policy | `same-origin` |
| Cross-Origin-Resource-Policy | `same-origin` |
| X-Frame-Options | `DENY` |

Die CSP erlaubt nur die eigene Herkunft, dazu gezielt:

- Skripte: `'self'` und `'wasm-unsafe-eval'` (nötig, damit der Browser das Wasm-Modul kompiliert). Kein `unsafe-inline`, kein `unsafe-eval`.
- Stile: `'self'` und `'unsafe-inline'`, weil Flutter-Web Inline-Stile setzt.
- Bilder und Abrufe: `api.laut.fm` (auch `wss:`), `itunes.apple.com`, `*.mzstatic.com` (Cover), `cdn.linefm.de` (Senderlogos), `assets.laut.fm`, `radiogruppe.de` (RadioGruppe-Logo).
- Audio: `*.laut.fm` (Streams laufen über `<sender>.stream.laut.fm`).
- Zusätzlich je nach Konfiguration die Telemetrie-Domains.

Bewusste Entscheidungen:

- **Kein COEP (`Cross-Origin-Embedder-Policy`).** Mit `require-corp` bräuchten Cover und Logos von Fremdservern CORP-Header. Folge: Skwasm läuft einthreadig. Das ist für diese App unproblematisch.
- **HSTS mit `preload`.** Der Header allein trägt die Domain nicht in die Preload-Liste ein. Eine Anmeldung auf hstspreload.org ist ein eigener Schritt und betrifft `linefm.de` samt allen Subdomains. Das entscheidet der Betreiber der Hauptdomain.
- **`interest-cohort` fehlt in der Permissions-Policy**, weil Chrome das Feature nicht mehr kennt und dafür eine Konsolenwarnung ausgibt.

## Prüfen am echten Host

```bash
curl -sI https://app.linefm.de/ | grep -iE 'content-security|strict-transport|etag|cache-control'
curl -sI https://app.linefm.de/main.*.dart.wasm   # Dateinamen aus asset-manifest.txt nehmen
curl -sI -H 'If-None-Match: <etag>' https://app.linefm.de/   # erwartet 304
```

Danach [Mozilla HTTP Observatory](https://developer.mozilla.org/en-US/observatory) und SSL Labs laufen lassen. Ziel ist A+ bei beiden. Die Messung am echten Host erfolgt nach dem ersten Deploy.
