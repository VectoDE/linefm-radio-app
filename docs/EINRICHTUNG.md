# Einrichtung für jaybelife

Diese Anleitung sagt dir, was du selbst eintragen oder beantragen musst, damit LINEFM Radio in den Stores und im Web erscheint. Alles andere ist vorbereitet. Du brauchst kein Programmierwissen. Wo etwas ein Entwickler tun muss, steht es dabei.

Wichtig vorab:

- Du trägst nur Zugangsdaten und Kontoangaben ein. Passwörter, Schlüssel und Tokens (geheime Zugangscodes) gehören **nie** in eine E-Mail oder einen Chat. Sie kommen als "Secret" in die GitHub-Einstellungen des Repos (Abschnitt 1) oder in deinen Passwortmanager.
- Erst die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) abarbeiten, dann veröffentlichen.
- Preise und Formulare der Anbieter ändern sich. Die Angaben unten stammen aus unserer Recherche vom November 2026. Im Zweifel gilt, was der Anbieter gerade anzeigt.
- Apple ist bewusst **nicht Teil der ersten Veröffentlichung**. Der Code ist vorbereitet, Abschnitt 3 beschreibt, was später nötig ist.

Fortschritt: Haken setzen, sobald ein Schritt erledigt ist. Reihenfolge der Abschnitte ist eine Empfehlung, nicht Pflicht.

## Übersicht: Was kostet das?

| Dienst | Kosten | Wofür |
|---|---|---|
| Google Play Console | 25 US-Dollar einmalig | Android |
| Microsoft Partner Center | für Einzelpersonen kostenlos | Windows-Store |
| Flathub, Snap Store | kostenlos | Linux |
| GitHub Releases | kostenlos | Installer für Windows, Linux, macOS, Android-APK |
| Apple Developer Program | 99 US-Dollar pro Jahr | iOS, macOS-Store, CarPlay (vorerst nicht) |
| Cloudflare Pages | kostenlos | Web, falls gewählt |
| eigener Server oder Plesk | vorhanden | Web, falls gewählt |

## 0. Vorbereitung

- [ ] GitHub-Einladung zum Repository `VectoDE/linefm-radio-app` annehmen (Rolle Collaborator).
- [ ] Passwortmanager bereithalten.
- [ ] Zustimmung zu App-Name "LINEFM Radio" und Paket-ID `de.linefm.app` geben (steht in der Freigabe-Checkliste). Die ID lässt sich im Play Store später nicht mehr ändern.

## 1. GitHub: Secrets eintragen

Die automatischen Abläufe (Bauen, Signieren, Hochladen) lesen ihre Zugangsdaten aus den Repo-Secrets.

Wo: Repository > Settings > Secrets and variables > Actions > "New repository secret".

- [ ] Jedes Secret, das in den folgenden Abschnitten genannt wird, dort anlegen. Name exakt übernehmen, Wert einfügen, speichern. Danach sieht man den Wert nie wieder, nur noch überschreiben.
- [ ] Ohne Secret passiert nichts Schlimmes: Der betreffende Schritt wird übersprungen oder baut unsigniert.

Die vollständige Liste aller Secrets und Variablen mit Herkunft und Zuständigkeit steht in [secrets.md](secrets.md). Wie die Abläufe zusammenhängen und in welcher Reihenfolge sie laufen, steht in [stores-pipelines.md](stores-pipelines.md).

## 2. Google Play (Android)

