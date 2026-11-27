# Datenschutzangaben für die Stores

Ausfüllhilfe für zwei Formulare: **Datensicherheit** (Data safety) in der Google Play Console und **App-Datenschutz** (App Privacy) in App Store Connect. Jede Zeile nennt die Frage, die Antwort und den Grund. LineFM Studios kann die Antworten übernehmen. Die Antworten gelten für den Stand des Quellcodes vom 21.11.2026 und müssen bei jeder Änderung an Telemetrie, Fremddiensten oder Berechtigungen nachgezogen werden (Gegenstücke: [telemetry.md](telemetry.md), `ios/Runner/PrivacyInfo.xcprivacy`, `android/app/src/main/AndroidManifest.xml`).

**Vor Abgabe anwaltlich prüfen.** Die Einordnung, was als "Erfassung", "Weitergabe" und "verknüpft" gilt, ist eine Rechtsfrage. Dieses Dokument ist eine technische Vorprüfung und kein Rechtsrat. Stellen, an denen eine Entscheidung offen ist, tragen die Marke **[Anwalt]**. Was wir nicht belegen konnten, steht als **[nicht belegt]**.

Quellen (abgerufen am 21.11.2026):

- Google Play, Data safety: <https://support.google.com/googleplay/android-developer/answer/10787469>
- Apple, App Privacy Details: <https://developer.apple.com/app-store/app-privacy-details/>

## 1. Datenflüsse der App

| Fluss | Was geht raus | Wann | Verantwortlich |
|---|---|---|---|
| Stream | Abruf der Audio-Adresse, damit technisch IP-Adresse und Geräteangaben (User-Agent) | bei jeder Wiedergabe | laut.fm (`stream.laut.fm`) |
| Titel- und Sendedaten | Anfrage nach Sender, aktuellem Titel, Verlauf, Hörerzahl, Sendeplan | im Hintergrund, solange ein Sender angezeigt wird | laut.fm (`api.laut.fm`) |
| Cover-Suche | Künstler und Titel als Suchbegriff, dazu IP-Adresse | je neuem Titel, abschaltbar ("Cover laden") | Apple (`itunes.apple.com`) |
| Senderlogos | Abruf einer Bilddatei | Web-Version | Betreiber (`cdn.linefm.de`) |
| Statistik | Bildschirmaufrufe, Ereignisse (Sender gestartet, gestoppt, Favorit), Sprache, Bildschirmgröße, Betriebssystem, App-Version | nur mit Einwilligung und nur, wenn der Build Umami konfiguriert hat | Umami-Instanz des Betreibers |
| Absturzberichte | Fehler, Stack, App-Version, Systemversion. Ohne Gerätename, Nutzer und IP im Bericht (`sendDefaultPii: false`, kein Tracing, keine Screenshots) | nur mit Einwilligung und nur, wenn der Build einen DSN konfiguriert hat | GlitchTip oder Sentry |
| Firebase (optional) | Analytics und Crashlytics | nur, wenn der Build mit `tool/enable_firebase.dart` umgestellt wurde. Der Standard-Build enthält Firebase nicht. | Google |
| Google Analytics 4 | Seitenaufrufe, Browser- und Gerätedaten | **nur Web-Version**, nur mit eigener Einwilligung. Kommt in den Store-Apps nicht vor. | Google |
| Cast | Stream-Adresse, Sender- und Titelname an das gewählte Gerät. Das Google-Cast-SDK sendet laut Google eigene Nutzungsdaten. | erst nach Tipp auf den Cast-Knopf. Auf Android kann das SDK schon beim Beenden der App starten. | Google |
| Links zu Spotify, YouTube Music, Apple Music | Künstler und Titel als Suchbegriff | erst nach Tipp, im Browser oder der Fremd-App | jeweiliger Anbieter |
| Lokaler Speicher | Favoriten, Verlauf, Einstellungen, Cover-Cache, Entscheidung zur Einwilligung | bleibt auf dem Gerät | niemand außerhalb |

Es gibt kein Konto, keine Werbung, keine Werbe-ID (`AD_ID` ist im Android-Manifest entfernt), keine Standortabfrage, keinen Zugriff auf Kontakte, Fotos oder Mikrofon.

