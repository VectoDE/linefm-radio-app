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

## Brotli (optional)

Mit dem Modul `libnginx-mod-http-brotli-filter` (Debian/Ubuntu-Paket) in `linefm-locations.conf` unter `gzip_types` ergänzen. Die Typliste muss dieselben Typen enthalten wie `gzip_types`, vor allem `application/octet-stream` (NOTICES, AssetManifest.bin) und Schriften:

```nginx
brotli on;
brotli_comp_level 5;
brotli_types text/plain text/css text/xml application/xml application/json application/javascript text/javascript application/manifest+json application/wasm image/svg+xml application/octet-stream font/otf font/ttf application/vnd.ms-fontobject;
```

## Traefik vor diesem nginx

Siehe [hosting-traefik.md](hosting-traefik.md), Abschnitt "Traefik vor nativem nginx".

## Prüfen

`nginx -t` stand in der Entwicklungsumgebung nicht zur Verfügung. Die Konfigurationen sind von Hand gegengelesen, nicht von nginx geprüft. Auf dem Server vor jedem Reload `nginx -t` laufen lassen.

```bash
sudo nginx -t
curl -sI https://app.linefm.de/ | grep -iE 'content-security|etag|cache-control'
curl -sI https://app.linefm.de/impressum/ | head -1      # 200
curl -sI https://app.linefm.de/gibtsnicht.js | head -1   # 404
curl -sI https://app.linefm.de/radio/favoriten | head -1 # 200 (SPA)
```
