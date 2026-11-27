# Freigabe-Checkliste

Diese Liste sagt, was vor der Veröffentlichung von LINEFM Radio geprüft und bestätigt sein muss. Teil A bestätigt LineFM Studios als Betreiber, Teil B prüft jemand mit den echten Geräten, Teil C sind Texte und Datenschutzangaben.

So geht es: Jeder Punkt wird mit Datum und Name abgehakt oder als "offen" vermerkt. Ein Punkt gilt erst als erledigt, wenn die Antwort schriftlich vorliegt (E-Mail oder Eintrag im Ticket reicht).

Alle Rechts- und Steuerfragen hier sind eine Vorprüfung. Sie ersetzen keinen Anwalt und keinen Steuerberater.

Die Kontoeinrichtung steht in [EINRICHTUNG.md](EINRICHTUNG.md).

## Harte Freigabesperren

Diese Punkte lassen sich nicht als "offen" begründen. Solange einer nicht erfüllt ist, wird nicht veröffentlicht bzw. nicht eingeschaltet.

- [ ] **Telemetrie nicht aktivieren, solange keine AVV unterschrieben ist.** Erst wenn der Vertrag zur Auftragsverarbeitung (Art. 28 DSGVO) mit dem Betreiber der Statistik- bzw. Fehlerberichte-Instanz unterschrieben vorliegt, dürfen `UMAMI_*`, `SENTRY_DSN` oder Firebase in `config/app.json` bzw. den CI-Variablen gesetzt werden. Hintergrund: Mit aktiver Telemetrie sagt die Datenschutzerklärung, dass diese Verträge bestehen (Abschnitt 12). Ohne Telemetrie erscheint der Satz nicht.
- [x] **App-Icon und Markenlogos: schriftliche Zustimmung von LineFM Studios.** Erfüllt: Die schriftliche Freigabe für App-Icon und Logos liegt laut Inhaber seit 21.11.2026 vor. Das gilt für das Icon aus `https://cdn.linefm.de/images/icons/main.png` (Android, iOS, macOS, Windows, Linux, Web), die Store-Grafiken und das Social-Preview-Bild. Die Sperre ist damit aufgehoben. Bei künftigen neuen Logos oder geänderten Motiven muss die Zustimmung erneut schriftlich (E-Mail oder Ticket-Eintrag) vorliegen. Das Social-Preview-Bild lädt der Inhaber selbst bei GitHub hoch.
- [ ] Der Release-Build mit `--strict` läuft durch: keine offenen Pflicht-Platzhalter in Rechtstexten, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `BARRIEREFREIHEIT.md` und `security.txt`.

## A. Bestätigungen durch LineFM Studios

### A1. Marke und Logos

- [ ] Die Marke LINEFM und das Logo dürfen in der App und in den Stores verwendet werden.
- [ ] Die sechs Sender stehen in der App: LineFM +MAIN, +RAP, +GAMING, +LOFI sowie **Radio3FM** und **FobFM**. Für Radio3FM und FobFM bestätigen: Die Namen und Logos dürfen gezeigt werden, und die Streams dürfen in der App laufen. Laut unserer Recherche sind diese beiden keine LINEFM-Sender bei laut.fm, deshalb ist das eine ausdrückliche Freigabe.
- [ ] Die Sender-Logos kommen von `https://cdn.linefm.de/images/icons/`. Nutzung in den Stores erlaubt.
- [ ] Das RadioGruppe-Logo wird von `radiogruppe.de` geladen (wie in der Web-App). Nutzung erlaubt, Datenschutzabschnitt dazu bestätigt.

### A2. Name und Kennung

- [ ] App-Name **"LINEFM Radio"**.
- [ ] Fenstertitel **"LINEFM | Radio"**.
- [ ] Paket-ID **`de.linefm.app`** (Android, Windows, iOS und macOS, Flathub, Snap). Sie lässt sich nach der Veröffentlichung nicht mehr ändern.
- [ ] Web-Adresse **`https://app.linefm.de`**.

### A3. App-Icon

- [ ] Das Icon aus `https://cdn.linefm.de/images/icons/main.png` darf unverändert (nur technisch skaliert) als App-Icon in allen Stores verwendet werden. Freigabe ist erteilt, hier nur noch schriftlich festhalten.

### A4. Impressum und Datenschutz

