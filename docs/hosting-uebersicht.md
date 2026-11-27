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
- Ersatzschriften: Für Zeichen, die Poppins und Syncopate nicht kennen (Emoji, Kyrillisch, Griechisch, CJK, Symbole), lädt die Engine Noto-Schriften von `fontFallbackBaseUrl`. Das Bootstrap setzt dafür `assets/fonts/fallback/`. Nach `flutter build web` und vor dem Postbuild legt `dart run tool/fetch_font_fallback.dart build/web` die Dateien dort ab: 728 Schriftdateien aus der Sperrdatei, 9,2 MiB ohne CJK und 25,2 MiB CJK (34,4 MiB). Mit `OFL.txt` und dem von Flutter selbst abgelegten `Roboto-Regular.ttf` liegen im Ordner 730 Dateien mit 34,6 MiB. Fehlt `assets/fonts/OFL.txt`, bricht das Werkzeug ab; der Postbuild prüft ebenfalls, dass neben den Schriften `OFL.txt` liegt. Jede Datei wird gegen die Prüfsumme aus `tool/font_fallback.lock.json` geprüft. Ausgeliefert wird nur, was ein Text wirklich braucht; ein Besucher mit deutschen Songtiteln lädt keine dieser Dateien. Wer Platz sparen muss, nimmt `--groups core`, dann fehlen nur chinesische, japanische und koreanische Zeichen. Nach jedem Flutter-Update `--check-sdk` laufen lassen und bei Abweichung `--update-lock`; die CI bricht mit `--strict` ab, wenn die Liste nicht mehr zum SDK passt. Fehlt der Ordner, warnt der Postbuild (mit `--strict` bricht er ab).
- `web_postbuild.dart` macht Folgendes (Details im Kopf der Datei):
  1. Hängt einen Inhalts-Hash an `main.dart.js/.wasm/.mjs` und trägt die neuen Namen im Bootstrap ein.
  2. Verschiebt `canvaskit/` nach `canvaskit/<engineRevision>/`, damit auch diese Dateien dauerhaft gecacht werden dürfen.
  3. Setzt Basis-URL, Search-Console-Token (`GSC_VERIFICATION`) und Build-ID des Service Workers.
  4. Schreibt die Hosting-Dateien mit der fertigen CSP: `_headers`, `_redirects`, `.htaccess` in `build/web`, alle übrigen nach `build/hosting/`.
  5. Entfernt Ballast: Sourcemaps (`*.map`), Debug-Symbole (`*.symbols`), die ungenutzten Engine-Varianten `wimp.*` und `webparagraph/` sowie die Flutter-Standarddateien `flutter.js` und `flutter_service_worker.js`. Das spart rund 16 MB im Ausrollordner (49,5 auf 33,3 MB, Messung unten). Behalten wird alles, was `flutter_bootstrap.js` laden kann: `main.<hash>.dart.wasm` mit `skwasm` und `skwasm_heavy`, der dart2js-Rückfall mit `canvaskit/chromium/` (Chromium) und `canvaskit/canvaskit.*` (Firefox, Safari). Wer die Debug-Dateien für eine Fehleranalyse braucht, startet den Postbuild mit `--keep-debug`.
  6. Erzeugt `asset-manifest.txt` mit SHA-256 und Größe jeder Datei.

Optionen: `--config`, `--csp-connect-extra`, `--targets cloudflare,plesk|none`, `--deploy-dir`, `--hosting-out`, `--base-url`, `--gsc`, `--keep-debug`. Ohne `--csp-connect-extra` werden die Telemetrie-Domains aus `config/app.json` abgeleitet (`UMAMI_URL`, `SENTRY_DSN`, `FIREBASE_ENABLED`). Wer die Server-Konfiguration einmal ohne Build rendern will, setzt `CSP_CONNECT_EXTRA` als Umgebungsvariable.

