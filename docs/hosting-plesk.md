# Hosting auf Plesk

Überblick und Cache-Regeln: [hosting-uebersicht.md](hosting-uebersicht.md).

**Hinweis zum Teststand:** Die Direktiven wurden gegen reines nginx und gegen die Syntax von Apache 2.4 geprüft, aber nicht auf einer echten Plesk-Installation. Nach dem Einrichten bitte mit den `curl`-Befehlen unten prüfen. Plesk-Versionen unterscheiden sich in den generierten Konfigurationen.

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

Secrets für den automatischen Deploy (`deploy-web.yml`, Paket P27): `PLESK_SFTP_HOST`, `PLESK_SFTP_USER`, `PLESK_SFTP_PASSWORD` oder ein SSH-Schlüssel sowie der Zielpfad. Der Betreiber trägt sie ein.

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
