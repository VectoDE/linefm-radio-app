# Verzeichnis der Verarbeitungstätigkeiten (Muster)

Ausgefülltes Muster nach Art. 30 Abs. 1 DSGVO für LINEFM Radio. Es beschreibt jeden Datenfluss der App und der Web-Version. LineFM Studios übernimmt es als eigenes Verzeichnis, prüft es und hält es aktuell. Die gepflegte Fassung liegt beim Verantwortlichen, nicht im Repository. Anleitung: [EINRICHTUNG.md](EINRICHTUNG.md), Schritt 17.11.

Das ist eine Vorprüfung, keine Rechtsberatung. Rechtsgrundlagen und Fristen mit einem Anwalt abstimmen. Die Rechtsgrundlagen folgen dem Entwurf der Datenschutzerklärung (`assets/legal/de/datenschutz.json`, Stand 19.11.2026).

Stand des Musters: 26.11.2026. Letzte Prüfung durch den Verantwortlichen: ____________

## Allgemeine Angaben

| Feld | Eintrag |
|---|---|
| Verantwortlicher | LineFM Studios, Anschrift wie Impressum |
| Vertretung | laut Impressum |
| Datenschutzbeauftragter | benannt: ja / nein (wie in der Datenschutzerklärung) |
| Kontakt für Datenschutzanfragen | E-Mail aus dem Impressum |
| Zuständige Aufsichtsbehörde | Landesdatenschutzbehörde am Sitz |
| Technische und organisatorische Maßnahmen (allgemein) | TLS für alle Verbindungen, HSTS, keine Konten in der App, Telemetrie nur nach Einwilligung, Zugänge mit Zwei-Faktor-Anmeldung, Secrets nur in GitHub und im Passwortmanager, Server-Logs gekürzt und befristet, siehe [betrieb/BEDROHUNGSMODELL.md](betrieb/BEDROHUNGSMODELL.md) |

## Verarbeitungen

Spalten: Zweck, betroffene Personen und Daten, Rechtsgrundlage, Empfänger, Drittland, Speicherdauer, aktiv ja/nein. "Aktiv" kreuzt der Verantwortliche je nach Konfiguration an.

### 1. Radio-Stream

- Zweck: Wiedergabe der Sender.
- Personen und Daten: Hörer. IP-Adresse, Zeitpunkt, abgerufene Adresse, Geräte- und Softwareangaben.
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. b DSGVO, hilfsweise Buchst. f.
- Empfänger: LAUT AG (laut.fm), eigenständig verantwortlich. Bei Radio3FM und FobFM die jeweiligen Streaming-Anbieter (prüfen).
- Drittland: nein (prüfen).
- Speicherdauer: bei laut.fm laut deren Datenschutzerklärung. Wir speichern nichts.
- Aktiv: ja

### 2. laut.fm-Schnittstelle (Titel, Hörerzahl, Sendeplan)

- Zweck: Anzeige von Titel, Interpret und Hörerzahl.
- Personen und Daten: Hörer. IP-Adresse, Zeitpunkt, Geräte- und Softwareangaben.
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. b DSGVO, hilfsweise Buchst. f.
- Empfänger: LAUT AG (`api.laut.fm`), eigenständig verantwortlich.
- Drittland: nein (prüfen).
- Speicherdauer: laut laut.fm. Wir speichern nichts außer dem lokalen Zwischenspeicher auf dem Gerät.
- Aktiv: ja

### 3. Albumcover (Apple iTunes-Suche)

