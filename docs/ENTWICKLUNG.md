# Entwicklung

Für Entwickler, die LINEFM Radio bauen, testen oder erweitern. Betreiber lesen stattdessen [EINRICHTUNG.md](EINRICHTUNG.md). Der Quellcode ist sichtbar, aber nicht frei lizenziert (alle Rechte vorbehalten, siehe [README](../README.md)).

## Voraussetzungen

| Werkzeug | Version | Hinweis |
|---|---|---|
| Flutter | 3.50.0 (Dart 3.14) | `pubspec.yaml` verlangt `sdk: ^3.14.0` und `flutter: >=3.50.0` |
| Git | aktuell | |
| Android | JDK 17, Android SDK (Plattform 37 (`compileSdk`) und höher, Build-Tools) | Lizenzen mit `flutter doctor --android-licenses` bestätigen |
| Windows | Visual Studio 2022 mit Workload "Desktop development with C++", **Rust** (rustup) | siehe unten |
| Linux | Flutter-Linux-Pakete (clang, cmake, ninja, pkg-config, GTK 3), libmpv | ungetestet, kein Linux-Rechner in der bisherigen Entwicklung |
| macOS und iOS | Xcode, CocoaPods | ungetestet, kein Mac in der bisherigen Entwicklung |
| Web | Chrome | |

