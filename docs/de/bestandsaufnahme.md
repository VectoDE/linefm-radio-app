# Bestandsaufnahme der Dokumentation

Stand: 28. November 2026. Grundlage sind `README.md`, `docs/` und die Dokumente im Wurzelverzeichnis. Die Spalte „Zielgruppe“ nennt, wer das Dokument vor allem liest: **H** Hörer, **B** Betreiber, **E** Entwickler und Admins, **P** Presse, Partner und Prüfer.

## Vorhanden

| Dokument | Zielgruppe | Modul | Bemerkung |
|---|---|---|---|
| `README.md` | alle | Einstieg | Deutsch; englischer Abschnitt nur Kurzfassung, Vollfassung in `README.en.md` |
| `.github/ACCESSIBILITY.md` | H, P | Nutzer | zweisprachig |
| `docs/BARRIEREFREIHEIT.md` | H, P | Nutzer | Entwurf |
| `docs/EINRICHTUNG.md` | B | Betreiber | sehr lang, Checkboxen je Konto |
| `docs/FREIGABE-CHECKLISTE.md` | B | Betreiber | Freigaben und Gerätetests |
| `docs/KONFIGURATION.md`, `docs/SENDER-VERWALTEN.md` | B | Betreiber | Referenz zu `config/` |
| `docs/BAUEN-UND-STARTEN.md` | B, E | Betreiber | Bauen auf GitHub und lokal |
| `docs/stores-pipelines.md`, `docs/secrets.md` | B | Betreiber | Abläufe und Secrets |
| `docs/STORE-TEXTE.md`, `docs/STORE-RICHTLINIEN.md`, `docs/STORE-POLICIES.md`, `docs/STORE-DATENSCHUTZANGABEN.md` | B | Referenz | Richtlinien auch auf Englisch |
| `docs/ENTWICKLUNG.md` | E | Entwicklung | Aufbau, Tests, Plattformen |
| `docs/PERFORMANCE.md`, `docs/GERAETETESTS.md`, `docs/BUILD_WARNINGS.md` | E | Entwicklung | Messungen und Berichte |
| `docs/hosting-*.md` | E, B | Betrieb | nginx, Traefik, Cloudflare, Plesk |
| `docs/telemetry.md` | E, P | Betrieb | Statistik, Absturzberichte |
| `docs/betrieb/` | B, E | Betrieb, Sicherheit | Runbook, Vorfall, Bedrohungsmodell |
| `docs/RELEASE-VERIFIZIEREN.md` | P, E | Sicherheit | Prüfsummen, Signaturen, SBOM |
| `docs/VERARBEITUNGSVERZEICHNIS.md`, `docs/ANWALT-UNTERLAGEN.md`, `docs/LIZENZEN-DRITTE.md` | B, P | Recht | |
| `docs/WETTBEWERB.md` | B | Referenz | |
| `docs/adr/` | E, P | Entscheidungen | acht Einträge |
| `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md` | alle | Gemeinschaft | |

## Neu in diesem Verzeichnis

`docs/de/` und `docs/en/` mit Einstieg, Bestandsaufnahme, Architektur, Datenfluss der Einwilligung, Release-Fluss und Glossar.

## Lücken

| Lücke | Modul | Hinweis |
|---|---|---|
| Bedienanleitung mit Bildschirmfotos (hell und dunkel) | Nutzer | Screenshots aus der CI fehlen |
| FAQ | Nutzer | bisher nur in Discussions |
| Konfigurationsreferenz mit allen Schlüsseln an einer Stelle | Referenz | verteilt auf `config/*.example.yaml` und `KONFIGURATION.md` |
| Plattformübersicht (Funktionen je Plattform) | Entwicklung | nur die Kurztabelle in der Architektur |
| Teststrategie und CI-Übersicht | Entwicklung | Workflows sind nicht gesammelt beschrieben |
| Updater und Live-Betrieb als durchgehende Betreiber-Strecke | Betreiber | Teile in `stores-pipelines.md` und `betrieb/` |
| Gestaltete Grafiken im App-Design (SVG) | alle | bisher nur Mermaid |
| Englische Fassung der Betreiber- und Entwicklerdokumente | alle | bisher nur Einstieg und neue Seiten |
| Einheitliche englische Dateinamen | alle | folgt mit der Umbenennung |
| Linkprüfung und Vollständigkeitstest in der CI, Spiegelung ins Wiki und auf Pages | alle | |
| Gegenlesen durch eine Laien-Persona | alle | |
