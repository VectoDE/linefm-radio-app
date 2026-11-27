# Gerätetests

Stand: 27.11.2026. Getestet wurde der Debug-Build vom aktuellen `main` im Android-Emulator, auf einem Emulator ohne Google-Dienste, die Web-Fassung in Microsoft Edge und die Windows-Fassung über den Integrationstest in der CI. Echte Telefone waren nicht im Spiel.

Die Belege liegen unter [`assets/geraetetests/`](assets/geraetetests/).

## Testumgebung

| Punkt | Wert |
|---|---|
| Android | Emulator `linefm_api35`, Android 15 (API 35), Systemabbild „Google APIs Play Store“, x86_64, 1080 × 2400 |
| App | `de.linefm.app`, Debug-APK, per `adb install` |
| Web | `flutter build web`, lokal über `http://localhost:8765`, Microsoft Edge über Playwright (Kanal `msedge`, frischer Kontext) |
| Android ohne Google-Dienste | Emulator `linefm_api35_aosp`, Android 15, Abbild „default“ (AOSP), x86_64 |
| Windows | Integrationstest in der CI (GitHub Actions, Windows-Runner) |

## Ergebnisse

| Nr. | Test | Ergebnis | Beleg |
|---|---|---|---|
| A1 | TalkBack-Durchgang | Teilweise, mit Befund | `android-talkback-ansage-titel.png`, `android-talkback-ansage-tab.png`, `android-talkback-ansage-einstellungen.png` |
| A2 | Systemschrift 200 % | Bestanden mit Befund | `android-schrift-200.png`, `android-schrift-200-player.png`, `android-schrift-200-verlauf.png` |
| A3 | Wischgesten im Player | Bestanden | `android-wischen-vorher.png`, `android-wischen-nachher.png` |
| A4 | Wecker mit `SCHEDULE_EXACT_ALARM` und Doze | Bestanden mit Befund | `android-wecker-dialog.png`, `android-wecker-gesetzt.png`, `android-wecker-ausgeloest.png`, Log unten |
| A5 | Cast-Initialisierung (§ 25 TDDDG, technische Prüfung) | Bestanden | Log unten |
| A6 | Android-Widget | Bestanden | `android-widget.png`, `android-widget-spielt.png`, `android-mediensteuerung.png` |
| A7 | Systemabbild ohne Google-Play-Dienste | Bestanden | `android-ohne-gms-start.png`, `android-ohne-gms-player.png`, `android-ohne-gms-cast.png`, Log unten |
| A8 | Android Auto mit Desktop Head Unit | Nicht durchgeführt | – |
| A9 | Store-Screenshots und Feature-Grafik für Google Play | Erstellt | `fastlane/metadata/android/*/images/` |
| W1 | Windows und Web mit NVDA | Nicht durchgeführt | – |
| W2 | Windows: Tastatur, Infobereich, Mini-Fenster | Über den CI-Integrationstest | Artefakt `windows-itest-screens` |
| W3 | Web: Autoplay in Edge | Bestanden | `web-edge-start.png`, `web-edge-nach-klick.png` |
| W4 | Web: Autoplay in Firefox | Nicht durchgeführt | – |

## Einzelheiten

### A1 TalkBack

TalkBack 15.0 lief mit zwei Entwickler-Einstellungen: „Display speech output“ blendet jede Ansage ein, „Log output level“ stand auf VERBOSE. Der Fokus startet auf dem Kopfbereich der App.

Den Fokus weiterbewegen ließ sich nicht fernsteuern:

- `adb shell input swipe` und `input tap` kommen als eingespielte Ereignisse an. TalkBack wertet sie nicht als Geste oder Touch-Erkundung, ein Tippen löst das Element direkt aus.
- Tastenkürzel über die echte Emulator-Tastatur (`adb emu event send`, Alt + Pfeil rechts) haben den Fokus nicht bewegt.
- `sendevent` auf das Touch-Gerät braucht Root-Rechte, das Play-Abbild hat keine.
- Auch mit VERBOSE schreibt TalkBack den gesprochenen Text nicht ins Log.

Belegt sind deshalb die Ansagen, die TalkBack von sich aus macht:

| Situation | Ansage | Beleg |
|---|---|---|
| Neuer Titel im Player | „I Like The Way She Do It, G-Unit ft. Young Buck“ | `android-talkback-ansage-titel.png` |
| Wechsel des Reiters in der unteren Navigation | „selected“ | `android-talkback-ansage-tab.png` |
| Einstellungen geöffnet | keine Ansage | `android-talkback-ansage-einstellungen.png` |

Befund: Beim Öffnen der Einstellungen und der Favoriten sagt TalkBack nichts an. Wer blind bedient, merkt den Seitenwechsel also nicht. Beim Reiterwechsel kommt nur „selected“, ohne den Namen des Reiters.

Belegt ist außerdem der Zugriffsbaum über `uiautomator dump`: Jeder Sender, jeder Favoriten-Stern, die Player-Leiste und die Navigation haben eine Beschriftung, zum Beispiel „LineFM +MAIN, now playing: Teddy Swims - Lose Control“ oder „Add LineFM +RAP to favorite stations“, auf Deutsch „LineFM +LOFI als Favoriten-Sender merken“.

Offen: ein Durchgang von Hand mit Wischgesten am Emulator-Fenster oder an einem Telefon.

### A2 Systemschrift 200 %

`settings put system font_scale 2.0`. Senderliste, Player und Verlauf bleiben bedienbar, nichts überlappt die Bedienelemente.

Befund: Die drei Beschriftungen der unteren Navigation laufen ohne Abstand ineinander und lesen sich als „STATIONSPLAYERHISTORY“. Lange Titel werden abgeschnitten oder laufen als Band, die Symbole im Kopfbereich wachsen nicht mit.

### A3 Wischgesten

Im Player wechselt ein Wisch nach links zum nächsten Sender (LineFM +MAIN zu LineFM +RAP). Das passt zum Code in `player_view.dart` (Schwelle 300 Pixel pro Sekunde).

### A4 Wecker, exakte Alarme und Doze

1. Nach der Installation ist „Alarms & reminders“ nicht erteilt. Die App zeigt den Hinweis mit „Open settings“ (`android-wecker-dialog.png`).
2. Recht per `appops set de.linefm.app SCHEDULE_EXACT_ALARM allow` erteilt.
3. Wecker auf 11:26 gestellt. `dumpsys alarm` zeigt ihn als `RTC_WAKEUP` mit `showIntent`, also als Wecker über `setAlarmClock`, und als „Next wake from idle“.
4. Bildschirm aus, Akku abgesteckt (`dumpsys battery unplug`), `dumpsys deviceidle force-inactive` und `step light`: leichte Doze-Stufe `IDLE`.
5. Der Wecker hat um 11:26:00 ausgelöst:

```text
11:26:00.189 ActivityManager: Background started FGS: Allowed [callingPackage: de.linefm.app ...]
11:26:00.611 MediaFocusControl: requestAudioFocus() ... AA=USAGE_ALARM ...
11:26:05.382 AlarmService: Alarm rang notification ... was processed successfully by Flutter.
11:26:05.512 AlarmPlugin: Making app visible on lock screen...
```

Danach zeigte die App „LineFM +MAIN is about to start.“ mit „Snooze“ und „Turn off“ (`android-wecker-ausgeloest.png`).

Die tiefe Doze-Stufe ließ sich im Emulator nicht erzwingen, `force-idle` blieb bei `INACTIVE` stehen. Der Test belegt also die leichte Stufe. Weil der Wecker über `setAlarmClock` läuft, weckt Android ihn auch aus der tiefen Stufe. Das ist dokumentiertes Verhalten von Android, hier aber nicht gemessen.

Befund: Nachdem das Recht per `appops` erteilt war, blieb der Hinweis „Without the ‚Alarms & reminders‘ permission …“ stehen, bis die Seite neu geöffnet wurde. Ursache ist der Testweg: `appops` ändert das Recht, während die App im Vordergrund bleibt. Die App prüft das Recht bei jeder Rückkehr in den Vordergrund neu (`AlarmBootstrap`, `AppLifecycleState.resumed`). Wer über „Open settings“ in die Systemeinstellungen wechselt und zurückkommt, sieht den Hinweis danach nicht mehr. Ein Widget-Test deckt das ab.

### A5 Cast und § 25 TDDDG