Schnellstart:

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome        # oder windows, android, ...
```

### UI-Bibliothek: material_ui

Die App importiert `package:material_ui/material_ui.dart` und **nicht** `package:flutter/material.dart`. Das gilt für alle Dateien unter `lib/` und `test/`. Lokalisierungs-Delegates kommen aus `material_ui` (`GlobalMaterialLocalizations.delegates`).

### Windows: Rust und MAX_PATH

- `smtc_windows` (Windows-Mediensteuerung) ist über `flutter_rust_bridge` angebunden und baut Rust-Code. Ohne Rust (`rustup`, Pfad `%USERPROFILE%\.cargo\bin`) scheitert `flutter build windows`.
- In `pubspec.yaml` steht ein `dependency_overrides` auf `flutter_rust_bridge: 2.11.1`. `smtc_windows` ist gegen diese Version erzeugt, neuere brechen die Laufzeitprüfung der Brücke. Beim Aktualisieren prüfen, nicht blind anheben.
- Der Windows-Build scheitert bei langen Pfaden (MAX_PATH, 260 Zeichen), zum Beispiel in einem tief verschachtelten Git-Worktree. Lösung: aus einer **kurzen Kopie** bauen.

```powershell
git worktree add C:\lf29 <branch>
cd C:\lf29
flutter build windows --release --dart-define-from-file=config/app.json
cd ..
git worktree remove --force C:\lf29
```

  Alternativ den Pfad kürzen oder lange Pfade in Windows aktivieren (Registry `LongPathsEnabled`). Die CI nutzt einen kurzen Checkout-Pfad.

## Konfiguration: `--dart-define-from-file`

Alle Laufzeiteinstellungen kommen beim Build über `--dart-define-from-file=config/app.json`. Vorlage: `config/app.example.json`. Die Datei `config/app.json` ist in `.gitignore` und wird nicht eingecheckt.

```bash
cp config/app.example.json config/app.json
flutter run -d windows --dart-define-from-file=config/app.json
```

| Schlüssel | Bedeutung |
|---|---|
| `APP_ENV`, `APP_VERSION` | Umgebung und angezeigte Version |
| `WEB_BASE_URL` | Basis für Share-Links und kanonische URL, Standard `https://app.linefm.de` |
| `UMAMI_URL`, `UMAMI_WEBSITE_ID`, `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `FIREBASE_*` | Telemetrie, siehe [telemetry.md](telemetry.md) |
| `WS_ENABLED` | laut.fm-WebSocket, Standard `false` (siehe unten) |
| `GSC_VERIFICATION` | Search-Console-Token für die Web-Version |
| `TRUST_GRIDINSOFT_URL`, `TRUST_TRUSTPILOT_URL` | Links für Vertrauens-Badges, leer = kein Badge |

Die Werte sind im Binary lesbar. Keine Geheimnisse hinein. Ohne Telemetrie-Werte sendet die App nichts.

## Bauen

| Ziel | Befehl |
|---|---|
| Android APK | `flutter build apk --release --dart-define-from-file=config/app.json` |
| Android App Bundle | `flutter build appbundle --release --dart-define-from-file=config/app.json` |
| Windows | `flutter build windows --release --dart-define-from-file=config/app.json` |
| Web | siehe [hosting-uebersicht.md](hosting-uebersicht.md): `flutter build web --release --wasm --no-web-resources-cdn ...` und danach `dart run tool/web_postbuild.dart build/web` |
| Linux, macOS, iOS | `flutter build linux`, `macos`, `ipa` (ungetestet) |

- Android signiert nur, wenn `android/key.properties` existiert, sonst entsteht ein unsigniertes Release. Details: [packaging/android/SIGNING.md](../packaging/android/SIGNING.md).
- Verpackung für die Verteilung (Inno Setup, MSIX, Flatpak, Snap, DMG, iOS-Export): [packaging/README.md](../packaging/README.md).
- `flutter build` schreibt `lib/l10n/gen/*` mit anderen Zeilenenden neu. Diese Änderungen nicht committen, zurücksetzen.
- App-Icons entstehen aus einer Quelle mit `tool/generate_icons.sh` (Quelle `assets/branding/source/`). Das Icon wird technisch skaliert, nicht verändert.
- Übersetzungen: `lib/l10n/app_de.arb` ist die Vorlage, `app_en.arb` die zweite Sprache. `flutter gen-l10n` erzeugt `lib/l10n/gen/`. Jeder Schlüssel muss in beiden Sprachen stehen (CI-Job und `test/app/language_test.dart` prüfen das). Neue sichtbare Texte kommen immer in die ARB-Dateien, nie als Literal in den Code. Texte ohne BuildContext (Wecker, Tray, Auto-Menü) holen `systemLocalizations()` aus `lib/l10n/system_l10n.dart`; das berücksichtigt die in den Einstellungen gewählte Sprache.

## Tests

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

- `test/` spiegelt die Struktur von `lib/`: `domain`, `data`, `services`, `features`, `platform`, `ui`, `app`, `tool`. Netzwerk-Fixtures liegen in `test/fixtures/`.
- Getestet wird, was absichert: Logik, Parser, Regeln, Wecker-Berechnung, Sleeptimer, Deep Links, Persistenz, Verdrahtung. Reine Optik nur über Goldens.
- Dienste werden über Provider mit Fakes ersetzt (siehe `test/app/app_host.dart` und `test/features/feature_host.dart`). Echtes Netzwerk gibt es in Tests nicht.
- **Goldens** (Bildvergleich) prüfen die Kernkomponenten in Dark und Hell: Stationskarte, Play-Knopf, Mini-Player, Player, Favoriten-Herz mit Badge, Einstellungs-Schalter, Knöpfe, Abschnittsüberschrift, Dialog, Sheet, App-Rahmen (Header, Navigation) und Einstellungen sowie Verlauf und Favoriten. Dateien: `test/ui/components_golden_test.dart`, `test/app/shell_golden_test.dart`, `test/features/history_favorites_golden_test.dart`; Bilder je Test in `goldens/<name>_dark.png` und `goldens/<name>_light.png` daneben.

### Goldens aktualisieren

Referenzbilder hängen von der Rasterung der Plattform ab. Sie gelten deshalb nur dort, wo sie entstanden sind: auf dem CI-Runner des Jobs „Golden-Tests (Windows)“ (`windows-latest`). Die Tests tragen das Tag `golden` (`dart_test.yaml`) und enden auf `_golden_test.dart`; der normale Testjob lässt sie aus.

- **Lokal** laufen sie durch (Layout, keine Ausnahmen), vergleichen aber keine Pixel und werden so nicht fälschlich rot. Die Meldung „Golden-Vergleich uebersprungen“ steht im Log. Mit `GOLDENS=1` (PowerShell: `$env:GOLDENS=1`) erzwingst du den Vergleich auch lokal; auf Windows 11 waren die Bilder bei der Einführung byte-gleich zu denen der CI, auf anderen Systemen sind Abweichungen zu erwarten.
- **Feste Bedingungen** machen die Bilder reproduzierbar: echte App-Schriften aus dem Font-Manifest (nicht Ahem), Fenstergröße fest bei Pixelverhältnis 1, Lauftext aus, keine Netzbilder (Fakes, Senderlogos ohne Netz), Sender ohne ladbares Logo zeigen das Kürzel.
- **Nach einer gewollten Änderung der Darstellung:**
  1. Branch pushen. Der Job „Golden-Tests (Windows)“ wird rot und lädt das Artifact `golden-kandidaten` (alle Bilder, auf dem Runner neu erzeugt) und `golden-failures` (Unterschiede je Bild) hoch.
  2. Artifact laden: `gh run download <run-id> -n golden-kandidaten -D tmp-goldens`, die PNGs unter `test/**/goldens/` kopieren.
  3. Die Bilder im Diff ansehen, nur gewollte Änderungen committen, pushen. Der Job wird grün.
- Alternativ lokal auf Windows 11: `flutter test --update-goldens test/ui/components_golden_test.dart` (je Datei), Bilder prüfen und committen. Die CI bleibt maßgeblich: stimmt sie nicht überein, gilt das Artifact.
- Ein neuer Golden-Test braucht das Tag (`@Tags(<String>['golden'])` und `library;` ganz oben), den Dateinamen `*_golden_test.dart` und `setUpAll(prepareGoldens)` aus `test/golden_support.dart`.

- Schwere Builds (APK, Windows, Web) laufen nicht parallel zu `flutter test`, das braucht viel Arbeitsspeicher.
- Eine Live-Probe der laut.fm-Schnittstelle liegt in `tool/dev/now_playing_probe.dart`.

## Architektur im Überblick

```
lib/
  main.dart        Startreihenfolge, runApp mit productionOverrides
  app/             App-Hülle, Provider, Shell (Navigation), PlayerController
  core/            Konfiguration (AppConfig), Uhr, Logging, Result
  domain/          Datenmodelle und reine Logik ohne Flutter-Abhängigkeit
                   (Station, Track, Favoriten, Wecker-Regeln, Sleeptimer, Einstellungen)
  data/            laut.fm-REST mit HTTP-Cache, iTunes-Cover, Live-Daten-Motor, Speicher
  services/        Schnittstellen und Implementierungen: audio, alarm, cast, share,
                   sleep_timer, telemetry, widgets
  platform/        Plattformbrücken: Deep Links, Desktop (Tray, Fenster, Hotkeys),
                   Web-Routen, AirPlay, CarPlay
  features/        Bildschirme: stations, player, mini_player, history, favorites,
                   settings, alarm, about, legal, consent, loader, storage_notice
  ui/              Design-System (Theme hell und dunkel, Tokens, Schriften), Widgets, Galerie
  l10n/            ARB-Dateien und generierter Code