Quellen: [Play Console](https://play.google.com/console), Signierung in [packaging/android/SIGNING.md](../packaging/android/SIGNING.md).

### 2.1 Konto

- [ ] Entwicklerkonto auf <https://play.google.com/console/signup> anlegen und einmalig 25 US-Dollar zahlen.
- [ ] Kontoart wählen. Ein **privates** Konto braucht für die Erstveröffentlichung einen geschlossenen Test mit mindestens 12 Testern über mindestens 14 Tage. Ein Organisationskonto (mit D-U-N-S-Nummer) braucht das nicht.
- [ ] Identität bestätigen (Ausweis, Adresse, Telefon). Google verlangt das, auch für sideloadbare APKs ab 2027 (Entwicklerverifizierung).
- [ ] Tim Hauke als Nutzer einladen: Nutzer und Berechtigungen > Neue Nutzer einladen, mit App-Rechten für Veröffentlichung.

### 2.2 App anlegen

- [ ] "App erstellen": Name `LINEFM Radio`, Sprache Deutsch, Typ App, kostenlos.
- [ ] Erklärungen zu Richtlinien und US-Exportgesetzen bestätigen.

### 2.3 Signierung

- [ ] **Play App Signing** aktiviert lassen (Standard bei neuen Apps). Google verwaltet dann den eigentlichen App-Schlüssel.
- [ ] Upload-Schlüssel erzeugen (einmalig, Befehl steht in `packaging/android/SIGNING.md`). Datei `upload-keystore.jks` und Passwörter im Passwortmanager sichern. Geht der Schlüssel verloren, lässt er sich über die Play Console zurücksetzen.
- [ ] GitHub-Secrets anlegen: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

### 2.4 Dienstkonto für automatischen Upload

- [ ] In der Google Cloud Console ein Dienstkonto anlegen und einen JSON-Schlüssel erzeugen.
- [ ] In der Play Console unter Nutzer und Berechtigungen das Dienstkonto einladen, mit Recht für Veröffentlichung auf Test- und Produktionsspuren.
- [ ] Inhalt der JSON-Datei als Secret `PLAY_SERVICE_ACCOUNT_JSON` eintragen. Danach lädt `store-google.yml` jedes Release als Entwurf in die Spur "internal" hoch (siehe [stores-pipelines.md](stores-pipelines.md)).

### 2.5 App-Inhalte und Erklärungen

Play Console > Richtlinie > App-Inhalte. Alles muss ausgefüllt sein, sonst blockiert Google die Veröffentlichung.

- [ ] **Datenschutzerklärung**: URL eintragen, `https://app.linefm.de/datenschutz/`.
- [ ] **Datensicherheit**: Die Antworten hängen davon ab, welche Telemetrie du aktivierst (Abschnitt 6).
  - Cast immer mit bedenken: Das Cast-SDK der Google Play-Dienste sendet laut Google Nutzungsdaten an Google. Die App startet es erst, wenn jemand auf den Cast-Knopf tippt. Auf Android kann das Cast-Plugin das SDK aber schon beim Beenden der App initialisieren, auch ohne dass Cast genutzt wurde (siehe [ENTWICKLUNG.md](ENTWICKLUNG.md), Abschnitt Google Cast). In der Play Console deshalb "App-Aktivität" und "Geräte- oder andere IDs" mit Zweck "App-Funktionen" und Weitergabe an Google angeben, auch wenn du keine eigene Telemetrie nutzt. Welche Daten genau, steht in der aktuellen Google-Dokumentation zum Cast-SDK. Dort vor dem Ausfüllen nachlesen. Die Datenschutzerklärung beschreibt das in Abschnitt 7.
  - Keine Telemetrie konfiguriert und kein Cast genutzt: App erhebt und teilt keine Daten. Favoriten, Verlauf und Einstellungen bleiben auf dem Gerät.
  - Umami, GlitchTip, Sentry oder Firebase aktiv: Nutzungsdaten (App-Aktivität) und Absturzdaten angeben, Verschlüsselung bei der Übertragung "ja", Löschung auf Anfrage nach deinem tatsächlichen Verfahren.
  - Die Antworten müssen zur Datenschutzerklärung passen. Im Zweifel anwaltlich prüfen lassen.
- [ ] **Werbung**: "Keine Werbung". Die Werbe-ID (Advertising ID) wird nicht verwendet. Vorsicht bei Firebase: Das Firebase-Analytics-Paket kann die Berechtigung `com.google.android.gms.permission.AD_ID` in das Manifest einmischen. Dann müsste in der Play Console "Werbe-ID: ja" stehen und die Datenschutzerklärung dazu passen. Ob sie im fertigen Manifest steht, prüft man mit `aapt dump permissions app-release.apk`. Das Manifest entfernt sie bereits per `tools:node="remove"` (`android/app/src/main/AndroidManifest.xml`). Nach dem Release-Build trotzdem mit `aapt` nachsehen, ob sie fehlt.
- [ ] **Zielgruppe und Inhalte**: Altersgruppe wählen (nicht für Kinder), Inhaltseinstufung per Fragebogen. Hinweis: Der Sender +RAP kann Texte mit Kraftausdrücken senden, das beim Fragebogen ehrlich angeben (siehe auch Flathub-Altersangabe in der Freigabe-Checkliste).
- [ ] **Foreground-Service-Erklärung** (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, Dienst für die Wiedergabe im Hintergrund): Typ "Media playback" wählen. Begründung: Die App spielt Live-Radio im Hintergrund und bei gesperrtem Bildschirm, mit Benachrichtigung und Medientasten. Google kann ein kurzes Video verlangen, das den Ablauf zeigt (Wiedergabe starten, App verlassen, Benachrichtigung bedienen).
- [ ] **Vollbild-Benachrichtigung** (`USE_FULL_SCREEN_INTENT`): Wird für den Radiowecker gebraucht, damit der Wecker bei gesperrtem Bildschirm sichtbar klingelt. Play lässt die Berechtigung seit Android 14 nur für Anruf- und Wecker-Apps standardmäßig zu. In der Erklärung angeben: Kernfunktion ist ein Radiowecker, der zur eingestellten Zeit den Sender startet. **Risiko:** Bei einer Radio-App kann Google das ablehnen. Fällt die Erklärung durch, entfernt der Entwickler die Berechtigung und der Wecker meldet sich dann ohne Vollbild. Das ist offen und wird mit dir abgestimmt.
- [ ] **Exakte Alarme** (`SCHEDULE_EXACT_ALARM`): Die App nutzt bewusst nicht `USE_EXACT_ALARM`. Beim Wecker fragt die App den Nutzer, ob exakte Alarme erlaubt sind.
- [ ] Weitere Pflichtangaben: Kontaktdaten der Store-Seite (E-Mail, optional Website), Behördenapp "nein", Finanzfunktionen "nein", Gesundheit "nein", Werbe-ID "nein" (außer die AD_ID-Berechtigung aus Firebase bleibt im Manifest, siehe oben).

### 2.6 Store-Eintrag

- [ ] Kurzbeschreibung (80 Zeichen) und ausführliche Beschreibung auf Deutsch und Englisch eintragen. Die Texte stehen fertig in [STORE-TEXTE.md](STORE-TEXTE.md).
- [ ] Grafiken hochladen: App-Icon 512 x 512 (liegt in `assets/branding/play_store_512.png`), Feature-Grafik 1024 x 500, mindestens 2 Telefon-Screenshots, für Tablets je 7 und 10 Zoll empfohlen. Siehe Abschnitt 8.
- [ ] Kategorie "Musik & Audio".

### 2.7 Geschlossener Test (nur privates Konto)

- [ ] Testspur "Geschlossener Test" anlegen, Release hochladen.
- [ ] Mindestens 12 Tester per E-Mail-Liste oder Google-Gruppe eintragen und einladen. Einladungstext und Testerliste-Vorlage stehen in [STORE-TEXTE.md](STORE-TEXTE.md).
- [ ] 14 Tage laufen lassen, dann "Zugriff auf Produktion beantragen".

### 2.8 Links für Android: assetlinks.json

Damit Links `https://app.linefm.de/?station=...` direkt in der App statt im Browser öffnen, muss die Web-Seite die App bestätigen.

- [ ] SHA-256-Fingerabdruck des **App-Signaturschlüssels** kopieren: Play Console > Test und Veröffentlichung > Einrichtung > App-Integrität > App-Signatur. (Nicht den Upload-Schlüssel.)
- [ ] Datei `assetlinks.json` (die Bestätigung, dass die Web-Seite und die App zusammengehören) unter `https://app.linefm.de/.well-known/assetlinks.json` bereitstellen. Inhalt:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "de.linefm.app",
    "sha256_cert_fingerprints": ["HIER:DER:SHA-256:FINGERABDRUCK"]
  }
}]
```

- [ ] Prüfen: Die Datei muss ohne Weiterleitung mit Status 200 und `application/json` erreichbar sein. Die mitgelieferten Server-Konfigurationen lassen den Ordner `/.well-known/` zu.
- [ ] Entwickler bitten, im Android-Manifest `autoVerify` auf `true` zu setzen und neu zu veröffentlichen. Bis dahin öffnen Links im Browser, die App funktioniert trotzdem.

## 3. Apple (vorbereitet, vorerst nicht veröffentlicht)

Apple ist für die Veröffentlichung herausgenommen. iOS, macOS, CarPlay und AirPlay sind im Code vorbereitet. Wenn du Apple später aktivieren willst:

- [ ] Apple Developer Program beitreten (<https://developer.apple.com/programs/>), 99 US-Dollar pro Jahr. Für eine Firma wird eine D-U-N-S-Nummer verlangt.
- [ ] **Team-ID** notieren (Account > Mitgliedschaft, 10 Zeichen). Secret `APPLE_TEAM_ID`.
- [ ] Bundle-ID `de.linefm.app` unter Zertifikate, IDs & Profile registrieren, mit den Fähigkeiten Background Modes (Audio) und später CarPlay.
- [ ] App in App Store Connect anlegen (Name "LINEFM Radio", Bundle-ID, Sprache Deutsch).
- [ ] API-Schlüssel für App Store Connect erzeugen (Nutzer und Zugriff > Integrationen). Schlüssel-ID, Issuer-ID und den Inhalt der `.p8`-Datei als Secrets `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID` und `APP_STORE_CONNECT_API_KEY_P8` eintragen.
- [ ] Zertifikate und Profile: "Apple Distribution" (iOS und Mac) und "Mac Installer Distribution" (nur Mac App Store) als `.p12` exportieren, dazu je ein App-Store-Profil für `de.linefm.app` und `de.linefm.app.widget` (iOS) sowie `de.linefm.app` (macOS). Secrets `APPLE_DISTRIBUTION_CERT_P12_BASE64`, `APPLE_DISTRIBUTION_CERT_PASSWORD`, `APPLE_MAC_INSTALLER_CERT_P12_BASE64`, `APPLE_MAC_INSTALLER_CERT_PASSWORD`, `APPLE_IOS_PROVISIONING_PROFILES_BASE64`, `APPLE_MACOS_PROVISIONING_PROFILE_BASE64`. Für das signierte DMG außerhalb des Stores zusätzlich `APPLE_DEVELOPER_ID_CERT_P12_BASE64` und `APPLE_DEVELOPER_ID_CERT_PASSWORD`. Die Pipeline (`store-apple.yml`) nutzt kein fastlane, Details in [secrets.md](secrets.md). Vorlagen für die Exportoptionen: [packaging/ios/README.md](../packaging/ios/README.md).
- [ ] Schalter `APPLE_PUBLISHING_ENABLED` (Repository-Variable, nicht Secret) erst dann auf `true` setzen, wenn alles vorliegt.
- [ ] **CarPlay-Audio-Berechtigung** beantragen (Formular im Apple-Entwicklerportal, "CarPlay App Entitlement Request", Kategorie Audio). Apple prüft von Hand, das kann Wochen dauern. Ohne Freigabe zeigt die App kein CarPlay.
- [ ] **AASA-Datei** (Bestätigungsdatei für Links, die direkt in der iOS-App öffnen, Universal Links): `https://app.linefm.de/.well-known/apple-app-site-association` (ohne Dateiendung, Antwort `application/json`, keine Weiterleitung). Inhalt, mit deiner Team-ID:

```json
{
  "applinks": {
    "details": [{ "appIDs": ["TEAMID.de.linefm.app"], "components": [{ "/": "/", "?": { "station": "*" } }] }]
  }
}
```

- [ ] Entwickler muss dafür im iOS-Projekt die Fähigkeit "Associated Domains" (`applinks:app.linefm.de`) ergänzen. Das ist noch nicht belegt und wird bei Aktivierung geprüft.
- [ ] macOS ohne Apple-Konto: Es gibt ein unsigniertes DMG auf GitHub Releases mit Öffnen-Anleitung ([packaging/macos/LIES-MICH-ZUERST.txt](../packaging/macos/LIES-MICH-ZUERST.txt)). Mit Apple-Daten wird automatisch signiert und notarisiert.
- [ ] Review-Risiko beachten: Apple lehnt reine Webseiten-Hüllen ab (Richtlinien 4.2 und 4.3). Die App bringt Favoriten, Verlauf, Sleeptimer, Wecker, Sperrbildschirm-Steuerung und CarPlay als Mehrwert mit.

## 4. Microsoft Partner Center (Windows-Store)

Quelle: [packaging/windows/README.md](../packaging/windows/README.md).

- [ ] Konto unter <https://partner.microsoft.com/dashboard/registration> als Einzelentwickler registrieren (kostenlos, Identitätsprüfung).
- [ ] App-Namen "LINEFM Radio" reservieren.
- [ ] Unter Produktverwaltung > Produktidentität drei Werte kopieren: `Package/Identity/Name`, `Package/Identity/Publisher` (sieht aus wie `CN=XXXXXXXX-...`) und `Package/Properties/PublisherDisplayName`. Diese Werte trägt der Entwickler im Build ein (`identity_name`, `publisher`, `publisher_display_name`).
- [ ] Azure-AD-Anwendung für die Store-Pipeline anlegen (Partner Center > Konto-Einstellungen > Benutzer > Azure-AD-Anwendungen, Rolle "Manager"). Secrets `MS_STORE_TENANT_ID`, `MS_STORE_SELLER_ID`, `MS_STORE_CLIENT_ID`, `MS_STORE_CLIENT_SECRET` und Variablen `MS_STORE_PRODUCT_ID`, `MS_STORE_IDENTITY_NAME`, `MS_STORE_PUBLISHER`, `MS_STORE_PUBLISHER_DISPLAY_NAME` eintragen (Quellen in [secrets.md](secrets.md)). `store-microsoft.yml` reicht dann den Entwurf ein, abgeschickt wird im Partner Center.
- [ ] Für den Store braucht es kein eigenes Zertifikat, Microsoft signiert selbst. Für den Installer auf GitHub optional: Codesigning-Zertifikat als `WINDOWS_CERT_PFX_BASE64` und `WINDOWS_CERT_PASSWORD`. Ohne Zertifikat zeigt Windows SmartScreen beim Installer eine Warnung.
- [ ] Store-Eintrag: Beschreibung, 300 x 300-Logo, mindestens ein Screenshot, Altersfreigabe, Datenschutz-URL.

