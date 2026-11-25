# Bedrohungsmodell

Eine Betrachtung nach STRIDE entlang der echten Datenflüsse von LINEFM Radio. Stand 25.11.2026 (Pentest-Runde 1), abgeleitet aus dem Quellcode und den Konfigurationen im Repository. Es ist eine Arbeitsgrundlage, kein Gutachten und keine Zusage. Gemeldete Lücken: [../../SECURITY.md](../../SECURITY.md). Vorfälle: [INCIDENT.md](INCIDENT.md).

STRIDE steht für Spoofing (Vortäuschen einer Identität), Tampering (Manipulation), Repudiation (Abstreiten), Information disclosure (Datenabfluss), Denial of service (Ausfall) und Elevation of privilege (Rechteausweitung).

## Was zu schützen ist

| Wert | Warum wichtig |
|---|---|
| Vertrauen der Hörer und der Name von LINEFM | Die App trägt Marken des Betreibers. Ein manipulierter Stream oder Release schadet ihm direkt. |
| Integrität des Programms (Releases, Web-Dateien) | Nutzer führen Code aus, der aus unserer Lieferkette kommt. |
| Daten der Nutzer: Favoriten, Verlauf, Einstellungen, Einwilligung | Liegen nur lokal. Sind harmlos im Einzelfall, aber personenbezogen. |
| Telemetrie-Daten (nur mit Einwilligung) | Pseudonym, personenbezogen im Sinne der DSGVO (IP-Adresse beim Empfänger). |
| Signaturschlüssel und Zugangsdaten (Stores, Hosting, GitHub) | Wer sie hat, kann im Namen des Betreibers veröffentlichen. |

Es gibt kein Backend, keine Konten, keine Passwörter und keine Zahlungen. Das beseitigt ganze Klassen von Angriffen (Kontoübernahme, SQL-Injection, Sitzungsdiebstahl). Siehe [ADR 0001](../adr/0001-kein-backend-keine-konten.md).

## Vertrauensgrenzen

```
Gerät des Nutzers (App / Browser)
   |-- HTTPS --> api.laut.fm            (Daten über Sender und Titel, fremd)
   |-- HTTPS --> *.stream.laut.fm       (Audio, fremd)
   |-- HTTPS --> itunes.apple.com       (Cover-Suche, fremd)
   |-- HTTPS --> cdn.linefm.de          (Senderlogos, Web, Betreiber)
   |-- HTTPS --> radiogruppe.de         (Logo, fremd)
   |-- HTTPS --> Telemetrie-Server      (nur mit Einwilligung, Betreiber oder Dienst)
   |-- lokales Netz --> Cast-Gerät      (nach Tipp auf Cast)
   |<-- Deep Link / Teilen-Link / Widget (andere Apps und Systemteile)
   |-- lokaler Speicher                 (Einstellungen, Favoriten, Cover-Cache)
Quellcode (GitHub) --> CI --> Release-Dateien --> Stores / Web-Server --> Gerät
```

## Datenflüsse und Bedrohungen

Die Spalte "Vorhanden" nennt Maßnahmen, die im Repository belegt sind. "Rest" ist das Risiko, das bleibt. Schweregrad nach den Stufen aus [INCIDENT.md](INCIDENT.md), geschätzt für den schlimmsten realistischen Fall.

### laut.fm-API (`api.laut.fm`)

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| S | Gefälschte Antworten (Man-in-the-middle) | HTTPS, Zertifikatsprüfung des Systems | Kompromittierte Zertifizierungsstelle oder Nutzergerät | S3 |
| T | Manipulierte oder unerwartete JSON-Daten: überlange Texte, falsche Typen, Steuerzeichen, Verweise auf fremde Adressen | Parser mit Typprüfung und Fixtures in `test/fixtures/`. Cover und Links werden nur über feste Hosts geladen (CSP im Web). | Robustheitstests mit zufälligen Eingaben fehlen noch | S3 |
| I | Abfluss von Nutzerdaten | Die App schickt nur Sender-Kennung, keine Nutzerkennung | laut.fm sieht die IP-Adresse (technisch nötig) | S4 |
| D | API fällt aus oder liefert langsam | Polling mit HTTP-Cache, Titelanzeige fällt weg, der Stream läuft weiter. WebSocket aus ([ADR 0002](../adr/0002-laut-fm-websocket-aus-polling.md)) | Keine Titelanzeige während des Ausfalls | S3 |
| E | nicht anwendbar | | | |

