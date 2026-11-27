# Hosting auf Ubuntu/Debian mit nginx

Für einen eigenen Server mit nativ installiertem nginx. Überblick und Cache-Regeln: [hosting-uebersicht.md](hosting-uebersicht.md).

## Dateien

| Datei im Repo | Ziel auf dem Server |
|---|---|
| `deploy/nginx/linefm-app.conf` | `/etc/nginx/sites-available/linefm-app.conf` (Symlink nach `sites-enabled/`) |
| `build/hosting/nginx/snippets/linefm-headers.conf` | `/etc/nginx/snippets/linefm-headers.conf` |
| `build/hosting/nginx/snippets/linefm-locations.conf` | `/etc/nginx/snippets/linefm-locations.conf` |
| `build/web/` | `/var/www/linefm-app/releases/<version>/` |

Die Snippets kommen aus `build/hosting/` (nach dem Postbuild), nicht aus `deploy/`. Nur dort sind `__CSP_CONNECT_EXTRA__`, `__CSP_SCRIPT_EXTRA__` und `__CSP_IMG_EXTRA__` ersetzt (Telemetrie-Domains; `https://www.gstatic.com` in `script-src` immer, für Google Cast, das erst nach Einwilligung lädt; Google-Tag-Quellen nur mit `GTM_ID` bzw. `GA4_MEASUREMENT_ID`, sonst leer).

## Einrichtung (einmalig)

1. nginx und certbot installieren: `sudo apt install nginx certbot`.
2. Ordner anlegen: `sudo mkdir -p /var/www/linefm-app/releases /var/www/certbot`.
3. Zertifikat holen. Vor dem ersten Start in `linefm-app.conf` den Block `listen 443` auskommentieren, dann:
   `sudo certbot certonly --webroot -w /var/www/certbot -d app.linefm.de`
   Anschließend den Block wieder aktivieren. Die Erneuerung läuft über den Timer von certbot.
4. Konfiguration einspielen (Tabelle oben), dann `sudo nginx -t && sudo systemctl reload nginx`.

## Deploy und Rollback

```bash
# lokal nach Build + Postbuild
V=$(date +%Y%m%d-%H%M%S)
rsync -a --delete build/web/ deploy@server:/var/www/linefm-app/releases/$V/
rsync -a build/hosting/nginx/snippets/ deploy@server:/tmp/linefm-snippets/   # nur bei geänderten Headern
ssh deploy@server "ln -sfn /var/www/linefm-app/releases/$V /var/www/linefm-app/current.new && mv -Tf /var/www/linefm-app/current.new /var/www/linefm-app/current"
```

`mv -T` tauscht den Symlink in einem Schritt, die Seite ist nie halb ausgerollt. **Rollback:** Symlink `current` auf den vorherigen Ordner stellen. Alte Releases mit `ls -t releases | tail -n +6 | xargs -I{} rm -rf releases/{}` aufräumen. Bei geänderten Headern die Snippets nach `/etc/nginx/snippets/` kopieren, `nginx -t` und `reload`.

Der GitHub-Workflow `deploy-web.yml` macht genau diese Schritte per SSH (Ziel `ssh`, Umgebung `production`). Dafür trägt der Betreiber die Secrets `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KNOWN_HOSTS` und die Variable `DEPLOY_PATH` ein, optional `DEPLOY_PORT` und `DEPLOY_RELOAD_COMMAND` (z. B. `sudo systemctl reload nginx`). Die Header-Snippets legt der Workflow unter `$DEPLOY_PATH/hosting/` ab, sie müssen bei Änderungen von Hand nach `/etc/nginx/snippets/`. Details in [secrets.md](secrets.md).

## OCSP-Stapling (bewusst aus)

`linefm-app.conf` setzt `ssl_stapling off`. Let's Encrypt hat die OCSP-Dienste 2025 abgeschaltet und setzt auf Zertifikatssperrlisten (CRL). Bei Zertifikaten ohne OCSP-Adresse ist `ssl_stapling on` wirkungslos und erzeugt nur Warnungen im Log. Stapling nur einschalten, wenn die Zertifizierungsstelle des eigenen Zertifikats noch OCSP anbietet (die Zeilen dazu stehen als Kommentar in der Datei). Bitte vor dem Ausrollen gegen die aktuelle Ankündigung von Let's Encrypt prüfen.

## Vorkomprimierte Dateien

`tool/web_postbuild.dart` legt neben jede komprimierbare Datei ab 1 KB eine `.gz`-Fassung (gzip 9) und, wenn `node` beim Bauen verfügbar ist, eine `.br`-Fassung (Brotli 11). `linefm-locations.conf` schaltet `gzip_static on` ein; nginx liefert dann die fertige `.gz`-Datei statt bei jeder Anfrage mit Stufe 5 zu komprimieren. Das Modul `http_gzip_static` steckt in den offiziellen nginx-Images und den Debian/Ubuntu-Paketen; prüfen mit `nginx -V 2>&1 | grep -o http_gzip_static_module`. Die `.br`-Dateien nutzt nginx nur mit ngx_brotli (`brotli_static on`, siehe unten). Wer nur Cloudflare Pages beliefert, baut mit `--no-precompress`.

## Brotli (optional)

Mit dem Modul `libnginx-mod-http-brotli-filter` (Debian/Ubuntu-Paket, für `.br`-Dateien zusätzlich `libnginx-mod-http-brotli-static` und `brotli_static on;`) in `linefm-locations.conf` unter `gzip_types` ergänzen. Die Typliste muss dieselben Typen enthalten wie `gzip_types`, vor allem `application/octet-stream` (NOTICES, AssetManifest.bin) und Schriften:

```nginx
brotli on;
brotli_comp_level 5;
brotli_types text/plain text/css text/xml application/xml application/json application/javascript text/javascript application/manifest+json application/wasm image/svg+xml application/octet-stream font/otf font/ttf application/vnd.ms-fontobject;
```

## nginx als Container (ohne Traefik)

`deploy/nginx/docker-compose.yml` startet denselben Container wie die Traefik-Variante (`deploy/traefik/Dockerfile`, gleiche Snippets), veröffentlicht Port 8080 aber nur auf `127.0.0.1`. TLS übernimmt ein vorgeschalteter Proxy, der auf `127.0.0.1:8080` weiterleitet. Bauen und Starten im Ordner `deploy/nginx` nach dem Postbuild: `docker compose up -d --build`. Über `WEB_BIND`, `WEB_PORT` und `WEB_IMAGE` lassen sich Adresse, Port und Image-Tag ändern. Die CI prüft sie mit `docker compose config`.

## Traefik vor diesem nginx

Siehe [hosting-traefik.md](hosting-traefik.md), Abschnitt "Traefik vor nativem nginx".

## Prüfen

Die CI prüft die Syntax von `linefm-app.conf` samt Snippets mit `nginx -t` im gepinnten nginx-Image (Job „Hosting config“, Skript `tool/check_hosting_config.sh`, mit Wegwerf-Zertifikat). Das belegt die Syntax, nicht das Verhalten auf dem Server. Dort vor jedem Reload `nginx -t` laufen lassen.

```bash
sudo nginx -t
curl -sI https://app.linefm.de/ | grep -iE 'content-security|etag|cache-control'
curl -sI https://app.linefm.de/impressum/ | head -1      # 200
curl -sI https://app.linefm.de/gibtsnicht.js | head -1   # 404
curl -sI https://app.linefm.de/radio/favoriten | head -1 # 200 (SPA)
```