## 5. Linux: Flathub und Snap Store

### 5.1 Flathub

Quelle: [packaging/flathub/README.md](../packaging/flathub/README.md).

- [ ] Domain bestätigen: Datei `https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` bereitstellen (Inhalt nennt Flathub bei der Einreichung). Das geht nur über die Hauptdomain, die du verwaltest.
- [ ] Weitergabe erlauben: Flathub muss die App weiterverteilen dürfen. LINEFM Radio ist **proprietär** (alle Rechte vorbehalten, keine Open-Source-Lizenz). Das ist bei Flathub erlaubt, wenn du die Weitergabe ausdrücklich erlaubst. Schriftlich bestätigen.
- [ ] **Ehrlicher Hinweis:** Unser Paket enthält die fertig gebaute Binärdatei, nicht den Quelltext. Flathub verlangt bei nicht offener Software meist den Bau aus dem Quelltext oder besondere Regeln. Es kann sein, dass Flathub die Einreichung ablehnt oder eine Ausnahme verlangt. Das lässt sich nur durch Nachfragen bei den Flathub-Betreuern klären (Issue im Repo `flathub/flathub`). Wenn es scheitert, bleiben Snap Store und der Tarball auf GitHub.
- [ ] Altersangabe (OARS, die Alterseinstufung bei Linux-Stores) in der Metainfo (der Beschreibungsdatei für die Stores) bestätigen, wegen Kraftausdrücken bei +RAP.
- [ ] Screenshots im Netz bereitstellen und die URLs in der Metainfo eintragen (Platzhalter).
- [ ] Einreichung: Pull Request gegen `flathub/flathub`. Der Entwickler bereitet ihn vor, du reichst mit deinem GitHub-Konto ein oder gibst Tim Hauke die Vollmacht.