## 2. Zwei Fälle

Ob die Store-Version Daten sendet, entscheidet die Build-Konfiguration (`config/app.json`, siehe [telemetry.md](telemetry.md)). Das ist eine Entscheidung des Betreibers, die noch nicht gefallen ist.

| Fall | Build-Konfiguration | Google Play | App Store |
|---|---|---|---|
| A | keine Telemetrie-Werte | "Keine Daten erhoben oder weitergegeben" (siehe 3.1) | "Data Not Collected" (siehe 4.1) |
| B | Umami und/oder GlitchTip/Sentry konfiguriert | Tabellen 3.2 bis 3.4 | Tabellen 4.2 bis 4.3 |

Die Fälle unterscheiden sich nur bei Statistik und Absturzberichten. Die Fremddienste aus der Tabelle oben (laut.fm, Apple-Suche, Cast) gelten in beiden Fällen und sind in 3.5 und 4.4 eingeordnet.

## 3. Google Play: Datensicherheit

Pfad: Play Console > App-Inhalte > Datensicherheit.

### 3.1 Einstiegsfragen

| Frage | Antwort | Grund |
|---|---|---|
| Erhebt oder teilt die App Nutzerdaten der vorgegebenen Typen? | Fall A: **Nein**. Fall B: **Ja**. | Nur Statistik und Absturzberichte gelten als Erhebung (Fall B). Zu den übrigen Flüssen siehe 3.5. |
| Sind alle erhobenen Daten bei der Übertragung verschlüsselt? | **Ja** | Alle Verbindungen laufen über HTTPS (laut.fm, Apple, Telemetrie). Die Telemetrie-Adressen müssen `https://` verwenden, sonst wäre die Antwort falsch. Zum Cast-Gerät im lokalen Netz überträgt die App keine Nutzerdaten an einen Server. |
| Können Nutzer die Löschung ihrer Daten beantragen? | **Nein** vorgeschlagen **[Anwalt]** | Es gibt kein Konto. Statistik und Berichte enthalten keinen Namen und keine Kennung, die einen Nutzer auffindbar machen würde. Der Nutzer kann die Einwilligung jederzeit widerrufen, ab dann sendet die App nichts mehr. Ob ein Antrag per E-Mail an den Betreiber als Verfahren genügt, ist eine Rechtsfrage (Art. 17 DSGVO, steht in der Datenschutzerklärung). |

### 3.2 Datentypen (nur Fall B)

| Datentyp (Google) | Erhoben | Weitergegeben | Optional | Zweck | Grund |
|---|---|---|---|---|---|
| App-Aktivität > App-Interaktionen | Ja | Nein | **Optional** (Nutzer kann ablehnen) | Analyse | Umami-Ereignisse: Bildschirmaufrufe, Sender gestartet oder gestoppt, Favorit, Teilen, Export |
| App-Informationen und Leistung > Absturzprotokolle | Ja | Nein | **Optional** | Analyse (alternativ App-Funktionalität) | GlitchTip oder Sentry. Die iOS-Datei `PrivacyInfo.xcprivacy` nennt "App-Funktionalität". Beide Formulare sollten denselben Zweck tragen, deshalb für beide Stores gemeinsam entscheiden. |
| App-Informationen und Leistung > Diagnose | Nein | | | | Das Sentry-SDK sendet kein Tracing und keine Leistungsdaten (`tracesSampleRate = 0`). |
| Geräte- oder andere IDs | **Nein** im Standard-Build | | | | Umami bildet die Besucher-Kennung serverseitig aus IP und Browserkennung, die App selbst legt keine ID an und liest keine Werbe-ID. **Bei aktivem Firebase: Ja** (Firebase-Installations-ID), Zweck Analyse, optional. |

### 3.3 Weitergabe (Sharing)

Antwort: **Nein** für beide Dienste. Begründung: Die Telemetrie-Dienste verarbeiten im Auftrag des Betreibers (Auftragsverarbeitung, Umami und GlitchTip selbst gehostet oder mit Vertrag). Google nimmt solche Dienstleister von der Weitergabe aus. **[Anwalt]** Das gilt nur mit Auftragsverarbeitungsvertrag. Bei Sentry Cloud oder Firebase muss er abgeschlossen sein.