**Keine `.htaccess` auf Cloudflare Pages:** Ohne `--targets` legt der Postbuild `_headers`, `_redirects` und `.htaccess` in `build/web`. Pages liefert jede Datei im Ausgabeordner öffentlich aus, auch `/.htaccess`. Wer von Hand auf Pages hochlädt, nimmt deshalb `--targets cloudflare` oder löscht `build/web/.htaccess` vor dem Upload. Der Workflow `deploy-web.yml` erledigt das selbst (`rm -f build/web/.htaccess` vor `pages deploy`). Auf nginx-Servern, auch in den Plesk-Zusatzanweisungen, sperren die mitgelieferten Regeln versteckte Dateien wie `/.htaccess` und dazu `/_headers` mit 404; Apache gibt `.htaccess` von sich aus nicht heraus.

Wichtig: **Nach jeder Änderung der Telemetrie-Einstellungen neu bauen und die gerenderten Header-Dateien neu ausrollen.** Sonst blockiert die CSP die neuen Domains.

### Ersatzschriften: CJK-Gruppe bleibt (Abwägung)

Gemessen am Build vom 19.11.2026 (`build/web/assets/fonts/fallback/`): 730 Dateien mit 34,6 MiB (728 Schriften, `OFL.txt`, `Roboto-Regular.ttf`). Davon gehören 568 Dateien mit 25,2 MiB zur CJK-Gruppe (Noto Sans SC, TC, HK, JP, KR). Die größte einzelne Datei hat 4,0 MiB. Der ganze Ausrollordner hat mit Ersatzschriften 799 Dateien und 69,8 MB.

Entscheidung: Die CJK-Gruppe bleibt im Build.

- Geladen wird sie nur, wenn ein Songtitel chinesische, japanische oder koreanische Zeichen enthält, und dann nur die Teil-Dateien für genau diese Zeichen. Wer deutsche oder englische Titel hört, lädt nichts davon.
- Fehlt sie, zeigt die App solche Titel als Kästchen. Bei Sendern mit K-Pop- oder Anime-Titeln wäre das ein sichtbarer Fehler.
- Cloudflare Pages erlaubt 20 000 Dateien je Deployment und 25 MiB je Datei. Mit 799 Dateien und höchstens 4,0 MiB je Datei liegt der Build weit darunter. nginx, Traefik und Plesk haben keine solche Grenze.
- Kosten: Speicher und Upload-Zeit beim Ausrollen, sonst nichts. Dank `immutable` lädt ein Browser jede Datei höchstens einmal.

Wer Platz sparen muss, baut mit `--groups core` und nimmt die Kästchen in Kauf.

## Cache-Strategie

| Pfad | Cache-Control | Grund |
|---|---|---|
| `/`, `/index.html`, `/flutter_bootstrap.js`, `/sw.js`, `/manifest.webmanifest`, `/version.json`, `/asset-manifest.txt`, `/impressum/`, `/datenschutz/` | `no-cache` | Immer beim Server nachfragen. Mit ETag ist die Antwort meist ein billiges 304. |
| `/main.<hash>.dart.js|mjs|wasm`, `/canvaskit/<revision>/**` | `public, max-age=31536000, immutable` | Der Hash steht im Dateinamen. Neue Version heißt neuer Name. |
| `/assets/AssetManifest.*`, `/assets/FontManifest.json`, `/assets/NOTICES` | `no-cache` | Fester Dateiname, aber der Inhalt ändert sich mit jedem Build. Mit einem Tag Cache bekäme ein Nutzer nach einem Update bis zu 24 Stunden ein altes Manifest zu neuen Dateien. |
| `/assets/fonts/fallback/**` | `public, max-age=31536000, immutable` | Ersatzschriften liegen unter versionierten Pfaden (`notosans/v39/<hash>.woff2`). Eine neue Schriftversion bekommt einen neuen Pfad. |
| übrige `/assets/**`, `/icons/**`, `/favicon.png` | `public, max-age=86400, stale-while-revalidate=604800` | Nicht gehasht, ändert sich selten. |
| `/robots.txt`, `/sitemap.xml`, `/llms.txt` | `public, max-age=3600` | Crawler sollen Änderungen innerhalb einer Stunde sehen. |

