# Freigabe-Checkliste

Diese Liste gehört zu Issue #27. Sie sagt, was vor der Veröffentlichung von LINEFM Radio geprüft und bestätigt sein muss. Teil A bestätigt jaybelife als Betreiber, Teil B prüft jemand mit den echten Geräten, Teil C sind Texte und Datenschutzangaben.

So geht es: Jeder Punkt wird mit Datum und Name abgehakt oder als "offen" vermerkt. Ein Punkt gilt erst als erledigt, wenn die Antwort schriftlich vorliegt (E-Mail oder Eintrag im Issue reicht).

Alle Rechts- und Steuerfragen hier sind eine Vorprüfung. Sie ersetzen keinen Anwalt und keinen Steuerberater.

Die Kontoeinrichtung steht in [EINRICHTUNG.md](EINRICHTUNG.md).

## A. Bestätigungen durch jaybelife

### A1. Marke und Logos (Entscheidungen 6 und 32)

- [ ] Die Marke LINEFM und das Logo dürfen in der App und in den Stores verwendet werden.
- [ ] Die sechs Sender stehen in der App: LineFM +MAIN, +RAP, +GAMING, +LOFI sowie **Radio3FM** und **FobFM**. Für Radio3FM und FobFM bestätigen: Die Namen und Logos dürfen gezeigt werden, und die Streams dürfen in der App laufen. Laut unserer Recherche sind diese beiden keine LINEFM-Sender bei laut.fm, deshalb ist das eine ausdrückliche Freigabe.
- [ ] Die Sender-Logos kommen von `https://cdn.linefm.de/images/icons/`. Nutzung in den Stores erlaubt.
- [ ] Das RadioGruppe-Logo wird von `radiogruppe.de` geladen (wie in der Web-App). Nutzung erlaubt, Datenschutzabschnitt dazu bestätigt (Entscheidung 47).

### A2. Name und Kennung (Entscheidung 16)

- [ ] App-Name **"LINEFM Radio"**.
- [ ] Fenstertitel **"LINEFM | Radio"**.
- [ ] Paket-ID **`de.linefm.app`** (Android, Windows, iOS und macOS, Flathub, Snap). Sie lässt sich nach der Veröffentlichung nicht mehr ändern.
- [ ] Web-Adresse **`https://app.linefm.de`** (Entscheidung 38).

### A3. App-Icon (Entscheidung 41)

- [ ] Das Icon aus `https://cdn.linefm.de/images/icons/main.png` darf unverändert (nur technisch skaliert) als App-Icon in allen Stores verwendet werden. Freigabe ist erteilt, hier nur noch schriftlich festhalten.

### A4. Impressum und Datenschutz (Entscheidungen 45, 47)

- [ ] Betreiberdaten stimmen mit `https://linefm.de/impressum` überein (Name, Anschrift, E-Mail). Fehlende Angaben liefern: Telefon oder Kontaktformular, Vertretung, Datenschutzbehörde, Hosting-Anbieter, CDN-Betreiber, Log-Dauer (Liste in `assets/legal/placeholders.json`).
- [ ] Der Datenschutztext passt zur tatsächlichen Konfiguration (welche Telemetrie ist aktiv, wer hostet).
- [ ] Rechtsprüfung durch jaybelife oder einen Anwalt ist erfolgt (Entscheidung 48). Offene Rechtsfragen, die jaybelife selbst klärt:
  - [ ] **Rundfunkrecht (MStV):** Ist für das Webradio eine Zulassung nötig, oder gilt es als zulassungsfrei? Welche Angaben verlangt § 18 MStV im Impressum (verantwortliche Person)? Die Felder `AUFSICHTSBEHOERDE_MEDIEN` und `VERANTWORTLICHER_MSTV` stehen noch offen.
  - [ ] **GEMA und GVL:** Sind die Musikrechte für die Wiedergabe über eine eigene App abgedeckt? Unsere Quelle (laut.fm) belegt das nur in einem Artikel von 2015. Empfehlung: schriftliche Bestätigung von laut.fm (`team@laut.fm`) einholen.
  - [ ] **Speicher-Hinweis in den nativen Apps:** Der Hinweis "Wir speichern kleine Daten …" erscheint überall wie in der Web-App (Entscheidung 39). Prüfen lassen, ob er in den nativen Apps rechtlich nötig oder ausreichend ist.
  - [ ] **Einwilligung nach DSGVO/TDDDG:** Wortlaut des Einwilligungsdialogs für Statistik und Absturzberichte prüfen, falls Telemetrie aktiv wird.
  - [ ] **Barrierefreiheit (BFSG):** Klären, ob für das Angebot eine Erklärung zur Barrierefreiheit nötig ist.