### 3.4 Einwilligung als "optional"

Der Einwilligungsdialog erscheint beim ersten Start, wenn Telemetrie konfiguriert ist. Die App funktioniert bei Ablehnung unverändert. Deshalb "Optional: Nutzer können wählen, ob diese Daten erhoben werden".

### 3.5 Flüsse, die wir nicht als Erhebung angeben, und warum

| Fluss | Vorschlag | Grund und Risiko |
|---|---|---|
| Stream und Titeldaten von laut.fm | nicht angeben | Der Nutzer fordert den Stream selbst an. IP-Adresse ist kein eigener Datentyp in der Liste (Google: nach tatsächlicher Verwendung angeben, hier keine Standortbestimmung). **[Anwalt]** Ob laut.fm als Dritter gilt, an den "geteilt" wird. Wir geben keine Nutzerdaten an laut.fm, die App ruft nur öffentliche Daten ab. |
| Cover-Suche bei Apple | nicht angeben | Es geht nur Künstler und Titel (kein Nutzerinhalt) und die IP-Adresse an Apple. **[Anwalt]** Der Schalter "Cover laden" lässt sich abschalten. |
| Google Cast (Android) | **[nicht belegt]** | Das SDK sendet laut Google eigene Nutzungsdaten. Welche Datentypen Google dafür vorsieht, haben wir nicht aus einer offiziellen Tabelle belegt. Vor Abgabe in der Cast-Dokumentation und den Hinweisen zu Play-Diensten nachlesen und die Angabe ergänzen. Datenschutzerklärung, Abschnitt Cast, enthält dieselbe offene Frage. |
| Lokaler Speicher | nicht angeben | Verlässt das Gerät nicht (Google: Verarbeitung auf dem Gerät ist keine Erhebung). |
| Google Analytics 4 | nicht angeben | Gibt es nur in der Web-Version, nicht in den Store-Apps. |

### 3.6 Weitere Angaben in der Play Console, die dazu gehören

| Frage | Antwort | Grund |
|---|---|---|
| Werbe-ID verwendet? | **Nein** | Berechtigung `AD_ID` ist im Manifest entfernt. |
| Enthält die App Werbung? | **Nein** | |
| Datenschutzerklärung (URL) | `https://app.linefm.de/datenschutz/` | Die Seite muss erreichbar sein, bevor die App eingereicht wird. Sie ist noch ein Entwurf mit offenen Platzhaltern (siehe [FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md)). |
| Zielgruppe | Kein Angebot für Kinder, Altersgruppe 18+ oder 13+ nach Wahl des Betreibers **[Anwalt]** | Lieder können Kraftausdrücke enthalten (Hinweis in den Store-Texten). Die Zielgruppen-Angabe löst bei unter 13 Jahren zusätzliche Pflichten (Families Policy) aus. |

## 4. App Store: App-Datenschutz

Pfad: App Store Connect > App > App-Datenschutz. Die Angaben müssen zu `ios/Runner/PrivacyInfo.xcprivacy` und zu den Manifesten der Fremd-SDKs passen. Xcode fasst sie beim Archivieren zusammen (Bericht: Product > Archive > Generate Privacy Report). Der Bericht ist die Prüfvorlage für die Formularantworten.

### 4.1 Einstiegsfrage

| Frage | Antwort | Grund |
|---|---|---|
| Erfassen Sie oder Ihre Drittanbieter-Partner Daten aus dieser App? | Fall A: **Nein** ("Data Not Collected"). Fall B: **Ja**. | Apple zählt Daten nur als erfasst, wenn sie das Gerät verlassen **und** länger als zur Bearbeitung der Anfrage nötig zugänglich bleiben. |
| Datenschutzerklärung (URL) | `https://app.linefm.de/datenschutz/` | Pflicht. |
| Datenschutzoptionen (URL) | leer lassen | Optional. Es gibt keine Konto-Seite. Der Widerruf steht in der App unter Einstellungen. |

### 4.2 Datentypen (nur Fall B)