Logcat geleert, App frisch gestartet, 30 Sekunden laufen lassen, mit Zurück und Home verlassen. Im Prozess der App gibt es dabei keine Zeile zu `CastContext`, `MediaRouter` oder einer Gerätesuche. Die einzige Cast-Zeile kommt beim Beenden:

```text
11:28:33.336 GoogleCastPlugin: App destroyed - stopCastingOnAppTerminated is false, keeping cast session alive
```

Das ist die Abmeldung des Plugins, keine Gerätesuche. Ohne Tippen auf die Cast-Schaltfläche wird also keine Cast-Sitzung aufgebaut. Einschränkung: Wir haben nur das Log ausgewertet, keinen Netzwerkverkehr mitgeschnitten (mDNS). Die rechtliche Einordnung nach § 25 TDDDG gehört zu Anwalt oder Datenschutzbeauftragtem.

### A6 Widget

Widget „LINEFM Radio“ (4 × 1) über die Widget-Auswahl des Pixel-Launchers auf den Startbildschirm gelegt. Es zeigt Sender, Titel und Interpret. Ein Tippen auf Play startet den Stream, die Mediensitzung wechselt über `CONNECTING` auf `PLAYING`.

### A7 Ohne Google-Play-Dienste

Abbild `system-images;android-35;default;x86_64` (AOSP, Revision 2, Datei `x86_64-35_r02.zip`), über `sdkmanager` von dl.google.com geladen, entpackt 1,7 GB. Darauf das neue Gerät `linefm_api35_aosp`. Ein Paket `com.google.android.gms` gibt es auf dem Abbild nicht.

- Start: Die App startet ohne Fehler, der Hinweis zur Speicherung erscheint (`android-ohne-gms-start.png`).
- Wiedergabe: Der Stream läuft, die Mediensitzung steht auf `PLAYING` (`android-ohne-gms-player.png`).
- Cast-Knopf: Erst beim Tippen versucht die App, Cast zu starten. Das schlägt fehl, die App stürzt aber nicht ab. Sie meldet „Google Cast is not available on this device. On Android it needs Google Play services.“ und blendet den Cast-Knopf danach aus. Der Stream läuft weiter (`android-ohne-gms-cast.png`).

```text
12:13:22.394 GoogleApiManager: The service for com.google.android.gms.cast.internal.zzo is not available: ConnectionResult{statusCode=SERVICE_INVALID ...}
12:13:22.422 CastContext: Failed to set shared instance
12:13:22.422 CastContext:   at com.felnanuke.google_cast.CastContextMethodChannel.setSharedInstance(CastContextMethodChannel.kt:193)
```

Das bestätigt A5: `CastContext` entsteht erst nach dem Tippen auf den Cast-Knopf, nicht beim Start.

### A8 Android Auto

Nicht durchgeführt. Die Desktop Head Unit liegt im SDK (`extras/google/auto/desktop-head-unit.exe`). Auf dem Emulator ist Android Auto aber nur als Platzhalter installiert (`1.2.542030-stub`). Für den Head-Unit-Server braucht es die volle App aus dem Play Store und dafür ein angemeldetes Google-Konto auf dem Emulator. Die App meldet sich laut Manifest als `MediaBrowserService` für Android Auto an.

### A9 Store-Screenshots

Je Sprache sieben Bilder, 1080 × 1920 (9:16). Google Play erlaubt höchstens 2:1. Die echte Anzeige von 1080 × 2400 liegt darüber, deshalb lief der Emulator dafür mit `wm size 1080x1920`.

| Datei (de-DE) | Datei (en-US) | Inhalt |
|---|---|---|
| `1_sender.png` | `1_stations.png` | Senderliste, dunkel |
| `2_player.png` | `2_player.png` | Player, dunkel |
| `3_verlauf.png` | `3_history.png` | Verlauf, dunkel |
| `4_favoriten.png` | `4_favorites.png` | Favoriten, dunkel |
| `5_wecker.png` | `5_alarm.png` | Wecker, dunkel |
| `6_player_hell.png` | `6_player_light.png` | Player, hell |
| `7_sender_hell.png` | `7_stations_light.png` | Senderliste, hell |

Die Bilder zeigen echte App-Daten mit laufendem Programm. „Cover laden“ war ausgeschaltet, deshalb sind nur die Senderlogos von LINEFM zu sehen, keine Albumcover. Titel und Interpreten aus dem Programm stehen als Text in den Bildern. Die Statusleiste lief im Demo-Modus von Android (feste Uhrzeit, voller Akku, keine Benachrichtigungen).