### A5. laut.fm-Daten (Entscheidung 33)

- [ ] jaybelife bestätigt: Es besteht eine eigene laut.fm-Lizenz. Die App nutzt die öffentliche laut.fm-API (Titel, Cover-Hinweis, Hörerzahl, Streams), um die Daten der eigenen Sender anzuzeigen. Eine Anfrage bei laut.fm ist nicht nötig.
- [ ] Der Lizenzhinweis in Datenschutz und Impressum ist richtig formuliert.
- [ ] Cover kommen von der iTunes-Suche (Apple). Bestätigen, dass das in Ordnung ist, und dass es in der Datenschutzerklärung steht.

### A6. Rechte und Übergabe (Entscheidungen 1, 43, 46)

Festzuhalten, damit später keine Zweifel entstehen:

- [ ] Tim Hauke (VectoDE) hat die App **unentgeltlich für jaybelife** entwickelt.
- [ ] LINEFM, die Marke, die Logos und das App-Icon gehören jaybelife.
- [ ] Der Quellcode steht unter "Alle Rechte vorbehalten", ohne Open-Source-Lizenz. Er ist sichtbar, aber nicht frei nutzbar. Schriftlich regeln, wer die Rechte am Code hat und was jaybelife damit tun darf (Weiterentwicklung durch Dritte, Weitergabe, Übergabe des Repos).
- [ ] Der Hinweis "Entwickelt von Tim Hauke (VectoDE) für jaybelife" mit GitHub-Link bleibt im Über-Bereich der App (Entscheidung 46). jaybelife stimmt dem Wortlaut zu.
- [ ] Übergabe: Repository, Zugänge und Schlüssel. Upload-Schlüssel (Android) und Konten gehören jaybelife und liegen im Passwortmanager von jaybelife. Wer verwaltet die Stores nach dem Start?
- [ ] Wartung nach dem Start: Wer reagiert auf Fehler, Store-Rückfragen und Updates?

### A7. Veröffentlichen

- [ ] Freigabe, das GitHub-Repository öffentlich zu schalten (Entscheidung 42). Danach sieht jeder den Code.
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

- [ ] Prüfung mit dem Desktop Head Unit (DHU) und, wenn möglich, im echten Auto.
- [ ] Die App erscheint in der Medienliste.
- [ ] Menü zeigt Favoriten-Sender, alle Stationen und "Zuletzt gehört" (Entscheidung 49).
- [ ] Sender starten, Titel und Cover erscheinen.

### B3. Radiowecker (Entscheidungen 36, 40)

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

- [ ] Installer und MSIX installieren und deinstallieren sauber.
- [ ] **Tray-Symbol und Menü:** Rechtsklick-Menü zeigt Play/Stopp, Sender, Mini-Fenster, Beenden. Wiedergabe läuft bei geschlossenem Fenster weiter.
- [ ] **Mini-Fenster:** Öffnet, bleibt auf Wunsch im Vordergrund, merkt Größe und Position.
- [ ] Medientasten der Tastatur und die Mediensteuerung von Windows (Lautstärke-Flyout) zeigen Titel und steuern die Wiedergabe.
- [ ] Zweiter Start holt das vorhandene Fenster nach vorn (nur eine Instanz).
- [ ] Tastenkürzel funktionieren.
- [ ] **Deep Link:** `linefm://play?station=linefmrap` im Browser oder Terminal öffnet die App beim richtigen Sender, auch wenn sie schon läuft.
- [ ] Hohe Skalierung (150 und 200 Prozent), mehrere Monitore.

