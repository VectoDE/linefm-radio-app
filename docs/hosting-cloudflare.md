# Hosting auf Cloudflare Pages

Überblick und Cache-Regeln: [hosting-uebersicht.md](hosting-uebersicht.md).

## Dateien

Der Postbuild legt `_headers` und `_redirects` in `build/web` (aus `deploy/cloudflare/`). Pages liest sie beim Deploy und liefert sie nicht aus. `deploy/cloudflare/wrangler.toml` enthält Projektname und Ausgabeordner.

- `_headers`: Security-Header für alle Pfade (`/*`), Cache-Control je Pfadgruppe nach der Cache-Strategie. Cache-Control steht absichtlich nur in den Pfadregeln, weil Pages die Header mehrerer passender Regeln zusammenführt.
- `_redirects`: `/* /index.html 200` für das SPA-Routing. Vorhandene Dateien liefert Pages zuerst, auch `/impressum/` und `/datenschutz/`.
- ETags setzt Pages selbst.

## Einmalige Einrichtung (Betreiber)

1. Im Cloudflare-Dashboard unter Workers & Pages ein Pages-Projekt `linefm-app` anlegen (Direct Upload).
2. Eigene Domain `app.linefm.de` unter "Custom domains" hinzufügen. Liegt `linefm.de` bei Cloudflare, legt Cloudflare den CNAME selbst an, sonst wird ein CNAME auf `linefm-app.pages.dev` beim DNS-Anbieter gesetzt.
3. API-Token mit Berechtigung "Cloudflare Pages: Edit" erstellen. Als GitHub-Secrets `CLOUDFLARE_API_TOKEN` und `CLOUDFLARE_ACCOUNT_ID` eintragen, damit `deploy-web.yml` (Paket P27) automatisch ausrollt.

## Deploy von Hand

```bash
# im Repo-Wurzelordner, nach Build + Postbuild (dart run tool/web_postbuild.dart build/web --targets cloudflare)
npx wrangler pages deploy build/web --project-name linefm-app
```

Rollback: im Dashboard bei Deployments ein früheres Deployment auswählen und "Rollback to this deployment".

## Lokal prüfen

```bash
npx wrangler pages dev build/web
curl -sI http://localhost:8788/ | grep -iE 'content-security|cache-control'
```

## Grenzen

- Fehlende Pfade unter `/impressum/` und `/datenschutz/` liefern über `/* /index.html 200` die App statt eines 404. Pages kann einzelne Pfade nicht per `_redirects` auf 404 setzen. Das betrifft nur falsch eingetippte Adressen.
- Ebenso liefert eine fehlende Datei mit Endung die App. Browser-Folgen gibt es nicht, weil die App ihre Dateien nur über die gehashten Namen lädt.
- `_headers` erlaubt höchstens 100 Regeln mit je 2000 Zeichen. Die CSP liegt deutlich darunter. Kommen viele Telemetrie-Domains dazu, Länge prüfen.
- Pages entscheidet über Kompression selbst (Brotli/gzip). Einstellen lässt sich das nicht.