Feature-Grafik: `featureGraphic.png`, 1024 × 500, 24 Bit ohne Transparenz, je Sprache. Gebaut aus den Senderlogos unter `assets/images/stations/` (nur die vier LINEFM-Sender), den Schriften Syncopate und Poppins und den Markenfarben.

### W1 NVDA

Nicht durchgeführt. Die Installer sind geladen, ihre Signaturen sind gültig (`Get-AuthenticodeSignature`, Status „Valid“):

| Programm | Datei | Quelle | Größe | Signiert von |
|---|---|---|---|---|
| NVDA 2026.3.1 | `nvda_2026.3.1.exe` | download.nvaccess.org | 66,7 MB | NV Access Limited |
| Firefox 161.0 (de) | `Firefox Setup 161.0.exe` | download-installer.cdn.mozilla.net | 92,1 MB | Mozilla Corporation |

Die stille Installation (`--install-silent` bzw. `-ms`) hat die Rechteverwaltung der Testumgebung abgelehnt. Ohne NVDA gibt es keinen Durchgang durch die Windows-App und die Web-App, ohne Firefox keinen Autoplay-Test dort. Die Installation muss der Inhaber selbst starten oder per Rechteregel freigeben.

### W2 Windows: Tastatur, Infobereich, Mini-Fenster