| Datentyp (Apple) | Mit dem Nutzer verknüpft | Für Tracking | Zweck | Grund |
|---|---|---|---|---|
| Nutzungsdaten > Product Interaction | siehe 4.3 | **Nein** | Analytics | Umami-Ereignisse. Entspricht `NSPrivacyCollectedDataTypeProductInteraction` in der Datei. |
| Diagnose > Crash Data | siehe 4.3 | **Nein** | App Functionality (so in der Datei) | GlitchTip oder Sentry. Entspricht `NSPrivacyCollectedDataTypeCrashData`. |
| Diagnose > Performance Data | nicht angeben | | | Kein Tracing, keine Leistungsmessung. |
| Kennungen > Device ID | nicht angeben im Standard-Build | | | **Bei aktivem Firebase: angeben** (Installations-ID, Zweck Analytics). |

Tracking: **Nein**. Die App verknüpft keine Daten mit Fremddaten für Werbung, gibt nichts an Datenhändler und fragt keine App-Tracking-Berechtigung ab (`NSPrivacyTracking = false`, keine Tracking-Domains).

### 4.3 Offene Frage "Mit dem Nutzer verknüpft" **[Anwalt]**

`PrivacyInfo.xcprivacy` führt beide Datentypen mit `NSPrivacyCollectedDataTypeLinked = false`. Apple schreibt aber, dass Daten, die nach Datenschutzrecht personenbezogen sind, **immer als verknüpft gelten**. Die Datenschutzerklärung und [telemetry.md](telemetry.md) stufen Statistik und Absturzberichte als **pseudonym und damit personenbezogen** ein, weil die IP-Adresse technisch beim Server ankommt. Das passt nicht zusammen.

Vorschlag: Im Formular **"Verknüpft: Ja"** angeben und `NSPrivacyCollectedDataTypeLinked` in beiden Einträgen der Datei auf `true` setzen, sofern der Anwalt die Einordnung als personenbezogen bestätigt. Die Datei ist in diesem Schritt nicht geändert worden, weil iOS-Änderungen erst nach einem Xcode-Lauf in der CI als belegt gelten. Entscheidung und Änderung stehen aus.

### 4.4 Flüsse, die wir nicht als Erfassung angeben

| Fluss | Vorschlag | Grund und Risiko |
|---|---|---|
| Stream und Titeldaten von laut.fm | nicht angeben | laut.fm ist die Quelle des Inhalts, kein in die App eingebundenes SDK. **[Anwalt]** Wie lange laut.fm Anfragen speichert, wissen wir nicht. |
| Cover-Suche bei Apple | nicht angeben | Apple ist selbst der Empfänger. Es geht kein Nutzerinhalt, nur Künstler und Titel. |
| AirPlay, CarPlay | nicht angeben | Systemfunktionen von Apple, die App sendet nichts an eigene oder fremde Server. |
| Lokaler Speicher | nicht angeben | Bleibt auf dem Gerät. In `PrivacyInfo.xcprivacy` stehen dafür die Pflichtbegründungen für UserDefaults (`CA92.1`, `1C8F.1`) und Dateizeitstempel (`C617.1`). |
| Google Cast auf iOS | **[nicht belegt]** | Die Store-Texte versprechen Cast nur für Android. Wird das Cast-SDK auch in der iOS-App mitgeliefert, muss seine Datenerfassung angegeben werden. Vor Abgabe im Xcode-Datenschutzbericht prüfen. |

## 5. Wenn sich etwas ändert

| Änderung | Anpassen |
|---|---|
| neuer Telemetrie-Anbieter oder neues Ereignis | Abschnitt 1 bis 4, [telemetry.md](telemetry.md), Datenschutzerklärung, `PrivacyInfo.xcprivacy` |
| Firebase aktiviert | Google: Geräte-IDs. Apple: Device ID. Beide: Einwilligungstext und Datenschutzerklärung prüfen. |
| neue Android-Berechtigung | `AndroidManifest.xml` und diese Datei |
| Konto oder Cloud-Funktion | alle Antworten neu ableiten, insbesondere Löschanfrage und "verknüpft" |
