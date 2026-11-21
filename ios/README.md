# iOS und macOS: native Teile (P17)

Diese Seite beschreibt den nativen Code der Apple-Plattformen. Veröffentlicht
wird für Apple vorerst nicht (Entscheidung 21); alles ist so vorbereitet, dass
später nur Konto, Profile und Freigaben eingetragen werden müssen.

Hinweis: Entwickelt wurde ohne Mac. iOS und macOS sind nicht lokal gebaut
worden; Abnahme über den macOS-Job in CI (`build.yml`, `apple=true` bzw.
PR-Label `ci:apple`) oder einen Mac. Der iOS-Job prüft nach dem Build das
fertige Bundle (Widget eingebettet, Info.plist-Schlüssel, Privacy-Manifeste,
native Kanäle im Binary).

Mindestversion: iOS 16.0 (Entscheidung des Inhabers vom 21.11.2026). Grund:
Chromecast läuft über `flutter_chrome_cast`, das das Google Cast SDK per
Swift Package Manager zieht (`SRGSSR/google-cast-sdk`); ab SDK 4.8.6 verlangt
Google iOS 16. macOS: Flutter hebt das Ziel beim Build selbst auf 12.0.

Cast-SDK-Pin: Das Plugin (2.0.0) erklärt selbst nur iOS 15, fordert das SDK
aber mit `from: "4.8.4"` an. SPM löst dann 4.8.6 auf, und Xcode bricht am
Plugin-Ziel ab („GoogleCast requires minimum platform version 16.0 … this
target supports 15.0“), egal welche Mindestversion die App hat. Deshalb
pinnt `Runner.xcodeproj` das SDK exakt auf 4.8.4 (`XCRemoteSwiftPackageReference`,
ein Pin im Wurzelprojekt gewinnt gegen den Bereich des Plugins). Entfernen,
sobald `flutter_chrome_cast` iOS 16 erklärt (Upstream-Issue
felnanuke2/flutter_google_cast#90), dann läuft wieder das aktuelle SDK.

## Überblick iOS (`ios/Runner`)

| Datei | Aufgabe |
| --- | --- |
| `AppDelegate.swift` | Erzeugt und startet die gemeinsame `FlutterEngine`, registriert Plugins und die eigenen Kanäle |
| `SceneDelegate.swift` | Telefon-Szene, zeigt die gemeinsame Engine (kein Storyboard mehr) |
| `CarPlaySceneDelegate.swift` | CarPlay-Audio: Tabs Favoriten-Sender, Stationen, Zuletzt gehört; Antippen spielt und öffnet Now Playing |
| `CarPlayChannel.swift` | Kanal `de.linefm.app/carplay` (Vertrag in `lib/platform/carplay_bridge.dart`) |
| `AlarmNotifications.swift` | Kanal `de.linefm.app/alarm_ios`: Wecker als lokale Mitteilung (`UNCalendarNotificationTrigger`, Systemton) |
| `AirPlayRoutePicker.swift` | Platform View `de.linefm.app/airplay_route_picker` + Kanal `de.linefm.app/airplay` |
| `PrivacyInfo.xcprivacy` | Datenschutz-Manifest (Required Reason APIs, erhobene Daten) |
| `Runner.entitlements` / `Runner-CarPlay.entitlements` | App Group; CarPlay nur in der zweiten Datei |
| `de.lproj`, `en.lproj` | Systemtexte (`InfoPlist.strings`) |

Widget: `ios/LinefmWidget` (WidgetKit, Ziel `LinefmWidgetExtension`,
Bundle-ID `de.linefm.app.widget`). Senderlogos für Widget und CarPlay liegen
in `ios/Shared/StationLogos.xcassets` (`station_<slug>`).

### Gemeinsame Engine

CarPlay muss auch starten, wenn nur das Auto verbunden und das Telefon
gesperrt ist. Deshalb startet der `AppDelegate` die Engine beim App-Start
(`allowHeadlessExecution`). Telefon und CarPlay teilen sie. In `main()` muss
`initCarPlay(playback)` nach `initAudio()` laufen (Änderungswunsch an P28).

### Deep Links

- `linefm://play?station=<slug>` (Info.plist `CFBundleURLTypes`) kommt über
  Flutters Deep Linking (`FlutterDeepLinkingEnabled`) als Routeninformation
  an `DeepLinkObserver` (`lib/platform/deep_links.dart`). Kaltstart: der
  `SceneDelegate` legt das Fenster vor `super` an, damit Flutter den Link aus
  den Verbindungsoptionen der Engine zustellen kann.
- Wecker und Widget öffnen denselben Link.
- Universal Links `https://app.linefm.de/?station=<slug>`: vorbereitet,
  aber aus. So einschalten:
  1. Team-ID aus dem Apple-Konto holen.
  2. Auf `https://app.linefm.de/.well-known/apple-app-site-association`
     (ohne Endung, `Content-Type: application/json`, ohne Weiterleitung)
     ausliefern:
     `{"applinks":{"details":[{"appIDs":["<TEAM_ID>.de.linefm.app"],"components":[{"/":"/*","?":{"station":"*"}}]}]}}`
  3. In der App-ID „Associated Domains“ aktivieren, Profile neu erzeugen.
  4. In `Runner.entitlements` und `Runner-CarPlay.entitlements` den
     auskommentierten Block `com.apple.developer.associated-domains`
     einkommentieren.
  Die App braucht dafür keinen weiteren Code: `continueUserActivity` leitet
  Flutter genauso an den `DeepLinkObserver` weiter.

## CarPlay einschalten

Voraussetzung: jaybelife beantragt bei Apple das CarPlay-Audio-Entitlement
(https://developer.apple.com/carplay/, Kategorie Audio) für die App-ID
`de.linefm.app`.

Nach der Freigabe:

1. Im Apple-Developer-Konto das Entitlement der App-ID zuordnen und die
   Provisioning-Profile neu erzeugen.
2. Build-Einstellung `CARPLAY_ENABLED` auf `YES` setzen, entweder dauerhaft
   im Ziel „Runner“ (Xcode → Build Settings → User-Defined) oder je Build:
   `xcodebuild … CARPLAY_ENABLED=YES` bzw. in fastlane `xcargs:
   "CARPLAY_ENABLED=YES"`.
   Damit verwendet Xcode `Runner/Runner-CarPlay.entitlements`.

Mehr ist nicht nötig. Szene (`CPTemplateApplicationSceneSessionRoleApplication`
im Info.plist) und Code sind immer enthalten; ohne Entitlement verbindet iOS
die CarPlay-Szene nur nicht.

Testen ohne Freigabe: Xcode-Simulator → I/O → External Displays → CarPlay
(Debug-Build mit `CARPLAY_ENABLED=YES`, Simulator prüft die Signatur nicht).

## Wecker (iOS)

iOS startet keine App zur Weckzeit. Die App plant deshalb je Wochentag eine
wiederholende Mitteilung mit Systemton (Entscheidung 40). Antippen öffnet
`linefm://play?station=<slug>` und startet den Sender. Für Mitteilungen gibt
es unter iOS keinen eigenen Erklärtext im Info.plist; die Systemabfrage
erscheint beim ersten Planen.

## macOS (`macos/Runner`)

- Sandbox mit `network.client` (Streams, API) und
  `files.downloads.read-write` (Export-Rückfall in „Downloads“).
- Release mit Hardened Runtime (Voraussetzung für die Notarisierung).
- Now Playing, Medientasten und Steuerzentrale über audio_service
  (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`), kein eigener Code.
- Menüleiste: Standardmenüs aus `MainMenu.xib` mit App-Name „LINEFM Radio“.
- AirPlay-Knopf: `AirPlayRoutePicker.swift` (macOS 10.15+). Offen: auf einem
  Mac prüfen, ob der Picker ohne AVPlayer-Bezug die Ausgabe umschaltet.

## Datenschutz-Manifest

`PrivacyInfo.xcprivacy` (App, Widget, macOS) nennt die Required Reason APIs
des eigenen Codes (UserDefaults, Dateizeitstempel) und die nur mit
Einwilligung erhobenen Daten (Absturzdaten, Nutzungsereignisse; nicht
verknüpft, kein Tracking). Ändert sich die Telemetrie (`docs/telemetry.md`),
Manifest und App-Store-Angaben anpassen.

## Offen (braucht Apple-Konto oder Mac)

- Simulator- und Gerätetests (der CI-Job baut nur unsigniert für Geräte).
- App Group `group.de.linefm.app` im Konto anlegen, beiden App-IDs zuordnen.
- CarPlay-Entitlement (siehe oben), Universal Links (Team-ID, AASA).