### B5. Linux

- [ ] Start aus Flatpak und Snap (wenn veröffentlicht), sonst aus dem Tarball.
- [ ] Wiedergabe, Medientasten (MPRIS), Tray-Symbol (je nach Desktop), Mini-Fenster.
- [ ] Deep Link `linefm://play?station=...` über die Desktop-Datei.

### B6. macOS

- [ ] DMG öffnen, App starten laut [Anleitung](../packaging/macos/LIES-MICH-ZUERST.txt) (macOS 15 verlangt den Weg über Systemeinstellungen).
- [ ] Wiedergabe, Medientasten, Tray-Symbol in der Menüleiste, Mini-Fenster.

### B7. Web

- [ ] Chrome, Firefox, Safari und Edge auf Windows, macOS, Android, iOS.
- [ ] Wiedergabe startet nach Klick. Blockiert der Browser Autoplay, muss ein Knopf zum Starten erscheinen. Die Mediensteuerung des Browsers zeigt den Titel.
- [ ] Installation als App (PWA) möglich.
- [ ] Lighthouse und Barrierefreiheit (axe): keine kritischen Befunde.
- [ ] HTTP-Header nach dem Ausrollen prüfen (siehe [hosting-uebersicht.md](hosting-uebersicht.md)).
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
- [ ] Deutsch und Englisch, Wechsel der Systemsprache.
- [ ] Bildschirmleser (TalkBack, VoiceOver, NVDA): Player, Liste und Einstellungen sind bedienbar.
- [ ] Einwilligungsdialog erscheint nur, wenn Telemetrie konfiguriert ist; ohne Einwilligung gehen keine Daten raus.
- [ ] Akku und Datenverbrauch bei einer Stunde Wiedergabe sind unauffällig. Die App nutzt bewusst keinen WebSocket von laut.fm (Messwerte in [ENTWICKLUNG.md](ENTWICKLUNG.md)).

## C. Store-Texte und Datenschutzangaben

- [ ] Kurz- und Langbeschreibung auf Deutsch und Englisch gelesen und freigegeben. Sie nennen nur, was die App wirklich kann. Plattform-Hinweise stimmen (kein CarPlay, solange Apple fehlt).
- [ ] Keine Aussagen wie "offizielle App der RadioGruppe", wenn jaybelife das nicht bestätigt hat. Der Hinweis "Ein Angebot von RadioGruppe Deutschland" entspricht der Web-App.
- [ ] Screenshots zeigen die echte App und keine Fantasiedaten, nichts Fremdes (keine Cover von Dritten in Großansicht ohne Freigabe).
- [ ] Altersangabe stimmt (+RAP: Kraftausdrücke möglich).
- [ ] Google Play: "Datensicherheit" und "App-Inhalte" zur Datenschutzerklärung passend ausgefüllt (siehe [EINRICHTUNG.md](EINRICHTUNG.md), Abschnitt 2.5).
- [ ] Google Play: Erklärung zu `USE_FULL_SCREEN_INTENT` und Foreground-Service gestellt, Entscheidung zum Umgang mit einer Ablehnung festgehalten.
- [ ] Microsoft Store: Datenschutz-URL und Altersfreigabe eingetragen.
- [ ] Flathub: Metainfo valide, Altersangabe (OARS) bestätigt, Domain-Bestätigung vorhanden.
- [ ] Datenschutz-Angaben: Die Seiten `/datenschutz/` und `/impressum/` (Deutsch und Englisch) sind erreichbar, enthalten keine offenen Platzhalter mehr und sind für Suchmaschinen freigegeben (kein `noindex`).
- [ ] Datenschutz in den Stores nennt dieselben Anbieter wie die Datenschutzerklärung (laut.fm, Apple iTunes für Cover, `cdn.linefm.de`, `radiogruppe.de`, aktive Telemetrie).

## D. Zum Schluss

- [ ] Alle Punkte oben sind abgehakt oder bewusst als "offen" begründet.
- [ ] Antwort an Tim Hauke: "Freigabe erteilt" mit Datum, oder die Liste der offenen Punkte.
- [ ] Danach erst veröffentlichen.
