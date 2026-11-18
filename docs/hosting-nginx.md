# Hosting auf Ubuntu/Debian mit nginx

Für einen eigenen Server mit nativ installiertem nginx. Überblick und Cache-Regeln: [hosting-uebersicht.md](hosting-uebersicht.md).

## Dateien

| Datei im Repo | Ziel auf dem Server |
|---|---|
| `deploy/nginx/linefm-app.conf` | `/etc/nginx/sites-available/linefm-app.conf` (Symlink nach `sites-enabled/`) |
| `build/hosting/nginx/snippets/linefm-headers.conf` | `/etc/nginx/snippets/linefm-headers.conf` |
| `build/hosting/nginx/snippets/linefm-locations.conf` | `/etc/nginx/snippets/linefm-locations.conf` |
| `build/web/` | `/var/www/linefm-app/releases/<version>/` |

Die Snippets kommen aus `build/hosting/` (nach dem Postbuild), nicht aus `deploy/`. Nur dort ist `__CSP_CONNECT_EXTRA__` durch die Telemetrie-Domains ersetzt.

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

Der GitHub-Workflow `deploy-web.yml` (Paket P27) macht genau diese Schritte per SSH. Dafür trägt der Betreiber `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PATH`, `DEPLOY_KNOWN_HOSTS` als Secrets ein.

## Brotli (optional)

Mit dem Modul `libnginx-mod-http-brotli-filter` (Debian/Ubuntu-Paket) in `linefm-locations.conf` unter `gzip_types` ergänzen:

```nginx
brotli on;
brotli_comp_level 5;
brotli_types text/plain text/css text/xml application/xml application/json application/javascript text/javascript application/manifest+json application/wasm image/svg+xml;
```

## Traefik vor diesem nginx

Siehe [hosting-traefik.md](hosting-traefik.md), Abschnitt "Traefik vor nativem nginx".

## Prüfen

```bash
sudo nginx -t
curl -sI https://app.linefm.de/ | grep -iE 'content-security|etag|cache-control'
curl -sI https://app.linefm.de/impressum/ | head -1      # 200
curl -sI https://app.linefm.de/gibtsnicht.js | head -1   # 404
curl -sI https://app.linefm.de/radio/favoriten | head -1 # 200 (SPA)
```
