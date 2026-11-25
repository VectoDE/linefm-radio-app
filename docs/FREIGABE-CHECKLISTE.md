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
- [ ] Freigabe für den Start in jedem Store einzeln (Google Play, Microsoft Store, Flathub, Snap, GitHub Releases, später Apple).

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
- [ ] Keine Aussagen wie "offizielle App der RadioGruppe", wenn LineFM Studios das nicht bestätigt hat. Der Hinweis "LineFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe" entspricht der Web-App.
- [ ] Screenshots zeigen die echte App und keine Fantasiedaten, nichts Fremdes (keine Cover von Dritten in Großansicht ohne Freigabe).
- [ ] Altersangabe stimmt (+RAP: Kraftausdrücke möglich).
- [ ] Google Play: "Datensicherheit" und "App-Inhalte" zur Datenschutzerklärung passend ausgefüllt (siehe [EINRICHTUNG.md](EINRICHTUNG.md), Abschnitt 2.5).
- [ ] Google Play: Erklärung zu `USE_FULL_SCREEN_INTENT` (Vollbild-Alarm bei gesperrtem Bildschirm) und Foreground-Service (Dienst für die Wiedergabe im Hintergrund) gestellt, Entscheidung zum Umgang mit einer Ablehnung festgehalten.
- [ ] Microsoft Store: Datenschutz-URL und Altersfreigabe eingetragen.
- [ ] Flathub: Metainfo (Beschreibungsdatei für Linux-Stores) gültig, Altersangabe (OARS, Alterseinstufung dort) bestätigt, Domain-Bestätigung vorhanden.
- [ ] Erklärung zur Barrierefreiheit ([BARRIEREFREIHEIT.md](BARRIEREFREIHEIT.md)) gelesen, Platzhalter ausgefüllt, mit Anwalt geklärt, ob sie Pflicht ist.
- [ ] Datenschutz-Angaben: Die Seiten `/datenschutz/` und `/impressum/` (Deutsch und Englisch) sind erreichbar, enthalten keine offenen Platzhalter mehr und sind für Suchmaschinen freigegeben (kein `noindex`).
- [ ] Datenschutz in den Stores nennt dieselben Anbieter wie die Datenschutzerklärung (laut.fm, Apple iTunes für Cover, `cdn.linefm.de`, `radiogruppe.de`, Google Cast SDK, aktive Telemetrie).
- [ ] Verträge zur Auftragsverarbeitung (AVV, Art. 28 DSGVO) mit Hosting-, CDN- und Telemetrie-Betreibern liegen vor. Bei US-Anbietern DPF-Zertifizierung geprüft (<https://www.dataprivacyframework.gov/list>).
- [ ] Lizenzhinweise für Linux und Windows: libmpv und FFmpeg (LGPL bzw. GPL) sind in [LIZENZEN-DRITTE.md](LIZENZEN-DRITTE.md) beschrieben und im Paket enthalten.

## D. Zum Schluss

- [ ] Alle Punkte oben sind abgehakt oder bewusst als "offen" begründet.
- [ ] Antwort an Tim Hauke: "Freigabe erteilt" mit Datum, oder die Liste der offenen Punkte.
- [ ] Danach erst veröffentlichen.