- Zweck: Cover zum laufenden Titel.
- Personen und Daten: Hörer. Interpret und Titel als Suchbegriff, IP-Adresse, Geräte- und Softwareangaben.
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. f DSGVO. Abschaltbar in den Einstellungen ("Cover laden").
- Empfänger: Apple (`itunes.apple.com`, Bilder von `*.mzstatic.com`).
- Drittland: USA. Grundlage: DPF-Zertifizierung prüfen (<https://www.dataprivacyframework.gov/list>).
- Speicherdauer: bei Apple laut deren Angaben. Lokal im Zwischenspeicher des Geräts.
- Aktiv: ja

### 4. Senderlogos (`cdn.linefm.de`)

- Zweck: Anzeige der Senderlogos.
- Personen und Daten: Hörer. IP-Adresse, Zeitpunkt, abgerufene Datei (Server-Protokoll).
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. f DSGVO.
- Empfänger: Betreiber von `cdn.linefm.de` (Auftragsverarbeiter, AVV nötig): ____________
- Drittland: ____________
- Speicherdauer: wie Server-Logs, Vorschlag 7 Tage.
- Aktiv: ja

### 5. Logo der RadioGruppe (`radiogruppe.de`)

- Zweck: Anzeige des Anbieters im Bereich "Über".
- Personen und Daten: Hörer, die "Über" öffnen. IP-Adresse, Zeitpunkt, abgerufene Datei.
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. f DSGVO.
- Empfänger: Betreiber von radiogruppe.de, eigenständig verantwortlich.
- Drittland: nein (prüfen).
- Speicherdauer: laut Betreiber.
- Aktiv: ja

### 6. Absturzberichte (Sentry bzw. GlitchTip)

- Zweck: Fehler finden und beheben.
- Personen und Daten: Nutzer mit Einwilligung. Fehlermeldung, Stacktrace, App-Version, Betriebssystem, Gerätemodell; technisch die IP-Adresse.
- Rechtsgrundlage: Einwilligung, Art. 6 Abs. 1 Buchst. a DSGVO und § 25 Abs. 1 TDDDG.
- Empfänger: Sentry (Functional Software) oder Betreiber der GlitchTip-Instanz, Auftragsverarbeiter, AVV nötig.
- Drittland: Sentry: USA möglich, DPF oder Standardvertragsklauseln prüfen. GlitchTip auf eigenem Server in der EU: nein.
- Speicherdauer: Vorschlag 90 Tage (`{{TELEMETRIE_AUFBEWAHRUNG}}`).
- Aktiv: ja / nein

### 7. Firebase (Statistik und Absturzberichte)

- Zweck: Nutzung und Stabilität der App messen.
- Personen und Daten: Nutzer mit Einwilligung. App-Ereignisse, Geräte- und App-Kennungen von Firebase, Absturzdaten, IP-Adresse.
- Rechtsgrundlage: Einwilligung, Art. 6 Abs. 1 Buchst. a DSGVO und § 25 Abs. 1 TDDDG.
- Empfänger: Google Ireland bzw. Google LLC, Auftragsverarbeiter (Data Processing Terms in der Firebase-Konsole).
- Drittland: USA möglich. DPF prüfen.
- Speicherdauer: Vorschlag 90 Tage, in Firebase einstellen.
- Aktiv: ja / nein

### 8. Umami (Statistik)

- Zweck: Reichweite und genutzte Funktionen messen.
- Personen und Daten: Nutzer mit Einwilligung. Aufgerufene Bereiche, Ereignisse, Gerätetyp, Sprache; technisch die IP-Adresse (Umami speichert sie nach Herstellerangabe nicht, prüfen).
- Rechtsgrundlage: Einwilligung, Art. 6 Abs. 1 Buchst. a DSGVO und § 25 Abs. 1 TDDDG.
- Empfänger: Betreiber der Umami-Instanz bzw. Hoster (Auftragsverarbeiter, AVV nötig): ____________
- Drittland: je nach Hoster.
- Speicherdauer: Vorschlag 90 Tage.
- Aktiv: ja / nein

### 9. Google Analytics 4 und Tag Manager (nur Web)

- Zweck: Reichweitenmessung der Web-Version.
- Personen und Daten: Besucher mit Einwilligung. Seitenaufrufe, Ereignisse, Cookie-Kennungen `_ga` und `_ga_<ID>`, Geräte- und Browserangaben, gekürzte IP-Adresse.
- Rechtsgrundlage: Einwilligung, Art. 6 Abs. 1 Buchst. a DSGVO und § 25 Abs. 1 TDDDG. Die Speicherung der Entscheidung selbst: § 25 Abs. 2 Nr. 2 TDDDG.
- Empfänger: Google Ireland, Auftragsverarbeiter (Datenverarbeitungsbedingungen in GA4 annehmen).
- Drittland: USA möglich. DPF prüfen.
- Speicherdauer: 2 Monate in GA4 (`{{GA4_AUFBEWAHRUNG}}`). Cookies laut Google bis 2 Jahre.
- Aktiv: ja / nein

### 10. Google Cast (Chromecast)

- Zweck: Wiedergabe auf Cast-Geräten.
- Personen und Daten: Nutzer, die Cast verwenden; auf Android unter Umständen alle Nutzer, weil das Plugin das SDK schon beim Beenden der App starten kann. Nutzungsdaten und Kennungen laut Google.
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. f DSGVO. Anwalt: gemeinsame Verantwortung mit Google prüfen.
- Empfänger: Google.
- Drittland: USA möglich. DPF prüfen.
- Speicherdauer: laut Google.
- Aktiv: ja (Android, iOS)

### 11. Hosting der Web-App (Server-Logs)

- Zweck: Auslieferung, Sicherheit, Fehlersuche.
- Personen und Daten: Besucher der Web-App. IP-Adresse (gekürzt), Zeitpunkt, URL, Statuscode, Browserangaben.
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. f DSGVO.
- Empfänger: Hoster (`{{HOSTING_ANBIETER}}`), bei Cloudflare zusätzlich CDN und DNS. Auftragsverarbeiter, AVV nötig.
- Drittland: Cloudflare: USA möglich, DPF prüfen. Eigener Server in der EU: nein.
- Speicherdauer: Vorschlag 7 Tage (`{{LOG_AUFBEWAHRUNG}}`).
- Aktiv: ja

### 12. Support-Anfragen (`support@linefm.de`)

- Zweck: Anfragen von Nutzern beantworten.
- Personen und Daten: Absender. E-Mail-Adresse, Name, Inhalt der Nachricht.
- Rechtsgrundlage: Art. 6 Abs. 1 Buchst. b bzw. f DSGVO.
- Empfänger: E-Mail-Anbieter von LineFM Studios (Auftragsverarbeiter, AVV nötig): ____________
- Drittland: je nach Anbieter.
- Speicherdauer: bis zur Erledigung, danach gesetzliche Aufbewahrung, falls sie greift.
- Aktiv: ja

### 13. Lokale Speicherung auf dem Gerät

- Zweck: Favoriten, Einstellungen, letzte Station, Zwischenspeicher.
- Personen und Daten: Nutzer. Daten bleiben auf dem Gerät, wir erhalten sie nicht.
- Rechtsgrundlage: § 25 Abs. 2 Nr. 2 TDDDG, soweit personenbezogen Art. 6 Abs. 1 Buchst. b und f DSGVO.
- Empfänger: keine.
- Drittland: nein. Ausnahme: eine Sicherung, die der Nutzer selbst bei Apple (iCloud) anlegt.
- Speicherdauer: bis zum Löschen durch den Nutzer oder Deinstallation.
- Aktiv: ja

## Änderungsprotokoll

| Datum | Änderung | Wer |
|---|---|---|
| 26.11.2026 | Muster angelegt | Entwickler |
| | | |
