# Changelog

Alle nennenswerten Änderungen an LINEFM Radio stehen hier. Das Format folgt [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), die Versionen folgen [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0] - unreleased

Erste Version. Noch in keinem Store veröffentlicht, das Datum wird beim Release gesetzt.

### Hinzugefügt

- Live-Wiedergabe von LineFM +MAIN, +RAP, +GAMING und +LOFI sowie der Partnersender Radio3FM und FobFM, mit Sendername, aktuellem Titel und Cover.
- Hintergrundwiedergabe mit Mediensteuerung (Sperrbildschirm, Kopfhörertaste, Medientasten).
- Favoriten für Songs und Sender, Teilen und Export. Verlauf der zuletzt gespielten Titel.
- Sleeptimer (15, 30, 45, 60 Minuten) und Radiowecker mit Sender und Ersatz-Alarmton.
- Android: Homescreen-Widget, Android Auto, Chromecast.
- Desktop: Tray-Symbol, Mini-Fenster, Tastenkürzel.
- Deep Links `https://app.linefm.de/?station=<sender>` und `linefm://play?station=<sender>`.
- Deutsch und Englisch, heller und dunkler Modus.
- Web-Version mit Service Worker, Sicherheits-Headern und Hosting-Konfigurationen für nginx, Traefik, Cloudflare Pages und Plesk.
- Optionale, selbst gehostete Telemetrie (Umami, GlitchTip) nach Einwilligung.
- Rechtstexte (Entwurf) und Erklärung zur Barrierefreiheit (Entwurf).
- Pipelines für Build, Release und Store-Upload (GitHub Actions).

### Geändert

- Der Web-Postbuild entfernt Sourcemaps, Debug-Symbole und ungenutzte Engine-Varianten. Der Ausrollordner schrumpft von 49,5 auf 33,3 MB, der Startsatz bleibt gleich.
- Der Service Worker legt beide Caches pro Build an und räumt alte Caches beim Update ab.
- Manifest-Dateien (`AssetManifest.*`, `FontManifest.json`, `NOTICES`) werden nicht mehr einen Tag gecacht, sondern bei jedem Aufruf geprüft.
- Komprimierung deckt jetzt Schriften und `application/octet-stream` ab.

### Sicherheit

- Die selbst gehostete GlitchTip-Instanz startet mit ausgeschalteter Registrierung.
- Die Telemetrie-Container laufen ohne Linux-Capabilities und mit `no-new-privileges`.
- `security.txt` und `SECURITY.md` ergänzt. OCSP-Stapling im nginx-Beispiel ausgeschaltet.

### Bekannt

- Apple (iOS, macOS-Store, CarPlay, AirPlay) ist im Code vorbereitet, aber nicht Teil der ersten Veröffentlichung.
- Gerätetests auf Android, Linux und macOS stehen aus (siehe `docs/FREIGABE-CHECKLISTE.md`).