android/ ios/ macos/ windows/ linux/ web/   Plattformprojekte
packages/linefm_firebase                      optionales Firebase-Paket (nicht in pubspec)
deploy/  Server-Konfiguration für das Web-Hosting
packaging/  Installer und Store-Pakete
tool/    Generatoren: Icons, Rechtstexte, Web-Postbuild, Firebase-Schalter
```

### Provider (Riverpod)

State-Management ist `flutter_riverpod` 3. Alle Provider stehen in `lib/app/providers.dart`.

- Die **Standardwerte sind Stubs** ohne Netzwerk (`StubLautApi`, `NoopArtworkService`, `FakeNowPlayingRepository`). Dadurch starten Tests und Vorschauen ohne Aufbau.
- `main()` ersetzt sie über **`productionOverrides(...)`** durch die echten Dienste: laut.fm-Client mit Cache, iTunes-Cover mit dauerhaftem Cache, Live-Daten-Motor, System-Teilen, Wecker- und Sleeptimer-Dienste, Chromecast, Widget-Sync. Eigene Dienste kommen als weiterer Override hinein.
- `main()` ruft vor `runApp` feste Init-Funktionen in dieser Reihenfolge: Schriftlizenzen, Konfiguration, `initAudio`, `initDesktop`, Speicher, Telemetrie samt Fehlerhandlern, `initAlarm`, `initCast`, `initHomeWidget`, `initDeepLinks`.
- Wiedergabe: `PlaybackService` kapselt `just_audio` und `audio_service` (Hintergrund, Sperrbildschirm, Medientasten, Android-Auto-Baum). Windows und Linux nutzen `just_audio_media_kit` (`media_kit`), Windows zusätzlich die Mediensteuerung über `smtc_windows`.
- Live-Daten: `LiveNowPlayingRepository` hält den Titel je Sender aktuell (siehe WebSocket-Entscheidung unten).
- Plattformcode wird über bedingte Importe getrennt (`*_io.dart`, `*_web.dart`, `*_stub.dart`), damit Web nicht an `dart:io` scheitert.

### Neue Funktion hinzufügen

1. Modell und Logik in `domain/` mit Test.
2. Dienst-Schnittstelle in `services/` oder `data/`, Fake für Tests.
3. Provider mit Stub in `providers.dart`, echter Dienst in `productionOverrides`.
4. Bildschirm in `features/`, Texte in beide ARB-Dateien.
5. `dart format`, `flutter analyze --fatal-infos`, `flutter test`.

## Deep Links: Wege pro Plattform

Format: `linefm://play?station=<slug>` und `https://app.linefm.de/?station=<slug>` (beliebiger Pfad). Gültige Slugs stehen in `lib/domain/stations_catalog.dart`. Alles läuft über `DeepLinks.dispatch` in `lib/platform/deep_links.dart` mit Puffer für den Kaltstart und Filter gegen doppelte Zustellung (2 Sekunden). Unbekannte Sender und fremde Schemata (z. B. `javascript:`) werden verworfen.