### 5.2 Snap Store

- [ ] Konto auf <https://snapcraft.io/> anlegen (Ubuntu One).
- [ ] Snap-Namen `linefm-radio` registrieren (`snapcraft register linefm-radio` oder über die Webseite).
- [ ] Zugangsdaten für die Pipeline erzeugen (`snapcraft export-login`, Befehl in [secrets.md](secrets.md)) und als Secret `SNAPCRAFT_STORE_CREDENTIALS` eintragen. Danach lädt `store-snap.yml` jedes Release in den Kanal "edge".
- [ ] Erste Version in den Kanal "edge" oder "candidate" stellen, testen, dann "stable".
- [ ] Hinweis: Ob die Tray-Funktion unter der strikten Snap-Absicherung läuft, ist noch ungetestet.

## 6. Statistik und Absturzberichte (optional)

Ohne Konfiguration sendet die App nichts und fragt auch nicht nach Einwilligung. Wenn du Auswertung willst:

- [ ] Anbieter wählen: Umami (Statistik), GlitchTip oder Sentry (Abstürze), Firebase (beides). Technische Details: [telemetry.md](telemetry.md).
- [ ] Selbst hosten: Docker-Compose-Dateien liegen in `deploy/telemetry/`. Passwörter und Schlüssel erzeugen. **Wichtig vor jeder Veröffentlichung:** Umami legt beim ersten Start das Konto `admin` mit dem Passwort `umami` an. Das Passwort direkt nach der ersten Anmeldung ändern, bevor Umami aus dem Internet erreichbar ist. GlitchTip hat die Registrierung ausgeschaltet, das erste Konto entsteht auf der Kommandozeile (Ablauf in [telemetry.md](telemetry.md)).
- [ ] Werte in `config/app.json` eintragen (Vorlage `config/app.example.json`): `UMAMI_URL`, `UMAMI_WEBSITE_ID`, `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, für Firebase `FIREBASE_*`. Es sind nur öffentliche IDs, keine Geheimnisse. Die Datei wird nicht ins Repo eingecheckt, die CI schreibt sie aus Secrets oder Variables.
- [ ] Nach jeder Änderung die Web-Version neu bauen und die Server-Header neu ausrollen, sonst blockiert die Sicherheitsrichtlinie die neuen Domains.
- [ ] Datenschutzerklärung anpassen: Abschnitte für aktivierte Anbieter einblenden (siehe Abschnitt 9, Impressum) und Betreiber sowie Speicherdauer ausfüllen (`UMAMI_BETREIBER`, `SENTRY_BETREIBER`, `TELEMETRIE_AUFBEWAHRUNG`).
- [ ] Mit jedem Dienstleister, der in deinem Auftrag Daten verarbeitet (Hosting, CDN, Betreiber der Umami- oder GlitchTip-Instanz), einen Vertrag zur Auftragsverarbeitung (AVV, Art. 28 DSGVO) abschließen. Bei Cloudflare, Google und Apple sind die Standardverträge der Anbieter ein Weg. Ob ein US-Anbieter unter dem EU-US Data Privacy Framework (DPF) zertifiziert ist, steht im öffentlichen Verzeichnis auf <https://www.dataprivacyframework.gov/list>. Eine Zertifizierung gilt nicht für immer, deshalb vor dem Start und danach regelmäßig nachsehen. Das ist eine Vorprüfung, keine Rechtsberatung.
- [ ] Google Play "Datensicherheit" entsprechend ausfüllen (Abschnitt 2.5).

## 7. Web-Hosting (app.linefm.de)

Die Web-App besteht nur aus Dateien. Such dir **einen** Weg aus. Jede Anleitung enthält fertige Konfigurationen, ein Überblick steht in [hosting-uebersicht.md](hosting-uebersicht.md).

- [ ] **Eigener Server mit nginx:** [hosting-nginx.md](hosting-nginx.md), Konfiguration in `deploy/nginx/`.
- [ ] **Server mit Docker und Traefik:** [hosting-traefik.md](hosting-traefik.md), Konfiguration in `deploy/traefik/`.
- [ ] **Cloudflare Pages:** [hosting-cloudflare.md](hosting-cloudflare.md), Konfiguration in `deploy/cloudflare/`. Dafür Secrets `CLOUDFLARE_API_TOKEN` (Berechtigung "Cloudflare Pages: Edit") und `CLOUDFLARE_ACCOUNT_ID`, Variable `CLOUDFLARE_PAGES_PROJECT`. Automatisch ausrollen: `deploy-web.yml`, Ziel `cloudflare` in der Variable `WEB_DEPLOY_TARGETS`.
- [ ] **Plesk:** [hosting-plesk.md](hosting-plesk.md), Konfiguration in `deploy/plesk/`.
- [ ] **Automatisch ausrollen:** Umgebung `production` mit Genehmigern anlegen, Secrets und Variablen für das gewählte Ziel eintragen ([secrets.md](secrets.md), Abschnitt "Web-Deploy"), `WEB_DEPLOY_TARGETS` auf `cloudflare`, `ssh` oder `plesk` setzen. Ohne diese Variable rollt nichts aus.
- [ ] DNS: `app.linefm.de` auf den gewählten Ort zeigen lassen.
- [ ] HTTPS-Zertifikat einrichten (Let's Encrypt oder Cloudflare). Ohne HTTPS laufen Service Worker und Installation als App nicht, und Browser warnen.
- [ ] Nach dem ersten Ausrollen prüfen (Befehle am Ende von `hosting-uebersicht.md`): Header, ETag, 304-Antwort.
- [ ] Optional Search Console: Bestätigungscode als `GSC_VERIFICATION` in `config/app.json` eintragen.
- [ ] Optional Vertrauens-Badges: Wenn Einträge bei Gridinsoft und Trustpilot existieren, die Links in `config/app.json` eintragen (`TRUST_GRIDINSOFT_URL`, `TRUST_TRUSTPILOT_URL`). Die Profile legst du an, ohne Eintrag erscheint kein Badge.

## 8. Bilder und Grafiken, CDN

- [ ] **CORS für die Senderlogos:** Der Server hinter `cdn.linefm.de` muss für `/images/icons/` den Header `Access-Control-Allow-Origin: *` (oder `https://app.linefm.de`) senden. Ohne ihn kann die Web-Version das Logo nicht als Cover in der Mediensteuerung des Browsers zeigen. Die App läuft trotzdem.
- [ ] **Screenshots für die Stores** (Telefon, Tablet, Desktop) erstellen. Empfehlung: Stationen, Player, Verlauf, Favoriten, Wecker, jeweils dunkel und hell. Der Entwickler erzeugt sie auf den Geräten oder Emulatoren, du gibst sie frei. Maße je Store:
  - Google Play: 2 bis 8 Telefon-Screenshots, 16:9 bis 9:16, Kanten 320 bis 3840 px.
  - Microsoft Store: mindestens 1, empfohlen 4 oder mehr, 1366 x 768 oder größer.
  - Flathub: mindestens 1, über URL erreichbar.
