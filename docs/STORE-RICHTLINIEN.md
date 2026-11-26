# Store-Richtlinien: Prüfliste für LINEFM Radio

Englische Fassung: [STORE-POLICIES.md](STORE-POLICIES.md). Beide Dateien haben denselben Inhalt.

Diese Liste ist für den Kunden und den Betreiber gedacht. Sie dient als Vorlage für jede Einreichung und als Prüfliste vor jedem Release. Jeder Punkt fasst eine offizielle Richtlinie in eigenen Worten zusammen und ersetzt den Originaltext nicht. Vor einer Einreichung also die verlinkte Quelle öffnen und den aktuellen Wortlaut lesen. Kurze Zitate bleiben unter 15 Wörtern.

**So liest du einen Eintrag**

- `[x]` heißt: heute erfüllt. `[ ]` heißt: Hier ist noch etwas zu tun.
- **Status:** `OK` (erfüllt und im Repository geprüft), `offen` (im Repository fehlt noch Arbeit) oder `Inhaber` (der Kunde oder der Betreiber entscheidet oder handelt in einer Store-Konsole).
- **Wo:** die Stelle, an der der Punkt erledigt wird: ein Pfad in diesem Repository, ein Feld in einer Store-Konsole oder eine Seite der Website.
- **Quelle:** Link auf die offizielle Seite und das Abrufdatum. "nicht geprüft" heißt, die Seite wurde an dem Tag nicht vollständig gelesen (zum Beispiel, weil sie nur mit JavaScript lädt). Dann vorher selbst lesen.

**Bereits getroffene Entscheidungen (26.11.2026)**

- Altersfreigabe 13+ in allen Stores, Zielgruppe 13+, OARS `language-profanity` moderate. Keine Ausrichtung auf Kinder.
- Telemetrie in Store-Builds: Sentry, Firebase und Umami, jeweils erst nach Einwilligung. Alle Datenschutzformulare geben diese drei als optionale Datenerhebung an.
- Der Updater steckt nur in den Direktdownloads (Windows-Setup, macOS-DMG). Ein Build-Schalter entfernt ihn aus jedem Store-Build, ein CI-Check stellt das sicher.
- Flathub bekommt einen Offline-Build aus dem Quellcode, kein vorgebautes Archiv.
- iOS-Wecker: AlarmKit ab iOS 26, darunter eine Mitteilung als Ersatz, mit klarem Hinweis in App und Store-Text.
- Der Mac App Store wird zusammen mit iOS eingereicht. Der Export läuft über einen Speichern-Dialog statt über die Berechtigung für den Downloads-Ordner.
- Lizenzseite: `/lizenz/` (Deutsch und Englisch) in der Web-App.
- `USE_FULL_SCREEN_INTENT` ist eine Nebenfunktion: in der Play Console deklariert, zur Laufzeit angefragt, mit Mitteilung als Ersatz.
- Jeder Store läuft über das eigene Organisationskonto des Kunden.
- Apple (iOS und Mac App Store) gehört nicht zum ersten Release, beide folgen später gemeinsam.
- Support-Kontakt in jedem Store: support@linefm.de und eine Seite `/support/` (Deutsch und Englisch) in der Web-App.
- Der Signaturschlüssel des Updaters ist das Secret `UPDATER_ED25519_PRIVATE_KEY` in der Umgebung `release`.
- Der Kunde hat die Vereinbarung mit laut.fm und verwahrt sie selbst. Wo ein Store nach Inhaltsrechten fragt, steht es unten beim Eintrag.
- Der Kunde legt die Flathub-Datei zur Domain-Bestätigung zum Livegang ab.

<a id="aktualitaet"></a>**Aktualität:** Der Workflow `.github/workflows/store-policy-watch.yml` prüft einmal im Monat jede verlinkte Seite (erreichbar, Text geändert) und legt bei einer Änderung ein Ticket an. Nach dem Durchsehen die Vergleichsbasis mit `python3 tool/check_store_policy_links.py --update-baseline` erneuern und die betroffenen Einträge und Daten hier und in der englischen Fassung anpassen.

---

## Google Play

Quellen (alle abgerufen am 26.11.2026):

- Richtlinien für Entwickler: <https://play.google/developer-content-policy/>
- Datensicherheit: <https://support.google.com/googleplay/android-developer/answer/10787469>
- Nutzerdaten: <https://support.google.com/googleplay/android-developer/answer/10144311>
- Berechtigungen und sensible APIs (auch exakte Alarme): <https://support.google.com/googleplay/android-developer/answer/9888170>
- Vordergrunddienst und Vollbild-Intent: <https://support.google.com/googleplay/android-developer/answer/13392821>
- Typen von Vordergrunddiensten: <https://developer.android.com/develop/background-work/services/fgs/service-types>
- Ziel-API-Level: <https://developer.android.com/google/play/requirements/target-sdk>
- Zielgruppe und App-Inhalte: <https://support.google.com/googleplay/android-developer/answer/9867159>
- Altersfreigabe (IARC): <https://support.google.com/googleplay/android-developer/answer/9898843>
- Metadaten: <https://support.google.com/googleplay/android-developer/answer/9898842>
- Qualität von Auto-Apps: <https://developer.android.com/docs/quality-guidelines/car-app-quality>
- 16-KB-Speicherseiten: <https://developer.android.com/guide/practices/page-sizes>
- Play App Signing: <https://support.google.com/googleplay/android-developer/answer/9842756>

### Richtlinien für Entwickler (ein Eintrag je Abschnitt)