| Plattform | Weg |
|---|---|
| Web | Start-Adresse (`Uri.base`), vom `PlayerController` beim Start ausgewertet. Die Seite nutzt Pfad-URLs (`web_routes.dart`, `pushState`). |
| Android | Eigener Kanal `de.linefm.app/deep_links` in `MainActivity` (Start-Link und laufende Links). Flutters eigenes Deep-Linking ist abgeschaltet (`flutter_deeplinking_enabled=false`), damit nichts doppelt ankommt. Intent-Filter für `linefm://play` und `https://app.linefm.de`. `autoVerify` ist aus, bis `assetlinks.json` auf dem Server liegt (siehe [EINRICHTUNG.md](EINRICHTUNG.md), Abschnitt 2.8). Quelle ist auch das Homescreen-Widget. |
| iOS | Schema `linefm` in `Info.plist`. Das Framework meldet den Link beim Kaltstart über `PlatformDispatcher.defaultRouteName`, laufend über `didPushRouteInformation` (`DeepLinkObserver`). Universal Links: `Runner.entitlements` enthält Associated Domains (`applinks:app.linefm.de`), die AASA-Vorlage liegt in `web/.well-known/apple-app-site-association` und der Web-Postbuild füllt `APPLE_TEAM_ID` ein. Auf einem Gerät noch nicht getestet. |
| macOS | Schema `linefm` in `Info.plist`. Auslieferung wie bei iOS, auf dem Mac ungetestet. |
| Windows | Link als Startargument. Eine zweite Instanz (Mutex pro Benutzersitzung) reicht ihre Argumente an die erste weiter und holt deren Fenster nach vorn. `DeepLinks.dispatchFromArguments(args)`. Der Installer registriert das Schema `linefm://`. |
| Linux | Startargument über die `.desktop`-Datei. Die Einzel-Instanz ist nur unter Windows umgesetzt. |

Tests: `test/platform/deep_links_test.dart`, `android_deep_links_test.dart`, `web_routes_test.dart`.

## Android: Zurück-Geste, Sprachen, Edge-to-Edge