Belegt über den Integrationstest `integration_test/windows_app_test.dart` in der CI (Workflow „Windows integration test“). Letzter Lauf auf `main`: [Lauf 45976406020](https://github.com/VectoDE/linefm-radio-app/actions/runs/45976406020) vom 27.11.2026, Commit `370d3e6`, Artefakt `windows-itest-screens`.

- Infobereich: Der Test schließt das Fenster in den Infobereich und holt es zurück (Bilder `87-09-geschlossen-im-tray` und `87-10-aus-dem-tray-zurueck`).
- Tastatur und Mini-Fenster: Mit diesem Bericht kommt ein Testfall dazu. Er bewegt den Fokus mit Tab, startet mit der Taste 2 den zweiten Sender, wechselt ins Mini-Fenster (360 × 120, immer im Vordergrund) und zurück. Bilder `60-01-tab-fokus` bis `60-04-zurueck-aus-mini-fenster`. Lokal ist der Testfall nur statisch geprüft (`flutter analyze` ohne Befund). Laufen wird er erst in der CI nach dem Push.

### W3 und W4 Web-Autoplay

In Edge erscheint nach dem Laden die Startseite mit „Radio starten“. Bis zum Klick spielt kein Ton, die Konsole meldet keinen abgelehnten Autoplay-Versuch. Nach dem Klick läuft der Stream: Pegelanzeige am Sender, Stopp-Schaltfläche im Player. Die App hält sich damit an die Autoplay-Regeln der Browser, weil sie auf eine Nutzeraktion wartet.

Chrome war für diesen Test ausgeschlossen. Firefox ist geladen, aber nicht installiert (siehe W1).

Nebenbefund: Im lokalen Web-Build steht im Fuß `© __COPYRIGHT_YEARS__`. Der Platzhalter wird offenbar erst in der Release-Pipeline ersetzt. Ob das dort klappt, ist hier nicht geprüft.

## Automatisierte Prüfungen (ohne Gerät)

Was sich ohne echtes Gerät prüfen lässt, läuft automatisch. Stand 27.11.2026.

| Nr. | Prüfung | Wo sie läuft | Ergebnis |
|---|---|---|---|
| S1 | Zugriffsbaum der Navigation: benannte Schaltflächen, genau ein Ziel ausgewählt, Ansage des Bereichs beim Wechsel, Schiene im breiten Layout mit „Tab n von 3“, keine unbenannte Schaltfläche in den fünf Bereichen (`test/a11y/semantics_tree_test.dart`) | Tests in der CI (`ci.yml`) | 4 Tests grün |
| S2 | Tippflächen, Beschriftungen, Kontrast, Textgröße 200 %, Tab-Reihenfolge (`test/a11y/semantics_guidelines_test.dart`) | Tests in der CI | bestehend |
| S3 | Tastenkürzel unter der Plattform Linux: Ziffern 1 bis 6, Leertaste, Strg+Komma, Esc, F, S, Abschalten der Ein-Zeichen-Kürzel (WCAG 2.1.4), Alt bleibt beim Fenstermanager (`test/a11y/keyboard_shortcuts_linux_test.dart`) | Tests in der CI (Ubuntu-Runner) | 7 Tests grün |
| S4 | axe-core gegen die Web-Version (WCAG 2.2) | `a11y.yml` | bestehend |
| S5 | Zugriffsbaum auf Android: `uiautomator dump` ist derselbe Baum, den TalkBack liest. `tool/a11y/android_tree_check.py` prüft, dass jedes bedienbare Element einen Namen hat und mindestens 48 × 48 dp misst, `tool/a11y/android_walk.py` geht die fünf Bereiche durch | lokal, Emulator `linefm_api35_aosp`, Debug-Build von `main` | 5 von 5 Bereichen ohne Befund (41, 33, 59, 32 und 43 Knoten, 20, 12, 18, 10 und 15 bedienbare) |

Grenzen von S3: Die Tests laufen mit der Plattformangabe Linux, aber ohne echten Linux-Desktop. Fenstermanager, Eingabemethode und globale Tastenkürzel des Desktops prüft nur ein Lauf auf einem Linux-Rechner. Grenzen von S5: Der Baum belegt Namen, Größen und Klickbarkeit. Er belegt nicht, was TalkBack spricht und in welcher Reihenfolge Wischgesten den Fokus bewegen (siehe A1).

## Nur mit Gerät, Programm oder Konto (Inhaber oder Julian)

Diese Prüfungen lassen sich nicht automatisieren. Sie laufen von Hand, die Ergebnisse tragen wir hier nach.

| Prüfung | Was gebraucht wird | Warum nicht automatisch |
|---|---|---|
| TalkBack-Durchgang mit Wischgesten und Sprachausgabe | Android-Telefon oder Emulator mit Fenster und von Hand bedient | Eingespielte Touch-Ereignisse wertet TalkBack nicht als Geste (A1), die Sprachausgabe steht nicht im Log |
| NVDA mit Windows-App und Web-App (Chrome, Edge, Firefox) | NVDA 2026.3.1 und Firefox sind geladen, die Installation lehnt die Rechteverwaltung der Testumgebung ab (W1) | Installation braucht Administratorrechte |
| VoiceOver auf iPhone und Mac, Tastatur, Screenreader und Autoplay in Safari | Mac und iPhone | Safari und VoiceOver gibt es nur auf Apple-Geräten |
| Chromecast: Start, Titelwechsel, Senderwechsel, Lautstärke | Chromecast im selben Netz | Braucht ein echtes Cast-Gerät |
| Android Auto mit Head Unit (A8) | Telefon mit Android Auto oder Emulator mit Google-Konto, Desktop Head Unit | Volle Android-Auto-App braucht ein angemeldetes Google-Konto |
| Doze, tiefe Stufe, Wecker auf einem Telefon (A4) | Echtes Telefon | Im Emulator nicht erzwingbar |
| Desktop-Tray, Mini-Fenster und Tastenkürzel auf einem echten Linux-Desktop | Linux-Rechner (GNOME, KDE) | Das Tray hängt am Desktop (S3 deckt nur die Logik ab) |
| Autoplay in Firefox und Safari (siehe W3) | Firefox installiert, Safari auf einem Mac | Browser nicht vorhanden |

## Was offen bleibt

- TalkBack-Durchgang von Hand mit Wischgesten (Zugriffsbaum ist automatisch belegt, siehe S5).
- Tiefe Doze-Stufe messen, am besten auf einem echten Telefon.
- Android Auto mit Head Unit: Google-Konto auf dem Emulator und volle Android-Auto-App nötig.
- NVDA und Firefox installieren, dann Windows-App und Web-App mit NVDA durchhören und Autoplay in Firefox prüfen.
- Neuen Windows-Testfall (Tastatur, Mini-Fenster) in der CI laufen lassen und die Bilder prüfen.
- Am Gerät nachprüfen: Abstand der Navigationsbeschriftungen bei 200 % Schrift und Ansage von Seiten- und Reiterwechsel mit TalkBack. Beides ist eingebaut und per Widget-Test belegt.