ETag setzen nginx (`etag on`), Apache (`FileETag MTime Size`) und Cloudflare Pages selbst. Komprimiert werden `html`, `js`, `mjs`, `wasm`, `json`, `css`, `svg`, `txt`, `xml`, das Manifest, Schriften (`otf`, `ttf`) und `application/octet-stream`. Letzteres ist wichtig: `assets/NOTICES` (1,4 MB, ohne Dateiendung) und `AssetManifest.bin` liefern nginx und Apache als `octet-stream`, ohne den Eintrag blieben sie unkomprimiert. Brotli: Cloudflare Pages komprimiert selbst (Brotli und gzip). Bei nginx und Apache ist Brotli ein optionales Modul (Anleitung in den Hosting-Dokumenten). Ohne Modul gilt gzip, das reicht als Mindeststand. Wichtig sind die MIME-Typen `application/wasm` für `.wasm` und ein JavaScript-Typ für `.mjs`. Die mitgelieferten Konfigurationen setzen beides.

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

- Skripte: `'self'` und `'wasm-unsafe-eval'` (nötig, damit der Browser das Wasm-Modul kompiliert). Kein `unsafe-inline`, kein `unsafe-eval`. Dazu `https://www.gstatic.com` für Google Cast: `cast.js` lädt das Cast-Skript von dort erst, wenn jemand der Übertragung zugestimmt hat.
- Stile: `'self'` und `'unsafe-inline'`. **Dokumentierte Ausnahme:** Die Flutter-Engine setzt zur Laufzeit Inline-Stile (`style`-Attribute an `flt-*`-Elementen), und die statische Startseite bringt ein eigenes `<style>`. Beides lässt sich ohne Nonce oder Hash nicht erlauben, und ein Nonce pro Antwort geht bei statischem Hosting nicht. Das Risiko ist begrenzt, weil `script-src` kein `unsafe-inline` hat: Wer Stile einschleust, führt dadurch keinen Code aus. Wird die Ausnahme eng, wäre der Weg ein Hash für das Start-`<style>` und, sobald die Engine es erlaubt, der Verzicht auf `unsafe-inline`. Vor jedem Flutter-Update neu prüfen.
- Bilder und Abrufe: `api.laut.fm` (auch `wss:`), `itunes.apple.com`, `*.mzstatic.com` (Cover), `cdn.linefm.de` (Senderlogos), `assets.laut.fm`, `radiogruppe.de` (RadioGruppe-Logo).
- Audio: `*.laut.fm` (Streams laufen über `<sender>.stream.laut.fm`).
- Zusätzlich je nach Konfiguration die Telemetrie-Domains.

Bewusste Entscheidungen:

- **Kein COEP (`Cross-Origin-Embedder-Policy`).** Mit `require-corp` bräuchten Cover und Logos von Fremdservern CORP-Header. Folge: Skwasm läuft einthreadig. Das ist für diese App unproblematisch.
- **HSTS mit `preload`.** Der Header allein trägt die Domain nicht in die Preload-Liste ein. Eine Anmeldung auf hstspreload.org ist ein eigener Schritt und betrifft `linefm.de` samt allen Subdomains. Das entscheidet der Betreiber der Hauptdomain.
- **`interest-cohort` fehlt in der Permissions-Policy**, weil Chrome das Feature nicht mehr kennt und dafür eine Konsolenwarnung ausgibt.

## Automatische Prüfung in der CI

Die CI (`.github/workflows/ci.yml`) prüft die Hosting-Dateien in drei Stufen. Docker-Images werden nur dort gebaut, nie auf dem Entwicklungsrechner.