- **targetSdk** kommt aus Flutter (`flutter.targetSdkVersion`, mit Flutter 3.50 also API 36), `compileSdk` steht fest auf 37 (`android/app/build.gradle.kts`). Nach einem Flutter-Update prüfen, ob sich der Wert geändert hat, und die Punkte unten neu ansehen.
- **Edge-to-Edge:** Ab targetSdk 35 zeichnet Android jede App unter Status- und Navigationsleiste; ab API 36 lässt sich das nicht mehr abschalten. Flutter zeichnet ohnehin randlos, die Shell hält Inhalte mit `SafeArea` von den Leisten fern. Neue Bildschirme brauchen das ebenfalls, sonst liegen Knöpfe unter der Gestenleiste.
- **Vorhersagbares Zurück:** `android:enableOnBackInvokedCallback="true"` im Manifest. Die Shell nutzt `PopScope` (`canPop` nur auf der Senderliste), das mit der Geste zusammenarbeitet. Der Test „Vorhersagbares Zurueck“ in `test/app/shell_test.dart` spielt die Geste über den Kanal `flutter/backgesture` nach. Kein `WillPopScope` verwenden, das bricht die Geste.
- **Sprachen pro App:** `res/xml/locales_config.xml` nennt de und en (Android 13+, Einstellungen > Apps > Sprache). Kommt eine Sprache unter `lib/l10n/` dazu, dort ergänzen. Die Sprachwahl in der App (Einstellungen) ist unabhängig davon: Ohne eigene Wahl gilt die Systemsprache bzw. die Per-App-Sprache des Systems, die Wahl in der App geht der Systemsprache vor.

## laut.fm: WebSocket bewusst aus

Der WebSocket `wss://api.laut.fm/song_change.ws.json` meldet Titelwechsel **aller** Sender der Plattform. Gemessen am 19.11.2026:

- ca. **130 MB pro Stunde** Datenverkehr,
- **99,97 Prozent** davon gehören zu fremden Sendern, die die App nicht anzeigt.

Das ist für Mobilfunk und Akku nicht vertretbar. Deshalb ist `WS_ENABLED` standardmäßig `false` und gilt auf **allen** Plattformen. Stattdessen:

1. **`ends_at`-Timer** für den aktiven Sender: Abruf drei Sekunden nach dem angekündigten Ende des Titels (mindestens 10 Sekunden, höchstens 10 Minuten Wartezeit).
2. **Polling** alle 60 Sekunden im Vordergrund (`current_song` aller Sender, `last_songs` und `listeners` des aktiven Senders), im Hintergrund nur für den aktiven Sender und nur bei Wiedergabe.
3. **Live-Sendungen** ohne bekanntes Ende (Moderation): Abruf alle 30 Sekunden.
4. Antworten werden zwischengespeichert (die API liefert etwa 121 Sekunden Cache). Der Code steht noch, nur der Schalter ist aus. Wer ihn mit `WS_ENABLED=true` einschaltet, bekommt zusätzlich einen Traffic-Wächter.

Ein Titel erscheint dadurch bis zu einige Sekunden später als mit WebSocket. Die ICY-Metadaten des Streams sind nur auf Android, iOS und macOS lesbar, deshalb kommen Titel überall aus der API.

## Google Cast: offener Punkt beim Plugin

Die App startet das Cast-SDK erst beim ersten Tippen auf den Cast-Knopf (`initCast`, L4). Das Plugin `flutter_chrome_cast` 2.0.0 ruft auf Android aber in `onDetachedFromEngine` `CastContext.getSharedInstance(appContext)` auf (`android/src/main/kotlin/com/felnanuke/google_cast/CastContextMethodChannel.kt`, Zeile 139), um einen Listener abzumelden. Läuft das, ohne dass Cast vorher genutzt wurde, initialisiert genau dieser Aufruf das SDK, also beim Beenden der App.

Entscheidung: kein eigener Fork des Plugins. Die Datenschutzerklärung (Abschnitt 7) nennt die Ausnahme. Upstream-Wunsch an das Plugin: im Abbau `CastContext.getSharedInstance()` nur aufrufen, wenn der Kontext schon initialisiert ist (eigenes Flag oder `CastContext.getSharedInstance()` ohne Kontext-Argument mit try/catch). Bei jedem Update von `flutter_chrome_cast` die Stelle neu prüfen und die Datenschutzerklärung anpassen, sobald sie behoben ist.

## Weiterführende Dokumente

- Web-Hosting: [hosting-uebersicht.md](hosting-uebersicht.md) mit [nginx](hosting-nginx.md), [Traefik](hosting-traefik.md), [Cloudflare](hosting-cloudflare.md), [Plesk](hosting-plesk.md)
- Telemetrie und Selbsthosting von Umami und GlitchTip: [telemetry.md](telemetry.md)
- Verpackung und Signierung: [packaging/README.md](../packaging/README.md)
- Release-Gate: [FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md)