- [ ] Alt-Texte (Bildbeschreibungen für Screenreader) für alle Bilder bereithalten (Barrierefreiheit).

## 9. Impressum und Datenschutz mit deinen Daten füllen

Die Rechtstexte liegen als Entwurf in der App (`assets/legal/`) und als Webseiten (`/impressum/`, `/datenschutz/`). Die Betreiberdaten werden aus `https://linefm.de/impressum` übernommen. Du bestätigst sie.

- [ ] Liste der Platzhalter ansehen: `assets/legal/placeholders.json`. Pflichtfelder sind Name, Rechtsform, Anschrift, Vertreter, E-Mail, Telefon oder Kontaktweg, Medienaufsicht, Verantwortlicher nach § 18 MStV, Datenschutzbeauftragter, Datenschutzbehörde, Hosting-Anbieter, CDN-Betreiber, Aufbewahrungsdauer der Logs und der Auftraggeber der App (Impressum, `APP_AUFTRAGGEBER`).
- [ ] Werte in eine Datei `legal_values.json` schreiben (Schlüssel = Platzhalter, Wert = Text). Nicht zutreffende Angaben als `"Nicht zutreffend."` eintragen, nicht leer lassen. Die Datei nicht ins Repo einchecken.
- [ ] Entwickler lässt den Generator laufen:

```bash
dart run tool/gen_legal_html.dart --values=legal_values.json --fill-assets --strict --providers=umami,sentry
```

  `--providers` nennt die aktivierten Telemetrie-Dienste, `--strict` bricht ab, solange Pflichtfelder offen sind. Solange etwas offen ist, setzt die Webseite `noindex`.
- [ ] Texte lesen und mit Anwalt abstimmen. Die Rechtstexte sind ein Entwurf nach Stand November 2026 und ersetzen keine Rechtsberatung.
- [ ] Vor dem Veröffentlichen prüft der Generator, dass kein Pflicht-Platzhalter mehr offen ist (`--strict`). Mit `--strict` prüft er zusätzlich `SECURITY.md`, `CODE_OF_CONDUCT.md`, `docs/BARRIEREFREIHEIT.md` und `web/.well-known/security.txt` auf `{{` (zum Beispiel `{{SECURITY_KONTAKT}}`). Diese Angaben trägst du selbst im Repo ein, keine Adresse wird vom Entwickler erfunden. Die CI baut jeden Tag-Build (auch Vorabversionen, denn auch die gehen in die Store-Testspuren) und jeden Store-Upload mit `--strict`.
- [ ] Der Einwilligungstext in der App (Dialog für Statistik und Fehlerberichte) nennt den Empfänger (Betreiber der Umami- bzw. GlitchTip-Instanz) und sagt, dass technisch die IP-Adresse übertragen wird. Prüfe, ob die Angabe zu deiner Konfiguration passt, und lass sie mit der Datenschutzerklärung abstimmen. Der Text liegt in den Sprachdateien der App (`lib/l10n/`), nicht in `assets/legal/`.

## 10. Wenn etwas hakt

- Frag im Repo unter Issues oder Discussions nach. Beschreibe, welchen Schritt du gerade machst und was du siehst.
- Bei Fehlermeldungen von Stores: Meldung kopieren, Screenshot anhängen, keine Passwörter.
- Den Zeitaufwand für Prüfungen der Stores einplanen: Google Play einige Tage, CarPlay-Antrag Wochen, Flathub je nach Betreuern.