- [ ] Betreiberdaten stimmen mit `https://linefm.de/impressum` überein (Name, Anschrift, E-Mail). Fehlende Angaben liefern: Telefon oder Kontaktformular, Vertretung, Datenschutzbehörde, Hosting-Anbieter, CDN-Betreiber, Log-Dauer (Liste in `assets/legal/placeholders.json`).
- [ ] Der Datenschutztext passt zur tatsächlichen Konfiguration (welche Telemetrie ist aktiv, wer hostet).
- [ ] Rechtsprüfung durch LineFM Studios oder einen Anwalt ist erfolgt. Offene Rechtsfragen, die LineFM Studios selbst klärt:
  - [ ] **Rundfunkrecht (MStV):** Ist für das Webradio eine Zulassung nötig, oder gilt es als zulassungsfrei? Welche Angaben verlangt § 18 MStV im Impressum (verantwortliche Person)? Die Felder `AUFSICHTSBEHOERDE_MEDIEN` und `VERANTWORTLICHER_MSTV` stehen noch offen.
  - [ ] **GEMA und GVL:** Sind die Musikrechte für die Wiedergabe über eine eigene App abgedeckt? Unsere Quelle (laut.fm) belegt das nur in einem Artikel von 2015. Empfehlung: schriftliche Bestätigung von laut.fm (`team@laut.fm`) einholen.
  - [ ] **Speicher-Hinweis in den nativen Apps:** Der Hinweis erscheint im Browser als Banner am unteren Rand, in der App und auf dem Desktop als Popup beim ersten Start, das mit "Verstanden" bestätigt werden muss. Prüfen lassen, ob er in den nativen Apps rechtlich nötig oder ausreichend ist.
  - [ ] **Einwilligung nach DSGVO/TDDDG:** Wortlaut des Einwilligungsdialogs für Statistik und Absturzberichte prüfen, falls Telemetrie aktiv wird.
  - [ ] **Barrierefreiheit (BFSG):** Klären, ob für das Angebot eine Erklärung zur Barrierefreiheit nötig ist.

### A5. laut.fm-Daten

- [ ] LineFM Studios bestätigt schriftlich, ob und in welchem Umfang für die Sender eine Lizenz über laut.fm besteht. Die App nutzt die öffentliche laut.fm-API (Titel, Cover-Hinweis, Hörerzahl, Streams). Im Impressum steht deshalb bewusst keine Aussage wie "eigene Lizenz", sondern nur, dass die Lizenzierung bei den Sendern bzw. bei laut.fm liegt. Wenn sich das belegen lässt, kann der Satz genauer werden.
- [ ] Radio3FM und FobFM stehen in den Texten als Partnersender (Sender anderer Betreiber). Bestätigen, dass diese Bezeichnung stimmt.
- [ ] Der Hinweis in Datenschutz und Impressum zu laut.fm ist richtig formuliert, vor allem die Aussage, dass wir selbst keine Verbindungsdaten aus dem Stream sehen. Prüfen, ob laut.fm dem Betreiber Hörerstatistiken bereitstellt.
- [ ] Cover kommen von der iTunes-Suche (Apple). Bestätigen, dass das in Ordnung ist, und dass es in der Datenschutzerklärung steht.

### A6. Rechte und Übergabe

Festzuhalten, damit später keine Zweifel entstehen:

- [ ] Tim Hauke (VectoDE) hat die App **unentgeltlich für LineFM Studios** entwickelt.
- [ ] LINEFM, die Marke, die Logos und das App-Icon gehören LineFM Studios.
- [ ] Der Quellcode steht unter "Alle Rechte vorbehalten", ohne Open-Source-Lizenz. Er ist sichtbar, aber nicht frei nutzbar. Schriftlich regeln, wer die Rechte am Code hat und was LineFM Studios damit tun darf (Weiterentwicklung durch Dritte, Weitergabe, Übergabe des Repos).
- [ ] Der Hinweis "Entwickelt von Tim Hauke (VectoDE) für LineFM Studios" mit GitHub-Link bleibt im Über-Bereich der App. LineFM Studios stimmt dem Wortlaut zu.
- [ ] Übergabe: Repository, Zugänge und Schlüssel. Upload-Schlüssel (Android) und Konten gehören LineFM Studios und liegen im Passwortmanager von LineFM Studios. Wer verwaltet die Stores nach dem Start?
- [ ] Wartung nach dem Start: Wer reagiert auf Fehler, Store-Rückfragen und Updates?