### Audio-Stream (`<sender>.stream.laut.fm`)

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| S | Anderer Server liefert Ton unter dem Sendernamen | HTTPS. Stream-Adressen fest im Code, im Web per CSP `media-src` auf `*.laut.fm` beschränkt | laut.fm-Konto oder Sender selbst übernommen (außerhalb unseres Einflusses) | S2 |
| T | Eingeschleuste Inhalte im Stream | keine, wir senden nur ab | Inhalt liegt bei laut.fm und beim Sender | S3 |
| I | IP-Adresse und Hörzeit sichtbar für laut.fm | in der Datenschutzerklärung genannt | nicht vermeidbar | S4 |
| D | Stream nicht erreichbar | App meldet Fehler, wiederholt, Wecker fällt auf den Systemton zurück | Hörer ohne Ton | S2 |

### Cover-Suche (`itunes.apple.com`, Bilder von `*.mzstatic.com`)

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| T | Falsches oder unpassendes Bild bei mehrdeutiger Suche | Fallback auf das Senderlogo bei Fehlern. Die Zuordnung ist nur eine Suche nach Künstler und Titel. | Falsches Cover möglich | S4 |
| T | Bildparser-Lücke durch präpariertes Bild | Flutter-Engine decodiert, Hosts fest | Abhängig von Flutter und Plattform | S3 |
| I | Apple erhält Künstler, Titel und IP | Schalter "Cover laden", Datenschutzerklärung Abschnitt 5 | bei eingeschaltetem Schalter nicht vermeidbar | S4 |
| D | Dienst fällt aus oder begrenzt Anfragen | Cache für Cover, Fallback aufs Logo | Kein Cover | S4 |

### Logos: `cdn.linefm.de` und `radiogruppe.de`

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| T | Austausch des Logos durch Dritte (Übernahme des CDN oder der Domain) | HTTPS, CSP im Web. Senderlogos der Apps liegen als Asset im Paket (`assets/images/stations/`) | Das RadioGruppe-Logo wird zur Laufzeit geladen und ist nicht gepinnt. Bei Übernahme der Domain könnte ein anderes Bild erscheinen. | S3 |
| I | Betreiber der Seite sieht IP und Zeitpunkt | Datenschutzerklärung nennt es (Art. 6 Abs. 1 Buchst. f) | nicht vermeidbar, solange das Logo nachgeladen wird | S4 |
| D | Seite offline | Logo fehlt, App funktioniert | | S4 |

### Telemetrie-Anbieter (Umami, GlitchTip, Sentry, optional Firebase)

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| S | Falsche Ereignisse von Dritten, weil Website-ID und DSN im Binary lesbar sind | bekannt und akzeptiert (öffentliche Kennungen, [../../SECURITY.md](../../SECURITY.md)) | Statistik lässt sich verfälschen | S4 |
| T | Absturzberichte mit Nutzerdaten | `sendDefaultPii: false`, `scrubEvent`, kein Tracing, keine Screenshots | Texte in Fehlermeldungen können Titel oder Sender enthalten | S4 |
| I | Senden ohne Einwilligung | Sinks starten erst nach Einwilligung, Widerruf stoppt sie ([../telemetry.md](../telemetry.md)). Ohne Konfiguration nichts. | Fehler in der Einwilligungslogik wären ein Rechtsverstoß. Tests sichern es ab. | S2 |
| I | IP-Adresse beim Empfänger, Aufbewahrung im Proxy-Log | in Datenschutzerklärung und Doku genannt, Hinweise zum Abschalten der Logs | Betreiber muss die Server richtig einstellen | S3 |
| D | Telemetrie-Server fällt aus | Warteschlange begrenzt (50), bei Fehler verworfen | | S4 |

