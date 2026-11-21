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
- Desktop: eigene Fenster-Titelleiste im App-Design (Logo, Name, Farben aus Dunkel und Hell). Windows und Linux mit eigenen Knöpfen für Minimieren, Maximieren und Schließen, Snap-Layouts von Windows 11 inklusive; macOS behält die Ampeln links.
- Deep Links `https://app.linefm.de/?station=<sender>` und `linefm://play?station=<sender>`.
- Deutsch und Englisch, heller und dunkler Modus. In den Einstellungen wählbar: Systemsprache, Deutsch oder English, sofort wirksam und gespeichert. Wecker-Benachrichtigungen, Tray-Menü, Auto-Menü, Widget und Favoriten-Export folgen der gewählten Sprache. Alle sichtbaren Texte stehen in den ARB-Dateien, auch die Spaltenköpfe des Favoriten-Exports und die Ordnernamen des Auto-Menüs.
- Web-Version mit Service Worker, Sicherheits-Headern und Hosting-Konfigurationen für nginx, Traefik, Cloudflare Pages und Plesk.
- Optionale, selbst gehostete Telemetrie (Umami, GlitchTip) nach Einwilligung.
- Rechtstexte (Entwurf) und Erklärung zur Barrierefreiheit (Entwurf).
- Pipelines für Build, Release und Store-Upload (GitHub Actions).
- Anleitung [Bauen und Starten](docs/BAUEN-UND-STARTEN.md) für Betreiber: Bau über GitHub Actions, lokal bauen, Ergebnisse öffnen. Start-Skripte `tool/bauen.ps1` und `tool/bauen.sh`.

### Geändert

- iOS braucht mindestens iOS 16 (geplant war iOS 13). Das Google Cast SDK für Chromecast verlangt ab Version 4.8.6 iOS 16. Bis das Cast-Plugin das selbst erklärt, ist das SDK auf 4.8.4 festgelegt.
- Der Web-Postbuild entfernt Sourcemaps, Debug-Symbole und ungenutzte Engine-Varianten. Der Ausrollordner schrumpft von 49,5 auf 33,3 MB, der Startsatz bleibt gleich.
- Der Service Worker legt beide Caches pro Build an und räumt alte Caches beim Update ab.
- Manifest-Dateien (`AssetManifest.*`, `FontManifest.json`, `NOTICES`) werden nicht mehr einen Tag gecacht, sondern bei jedem Aufruf geprüft.
- Komprimierung deckt jetzt Schriften und `application/octet-stream` ab.
- Der Speicher-Hinweis erscheint nur noch im Browser als Banner. In der App (Android, iOS) und auf dem Desktop (Windows, macOS, Linux) öffnet sich beim ersten Start stattdessen ein Popup, das mit „Verstanden“ bestätigt werden muss. Zurück, Esc und ein Tipp daneben schließen es nicht. Der Datenschutz-Link öffnet die Seite, danach steht das Popup weiter offen. Reihenfolge beim Start: Ladebildschirm, Speicher-Hinweis, Einwilligung, Autoplay. „Speicher löschen“ bringt das Popup zurück.

### Sicherheit

- Die selbst gehostete GlitchTip-Instanz startet mit ausgeschalteter Registrierung.
- Die Telemetrie-Container laufen ohne Linux-Capabilities und mit `no-new-privileges`.
- `security.txt` und `SECURITY.md` ergänzt. OCSP-Stapling im nginx-Beispiel ausgeschaltet.

### Bekannt

- Apple (iOS, macOS-Store, CarPlay, AirPlay) ist im Code vorbereitet, aber nicht Teil der ersten Veröffentlichung.
- Gerätetests auf Android, Linux und macOS stehen aus (siehe `docs/FREIGABE-CHECKLISTE.md`).
