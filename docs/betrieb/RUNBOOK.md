# Betriebshandbuch

Für den Betrieb der Web-Version unter https://app.linefm.de und für die Veröffentlichung der App-Pakete. Zielgruppe: jaybelife als Betreiber, dazu ein Entwickler, der später einspringt. Meldewege bei Störungen: [INCIDENT.md](INCIDENT.md).

Die App hat kein Backend, keine Datenbank und keine Konten. Es gibt nichts, was gesichert oder aus einem Backup zurückgespielt werden müsste. Der Betrieb besteht aus drei Dingen: statische Web-Dateien ausliefern, die Fremddienste im Blick behalten (laut.fm, Stream, Cover-Suche) und Releases bei Bedarf zurücknehmen.

## Was läuft wo

| Baustein | Wer betreibt ihn | Ausfall wirkt |
|---|---|---|
| Web-Dateien unter app.linefm.de | Betreiber (nginx, Traefik, Cloudflare Pages oder Plesk) | Web-Version nicht erreichbar. Installierte Apps laufen weiter. |
| api.laut.fm (Titel, Sender, Verlauf) | laut.fm | Kein Titel- und Coverwechsel. Der Stream läuft weiter. |
| stream.laut.fm (Audio) | laut.fm | Kein Ton. Die App zeigt einen Fehler und versucht es erneut. |
| itunes.apple.com (Cover) | Apple | Statt Cover erscheint das Senderlogo. |
| cdn.linefm.de (Senderlogos in der Web-Version) | Betreiber | Logos fehlen. |
| Telemetrie (Umami, GlitchTip, Sentry, Firebase) | je nach Einrichtung | Keine Statistik. Die App läuft weiter. |
| GitHub (Quellcode, Releases, CI) | GitHub | Keine neuen Releases. Ausgelieferte Versionen laufen weiter. |

Die Senderliste ist fest in der App. Ändert sich ein Stream-Link bei laut.fm, hilft nur ein App-Update (siehe [ADR 0003](../adr/0003-senderliste-fest-im-code.md)).

## Überwachung (Uptime-Monitor)

Der Workflow `.github/workflows/uptime.yml` prüft alle 30 Minuten die Web-Version und `api.laut.fm`. Er läuft nur, wenn die Repository-Variable `WEB_BASE_URL` gesetzt ist (Einstellungen > Secrets and variables > Actions > Variables, Wert `https://app.linefm.de`). Ohne die Variable überspringt er sich mit einem Hinweis.

- Bei einem Fehler legt der Workflow ein Issue mit dem Label `uptime` an. Gibt es schon ein offenes Uptime-Issue, kommentiert er dort, statt ein neues anzulegen.
- Das Issue schließt der Betreiber von Hand, wenn die Störung behoben ist. Der Workflow schließt nichts.
- GitHub benachrichtigt über die üblichen Wege (E-Mail, Mobile App), wenn man das Repository beobachtet.
- Grenzen: GitHub führt geplante Workflows nicht auf die Minute genau aus und kann sie bei hoher Last verzögern. Das ist ein Hinweisgeber, kein Dienst mit Zusage. Wer eine Alarmierung per SMS oder Anruf will, braucht einen eigenen Monitor-Dienst. Das ist eine Entscheidung des Betreibers und nicht eingerichtet.

## Deploy

Der Normalweg ist der Workflow `deploy-web.yml`. Er rollt das Web-Artefakt aus einem GitHub-Release auf die Ziele aus der Variable `WEB_DEPLOY_TARGETS` aus (`cloudflare`, `ssh`, `plesk`). Die Einrichtung der Secrets steht in [../secrets.md](../secrets.md), die Server-Einrichtung in den Dokumenten `hosting-*.md`.

Von Hand startet man ihn unter Actions > Deploy Web > Run workflow mit dem Tag (Form `vX.Y.Z`) und optional den Zielen. Das Ziel `production` verlangt einen Genehmiger, sofern er in den Umgebungseinstellungen gesetzt ist.

Nach jedem Deploy prüfen:

```bash
curl -sI https://app.linefm.de/ | head -1                          # 200
curl -sI https://app.linefm.de/radio/favoriten | head -1           # 200, die App-Seite
curl -s  https://app.linefm.de/version.json                        # die erwartete Version
```

## Rollback

Jedes Release bleibt im GitHub-Release erhalten. Der universelle Weg ist deshalb: den Workflow Deploy Web mit dem **Tag der letzten guten Version** erneut starten. Das funktioniert für alle vier Ziele. Zusätzlich gibt es je Ziel einen schnelleren Weg.