### Google Cast (Chromecast)

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| S | Gerät im lokalen Netz gibt sich als Chromecast aus | Auswahl durch den Nutzer in der Geräteliste | Im selben Netz kann ein Angreifer ein Gerät anbieten. Es erhält nur Stream-Adresse und Titel (öffentliche Daten). | S4 |
| I | Das Cast-SDK sendet Nutzungsdaten an Google | Cast startet erst nach Tipp auf den Cast-Knopf | Auf Android kann das Plugin das SDK beim Beenden der App schon initialisieren (gemeldet: felnanuke2/flutter_google_cast#103) | S3 |
| E | Lokales-Netz-Berechtigung (iOS, Android 13 und höher) | Berechtigung nur bei Nutzung nötig | | S4 |

### Deep Links, Teilen-Links, Widget

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| S | Fremde App oder Webseite löst `linefm://play?station=…` aus | Nur Links mit bekanntem Sender werden angenommen (`stations_catalog`), alles andere wird verworfen. Ein Link startet nur die Wiedergabe eines bekannten Senders. | Fremde Seite kann einen Sender starten (Lästigkeit, kein Datenzugriff) | S4 |
| T | Link mit überlangen oder präparierten Parametern | Parameter werden gegen die feste Senderliste geprüft, nicht interpretiert | | S4 |
| E | Exportierte Android-Komponenten (Medien-Dienst für Android Auto, Widget-Empfänger) werden von fremden Apps angesprochen | `exported` nur dort, wo Android Auto es verlangt (Begründung im Manifest). Intent-Filter `autoVerify=false` für https | App Links sind nicht verifiziert, andere Apps könnten dieselben https-Links beanspruchen | S4 |

### Lokaler Speicher und Favoriten-Import/-Export

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| T | Manipulierte Importdatei für Favoriten | Dateiauswahl durch den Nutzer, Parser mit Prüfung, Import nur in Favoriten | Parser-Fuzz-Tests fehlen | S4 |
| I | Zugriff auf Geräte-Daten durch andere Apps oder Backups | Daten im App-Container. iOS-Sicherung kann sie enthalten (Datenschutzerklärung nennt es). Web: `localStorage` je Origin | Gerät mit Root oder Jailbreak | S4 |
| I | Export-Datei liegt offen herum | Nutzer wählt den Speicherort selbst | | S4 |
| D | Voller oder beschädigter Speicher | Standardwerte beim Lesen, Funktion "Speicher löschen" | | S4 |

### Web-Auslieferung

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| T | Manipulierte Dateien auf dem Server, Skript-Einschleusung (XSS) | strenge CSP ohne `unsafe-eval` und ohne `unsafe-inline` bei Skripten, HSTS, `nosniff`, Hash im Dateinamen, `asset-manifest.txt` mit Prüfsummen | `style-src 'unsafe-inline'` (dokumentierte Ausnahme der Flutter-Engine). Server-Zugang ist der schwache Punkt. | S1 |
| S | Domain-Übernahme oder DNS-Manipulation | HSTS | Registrar-Konto und DNS gehören zum Betreiber. 2-Faktor-Anmeldung dort ist Pflicht (nicht prüfbar aus dem Repository). | S1 |
| D | Ausfall des Hosts | Statische Dateien, vier mögliche Ziele, Rollback ([RUNBOOK.md](RUNBOOK.md)), Uptime-Monitor | Kein automatischer Failover | S2 |
| I | Abfluss über Referrer oder Header | `Referrer-Policy`, `Permissions-Policy`, COOP, CORP | | S4 |

### Update- und Release-Kette

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| T | Manipulierter Abhängigkeitsstand (Pub, Gradle, Actions, Docker) | `pubspec.lock` mit `--enforce-lockfile`, Actions und Images per SHA oder Digest gepinnt, Dependabot mit 7 Tagen Wartezeit, OSV-Scanner und CodeQL | Ein bösartiges Update eines Pakets kann zwischen Veröffentlichung und Fund einrücken. Die Wartezeit mildert das. | S1 |
| T | Eingeschleuster Code im Release | Release-Dateien tragen GitHub-Attestierung (Provenance) und cosign-Signatur. Prüfanleitung [../RELEASE-VERIFIZIEREN.md](../RELEASE-VERIFIZIEREN.md). Gegenprüfung mit älteren cosign-Versionen offen. | Nutzer müssen die Prüfung selbst ausführen. Die Stores signieren zusätzlich mit eigenen Schlüsseln. | S1 |
| S | Gestohlenes GitHub-Konto oder Token | Aktionen mit minimalen `permissions:`, Umgebung `production` mit Genehmiger (Betreiber muss ihn einrichten), Secret-Scan mit gitleaks | Kontosicherheit (2FA, Hardware-Schlüssel) liegt beim Betreiber | S1 |
| I | Secrets in Code oder Logs | gitleaks, Secret-Gate-Action, keine Secrets im Repository | Fehler im Workflow könnten Secrets ausgeben | S1 |
| R | Wer hat was veröffentlicht | Git-Verlauf, geschützter Hauptzweig, Workflow-Läufe mit Benutzer und Zeit, Attestierungen | Rulesets und Branch-Schutz müssen aktiv sein (Repo-Einstellung) | S3 |
| T | Unverankertes Build-Werkzeug im Signier-Job | Der Windows-Installer entsteht mit dem eigenen Packer aus dem Repository (`installer/windows`), es wird kein Fremdwerkzeug nachinstalliert | Der Axe.Windows-Scanner im Prüflauf ist per Hash gepinnt | S3 |
| E | Fremder Pull Request führt Code mit Rechten aus | Kein privilegierter Job auf `pull_request`, Secrets nur in geschützten Läufen | Fehlkonfiguration bei neuen Workflows. Jeder neue Workflow wird gegen diese Regel geprüft. | S2 |

### Desktop-Installation (Windows, Linux, macOS)

| STRIDE | Bedrohung | Vorhanden | Rest | Stufe |
|---|---|---|---|---|
| T | Austausch von Programmdateien nach der Installation | Windows: Installation pro Benutzer (`PrivilegesRequired=lowest`), Programmdateien liegen im Benutzerprofil und laufen ohne erhöhte Rechte. Signierte EXE (sobald Zertifikat gesetzt). | Wer schon als derselbe Benutzer Code ausführt, kann die Dateien ändern. Das ist keine neue Grenze. | S4 |
| E | Schema-Handler `linefm://` startet die App mit fremdem Argument | Argument wird nur als URI gelesen, nur `linefm://play?station=<slug>` mit Slug aus der festen Senderliste wirkt (`lib/platform/deep_links.dart`) | Ein Link kann höchstens einen bekannten Sender starten | S4 |
| T | Manipuliertes Update | Kein In-App-Updater. Updates kommen über Stores, Paketquellen oder einen neuen Installer mit Signatur und Provenance | | S4 |

## Nicht im Umfang

- Angriffe auf laut.fm, Apple, Google, Cloudflare und andere Anbieter selbst.
- Physischer Zugriff auf ein Gerät.
- Rechtliche Risiken (Marken, Lizenzen, DSGVO-Einordnung). Dafür sind die Hinweise in den Rechtstexten und die Freigabe-Checkliste zuständig, mit anwaltlicher Prüfung.

## Offene Punkte aus diesem Modell

| Punkt | Wo erfasst |
|---|---|
| Robustheits- und Fuzz-Tests für Parser (laut.fm-JSON, Favoriten-Import) | Aufgabe "Fuzz-Tests" |
| Gegenprüfung der Signaturen mit cosign 2.x und 3.x | Aufgabe "cosign" |
| App Links verifizieren (`autoVerify`) | offen, setzt `assetlinks.json` auf dem Server voraus (nach Inbetriebnahme von app.linefm.de) |
| RadioGruppe-Logo als Asset ins Paket legen statt nachladen | offen, Entscheidung des Betreibers (Entscheidung 47 im Projektverlauf sieht das Nachladen vor) |
| 2FA und Hardware-Schlüssel für GitHub, Registrar, Stores und Hosting | Betreiber, nicht aus dem Repository prüfbar |

Das Modell wird bei jedem neuen Fremddienst, jeder neuen Plattform und nach jedem Vorfall überarbeitet.