| Job | Was er prüft |
|---|---|
| „Hosting config“ | `tool/hosting_check.py consistency`: Security-Header (Namen und Werte, vor allem die CSP) sind in nginx-Snippet, Plesk-nginx, `.htaccess` und Cloudflare `_headers` identisch; alle vier nutzen dieselben Cache-Control-Werte; für rund 30 Beispielpfade liefern `.htaccess`, Plesk-nginx und `_headers` dasselbe Cache-Control. Dazu `docker compose config`, `nginx -t` und `httpd -t` mit gepinnten Images (`tool/check_hosting_config.sh`). Bei einer Abweichung schlägt der Job fehl. |
| „Hosting smoke (nginx)“ | Baut das Image aus `deploy/nginx/docker-compose.yml` mit dem echten Web-Build und prüft es mit `tool/hosting_check.py smoke`: Header exakt und einmalig, Cache je Pfad, ETag und 304, gzip, MIME-Typen, SPA-Fallback, 404 für fehlende Dateien, gesperrte Hosting- und Punktdateien, `/healthz`. |
| „Hosting smoke (traefik)“ | Dasselbe hinter einem echten Traefik (Docker-Provider, Compose-Labels aus `deploy/traefik`, Standardzertifikat statt Let's Encrypt), zusätzlich HTTP-zu-HTTPS-Weiterleitung. |
| „Hosting smoke (apache)“ | Apache 2.4 mit der gerenderten `.htaccess` aus `deploy/plesk` (`AllowOverride All`). |

Nicht abgedeckt: Cloudflare Pages selbst (nur die Header-Konsistenz, Ausrollen über `deploy-web.yml`) und eine echte Plesk-Installation. Beides prüft der Betreiber nach dem Einrichten mit den `curl`-Befehlen unten.

Die Ladezeit vorher/nachher misst `performance.yml`: Lighthouse gegen einen unkonfigurierten nginx (keine Kompression, keine Cache-Header) und gegen den Projekt-Container, gleicher Build, gleicher Runner. Die Tabelle steht in der Zusammenfassung des Laufs (Job „Web measure (lighthouse)“), siehe [PERFORMANCE.md](PERFORMANCE.md).

## Prüfen am echten Host

```bash
curl -sI https://app.linefm.de/ | grep -iE 'content-security|strict-transport|etag|cache-control'
curl -sI https://app.linefm.de/main.*.dart.wasm   # Dateinamen aus asset-manifest.txt nehmen
curl -sI -H 'If-None-Match: <etag>' https://app.linefm.de/   # erwartet 304
```

## Größe des Ausrollordners und Startsatz (gemessen)

Messung am 19.11.2026 mit `flutter build web --release --wasm --no-web-resources-cdn`, Postbuild vorher und nachher, lokal ohne Kompression, **ohne** Ersatzschriften (die kommen mit 729 Dateien und rund 34,6 MiB dazu: 728 Schriften plus `OFL.txt`; `Roboto-Regular.ttf` liegt schon in den 70 Basisdateien, siehe oben):

| | vorher | nachher |
|---|---|---|
| Ausrollordner (Bytes) | 49 527 699 (84 Dateien) | 33 342 939 (70 Dateien) |
| Start in Chromium mit Wasm (übertragen, Bytes) | 8 206 471 | 8 206 295 |
| Start in Chromium mit erzwungenem dart2js-Rückfall (Bytes) | 10 604 659 | 10 604 483 |

Der Startsatz bleibt gleich, weil der Browser die entfernten Dateien nie geladen hat. Der Gewinn liegt bei Deploy-Zeit, Speicher und Cache-Größe. Beide Startwege laufen nach dem Postbuild ohne 404 und ohne Seitenfehler, geprüft mit Playwright in Chromium (Rückfall erzwungen, indem `WebAssembly.validate` auf `false` gesetzt wird). Firefox und Safari wurden nicht geprüft. Ihr Rückfall nutzt `canvaskit/canvaskit.wasm`, die Datei bleibt erhalten.

Danach [Mozilla HTTP Observatory](https://developer.mozilla.org/en-US/observatory) und SSL Labs laufen lassen. Ziel ist A+ bei beiden. Die Messung am echten Host erfolgt nach dem ersten Deploy.