- [x] <a id="g-01"></a>**G-01 Eingeschränkte Inhalte.** Keine sexuellen Inhalte, kein Hass, keine Gewalt, keine illegalen Waren und kein Glücksspiel in der App selbst. Die Streams sind Radioprogramme, gelegentlich derbe Songtexte deckt die Altersfreigabe ab. Status: OK. Wo: Senderliste unter `assets/config/`, Einstufung in der Play Console. Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [x] <a id="g-02"></a>**G-02 Identitätsdiebstahl.** Die App gibt sich nicht als andere Marke aus und behauptet keine offizielle Verbindung, die es nicht gibt. Die Store-Texte nennen "LineFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe" und führen Radio3FM und FobFM als Partnersender. Status: OK. Wo: `docs/STORE-TEXTE.md`. Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [ ] <a id="g-03"></a>**G-03 Geistiges Eigentum.** Für Streams, Sendernamen und Logos braucht es ein Nutzungsrecht. Der Kunde hat die laut.fm-Vereinbarung und hält sie bereit, falls Google nachfragt. Status: Inhaber. Wo: Unterlagen des Kunden, Play Console > App-Inhalte (auf Nachfrage). Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [ ] <a id="g-04"></a>**G-04 Datenschutz, Täuschung und Gerätemissbrauch.** Nur erheben, was offengelegt ist, vorher fragen, kein verstecktes Verhalten. Telemetrie startet erst nach Einwilligung. In der Datenschutzerklärung stehen noch Platzhalter. Status: offen. Wo: `lib/features/consent/`, `web/datenschutz/index.html`, `docs/STORE-DATENSCHUTZANGABEN.md`. Quelle: [Nutzerdaten](https://support.google.com/googleplay/android-developer/answer/10144311), 26.11.2026.
- [x] <a id="g-05"></a>**G-05 Monetarisierung und Werbung.** Keine In-App-Käufe, keine Werbung, keine Werbe-ID. Status: OK. Wo: `pubspec.yaml` (kein Billing- oder Werbe-Plugin), `android/app/src/main/AndroidManifest.xml` (Werbe-ID entfernt). Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [ ] <a id="g-06"></a>**G-06 Store-Eintrag und Werbung dafür.** Titel, Beschreibungen und Grafiken müssen stimmen, keine Keyword-Häufung, keine irreführenden Aussagen. Titel, Kurz- und Langbeschreibung gibt es, Screenshots und Feature-Grafik fehlen. Status: offen. Wo: `docs/STORE-TEXTE.md`, `fastlane/metadata/android/`. Quelle: [Metadaten](https://support.google.com/googleplay/android-developer/answer/9898842), 26.11.2026.
- [x] <a id="g-07"></a>**G-07 Spam, Funktion und Nutzererlebnis.** Die App muss funktionieren, darf nicht abstürzen und muss mehr bieten als eine verpackte Website. Native Wiedergabe, Widget, Wecker, Android Auto und Chromecast sind da. Status: OK. Wo: `lib/`, Tests unter `test/` und `integration_test/`. Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [x] <a id="g-08"></a>**G-08 Malware und unerwünschte Software.** Kein verstecktes Nachladen von Code, kein unerwartetes Verhalten. Der Updater gehört nicht in Play-Builds. Status: OK (CI-Check für den Updater-Schalter fehlt noch, siehe D-01). Wo: Build-Schalter in `tool/bauen.sh`, `.github/workflows/store-google.yml`. Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [x] <a id="g-09"></a>**G-09 Familien.** Die Familien-Regeln gelten nur für Apps, die sich an Kinder richten. LINEFM richtet sich an 13+ und spricht Kinder nicht an. Status: OK (entschieden). Wo: Play Console > Zielgruppe und Inhalte. Quelle: [Zielgruppe](https://support.google.com/googleplay/android-developer/answer/9867159), 26.11.2026.
- [ ] <a id="g-10"></a>**G-10 Anforderungen an die Play Console und Durchsetzung.** Entwicklerkonto mit bestätigter Identität und Kontaktdaten. Wer gegen Richtlinien verstößt, riskiert die Entfernung. Status: Inhaber (eigenes Organisationskonto des Kunden). Wo: Play Console > Konto. Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.

### Technische und formale Anforderungen

- [x] <a id="g-11"></a>**G-11 Ziel-API-Level.** Neue Apps und Updates müssen Android 16 (API 36) oder höher als Ziel haben. Status: OK. Wo: `android/app/build.gradle.kts` (Flutter-Standard 36). Quelle: [Ziel-API](https://developer.android.com/google/play/requirements/target-sdk), 26.11.2026.
- [ ] <a id="g-12"></a>**G-12 Formular Datensicherheit.** Jeden erhobenen Datentyp angeben, auch die optionale Erhebung nach Einwilligung: Absturzdaten (Sentry), App-Interaktionen (Firebase, Umami) und was das Cast-SDK sendet. Status: Inhaber. Wo: Play Console > Datensicherheit, vorbereitete Antworten in `docs/STORE-DATENSCHUTZANGABEN.md`. Quelle: [Datensicherheit](https://support.google.com/googleplay/android-developer/answer/10787469), 26.11.2026.
- [ ] <a id="g-13"></a>**G-13 Link zur Datenschutzerklärung.** Öffentlich erreichbar, im Store-Eintrag und in der App verlinkt, ohne Platzhalter. Status: offen (Platzhalter). Wo: `web/datenschutz/`, `fastlane/metadata/*/privacy_url.txt`. Quelle: [Nutzerdaten](https://support.google.com/googleplay/android-developer/answer/10144311), 26.11.2026.
- [x] <a id="g-14"></a>**G-14 Typ des Vordergrunddienstes.** Die Wiedergabe läuft als `mediaPlayback` mit passender Berechtigung. Status: OK. Wo: `android/app/src/main/AndroidManifest.xml`. Quelle: [FGS-Typen](https://developer.android.com/develop/background-work/services/fgs/service-types), 26.11.2026.
- [ ] <a id="g-15"></a>**G-15 Deklaration Vordergrunddienst.** Die Play Console will eine Beschreibung und ein kurzes Video des Vordergrunddienstes. Status: Inhaber (der Kunde nimmt das Video auf). Wo: Play Console > App-Inhalte > Berechtigungen für Vordergrunddienste; Texte in `docs/STORE-TEXTE.md`. Quelle: [FGS und Vollbild-Intent](https://support.google.com/googleplay/android-developer/answer/13392821), 26.11.2026.
- [x] <a id="g-16"></a>**G-16 Exakte Alarme.** Der Wecker nutzt `SCHEDULE_EXACT_ALARM`, das der Nutzer freigibt, und nicht `USE_EXACT_ALARM`, das Wecker- und Kalender-Apps als Kernfunktion vorbehalten ist. Status: OK. Wo: `android/app/src/main/AndroidManifest.xml`, `lib/features/alarm/`. Quelle: [Berechtigungen und APIs](https://support.google.com/googleplay/android-developer/answer/9888170), 26.11.2026.
- [ ] <a id="g-17"></a>**G-17 Vollbild-Intent.** Automatisch bekommen ihn nur Wecker- und Anruf-Apps. LINEFM deklariert ihn als Nebenfunktion, fragt zur Laufzeit und fällt auf eine normale Mitteilung zurück. Status: Inhaber (Deklaration in der Konsole). Wo: Play Console > App-Inhalte; `lib/services/alarm/alarm_permissions.dart`. Quelle: [FGS und Vollbild-Intent](https://support.google.com/googleplay/android-developer/answer/13392821), 26.11.2026.
- [x] <a id="g-18"></a>**G-18 Berechtigung für Mitteilungen.** Ab Android 13 zur Laufzeit angefragt. Wer ablehnt, kann trotzdem hören. Status: OK (Gerätetest steht noch aus). Wo: `lib/services/alarm/alarm_permissions.dart`. Quelle: [Berechtigungen und APIs](https://support.google.com/googleplay/android-developer/answer/9888170), 26.11.2026.
- [ ] <a id="g-19"></a>**G-19 Altersfreigabe (IARC).** Fragebogen ehrlich ausfüllen: Musikstreams mit gelegentlich derber Sprache, kein Chat, keine Käufe. Ziel 13+ (entschieden). Status: Inhaber. Wo: Play Console > Einstufung des Inhalts. Quelle: [Altersfreigaben](https://support.google.com/googleplay/android-developer/answer/9898843), 26.11.2026.
- [ ] <a id="g-20"></a>**G-20 Zielgruppe.** Nur "13 und älter" auswählen. Status: Inhaber. Wo: Play Console > Zielgruppe und Inhalte. Quelle: [Zielgruppe](https://support.google.com/googleplay/android-developer/answer/9867159), 26.11.2026.
- [ ] <a id="g-21"></a>**G-21 Android Auto, Medienqualität.** Senderauswahl und Wiedergabe müssen der Qualitätsliste für Auto-Apps folgen (kein Video, sichere Bedienung beim Fahren, funktionierende Mediensitzung). Der Code steht, der Test auf der Desktop Head Unit fehlt. Status: offen. Wo: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/automotive_app_desc.xml`; Play Console > Erweiterte Einstellungen > Formfaktoren. Quelle: [Qualität von Auto-Apps](https://developer.android.com/docs/quality-guidelines/car-app-quality), 26.11.2026.
- [ ] <a id="g-22"></a>**G-22 16-KB-Speicherseiten.** Native Bibliotheken müssen auf Geräten mit 16-KB-Seiten laufen. Flutter selbst passt, die Bibliotheken der Plugins sind ungeprüft. Status: offen. Wo: Release-Build, Prüfung mit `zipalign -c -P 16`. Quelle: [16-KB-Seiten](https://developer.android.com/guide/practices/page-sizes), 26.11.2026.
- [ ] <a id="g-23"></a>**G-23 Play App Signing.** Google verwahrt den Signaturschlüssel der App, wir signieren Uploads mit dem Upload-Schlüssel. Status: Inhaber (in der Konsole aktivieren). Wo: Play Console > App-Integrität; `android/app/build.gradle.kts`, `.github/workflows/store-google.yml`. Quelle: [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756), 26.11.2026.
- [x] <a id="g-24"></a>**G-24 App-Zugriff und Kontolöschung.** Es gibt keine Anmeldung, also weder Testkonto noch Löschweg. Status: OK. Wo: Play Console > App-Zugriff ("alle Funktionen ohne Einschränkung verfügbar"). Quelle: [Nutzerdaten](https://support.google.com/googleplay/android-developer/answer/10144311), 26.11.2026.

### Konto, Gebühren, Prüfung und wiederkehrende Pflichten

- [ ] <a id="g-25"></a>**G-25 Kontotyp und Identität.** Organisationskonto mit D-U-N-S-Nummer, bestätigter Identität, Kontakt-E-Mail und Telefon sowie öffentlicher Entwickleradresse. Private Konten, die nach dem 13. November 2023 angelegt wurden, brauchen vor dem Produktionszugang einen geschlossenen Test mit mindestens 12 Testern über 14 Tage. Für ein Organisationskonto gilt das nicht. Status: Inhaber. Wo: Play Console > Kontodetails. Quelle: [Testpflicht für private Konten](https://support.google.com/googleplay/android-developer/answer/14151465), 26.11.2026; [Pflichtangaben zum Konto](https://support.google.com/googleplay/android-developer/answer/13628312), 26.11.2026; [Identitätsbestätigung](https://support.google.com/googleplay/android-developer/answer/10841920), 26.11.2026.
- [ ] <a id="g-26"></a>**G-26 Händlerstatus in der EU (Digital Services Act).** Angeben, ob das Konto als Händler auftritt. Händler zeigen in der EU Adresse, E-Mail und Telefon öffentlich im Store-Eintrag. Als Unternehmen ist der Kunde Händler. Status: Inhaber. Wo: Play Console > Kontodetails. Quelle: [Pflichtangaben zum Konto](https://support.google.com/googleplay/android-developer/answer/13628312), 26.11.2026 (Wortlaut zum Händlerstatus nicht im Detail geprüft).
- [ ] <a id="g-27"></a>**G-27 Gebühr.** Einmalige Registrierungsgebühr von 25 US-Dollar. Status: Inhaber. Wo: Kontoanlage. Quelle: [Einstieg in die Play Console](https://support.google.com/googleplay/android-developer/answer/6112435), 26.11.2026.
- [x] <a id="g-28"></a>**G-28 Zahlungsprofil und Steuerformulare.** Nur nötig für kostenpflichtige Apps oder Käufe. LINEFM verkauft nichts. Status: OK (kein Händlerkonto). Wo: Play Console > Zahlungsprofil. Quelle: [Einstieg in die Play Console](https://support.google.com/googleplay/android-developer/answer/6112435), 26.11.2026.
- [ ] <a id="g-29"></a>**G-29 Support-Kontakt.** Eine Support-E-Mail ist im Store-Eintrag Pflicht, eine Website ist empfohlen: support@linefm.de und die Seite `/support/`. Status: Inhaber. Wo: Play Console > Store-Einstellungen > Kontaktdaten; `docs/STORE-TEXTE.md`. Quelle: [Metadaten](https://support.google.com/googleplay/android-developer/answer/9898842), 26.11.2026.
- [ ] <a id="g-30"></a>**G-30 Hinweise für die Prüfung und App-Zugriff.** Vermerken, dass keine Anmeldung nötig ist, und Wecker, Android Auto und Chromecast so beschreiben, dass die Prüfer sie finden. Status: Inhaber. Wo: Play Console > App-Inhalte > App-Zugriff. Quelle: [Nutzerdaten](https://support.google.com/googleplay/android-developer/answer/10144311), 26.11.2026.
- [x] <a id="g-31"></a>**G-31 Löschanfragen.** Ohne Konten ist kein Löschlink nötig. Anfragen zu Telemetriedaten gehen an den Kontakt aus der Datenschutzerklärung. Status: OK. Wo: `web/datenschutz/`. Quelle: [Kontolöschung](https://support.google.com/googleplay/android-developer/answer/13327111), 26.11.2026.
- [ ] <a id="g-32"></a>**G-32 Nachweis der Inhaltsrechte.** Kommt eine Beschwerde wegen geistigen Eigentums oder Identitätsanmaßung, lädt der Kunde die laut.fm-Vereinbarung und die Markenfreigabe von LINEFM über die Seite "Richtlinienstatus" hoch. Status: Inhaber (Kunde). Wo: Play Console > Richtlinienstatus. Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [ ] <a id="g-33"></a>**G-33 Umgang mit Ablehnungen.** Ursache beheben, dann neu einreichen oder über den Richtlinienstatus Einspruch einlegen. Wiederholte Verstöße gefährden das Konto. Status: Inhaber. Wo: Play Console > Richtlinienstatus. Quelle: [Richtlinien](https://play.google/developer-content-policy/), 26.11.2026.
- [ ] <a id="g-34"></a>**G-34 Wiederkehrende Fristen.** Das Ziel-API-Level steigt jedes Jahr (meist zum 31. August). Die Deklarationen zu Datensicherheit, Vordergrunddienst, Vollbild-Intent und exakten Alarmen muss man erneut bestätigen, wenn Google danach fragt. Status: Inhaber (Kalendereintrag jeden Juli). Quelle: [Ziel-API](https://developer.android.com/google/play/requirements/target-sdk), 26.11.2026.

- [ ] <a id="g-35"></a>**G-35 Erklärung Gesundheits-Apps.** Jede App bei Google Play füllt sie aus, auch ohne Gesundheitsfunktionen. Antwort: keine Gesundheitsfunktionen. Status: Inhaber. Wo: Play Console > App-Inhalte. Quelle: [Health apps](https://support.google.com/googleplay/android-developer/answer/14738291), 26.11.2026
- [ ] <a id="g-36"></a>**G-36 Erklärung Finanzfunktionen.** Antwort: Die App bietet keine Finanzfunktionen. Status: Inhaber. Wo: Play Console > App-Inhalte. Quelle: [Financial features](https://support.google.com/googleplay/android-developer/answer/13849271), 26.11.2026
- [ ] <a id="g-37"></a>**G-37 Erklärung Behörden-App.** Antwort: keine Behörden-App und nicht im Auftrag einer Behörde entwickelt. Status: Inhaber. Wo: Play Console > App-Inhalte. Quelle: [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455), nicht geprüft
- [ ] <a id="g-38"></a>**G-38 Erklärung Nachrichten-App.** Antwort: nein. Google nimmt Streaming-Apps für Medien ausdrücklich aus der Nachrichten-Richtlinie aus, auch wenn sie Nachrichtensendungen enthalten. LINEFM ist eine Radio-Streaming-App und steht nicht in der Kategorie "Nachrichten & Magazine". Status: Inhaber. Wo: Play Console > App-Inhalte; Kategorie in den Store-Einstellungen. Quelle: [News and magazine apps](https://support.google.com/googleplay/android-developer/answer/10523915), 26.11.2026
- [ ] <a id="g-39"></a>**G-39 Erklärung Werbung.** Antwort: keine Werbung. Die App bindet kein Werbe-SDK ein, Werbespots in fremden Streams kommen von den Sendern. Google kann das Label "Enthält Werbung" nach eigener Prüfung trotzdem selbst setzen. Status: Inhaber. Wo: Play Console > App-Inhalte > Werbung. Quelle: [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455), 26.11.2026
- [ ] <a id="g-40"></a>**G-40 Erklärung Werbe-ID.** Apps ab Ziel Android 13 geben an, ob sie die Werbe-ID nutzen. Antwort: nein, die Berechtigung `AD_ID` ist aus dem zusammengeführten Manifest entfernt. Im Release-Build mit `aapt dump permissions` prüfen. Status: Inhaber. Wo: Play Console > App-Inhalte > Werbe-ID; `android/app/src/main/AndroidManifest.xml`. Quelle: [Advertising ID](https://support.google.com/googleplay/android-developer/answer/6048248), 26.11.2026
- [ ] <a id="g-41"></a>**G-41 Entwicklerbestätigung für das Direkt-APK.** Zertifizierte Android-Geräte installieren nur Apps, deren Paket und Signaturschlüssel einem bestätigten Entwickler zugeordnet sind. Start am 30. September 2026 in Brasilien, Indonesien, Singapur und Thailand, weltweit 2027. Das APK auf GitHub Releases bleibt (entschieden), also registriert der Kunde in der Play Console den Paketnamen und den Schlüssel, mit dem das Direkt-APK signiert ist. Status: Inhaber. Wo: Play Console > Entwicklerbestätigung; `.github/workflows/release.yml`. Quelle: [Android developer verification](https://developer.android.com/developer-verification), 26.11.2026

### Überblick nach Thema

#### Datenschutz

Punkte: [G-04](#g-04), [G-12](#g-12), [G-13](#g-13), [G-31](#g-31)

#### Geistiges Eigentum

Punkte: [G-02](#g-02), [G-03](#g-03), [G-32](#g-32)

#### Updates

Punkte: [G-08](#g-08), [G-11](#g-11), [G-34](#g-34), [D-01](#d-01)

#### Kontakt und Support

Punkte: [G-29](#g-29), [G-30](#g-30)

---

## Apple App Store

Umfang: iOS, iPadOS, CarPlay und Mac App Store. Nicht Teil des ersten Releases; iOS und Mac folgen später gemeinsam.

Quellen (alle abgerufen am 26.11.2026):

- App Review Guidelines: <https://developer.apple.com/app-store/review/guidelines/>
- Privacy Manifest: <https://developer.apple.com/documentation/bundleresources/privacy-manifest-files>
- APIs mit Begründungspflicht: <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>
- Anforderungen an Drittanbieter-SDKs: <https://developer.apple.com/support/third-party-SDK-requirements/>
- Datenschutzangaben (Labels): <https://developer.apple.com/app-store/app-privacy-details/>
- Exportkontrolle Verschlüsselung: <https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations>
- Altersfreigabe: <https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating>
- CarPlay: <https://developer.apple.com/carplay/>
- App Sandbox: <https://developer.apple.com/documentation/security/app-sandbox>
- Kommende Anforderungen: <https://developer.apple.com/news/upcoming-requirements/>
- AlarmKit: <https://developer.apple.com/documentation/alarmkit>

### App Review Guidelines (ein Eintrag je Abschnitt)

- [ ] <a id="a-01"></a>**A-01 Vor der Einreichung.** Der Build ist vollständig, auf einem Gerät getestet, Links funktionieren, Hinweise und Kontaktdaten für die Prüfung sind hinterlegt. Status: offen. Wo: App Store Connect > Informationen zur App-Prüfung; `fastlane/metadata/{de-DE,en-US}/` (noch ohne `review_information`). Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [x] <a id="a-02"></a>**A-02 Abschnitt 1, Sicherheit.** Die App erzeugt keine anstößigen Inhalte, hat keine Inhalte von Nutzern, Kontaktdaten sind erreichbar, das Gerät nimmt keinen Schaden. Status: OK. Wo: `lib/`, Impressum in der App. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-03"></a>**A-03 Abschnitt 2.1 bis 2.3, Vollständigkeit und korrekte Metadaten.** Screenshots zeigen die echte App, Metadaten passen dazu. Screenshots für iPhone, iPad und Mac fehlen. Status: offen. Wo: `fastlane/metadata/`, App Store Connect > Produktseite. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-04"></a>**A-04 Abschnitt 2.4.5 und 2.5.2, kein eigener Updater und kein nachgeladener Code.** Apps im Mac App Store aktualisieren sich nur über den Store. Ein Build-Schalter entfernt den Updater, der CI-Check fehlt noch. Status: offen. Wo: `.github/workflows/store-apple.yml`, Build-Schalter. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [x] <a id="a-05"></a>**A-05 Abschnitt 2.5.4, Hintergrundmodi.** Nur der Modus `audio`, genutzt für hörbare Wiedergabe. Status: OK. Wo: `ios/Runner/Info.plist`. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [x] <a id="a-06"></a>**A-06 Abschnitt 3, Geschäftliches.** Keine Käufe, keine Abos, keine Werbung, keine externen Zahlungslinks. Status: OK. Wo: `pubspec.yaml`. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [x] <a id="a-07"></a>**A-07 Abschnitt 4.2, Mindestfunktion.** Mehr als ein verpackter Stream: Widget, Wecker, AirPlay, Favoriten, Verlauf. Diese Funktionen in den Prüfhinweisen aufzählen. Status: OK. Wo: `ios/LinefmWidget/`, `ios/Runner/`. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [x] <a id="a-08"></a>**A-08 Abschnitt 4, Design (übrige Punkte).** Natives Erscheinungsbild, iPad in allen Ausrichtungen, Startbildschirm vorhanden. Status: OK. Wo: `ios/Runner/Info.plist`. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-09"></a>**A-09 Abschnitt 5.1, Datenschutz.** Datenschutzerklärung in der App und in App Store Connect, Einwilligung vor der Erhebung, ohne Konto kein Löschweg nötig. In der Datenschutzerklärung stehen noch Platzhalter. Status: offen. Wo: `web/datenschutz/`, `lib/features/legal/`. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-10"></a>**A-10 Abschnitt 5.2, geistiges Eigentum.** Wer Inhalte Dritter streamt, braucht deren Erlaubnis. Der Kunde hat die laut.fm-Vereinbarung und gibt sie in App Store Connect bei den Inhaltsrechten an. Status: Inhaber. Wo: App Store Connect > App-Informationen > Inhaltsrechte; Unterlagen des Kunden. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [x] <a id="a-11"></a>**A-11 Abschnitt 5.3 bis 5.6, Glücksspiel, VPN, MDM, Verhaltenskodex.** Trifft nicht zu, abgesehen von ehrlichem Verhalten gegenüber Nutzern und Prüfern. Status: OK. Wo: nichts zu tun. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.

### Technische und formale Anforderungen

- [x] <a id="a-12"></a>**A-12 Privacy Manifest.** `PrivacyInfo.xcprivacy` für App, Widget und Mac-App, Tracking aus, Gründe für die genutzten APIs angegeben. Status: OK (prüfen, ob jedes Target die Datei ins Bundle kopiert). Wo: `ios/Runner/PrivacyInfo.xcprivacy`, `ios/LinefmWidget/PrivacyInfo.xcprivacy`, `macos/Runner/PrivacyInfo.xcprivacy`. Quelle: [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files), 26.11.2026.
- [ ] <a id="a-13"></a>**A-13 APIs mit Begründungspflicht in Plugins.** Jede gelistete API braucht einen zugelassenen Grund, auch in Plugins, sonst scheitert der Upload. Xcode-Datenschutzbericht auf einem Archiv erzeugen. Status: offen. Wo: Mac-Build, Plugins aus `pubspec.yaml`. Quelle: [APIs mit Begründungspflicht](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), 26.11.2026.
- [ ] <a id="a-14"></a>**A-14 SDKs von Drittanbietern.** Gelistete SDKs brauchen ein eigenes Manifest und eine Signatur (Firebase und andere). Status: offen. Wo: `ios/Podfile.lock` nach dem ersten Mac-Build. Quelle: [Anforderungen an SDKs](https://developer.apple.com/support/third-party-SDK-requirements/), 26.11.2026.
- [ ] <a id="a-15"></a>**A-15 Datenschutz-Labels.** Absturzdaten und Produktinteraktion angeben (Sentry, Firebase, Umami), nicht mit der Identität verknüpft, kein Tracking. Optionale Erhebung nach Einwilligung zählt trotzdem. Prüfen, ob Firebase eine Geräte-ID sendet. Status: Inhaber. Wo: App Store Connect > App-Datenschutz; `docs/STORE-DATENSCHUTZANGABEN.md`. Quelle: [Datenschutzangaben](https://developer.apple.com/app-store/app-privacy-details/), 26.11.2026.
- [x] <a id="a-16"></a>**A-16 Exportkontrolle.** Nur System-TLS, daher `ITSAppUsesNonExemptEncryption` auf false. Status: OK. Wo: `ios/Runner/Info.plist`, `macos/Runner/Info.plist`. Quelle: [Exportkontrolle](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations), 26.11.2026.
- [ ] <a id="a-17"></a>**A-17 Altersfreigabe.** Den aktuellen Fragebogen beantworten (neue Altersstufen seit 2026). Ziel 13+ wegen gelegentlich derber Sprache in Songs. Status: Inhaber. Wo: App Store Connect > App-Informationen > Altersfreigabe. Quelle: [Altersfreigabe](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating), 26.11.2026.
- [ ] <a id="a-18"></a>**A-18 Mindestversion für Uploads.** Seit 28. April 2026 müssen Uploads mit Xcode 26 und dem iOS-26-SDK gebaut sein. Der Workflow legt noch keine Xcode-Version fest. Status: offen. Wo: `.github/workflows/store-apple.yml`. Quelle: [Kommende Anforderungen](https://developer.apple.com/news/upcoming-requirements/), 26.11.2026.
- [x] <a id="a-19"></a>**A-19 Mindest-Deployment-Target.** Seit 9. September 2026 müssen iOS-Uploads mindestens iOS 13 als Ziel haben. Die App hat 13.0, das Widget 14.0. Status: OK. Wo: `ios/Runner.xcodeproj/project.pbxproj`. Quelle: [Kommende Anforderungen](https://developer.apple.com/news/upcoming-requirements/), 26.11.2026.
- [ ] <a id="a-20"></a>**A-20 AlarmKit.** Ab iOS 26 laufen Wecker über AlarmKit mit Nutzungsbeschreibung. Darunter gibt es eine Mitteilung mit dem klaren Hinweis, dass das Radio nach einem Tipp startet. Status: offen (entschieden, Code fehlt). Wo: `ios/Runner/AlarmNotifications.swift`, `ios/Runner/Info.plist`, `docs/STORE-TEXTE.md`. Quelle: [AlarmKit](https://developer.apple.com/documentation/alarmkit), 26.11.2026.
- [ ] <a id="a-21"></a>**A-21 CarPlay Audio.** CarPlay braucht eine Berechtigung, die Apple Audio-Apps auf Antrag erteilt, und nur vorlagenbasierte Oberflächen. Die Berechtigungsdatei liegt bereit und ist abgeschaltet. Status: Inhaber (Antrag über das Konto des Kunden). Wo: `ios/Runner/Runner-CarPlay.entitlements`, Apple-Entwicklerkonto > CarPlay-Antrag. Quelle: [CarPlay](https://developer.apple.com/carplay/), 26.11.2026.
- [ ] <a id="a-22"></a>**A-22 Sandbox im Mac App Store.** Sandbox ist Pflicht, Berechtigungen so wenige wie möglich. Die Berechtigung für den Downloads-Ordner durch einen Speichern-Dialog ersetzen (entschieden). Status: offen. Wo: `macos/Runner/Release.entitlements`. Quelle: [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), 26.11.2026.
- [ ] <a id="a-23"></a>**A-23 Mac App Store zusammen mit iOS.** Gleiches Release, eigene Screenshots und Kategorie. Status: offen. Wo: `.github/workflows/store-apple.yml`, App Store Connect > macOS. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-24"></a>**A-24 Entwicklerkonto.** Organisationskonto des Kunden (D-U-N-S-Nummer), die Agentur bekommt eine Rolle. Status: Inhaber. Wo: Apple Developer Program. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.

### Konto, Gebühren, Prüfung und wiederkehrende Pflichten

- [ ] <a id="a-25"></a>**A-25 Händlerstatus in der EU (Digital Services Act).** Jedes Konto gibt seinen Händlerstatus an, auch ohne Vertrieb in der EU. App Store Connect fragt bei der nächsten Einreichung danach. Bei Organisationen kommt die Anschrift aus dem D-U-N-S-Eintrag. Händler ergänzen Telefon und E-Mail (in der EU auf der Produktseite sichtbar), Zahlungskontodaten, falls noch nicht hinterlegt, und bestätigen, dass ihr Angebot EU-Recht einhält. Bei Nicht-Händlern erfahren EU-Verbraucher, dass Verbraucherrechte nicht gelten. Status: Inhaber. Wo: App Store Connect > Geschäftliches > Compliance. Quelle: [DSA-Händlerpflichten](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements), 26.11.2026.
- [ ] <a id="a-26"></a>**A-26 Mitgliedsgebühr.** Das Apple Developer Program kostet 99 US-Dollar pro Mitgliedsjahr, abgerechnet in Landeswährung. Rechtzeitig verlängern, sonst verschwinden die Apps aus dem Store. Status: Inhaber. Quelle: [Mitglied werden](https://developer.apple.com/programs/enroll/), 26.11.2026.
- [ ] <a id="a-27"></a>**A-27 Verträge, Steuern und Bankdaten.** Für eine kostenlose App reicht der Vertrag für kostenlose Apps, Steuerformulare braucht es nur bei Verkäufen. Als DSA-Händler verlangt Apple aber Zahlungskontodaten (siehe A-25). Neue Vertragsfassungen annehmen, sobald App Store Connect danach fragt, sonst stoppen die Uploads. Status: Inhaber. Wo: App Store Connect > Geschäftliches. Quelle: [Verträge unterzeichnen](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements), 26.11.2026.
- [ ] <a id="a-28"></a>**A-28 Support-URL.** Eine Support-URL mit echten Kontaktdaten ist Pflicht, eine Marketing-URL ist freiwillig: die Seite `/support/`. Status: Inhaber. Wo: `fastlane/metadata/*/support_url.txt`, App Store Connect > Produktseite. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-29"></a>**A-29 Prüfhinweise.** Vermerken, dass keine Anmeldung nötig ist, wie man Wecker, AirPlay und CarPlay ausprobiert und woher die Inhaltsrechte stammen. Status: Inhaber. Wo: App Store Connect > Informationen zur App-Prüfung. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-30"></a>**A-30 Antworten auf die Prüfung.** In App Store Connect antworten, beheben und neu einreichen oder beim App Review Board Einspruch einlegen. Status: Inhaber. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/) (Teil "After You Submit"), 26.11.2026.
- [x] <a id="a-31"></a>**A-31 Datenlöschung.** Keine Konten, also kein Löschweg in der App nötig. Anfragen zu Telemetriedaten laufen über den Datenschutzkontakt. Status: OK. Wo: `web/datenschutz/`. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.
- [ ] <a id="a-32"></a>**A-32 Wiederkehrende Fristen.** Jedes Frühjahr hebt Apple die Mindestversion von Xcode und SDK an. Antworten zur Altersfreigabe und die Datenschutz-Labels sind anzupassen, wenn Apple die Fragen ändert. Status: Inhaber (Kalendereintrag jeden März). Quelle: [Kommende Anforderungen](https://developer.apple.com/news/upcoming-requirements/), 26.11.2026.

- [x] <a id="a-33"></a>**A-33 Regel 4.3, Spam und Duplikate.** Eine App je Zweck, keine Kopien derselben App unter anderen Namen oder je Sender. Status: OK durch den Aufbau (eine App für alle Sender), so beibehalten. Wo: `assets/config/`. Quelle: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 26.11.2026.

- [ ] <a id="a-34"></a>**A-34 Werbung in App Store Connect.** Wo die Fragen zur Altersfreigabe nach Werbung fragen: nein. Die App zeigt keine eigene Werbung, Spots in den Streams kommen von den Sendern. Status: Inhaber. Wo: App Store Connect > Altersfreigabe. Quelle: [Age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating), nicht geprüft

### Überblick nach Thema

#### Datenschutz

Punkte: [A-09](#a-09), [A-12](#a-12), [A-15](#a-15), [A-31](#a-31)

#### Geistiges Eigentum

Punkte: [A-10](#a-10), [D-03](#d-03)

#### Updates

Punkte: [A-04](#a-04), [A-18](#a-18), [A-32](#a-32), [D-01](#d-01)

#### Kontakt und Support

Punkte: [A-28](#a-28), [A-29](#a-29)

---

## Microsoft Store

Richtlinienversion 7.20.

Quelle: <https://learn.microsoft.com/en-us/windows/apps/publish/store-policies>, abgerufen am 26.11.2026 (der Seitentitel bestätigt Version 7.20). Alle Einträge dieses Abschnitts beziehen sich auf diese Quelle.

### Produktrichtlinien

- [x] <a id="m-01"></a>**M-01 10.1 Eigenständige Funktion und zutreffende Darstellung.** Klarer Zweck, eindeutiger Titel ohne Keywords, Metadaten passen zur App. Status: OK. Wo: `pubspec.yaml` (`msix_config`), `docs/STORE-TEXTE.md`.
- [ ] <a id="m-02"></a>**M-02 10.2 Sicherheit.** Kein Code-Nachladen zur Laufzeit, ein Store-Paket aktualisiert sich nur über den Store. Ein Build-Schalter schließt den Updater aus, der CI-Check fehlt. Status: offen. Wo: `.github/workflows/store-microsoft.yml`, Build-Schalter.
- [x] <a id="m-03"></a>**M-03 10.3 Testbarkeit.** Keine Anmeldung, die Prüfer erreichen alle Funktionen. Status: OK. Wo: Partner Center > Hinweise für die Zertifizierung.
- [x] <a id="m-04"></a>**M-04 10.4 Benutzbarkeit.** Startet schnell, läuft auf den unterstützten Windows-Versionen, stürzt nicht ab. Status: OK (vor der Einreichung auf einem frischen Rechner testen). Wo: `.github/workflows/itest-windows.yml`.
- [ ] <a id="m-05"></a>**M-05 10.5 Personenbezogene Daten.** Wer personenbezogene Daten überträgt, braucht eine Datenschutzerklärung, Telemetrie erst nach Einwilligung. Platzhalter sind noch offen. Status: offen. Wo: `web/datenschutz/`, Partner Center > Eigenschaften > URL der Datenschutzerklärung.
- [x] <a id="m-06"></a>**M-06 10.6 Capabilities.** Nur angeben, was genutzt wird: `internetClient`. Status: OK. Wo: `pubspec.yaml` (`msix_config`).
- [x] <a id="m-07"></a>**M-07 10.7 Lokalisierung.** Store-Eintrag in jeder Sprache der App: Deutsch und Englisch. Status: OK. Wo: `docs/STORE-TEXTE.md`.
- [x] <a id="m-08"></a>**M-08 10.8 Finanztransaktionen.** Keine. Status: OK.
- [x] <a id="m-09"></a>**M-09 10.9 Benachrichtigungen.** Nur mit Kontrolle durch den Nutzer, keine Werbung in Benachrichtigungen. Status: OK. Wo: `lib/services/alarm/`.
- [x] <a id="m-10"></a>**M-10 10.10 Werbung.** Keine Werbung. Status: OK.
- [x] <a id="m-11"></a>**M-11 10.13 Gaming und Xbox.** Trifft nicht zu. Status: OK.
- [ ] <a id="m-12"></a>**M-12 10.14 Kontotyp.** Veröffentlichung über ein Firmenkonto des Kunden. Status: Inhaber. Wo: Partner Center > Kontoeinstellungen.

### Inhaltsrichtlinien

- [x] <a id="m-13"></a>**M-13 11.1 Allgemeine Inhalte.** Inhalte passen zur angegebenen Altersfreigabe. Status: OK.
- [ ] <a id="m-14"></a>**M-14 11.2 Namen, Logos, eigene und fremde Inhalte.** Nutzungsrecht für Sendernamen, Logos und Streams. Der Kunde hat die laut.fm-Vereinbarung und die Markenrechte an LINEFM. Status: Inhaber. Wo: Unterlagen des Kunden, Hinweise im Partner Center.
- [x] <a id="m-15"></a>**M-15 11.3 bis 11.8 Gefährdung, Verleumdung, Anstößiges, Alkohol/Tabak/Waffen/Drogen, Erwachsenen- und illegale Inhalte.** Kein Teil der eigenen Inhalte der App. Status: OK.
- [x] <a id="m-16"></a>**M-16 11.9 Übermäßige Kraftausdrücke.** Gelegentlich derbe Songtexte, abgedeckt durch die Altersfreigabe. Status: OK (siehe M-18).
- [x] <a id="m-17"></a>**M-17 11.10 Länderspezifische Anforderungen.** Impressum und Datenschutzerklärung folgen deutschem Recht. Status: OK (anwaltliche Prüfung empfohlen). Wo: `web/impressum/`, `web/datenschutz/`.
- [ ] <a id="m-18"></a>**M-18 11.11 Altersfreigaben.** IARC-Fragebogen im Partner Center, Ziel 13+. Status: Inhaber. Wo: Partner Center > Altersfreigaben.
- [x] <a id="m-19"></a>**M-19 11.12 bis 11.16 Nutzerinhalte, fremde Storefronts, Glücksspiel, Kinderschutz, generative KI live.** Nicht vorhanden. Status: OK.

### Konto, Gebühren und Prüfung

- [ ] <a id="m-20"></a>**M-20 Konto und Gebühr.** Firmenkonto des Kunden im Partner Center mit Firmenprüfung und einer E-Mail-Adresse auf der Firmendomain. Seit dem neuen Anmeldeablauf gibt es keine Registrierungsgebühr. Status: Inhaber. Quelle: [Kontotypen und Gebühren](https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/account-types-locations-and-fees), 26.11.2026.
- [x] <a id="m-21"></a>**M-21 Auszahlung und Steuerformulare.** Nur für kostenpflichtige Apps, hier nicht nötig. Status: OK. Wo: Partner Center > Auszahlung und Steuern.
- [ ] <a id="m-22"></a>**M-22 Support-Kontakt und Hinweise zur Zertifizierung.** Support-Kontakt im Store-Eintrag (support@linefm.de, Seite `/support/`), Hinweise für die Prüfer (keine Anmeldung, Wecker). Status: Inhaber. Wo: Partner Center > Eigenschaften und Einreichungsoptionen.
- [ ] <a id="m-23"></a>**M-23 Abgelehnte Zertifizierung.** Beheben und neu einreichen oder den Einspruchsweg am Ende der Richtlinie nutzen. Status: Inhaber.

- [x] <a id="m-24"></a>**M-24 10.11 und 10.12.** In Version 7.20 beide als "Policy removed" gekennzeichnet. Abschnitte 10.15 und 11.17 gibt es in Version 7.20 nicht. Status: OK. Quelle: [Store policies](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies), 26.11.2026
- [ ] <a id="m-25"></a>**M-25 Händlerstatus in der EU (Digital Services Act).** Fragt das Partner Center nach dem Händlerstatus, den Kunden als Händler angeben, mit derselben Anschrift, Telefonnummer und E-Mail wie bei Google und Apple. Status: Inhaber. Wo: Partner Center > Kontoeinstellungen. Quelle: [Open a developer account](https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account), nicht geprüft (am 26.11.2026 keine Microsoft-Seite zum Händlerstatus gefunden, gesucht über die Suche von Microsoft Learn und die Kontoseiten)
- [ ] <a id="m-26"></a>**M-26 Frage zur Werbung.** In den Produkteigenschaften mit nein beantworten: kein Werbe-SDK, Spots in Streams kommen von den Sendern. Status: Inhaber. Wo: Partner Center > Eigenschaften. Quelle: [Store policies](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies) 10.10, 26.11.2026

### Überblick nach Thema

#### Datenschutz

Punkte: [M-05](#m-05)

#### Geistiges Eigentum

Punkte: [M-14](#m-14), [D-03](#d-03)

#### Updates

Punkte: [M-02](#m-02), [D-01](#d-01)

#### Kontakt und Support

Punkte: [M-22](#m-22)

---

## Snap Store

Quellen:

- Nutzungsbedingungen Snap Store: <https://ubuntu.com/legal/terms-and-policies/snap-store-terms>, abgerufen am 26.11.2026.
- Store-Anfragen (Aliase, automatische Verbindungen, Tracks): <https://forum.snapcraft.io/t/process-for-aliases-auto-connections-and-tracks/455>, abgerufen am 26.11.2026.
- Berechtigungsanfragen: <https://snapcraft.io/docs/permission-requests>, nicht geprüft (die Seite lieferte am 26.11.2026 keinen lesbaren Titel).

- [x] <a id="s-01"></a>**S-01 Strikte Einschränkung.** Snaps aus dem Store laufen eingeschränkt, Schnittstellen nur nach Bedarf. Status: OK. Wo: `packaging/snap/snapcraft.yaml`. Quelle: [Nutzungsbedingungen](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026.
- [x] <a id="s-02"></a>**S-02 Schnittstellen ohne Einzelprüfung.** `audio-playback`, `network` und der MPRIS-Slot verbinden sich automatisch. Alles andere braucht eine Anfrage im Forum. Status: OK (Tray noch testen). Wo: `packaging/snap/snapcraft.yaml`. Quelle: [Store-Anfragen](https://forum.snapcraft.io/t/process-for-aliases-auto-connections-and-tracks/455), 26.11.2026.
- [ ] <a id="s-03"></a>**S-03 Name und Marke.** `linefm-radio` mit dem Konto des Markeninhabers registrieren. Status: Inhaber. Wo: Dashboard auf snapcraft.io. Quelle: [Nutzungsbedingungen](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026.
- [ ] <a id="s-04"></a>**S-04 Recht zur Veröffentlichung.** Wer veröffentlicht, braucht die Rechte an Inhalten und Code. Status: Inhaber (laut.fm-Vereinbarung und LINEFM-Rechte liegen beim Kunden). Quelle: [Nutzungsbedingungen](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026.
- [x] <a id="s-05"></a>**S-05 Keine Selbstaktualisierung.** Snaps aktualisieren sich über den Store, der Updater ist ausgeschlossen. Status: OK (CI-Check D-01 offen). Wo: Build-Schalter. Quelle: [Nutzungsbedingungen](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026.
- [ ] <a id="s-06"></a>**S-06 Build getestet.** Der Snap-Build ist in der CI noch nie gelaufen. Status: offen. Wo: `.github/workflows/store-snap.yml`. Quelle: [Nutzungsbedingungen](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026.

- [ ] <a id="s-07"></a>**S-07 Konto und Gebühren.** Ubuntu-One-Konto des Kunden, keine Gebühr, keine Steuerformulare für kostenlose Snaps. Status: Inhaber. Quelle: [Nutzungsbedingungen](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026.

- [ ] <a id="s-08"></a>**S-08 Kontakt und Support.** Kontaktadresse und Website in den Snap-Metadaten: support@linefm.de und die Seite `/support/`. Status: offen. Wo: `packaging/snap/snapcraft.yaml` (`contact`, `website`), `web/support/` (anzulegen). Quelle: [Nutzungsbedingungen](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026.

- [ ] <a id="s-09"></a>**S-09 Datenschutz und Kontakt im Store-Eintrag.** Im Eintrag auf snapcraft.io die URL der Datenschutzerklärung, support@linefm.de und die Seite `/support/` eintragen. Status: Inhaber. Wo: snapcraft.io > Listing. Quelle: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 26.11.2026 (Felder des Eintrags selbst nicht geprüft)

### Überblick nach Thema

#### Datenschutz

Punkte: [D-04](#d-04)

#### Geistiges Eigentum

Punkte: [S-03](#s-03), [S-04](#s-04)

#### Updates

Punkte: [S-05](#s-05), [D-01](#d-01)

#### Kontakt und Support

Punkte: [S-08](#s-08)

---

## Flathub

Quellen (alle abgerufen am 26.11.2026):

- Anforderungen: <https://docs.flathub.org/docs/for-app-authors/requirements>
- MetaInfo-Richtlinien: <https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines>
- Bestätigung (Verification): <https://docs.flathub.org/docs/for-app-authors/verification>

- [x] <a id="f-01"></a>**F-01 Aufnahmeregeln.** Grafische Desktop-App mit echter Funktion, keine reine Tray-App, kein Duplikat. Status: OK. Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [x] <a id="f-02"></a>**F-02 Monetarisierung und generative KI.** Keine Zahlungswege, keine generierten Inhalte. Status: OK. Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [x] <a id="f-03"></a>**F-03 App-ID.** Umgekehrter Domainname einer Domain, die wir kontrollieren: `de.linefm.app`. Status: OK. Wo: `packaging/flathub/de.linefm.app.yml`. Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [ ] <a id="f-04"></a>**F-04 Domain-Bestätigung.** Eine Token-Datei unter `linefm.de/.well-known/org.flathub.VerifiedApps.txt` (https) beweist die Kontrolle über die Domain und bringt das Häkchen "verifiziert". Der Kunde legt sie zum Livegang ab: Token im Flathub-Entwicklerportal kopieren, als reine Textdatei unter diesem Pfad auf dem Webserver von linefm.de speichern, im Browser prüfen, dass sie lädt, dann im Portal auf "Verify" klicken. Status: Inhaber. Wo: Webserver von linefm.de. Quelle: [Bestätigung](https://docs.flathub.org/docs/for-app-authors/verification), 26.11.2026.
- [ ] <a id="f-05"></a>**F-05 Build aus dem Quellcode.** Flathub baut aus dem Quellcode, vorgebaute Binärdateien nur bei bekannten Herstellern. Das Manifest nutzt noch ein vorgebautes Archiv. Der Offline-Quellbuild ist entschieden, aber nicht gebaut. Status: offen. Wo: `packaging/flathub/de.linefm.app.yml`, `.github/workflows/flathub-prep.yml`. Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [x] <a id="f-06"></a>**F-06 Kein Netz beim Build.** Alle Quellen mit Prüfsumme festgelegt. Status: OK (für den Quellbuild die Dart-Pakete als Quellen erzeugen). Wo: `packaging/flathub/de.linefm.app.yml`. Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [ ] <a id="f-07"></a>**F-07 Lizenz.** Lizenz in der Metainfo, Lizenzdatei installiert, Inhalte dürfen weitergegeben werden. Die Lizenz-URL muss auf `/lizenz/` zeigen, die Seite gibt es noch nicht. Status: offen. Wo: `linux/de.linefm.app.metainfo.xml`, `web/lizenz/` (anzulegen). Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [ ] <a id="f-08"></a>**F-08 Berechtigungen.** So wenige wie möglich, Portale wo es sie gibt. `--share=ipc` und den Busnamen für Mitteilungen begründen. Status: offen (durchsehen). Wo: `packaging/flathub/de.linefm.app.yml` (`finish-args`). Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [x] <a id="f-09"></a>**F-09 Stabile Versionen und Patches.** Nur stabile Versionen, Patches möglichst upstream. Status: OK. Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.
- [ ] <a id="f-10"></a>**F-10 Qualität der MetaInfo.** Echte Screenshots unter stabilen URLs, Release-Einträge mit Datum, OARS-Einstufung (`language-profanity` moderate), Entwickler-Angabe, keine Markenverletzung in Name oder Icon. Status: offen (Platzhalter). Wo: `linux/de.linefm.app.metainfo.xml`. Quelle: [MetaInfo-Richtlinien](https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines), 26.11.2026.
- [x] <a id="f-11"></a>**F-11 Keine Selbstaktualisierung.** Flatpaks aktualisieren sich über Flathub, der Updater ist ausgeschlossen. Status: OK (CI-Check D-01 offen). Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.

- [ ] <a id="f-12"></a>**F-12 Konto, Gebühren und Prüfung.** GitHub-Konto des Kunden für die Einreichung, keine Gebühr. Die Prüfung läuft öffentlich in der Einreichung auf GitHub, dort antwortet man den Prüfern. Status: Inhaber. Quelle: [Anforderungen](https://docs.flathub.org/docs/for-app-authors/requirements), 26.11.2026.

- [ ] <a id="f-13"></a>**F-13 Kontakt und Support.** `url type="contact"` und `url type="support"` in der Metainfo: support@linefm.de und die Seite `/support/`. Status: offen. Wo: `linux/de.linefm.app.metainfo.xml`. Quelle: [MetaInfo-Richtlinien](https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines), 26.11.2026.

### Überblick nach Thema

#### Datenschutz

Punkte: [D-04](#d-04)

#### Geistiges Eigentum

Punkte: [F-07](#f-07), [F-10](#f-10), [D-03](#d-03)

#### Updates

Punkte: [F-09](#f-09), [F-11](#f-11), [D-01](#d-01)

#### Kontakt und Support

Punkte: [F-13](#f-13)

---

## Web und PWA

Quellen (abgerufen am 26.11.2026): <https://web.dev/articles/install-criteria>, <https://www.w3.org/TR/appmanifest/>.

- [x] <a id="w-01"></a>**W-01 Installierbar.** Manifest mit Name, Icons 192 und 512 (maskable), Start-URL, `display` standalone, ausgeliefert über HTTPS mit Service Worker. Status: OK. Wo: `web/manifest.webmanifest`. Quelle: [Installationskriterien](https://web.dev/articles/install-criteria), 26.11.2026.
- [ ] <a id="w-02"></a>**W-02 Erweiterter Installationsdialog.** Optional `screenshots` und `shortcuts` im Manifest. Status: offen (freiwillig). Wo: `web/manifest.webmanifest`. Quelle: [Manifest](https://www.w3.org/TR/appmanifest/), 26.11.2026.
- [x] <a id="w-03"></a>**W-03 Einwilligung vor dem Tracking.** GA4 und GTM erst nach Einwilligung. Status: OK. Wo: `web/analytics.js`, `web/datenschutz/`. Quelle: [TDDDG § 25](https://www.gesetze-im-internet.de/ttdsg/__25.html), 26.11.2026.
- [ ] <a id="w-04"></a>**W-04 Lizenzseite.** `/lizenz/` auf Deutsch und Englisch, verlinkt aus der Metainfo und den Stores. Status: offen. Wo: `web/lizenz/` (anzulegen). Quelle: Entscheidung des Inhabers, Flathub braucht die Seite, siehe F-07.

- [ ] <a id="w-05"></a>**W-05 Kontakt und Support.** Seite `/support/` auf Deutsch und Englisch mit support@linefm.de, verlinkt aus Impressum, App und jedem Store-Eintrag. Status: offen. Wo: `web/support/` (anzulegen). Quelle: Entscheidung des Inhabers, die Stores brauchen die Seite, siehe G-29, A-28, M-22.

- [ ] <a id="w-06"></a>**W-06 Barrierefreiheitserklärung.** Freiwillig unter `/barrierefreiheit/` (Deutsch und Englisch) veröffentlicht, auch wenn die Ausnahme für Kleinstunternehmen im BFSG greifen könnte. Der Anwalt bestätigt das. Status: offen. Wo: `web/barrierefreiheit/` (anzulegen). Quelle: [BFSG § 3](https://www.gesetze-im-internet.de/bfsg/__3.html), 26.11.2026

### Überblick nach Thema

#### Datenschutz

Punkte: [W-03](#w-03)

#### Geistiges Eigentum

Punkte: [W-04](#w-04)

#### Updates

Punkte: [W-01](#w-01)

#### Kontakt und Support

Punkte: [W-05](#w-05)

---

## Store-übergreifend

- [ ] <a id="d-01"></a>**D-01 Updater nur in Direktdownloads.** Store-Builds (Play, App Store, Mac App Store, Microsoft Store, Snap, Flathub) entstehen ohne Updater. Ein CI-Check durchsucht die Store-Pakete nach Updater-Code. Status: offen. Wo: Build-Schalter, `.github/workflows/store-*.yml`.
- [ ] <a id="d-02"></a>**D-02 Eigene Konten des Kunden.** Jedes Store-Konto gehört der Organisation des Kunden. Status: Inhaber. Wo: `docs/EINRICHTUNG.md`.
- [ ] <a id="d-03"></a>**D-03 Inhaltsrechte.** Der Kunde verwahrt die laut.fm-Vereinbarung und nennt sie überall dort, wo ein Store nach Rechten fragt (Inhaltsrechte bei Apple, Google auf Nachfrage, Hinweise bei Microsoft, Snap, Flathub). Das gilt auch für die Partnersender Radio3FM und FobFM: Der Kunde verwahrt deren schriftliche Zustimmung zur Aufnahme. Außerdem holt der Kunde von laut.fm eine schriftliche Bestätigung ein, dass dessen GEMA- und GVL-Lizenzen die Wiedergabe in der LINEFM-App abdecken. Der Anwalt prüft sie. Status: Inhaber.
- [ ] <a id="d-04"></a>**D-04 Datenschutzerklärung ohne Platzhalter.** Verantwortlicher und Kontakt eingetragen, alle drei Telemetriedienste als optional genannt. Sie nennt auch die Links und Abfragen nach außen: Spotify, YouTube Music, radiogruppe.de und die iTunes-Suche für Cover. Die URL muss dauerhaft erreichbar bleiben: Domain verlängern, TLS und Uptime-Überwachung. Anwaltliche Prüfung empfohlen. Status: Inhaber. Wo: `web/datenschutz/`, `web/datenschutz/en/`.

- [ ] <a id="d-05"></a>**D-05 Verzeichnis der Verarbeitungstätigkeiten (Art. 30 DSGVO).** Eine ausgefüllte Vorlage nennt Sentry, Firebase, Umami, GA4/GTM im Web, laut.fm-Abrufe, Server-Logs und Support-Mail. Der Kunde prüft sie, ergänzt die Firmendaten und hält sie aktuell. Status: Inhaber. Wo: `docs/VERARBEITUNGSVERZEICHNIS.md`. Quelle: [Art. 30 DSGVO](https://dsgvo-gesetz.de/art-30-dsgvo/), 26.11.2026
- [ ] <a id="d-06"></a>**D-06 Jugendschutz (JMStV).** Die Einstufung 13+ und ihr Grund (gelegentlich derbe Sprache in fremden Streams) sind dokumentiert. Ob ein Jugendschutzbeauftragter nötig ist, prüft der Anwalt des Kunden. Status: Inhaber. Wo: Unterlagen des Kunden. Quelle: [JMStV § 7](https://www.gesetze-bayern.de/Content/Document/JMStV-7), 26.11.2026

---

## Weitere Stores (noch nicht geplant)

Hier stehen nur die wichtigsten Regeln und die Links. Wird ein Store relevant, bekommt er einen Abschnitt wie die oben.

- [ ] <a id="x-01"></a>**X-01 Amazon Appstore.** Inhaltsrichtlinie ähnlich wie bei Google Play. Amazon prüft die Apps und vergibt die Altersfreigabe selbst, Android-Funktionen laufen ohne Google-Dienste. Chromecast und Android Auto gehen auf Fire-Geräten nicht. Status: noch nicht geplant. Quelle: [Inhaltsrichtlinie](https://developer.amazon.com/docs/policy-center/understanding-content-policy.html), 26.11.2026.
- [ ] <a id="x-02"></a>**X-02 Samsung Galaxy Store.** Eigene Prüfung nach dem Distribution Guide: funktionierende App, korrekte Metadaten, Altersfreigabe, Datenschutzerklärung. Status: noch nicht geplant. Quelle: [Distribution Guide](https://developer.samsung.com/galaxy-store/distribution-guide.html), 26.11.2026.
- [ ] <a id="x-03"></a>**X-03 Huawei AppGallery.** Prüfregeln zu Inhalt, Datenschutz und Funktion. Apps müssen ohne Google Mobile Services laufen. Status: noch nicht geplant. Quelle: [Prüfrichtlinien](https://developer.huawei.com/consumer/en/doc/app/50104), nicht geprüft (Seite lädt nur mit JavaScript).
- [ ] <a id="x-04"></a>**X-04 F-Droid.** Nur freie Open-Source-Software, aus dem Quellcode gebaut. Proprietäre Abhängigkeiten (Firebase, Cast-SDK) werden markiert oder abgelehnt. Mit der proprietären Lizenz von LINEFM kommt F-Droid so nicht in Frage. Status: noch nicht geplant. Quelle: [Aufnahmeregeln](https://f-droid.org/docs/Inclusion_Policy/), 26.11.2026.
- [ ] <a id="x-05"></a>**X-05 winget.** Manifest im Community-Repository, das auf das signierte Windows-Setup zeigt. Der Installer muss still laufen können. Passt gut zum Setup aus dem Direktdownload. Status: noch nicht geplant. Quelle: [Pakete einreichen](https://learn.microsoft.com/en-us/windows/package-manager/package/), 26.11.2026.
- [ ] <a id="x-06"></a>**X-06 Homebrew Cask.** Cask für das notarisierte macOS-DMG. Die App muss signiert, notarisiert und einigermaßen bekannt sein. Status: noch nicht geplant. Quelle: [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks), 26.11.2026.