### A7. Veröffentlichen

- [ ] Freigabe, das GitHub-Repository öffentlich zu schalten. Danach sieht jeder den Code.
- [ ] Freigabe für den Start in jedem Store einzeln (Google Play, Microsoft Store, Flathub, Snap, GitHub Releases; Apple App Store mit Mac App Store später in einer eigenen Runde, siehe EINRICHTUNG.md Abschnitt 15). Je Store vorher die Punkte in [STORE-RICHTLINIEN.md](STORE-RICHTLINIEN.md) abgehakt: [Google Play](STORE-RICHTLINIEN.md#google-play), [Apple](STORE-RICHTLINIEN.md#apple-app-store), [Microsoft](STORE-RICHTLINIEN.md#microsoft-store), [Snap](STORE-RICHTLINIEN.md#snap-store), [Flathub](STORE-RICHTLINIEN.md#flathub), [Web](STORE-RICHTLINIEN.md#web-und-pwa).

## B. Gerätetests (Release-Gate)

Jeder Test wird auf einem **echten Gerät** oder echter Hardware gemacht. Emulatoren sind für Android Auto (DHU) und Wecker nur eine Ergänzung. Hinterlege Gerät, Version, Datum, Ergebnis, bei Fehlern Screenshot oder Video.

Stand: Die folgenden Tests sind noch **nicht** gelaufen. Bei der bisherigen Entwicklung gab es kein Android-Gerät, keinen Emulator, keinen Mac und keinen Linux-Rechner. Windows wurde gestartet und geprüft, das Tray-Menü und das Mini-Fenster wurden dabei **nicht sichtbar** geprüft.

### B1. Android (Handy und Tablet)

- [ ] Installation der signierten Version (aus dem Test-Kanal von Google Play).
- [ ] Wiedergabe startet, läuft im Hintergrund weiter, Benachrichtigung mit Sendername, Titel, Cover und Steuerung.
- [ ] Sperrbildschirm und Kopfhörertaste (Play/Pause) steuern die Wiedergabe.
- [ ] Anruf oder anderer Ton unterbricht und gibt die Wiedergabe sauber wieder frei.
- [ ] **Homescreen-Widget** hinzufügen: zeigt Sender und Titel, Knöpfe funktionieren, Tipp öffnet die App beim richtigen Sender.
- [ ] Teilen eines Songs und Öffnen eines Links `https://app.linefm.de/?station=...` und `linefm://play?station=...` startet den richtigen Sender.
- [ ] Netzwechsel (WLAN zu Mobilfunk, Flugmodus an und aus): Wiedergabe verbindet sich neu.
- [ ] Hell- und Dunkelmodus, Tablet-Layout (Liste links, Player rechts).

### B2. Android Auto

- [ ] Prüfung mit dem Desktop Head Unit (DHU, ein Simulator für das Auto-Display von Google) und, wenn möglich, im echten Auto.
- [ ] Die App erscheint in der Medienliste.
- [ ] Menü zeigt Favoriten-Sender, alle Stationen und "Zuletzt gehört".
- [ ] Sender starten, Titel und Cover erscheinen.

### B3. Radiowecker

- [ ] Alarm stellen, Gerät sperren, Alarm löst zur Zeit aus (Android: exakter Alarm, Vollbild bei gesperrtem Bildschirm).
- [ ] Wecken mit Sender, mit Fallback: Ist der Stream nicht erreichbar, klingt der Standard-Alarmton des Geräts.
- [ ] Erlaubnisdialog für exakte Alarme und Benachrichtigungen erscheint und führt in die richtigen Systemeinstellungen.
- [ ] **Zeitzone:** Zeitzone des Geräts ändern (z. B. Reise), danach prüfen, dass der Wecker zur neuen Ortszeit klingelt. Dasselbe bei Zeitumstellung (Sommer-/Winterzeit) und bei manueller Uhrzeitänderung.
- [ ] Wecker nach Neustart des Geräts weiterhin aktiv.
- [ ] Schlummern und Ausschalten funktionieren.
- [ ] Schlafmodus und Energiesparmodus (Akkuoptimierung) stören den Alarm nicht.
- [ ] Windows und Linux: Alarm klingelt bei laufender App, Hinweis bei geschlossener App ist verständlich.
- [ ] iOS (später): Hinweis statt voller Weckfunktion, Wortlaut prüfen.

### B4. Windows

- [ ] Installer und MSIX (Windows-Paketformat für den Store) installieren und deinstallieren sauber.
- [ ] **Tray-Symbol (Symbol im Infobereich der Taskleiste) und Menü:** Rechtsklick-Menü zeigt Play/Stopp, Sender, Mini-Fenster, Beenden. Wiedergabe läuft bei geschlossenem Fenster weiter.
- [ ] **Mini-Fenster:** Öffnet, bleibt auf Wunsch im Vordergrund, merkt Größe und Position.
- [ ] Medientasten der Tastatur und die Mediensteuerung von Windows (Lautstärke-Flyout) zeigen Titel und steuern die Wiedergabe.
- [ ] Zweiter Start holt das vorhandene Fenster nach vorn (nur eine Instanz).
- [ ] Tastenkürzel funktionieren.
- [ ] **Deep Link:** `linefm://play?station=linefmrap` im Browser oder Terminal öffnet die App beim richtigen Sender, auch wenn sie schon läuft.
- [ ] Hohe Skalierung (150 und 200 Prozent), mehrere Monitore.
- [ ] **Eigene Titelleiste:** Logo und Name scharf, Farbe wie der Header (Dunkel und Hell); Hover, Druck und rotes Schließen; inaktives Fenster gedämpft. Ziehen, Doppelklick, Andocken an Ränder, Snap-Layouts beim Überfahren von Maximieren, Größenänderung an allen Kanten, Schatten und runde Ecken (Windows 11), maximiert kein abgeschnittener Rand, Rechtsklick und Alt+Leertaste öffnen das Systemmenü. Schließen verhält sich wie vorher (Tray bzw. Beenden).

### B5. Linux

- [ ] Start aus Flatpak und Snap (wenn veröffentlicht), sonst aus dem Tarball.
- [ ] Wiedergabe, Medientasten (MPRIS, der Linux-Standard dafür), Tray-Symbol (Symbol im Infobereich, je nach Desktop), Mini-Fenster.
- [ ] Deep Link `linefm://play?station=...` über die Desktop-Datei.
- [ ] Eigene Titelleiste ohne zweite Systemleiste, Verschieben und Größenänderung an allen Kanten unter X11 und Wayland (GNOME, KDE).

### B6. macOS

- [ ] DMG öffnen, App starten laut [Anleitung](../packaging/macos/LIES-MICH-ZUERST.txt) (macOS 15 verlangt den Weg über Systemeinstellungen).
- [ ] Wiedergabe, Medientasten, Tray-Symbol in der Menüleiste, Mini-Fenster.
- [ ] Titelleiste in App-Farbe, Ampeln links mittig, Logo und Name überlappen sie nicht; Ziehen und Doppelklick (laut Systemeinstellung), Vollbild über die grüne Ampel.

### B7. Web

- [ ] Chrome, Firefox, Safari und Edge auf Windows, macOS, Android, iOS.
- [ ] Wiedergabe startet nach Klick. Blockiert der Browser Autoplay, muss ein Knopf zum Starten erscheinen. Die Mediensteuerung des Browsers zeigt den Titel.
- [ ] Installation als App (PWA, eine Web-App, die sich wie eine App installieren lässt) möglich.
- [ ] Lighthouse (Geschwindigkeits- und Qualitätsprüfung von Google) und axe (automatische Barrierefreiheitsprüfung): keine kritischen Befunde. Der aktuelle Stand mit bekannten Grenzen steht in [BARRIEREFREIHEIT.md](BARRIEREFREIHEIT.md) und in der Kurzfassung [ACCESSIBILITY.md](../.github/ACCESSIBILITY.md).
- [ ] HTTP-Header (Sicherheits- und Cache-Einstellungen, die der Server mitschickt) nach dem Ausrollen prüfen (siehe [hosting-uebersicht.md](hosting-uebersicht.md)).
- [ ] Teilen und Links `https://app.linefm.de/?station=...` öffnen den richtigen Sender.

### B8. Chromecast

- [ ] Cast-Symbol erscheint im Player (nur auf Android und iOS, im Web und auf dem Desktop ist es ausgeblendet).
- [ ] Wiedergabe wechselt vom Handy zum Gerät und zurück, Lautstärke und Stopp vom Handy funktionieren.
- [ ] Beim Titelwechsel gibt es am Cast-Gerät ein kurzes Neupuffern. Das ist technisch bedingt und wird nicht als Fehler gewertet.
- [ ] Verhalten bei Verbindungsabbruch.

### B9. AirPlay und CarPlay (später, nur mit Apple)

- [ ] AirPlay-Auswahl im Player, Wiedergabe auf HomePod oder Apple TV.
- [ ] CarPlay-Simulator in Xcode: App erscheint, Liste zeigt Favoriten-Sender, Stationen, "Zuletzt gehört".
- [ ] CarPlay im echten Auto, erst nach Freigabe der Apple-Berechtigung.

### B10. Querschnitt

- [ ] Autoplay beim Start ein und aus.
- [ ] Sleeptimer (Aus, 15, 30, 45, 60 Minuten) stoppt die Wiedergabe zum Zeitpunkt, auch bei gesperrtem Bildschirm.
- [ ] Favoriten (Songs und Sender) speichern, exportieren, nach Neustart noch da.
- [ ] Speicher löschen entfernt alle lokalen Daten.
- [ ] Deutsch und Englisch, Wechsel der Systemsprache. Platzhalter, Plural und lange Texte (Sendernamen, Fehlermeldungen) brechen das Layout nicht.
- [ ] Design und Bedienung: Leer-, Lade- und Fehlerzustände sind gestaltet und verständlich, hell und dunkel, Handy und Tablet bzw. schmales und breites Fenster.
- [ ] Medien: Sender-Icons, Logos und Screenshots sind scharf, mit Alt-Text bzw. Semantik-Label, Lizenz und Herkunft geklärt, ohne unnötig große Dateien.
- [ ] Tests: `flutter test` und der a11y-Workflow sind grün, Fehlerfälle (kein Netz, Stream bricht ab) von Hand geprüft.
- [ ] Bildschirmleser (TalkBack, VoiceOver, NVDA): Player, Liste und Einstellungen sind bedienbar.
- [ ] Einwilligungsdialog erscheint nur, wenn Telemetrie konfiguriert ist; ohne Einwilligung gehen keine Daten raus.
- [ ] Akku und Datenverbrauch bei einer Stunde Wiedergabe sind unauffällig. Die App nutzt bewusst keinen WebSocket von laut.fm (Messwerte in [ENTWICKLUNG.md](ENTWICKLUNG.md)).

## C. Store-Texte und Datenschutzangaben

- [ ] Kurz- und Langbeschreibung auf Deutsch und Englisch gelesen und freigegeben (Entwürfe in [STORE-TEXTE.md](STORE-TEXTE.md)). Sie nennen nur, was die App wirklich kann. Plattform-Hinweise stimmen (kein CarPlay, solange Apple fehlt).
- [ ] Keine Aussagen wie "offizielle App der RadioGruppe", wenn LineFM Studios das nicht bestätigt hat. Der Hinweis "LINEFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe" entspricht der Web-App.
- [ ] Screenshots zeigen die echte App und keine Fantasiedaten, nichts Fremdes (keine Cover von Dritten in Großansicht ohne Freigabe).
- [ ] Altersangabe stimmt: 13+ in allen Stores, OARS Kraftausdrücke moderat (+RAP: Kraftausdrücke möglich).
- [ ] Google Play: "Datensicherheit" und "App-Inhalte" zur Datenschutzerklärung passend ausgefüllt (siehe [EINRICHTUNG.md](EINRICHTUNG.md), Abschnitt 13.1).
- [ ] Google Play: Erklärungen Gesundheit, Finanzen, Behörde, Nachrichten, Werbung und Werbe-ID jeweils "nein", Prüfhinweise ausgefüllt, Kontaktdaten per Code bestätigt (Schritte 6.1, 6.5, 6.13, [G-10](STORE-RICHTLINIEN.md#g-10), [G-35](STORE-RICHTLINIEN.md#g-35), [G-36](STORE-RICHTLINIEN.md#g-36), [G-37](STORE-RICHTLINIEN.md#g-37), [G-38](STORE-RICHTLINIEN.md#g-38), [G-39](STORE-RICHTLINIEN.md#g-39), [G-40](STORE-RICHTLINIEN.md#g-40), [G-53](STORE-RICHTLINIEN.md#g-53)).
- [ ] Google Play: Vordergrunddienst-Erklärung mit Anwendungsfall und Video, Vollbild-Intent mit Nutzerabfrage ([G-43](STORE-RICHTLINIEN.md#g-43), [G-44](STORE-RICHTLINIEN.md#g-44)).
- [ ] Datensicherheit: Löschfrage beantwortet, optionale Erhebung gekennzeichnet, SDK-Daten (Sentry, Firebase, Cast) enthalten ([G-45](STORE-RICHTLINIEN.md#g-45), [G-46](STORE-RICHTLINIEN.md#g-46)).
- [ ] IARC-Fragebogen nach inhaltlichen Änderungen neu eingereicht ([G-49](STORE-RICHTLINIEN.md#g-49)).
- [ ] Entwicklerverifizierung für das Direkt-APK ([G-41](STORE-RICHTLINIEN.md#g-41), [G-52](STORE-RICHTLINIEN.md#g-52)).
- [ ] Microsoft: Werbung "nein", Texte und Screenshots bis PEGI 12 (auch Songtitel), Händlerstatus angegeben, laut.fm während der Zertifizierung erreichbar ([M-25](STORE-RICHTLINIEN.md#m-25), [M-26](STORE-RICHTLINIEN.md#m-26), [M-27](STORE-RICHTLINIEN.md#m-27), [M-29](STORE-RICHTLINIEN.md#m-29)).
- [ ] Radio3FM und FobFM: schriftliche Erlaubnis für Namen, Logos und Streams liegt vor ([M-28](STORE-RICHTLINIEN.md#m-28), [D-03](STORE-RICHTLINIEN.md#d-03)).
- [ ] Snap: Datenschutz-URL und Kontakt im Eintrag ([S-09](STORE-RICHTLINIEN.md#s-09)).
- [ ] Flathub: Manifest-Repo von einem Menschen angelegt und gepflegt, KI-Anteil nur gegenüber Flathub offengelegt, Pflege sichtbar, Domain per Datei oder DNS bestätigt ([F-15](STORE-RICHTLINIEN.md#f-15), [F-16](STORE-RICHTLINIEN.md#f-16), [F-20](STORE-RICHTLINIEN.md#f-20)).
- [ ] Apple (spätere Runde): Händlerstatus je App, keine Werbedaten in den Labels ([A-34](STORE-RICHTLINIEN.md#a-34), [A-43](STORE-RICHTLINIEN.md#a-43)).
- [ ] Android Auto: Formfaktor hinzugefügt, Auto-Prüfung bestanden (Schritt 6.10, [G-21](STORE-RICHTLINIEN.md#g-21)).
- [ ] 16-KB-Prüfung ohne Fehler (Schritt 6.11, [G-22](STORE-RICHTLINIEN.md#g-22)).
- [ ] Google Play: Erklärung zu `USE_FULL_SCREEN_INTENT` (Vollbild-Alarm bei gesperrtem Bildschirm) und Foreground-Service (Dienst für die Wiedergabe im Hintergrund) gestellt, Entscheidung zum Umgang mit einer Ablehnung festgehalten.
- [ ] Microsoft Store: Datenschutz-URL und Altersfreigabe eingetragen.
- [ ] Flathub: Metainfo (Beschreibungsdatei für Linux-Stores) gültig, Altersangabe (OARS, Alterseinstufung dort) bestätigt, Domain-Bestätigung vorhanden.
- [ ] Erklärung zur Barrierefreiheit ([BARRIEREFREIHEIT.md](BARRIEREFREIHEIT.md)) gelesen, Platzhalter ausgefüllt, mit Anwalt geklärt, ob sie Pflicht ist.
- [ ] Datenschutz-Angaben: Die Seiten `/datenschutz/` und `/impressum/` (Deutsch und Englisch) sind erreichbar, enthalten keine offenen Platzhalter mehr und sind für Suchmaschinen freigegeben (kein `noindex`).
- [ ] Datenschutz in den Stores nennt dieselben Anbieter wie die Datenschutzerklärung (laut.fm, Apple iTunes für Cover, `cdn.linefm.de`, `radiogruppe.de`, Google Cast SDK, aktive Telemetrie).
- [ ] Verträge zur Auftragsverarbeitung (AVV, Art. 28 DSGVO) mit Hosting-, CDN- und Telemetrie-Betreibern liegen vor. Bei US-Anbietern DPF-Zertifizierung geprüft (<https://www.dataprivacyframework.gov/list>).
- [ ] Lizenzhinweise für Linux und Windows: libmpv und FFmpeg (LGPL bzw. GPL) sind in [LIZENZEN-DRITTE.md](LIZENZEN-DRITTE.md) beschrieben und im Paket enthalten.

## E. Recht, Konten, Betrieb und Pflege

Die Schritte dazu stehen in [EINRICHTUNG.md](EINRICHTUNG.md), Abschnitte 17 bis 20. Die Store-Regeln je Punkt in [STORE-RICHTLINIEN.md](STORE-RICHTLINIEN.md). Rechts- und Steuerpunkte sind eine Vorprüfung, keine Beratung.

### E1. Recht und Datenschutz

- [ ] Impressum nach § 5 DDG vollständig, Anschrift in allen Konsolen gleich (Schritt 17.1).
- [ ] Datenschutzerklärung nennt Sentry, Firebase und Umami als optionale Dienste nach Einwilligung, dazu laut.fm, iTunes-Cover, `cdn.linefm.de`, `radiogruppe.de`, Google Cast, Hoster (Schritt 17.2).
- [ ] Ohne Einwilligung geht keine Anfrage an Sentry, Firebase, Umami oder Google raus, Widerruf wirkt sofort (Netzwerkmitschnitt).
- [ ] AVV je aktivem Auftragsverarbeiter abgelegt, DPF-Status mit Datum (Schritt 17.3).
- [ ] BFSG: Entscheidung festgehalten, Erklärung zur Barrierefreiheit fertig oder Begründung (Schritt 17.4).
- [ ] DSA-Händlerstatus bei Google, bei Apple in der späteren Apple-Runde angegeben und mit dem Anwalt abgestimmt ([G-26](STORE-RICHTLINIEN.md#g-26), [A-25](STORE-RICHTLINIEN.md#a-25), Schritt 17.5).
- [ ] Markenlage LINEFM geprüft (Schritt 17.6).
- [ ] laut.fm-Vereinbarung beim Kunden griffbereit, Hinweis für Prüfer in jeder Einreichung vermerkt (Schritt 17.7).
- [ ] Schriftliche Freigaben Radio3FM und FobFM abgelegt (Schritt 17.8).
- [ ] `/lizenz/` (de und en) erreichbar, Fremdlizenzen vollständig ([F-07](STORE-RICHTLINIEN.md#f-07), [W-04](STORE-RICHTLINIEN.md#w-04), Schritt 17.9).
- [ ] Altersfreigabe überall 13+ (IARC bei Google und Microsoft), Zielgruppe 13+, OARS "Kraftausdrücke: moderat", keine Kinderzielgruppe ([G-19](STORE-RICHTLINIEN.md#g-19), [G-20](STORE-RICHTLINIEN.md#g-20), [A-17](STORE-RICHTLINIEN.md#a-17), [M-18](STORE-RICHTLINIEN.md#m-18), [F-10](STORE-RICHTLINIEN.md#f-10)).
- [ ] Jugendschutz: Anwalt hat entschieden, ob ein Jugendschutzbeauftragter nach § 7 JMStV bestellt wird oder LineFM Studios der FSM beitritt (Schritt 17.10, [D-06](STORE-RICHTLINIEN.md#d-06), [D-07](STORE-RICHTLINIEN.md#d-07)).
- [ ] GEMA/GVL: schriftliche Bestätigung von laut.fm liegt vor (Schritt 2.1).
- [ ] Verzeichnis der Verarbeitungstätigkeiten aus dem Muster übernommen und geprüft (Schritt 17.11, [VERARBEITUNGSVERZEICHNIS.md](VERARBEITUNGSVERZEICHNIS.md)). Pflicht, keine Ausnahme nach Art. 30 Abs. 5 ([D-05](STORE-RICHTLINIEN.md#d-05), [D-08](STORE-RICHTLINIEN.md#d-08)).
- [ ] Meldeweg für Datenpannen (72 Stunden) in INCIDENT.md eingetragen (Schritt 17.12).
- [ ] Speicherdauern in Diensten, Datenschutzerklärung, Verzeichnis und Store-Formularen gleich (Schritt 17.13).
- [ ] Externe Links (YouTube Music, Spotify, radiogruppe.de, laut.fm, iTunes, `cdn.linefm.de`) in der Datenschutzerklärung genannt (Schritt 17.2).
- [ ] Freiwillige Erklärung zur Barrierefreiheit unter `/barrierefreiheit/` (de und en) erreichbar, Anwalt hat bestätigt (Schritt 17.4, [W-06](STORE-RICHTLINIEN.md#w-06)).

### E2. Konten, Kosten und Steuern

- [ ] D-U-N-S-Nummer liegt vor, Name und Anschrift stimmen mit dem Impressum überein (Schritt 18.1).
- [ ] Organisationskonten ([D-02](STORE-RICHTLINIEN.md#d-02)) von LineFM Studios bei Google Play, Apple, Microsoft, Snapcraft, Flathub, dazu Cloudflare, Sentry, Firebase, Umami-Host und Registrar; je Konto Zweitadmin und Zwei-Faktor-Anmeldung (Schritt 18.2).
- [ ] Snap-Name `linefm-radio` mit dem Konto von LineFM Studios registriert ([S-03](STORE-RICHTLINIEN.md#s-03)).
- [ ] Google-Entwicklerverifizierung für die APK außerhalb von Play erledigt (Schritt 6.12).
- [ ] Vereinbarungen in Play Console und Partner Center angenommen, keine offenen Hinweise (Schritt 18.3, Apple später).
- [ ] Steuerliche Einordnung der Kontokosten mit dem Steuerberater geklärt (Schritt 18.4).

### E3. Technik und Betrieb

- [ ] Domain mit automatischer Verlängerung und Transfer-Sperre, Ablaufdatum im Kalender (Schritt 19.1).
- [ ] TLS gültig, Erneuerung automatisch (Schritt 19.2).
- [ ] Alle Signierschlüssel doppelt gesichert, Wiederherstellung einmal getestet; Updater-Schlüssel `UPDATER_ED25519_PRIVATE_KEY` nur in der geschützten Umgebung `release`, Eigentümer LineFM Studios, Wechsel bei Verdacht geregelt (Schritt 19.3).
- [ ] Updater fehlt in allen Store-Builds, die CI-Prüfung dazu ist grün.
- [ ] Alle genutzten Secrets und Variablen aus Anhang A eingetragen, Release-Lauf meldet nichts Fehlendes (Schritt 19.4).
- [ ] Release-Ablauf einmal komplett durchlaufen, Freigabe in jedem Store von Hand (Schritt 19.5).
- [ ] Uptime-Monitor aktiv, Benachrichtigung für Tickets an; externer Monitor (UptimeRobot Free) mit E-Mail-Alarm an zwei Personen, Testalarm angekommen (Schritt 19.6).
- [ ] Meldewege in `docs/betrieb/INCIDENT.md` eingetragen (Schritt 19.7).
- [ ] Zuständigkeit für Dependabot und Sicherheitsmeldungen geregelt (Schritt 19.8).
- [ ] Live-Gang: Flathub-Domaindatei, Brotli, Telemetrie-Adressen in der CSP, Log-Kürzung (Schritt 19.9, [F-04](STORE-RICHTLINIEN.md#f-04), [W-01](STORE-RICHTLINIEN.md#w-01)).

### E4. Support und Pflege

- [ ] `support@linefm.de` angelegt, `/support/` (de und en) erreichbar, beides in jedem Support-Feld jedes Stores, Testmail kommt an (Schritt 20.1).
- [ ] Zuständigkeit für Bewertungen geregelt (Schritt 20.2).
- [ ] Sicherheitsmeldungen landen bei jemandem, `security.txt` gültig (Schritt 20.3).
- [ ] Monatliche Richtlinienprüfung läuft, Tickets mit Label `store-policy` werden binnen fünf Werktagen gelesen (Schritt 20.4).
- [ ] Umgang mit Ablehnungen bekannt (Schritt 20.6).
- [ ] Fristenkalender angelegt (Schritt 20.5).

## D. Zum Schluss

- [ ] Alle Punkte oben sind abgehakt oder bewusst als "offen" begründet.
- [ ] Antwort an Tim Hauke: "Freigabe erteilt" mit Datum, oder die Liste der offenen Punkte.
- [ ] Danach erst veröffentlichen.
