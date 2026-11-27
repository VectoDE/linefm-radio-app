# Hosting auf Plesk

Überblick und Cache-Regeln: [hosting-uebersicht.md](hosting-uebersicht.md).

**Hinweis zum Teststand:** Die CI prüft die Direktiven auf Syntax (`nginx -t` in einem Server-Block, `httpd -t`), vergleicht Header und Cache-Regeln mit den anderen Zielen und startet die `.htaccess` in einem echten Apache 2.4 mit `AllowOverride All` (Job „Hosting smoke (apache)“). Auf einer echten Plesk-Installation sind sie noch nicht getestet. Nach dem Einrichten bitte mit den `curl`-Befehlen unten prüfen. Plesk-Versionen unterscheiden sich in den generierten Konfigurationen.

## Welche Variante?

In Plesk unter Websites & Domains > `app.linefm.de` > Apache & nginx-Einstellungen:

| Einstellung in Plesk | Verwendete Datei |
|---|---|
| "Proxy-Modus" aus (nur Apache) | `.htaccess` (liegt nach dem Postbuild in `build/web`) |
| Proxy-Modus an und "Intelligente Verarbeitung statischer Dateien" **aus** | `.htaccess` für Apache |
| Reines nginx (Plesk-Variante ohne Apache) oder statische Dateien über nginx | `nginx-additional.conf` in "Zusätzliche nginx-Anweisungen" |

Immer nur **eine** der beiden Header-Quellen verwenden. Sonst entstehen doppelte Header. Für die nginx-Variante den Postbuild mit `--targets cloudflare` starten, dann liegt keine `.htaccess` im Upload. (Die `.htaccess` aus dem Upload löschen reicht ebenfalls.)

## Einrichtung (einmalig)

1. Domain `app.linefm.de` anlegen, Dokumentstamm z. B. `httpdocs`.
2. SSL/TLS-Zertifikate: Let's Encrypt aktivieren (Wildcard nicht nötig). "Permanente SEO-sichere 301-Weiterleitung von HTTP auf HTTPS" einschalten.
3. Hosting & DNS > Apache & nginx-Einstellungen: "Intelligente Verarbeitung statischer Dateien" deaktivieren, sonst liefert nginx statische Dateien ohne die Header.
4. Bei der nginx-Variante den Inhalt von `deploy/plesk/nginx-additional.conf` (gerendert: `build/hosting/plesk/nginx-additional.conf`) in "Zusätzliche nginx-Anweisungen" einfügen und speichern. Plesk prüft die Syntax und weist Fehler ab.
5. PHP für die Domain deaktivieren (wird nicht gebraucht).

## Deploy

**SFTP/SSH:** Inhalt von `build/web/` in den Dokumentstamm hochladen (`rsync -a --delete build/web/ user@host:httpdocs/`). Die Datei `.htaccess` muss mit hochgeladen werden (versteckte Datei).

**Git-Erweiterung von Plesk:** Ein Repository mit dem fertigen `build/web`-Inhalt anlegen (z. B. Branch `web-release`, vom Workflow befüllt) und in Plesk unter Git das Ziel "Dokumentstamm" wählen. Plesk zieht per Webhook oder von Hand.

**Automatisch per SSH (`deploy-web.yml`, Ziel `plesk`):** Der Workflow synchronisiert `build/web` per `rsync` über SSH in den Dokumentstamm. `.well-known/` (z. B. `assetlinks.json`) und `cgi-bin/` bleiben unberührt, die `.htaccess` aus dem Upload wird mitgeliefert. Voraussetzung ist ein Plesk-Abonnement mit SSH-Zugang und Schlüssel-Login (Plesk > Websites & Domains > Webspace-Zugang, Shell aktivieren, öffentlichen Schlüssel unter "SSH-Schlüssel" eintragen). Der Betreiber trägt die Secrets `PLESK_SSH_HOST`, `PLESK_SSH_USER`, `PLESK_SSH_KEY`, `PLESK_SSH_KNOWN_HOSTS` und die Variable `PLESK_DOCROOT` (z. B. `httpdocs`) ein, dazu `plesk` in `WEB_DEPLOY_TARGETS` ([secrets.md](secrets.md)). Passwort-Login per SFTP wird bewusst nicht unterstützt. Wer nur SFTP hat, nimmt die Git-Erweiterung oder lädt von Hand hoch.

## Komprimierung und Brotli

Beide Varianten komprimieren auch `application/octet-stream` und Schriften, damit `assets/NOTICES` und `AssetManifest.bin` nicht unkomprimiert rausgehen. Brotli geht bei Plesk nur, wenn der Server `mod_brotli` (Apache) bzw. `ngx_brotli` (nginx) mitbringt. Plesk liefert beides nicht fest mit. Fehlt das Modul, bleibt gzip aktiv. Prüfen mit `curl -sI -H 'Accept-Encoding: br' https://app.linefm.de/ | grep -i content-encoding`. Der Build legt vorkomprimierte `.gz`- und `.br`-Dateien mit ab. Plesk-nginx nutzt sie erst, wenn `gzip_static on;` (bzw. mit ngx_brotli `brotli_static on;`) in `nginx-additional.conf` aktiv ist; die Zeile steht dort als Kommentar, weil nicht jede Plesk-Installation das Modul `http_gzip_static` mitbringt (Prüfung steht daneben). Apache allein nutzt die Dateien nicht und komprimiert weiter selbst.

## Was die Dateien tun

- `.htaccess`: Security-Header (`mod_headers`), Cache-Regeln, `AddType application/wasm`, ETag (`FileETag MTime Size`), Deflate, SPA-Fallback über `mod_rewrite`. Fehlende Dateien mit Endung und fehlende Rechtstext-Unterseiten liefern 404.
- `nginx-additional.conf`: dasselbe für nginx. Die Cache-Regeln laufen über eine Variable (`$linefm_cache`), damit alle `add_header` auf Server-Ebene stehen und von Plesks Locations geerbt werden.

## Prüfen

```bash
curl -sI https://app.linefm.de/ | grep -iE 'content-security|etag|cache-control'
curl -sI https://app.linefm.de/main.<hash>.dart.wasm | grep -iE 'content-type|cache-control'   # application/wasm, immutable
curl -sI https://app.linefm.de/impressum/ | head -1      # 200
curl -sI https://app.linefm.de/radio/favoriten | head -1 # 200 (SPA)
curl -sI https://app.linefm.de/gibtsnicht.js | head -1   # 404
```

Fehlt ein Header: In Plesk gibt es unter Apache & nginx-Einstellungen eine Vorschau der erzeugten Konfiguration. Prüfen, ob eine Plesk-eigene `location` mit eigenem `add_header` oder `expires` dazwischenfunkt.