| Ziel | Schneller Rollback | Dauer |
|---|---|---|
| nginx (native Installation, Ziel `ssh`) | Symlink `current` auf den vorherigen Ordner in `releases/` setzen: `ln -sfn <alt> current.new && mv -Tf current.new current`. Der Workflow behält die letzten fünf Releases. | Sekunden |
| Traefik mit Docker Compose | In `.env` das vorherige Image-Tag eintragen (`WEB_IMAGE=...:<alte Version>`), dann `docker compose up -d`. Setzt voraus, dass Images mit Versions-Tag gebaut wurden. | Minuten |
| Cloudflare Pages | Im Dashboard unter Workers & Pages > linefm-app > Deployments ein früheres Deployment wählen und "Rollback to this deployment". | Sekunden |
| Plesk | Kein Schnellweg. Der Dokumentstamm wird überschrieben. Workflow mit altem Tag starten. Wer es schneller braucht, legt vor jedem Deploy ein Plesk-Backup an. | Minuten |

Nach dem Rollback die Prüfbefehle von oben ausführen. Danach ein Issue für die Ursache anlegen (Vorlage in [INCIDENT.md](INCIDENT.md)). Beim Zurücknehmen auf eine Version, die andere Header-Dateien braucht, die Header-Dateien aus `build/hosting/` derselben Version einspielen. Die Content-Security-Policy ist an die Telemetrie-Einstellungen der jeweiligen Version gebunden.

## Wiederherstellung (Disaster Recovery)

Es gibt keine Betreiberdaten, die verloren gehen können. Nutzerdaten (Favoriten, Verlauf, Einstellungen) liegen nur auf dem Gerät des Nutzers. Das Repository ist die Quelle für alles andere.

| Was ist weg | Wiederherstellung |
|---|---|
| Webserver oder Hosting-Konto | Neuen Server nach `hosting-*.md` einrichten, DNS umstellen, Deploy Web mit dem aktuellen Tag starten. Die Secrets stehen im Passwortmanager des Betreibers, nicht im Repository. |
| Domain app.linefm.de | DNS beim Anbieter wiederherstellen. Die Domain gehört dem Betreiber. Ohne sie funktionieren Share-Links und Deep Links nicht. |
| GitHub-Repository | Jede Entwickler-Kopie (`git clone`) enthält den vollständigen Stand samt Historie. Einen weiteren Dienst, der das Repository spiegelt, gibt es nicht. Empfehlung: ein zweiter Mensch mit Admin-Zugang und eine Klon-Kopie auf einem eigenen Rechner. |
| Signaturschlüssel Android (Upload-Keystore) | Nur im Passwortmanager des Betreibers. Ohne Sicherung kann die Play Console einen Upload-Key-Reset anbieten (Google-Verfahren, Dauer offen). **Der Betreiber muss prüfen, dass die Sicherung existiert.** |
| Apple-, Microsoft- und Play-Konten | Wiederherstellung über den jeweiligen Anbieter. Nicht Teil des Repositories. |
| Telemetrie-Server (Umami, GlitchTip) | Nur nötig, wenn selbst gehostet. Dann Volumes laut `deploy/telemetry/` sichern. Ein Verlust ist nur Statistik, kein Funktionsverlust. |

**Nicht getestet:** Ein Wiederherstellungstest auf einem frischen Server ist noch nicht gelaufen, weil bisher kein Zielserver eingerichtet ist (Stand 21.11.2026). Nach der ersten Einrichtung einmal den kompletten Weg üben: leerer Server, Deploy Web, Prüfbefehle, Rollback. Das Ergebnis hier eintragen.

## Zertifikate und Domain

- nginx und Traefik: Let's Encrypt erneuert automatisch (certbot-Timer bzw. certresolver). Einmal im Quartal prüfen, dass das Ablaufdatum in der Zukunft liegt: `echo | openssl s_client -connect app.linefm.de:443 -servername app.linefm.de 2>/dev/null | openssl x509 -noout -enddate`.
- Cloudflare Pages: Zertifikat automatisch.
- Domain-Verlängerung: beim Registrar des Betreibers.

## Release der Apps

Ablauf und Prüfung der Signaturen: [../RELEASE-VERIFIZIEREN.md](../RELEASE-VERIFIZIEREN.md), Store-Pipelines: [../stores-pipelines.md](../stores-pipelines.md), Freigaben: [../FREIGABE-CHECKLISTE.md](../FREIGABE-CHECKLISTE.md). Eine veröffentlichte App-Version lässt sich im Store nicht zurücknehmen. Man veröffentlicht eine neue, höhere Version mit dem alten Stand oder stoppt den gestaffelten Rollout in der Play Console bzw. App Store Connect (falls so eingerichtet).

## Regelmäßig

| Wann | Was |
|---|---|
| bei jeder Meldung des Uptime-Monitors | [INCIDENT.md](INCIDENT.md) |
| monatlich | Offene Dependabot-Pull-Requests ansehen, Security-Meldungen im Reiter Security lesen |
| quartalsweise | Zertifikatsablauf, die laut.fm-Schnittstelle prüfen (`flutter test tool/dev/now_playing_probe.dart`, macht echte Anfragen, Dauer über `PROBE_MINUTES`), Wiederherstellungsübung |
| bei jedem Flutter-Update | `dart run tool/fetch_font_fallback.dart --check-sdk`, siehe [../hosting-uebersicht.md](../hosting-uebersicht.md) |
