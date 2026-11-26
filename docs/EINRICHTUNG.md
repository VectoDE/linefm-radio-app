# Einrichtung für LineFM Studios

Diese Liste enthält alles, was du als Betreiber wissen, besorgen und eintragen musst, damit LINEFM Radio in den Stores und im Web erscheint und einwandfrei läuft. Alles andere ist vorbereitet. Du brauchst kein Programmierwissen. Wo ein Entwickler etwas tun muss, steht es dabei.

Die App selbst bauen, herunterladen und öffnen, ohne den Entwickler zu fragen: [BAUEN-UND-STARTEN.md](BAUEN-UND-STARTEN.md).

## So liest du diese Liste

Jeder Schritt hat eine Nummer (zum Beispiel 6.4) und diese fünf Angaben:

- **Was:** die Aufgabe.
- **Wozu:** was ohne den Schritt fehlt oder nicht geht.
- **Wo eintragen:** der genaue Ort.
- **Woher:** wo du den Wert bekommst.
- **Prüfschritt:** woran du erkennst, dass es funktioniert.

Wichtig vorab:

- Passwörter, Schlüssel und Tokens (geheime Zugangscodes) gehören **nie** in eine E-Mail, einen Chat oder ein Ticket. Sie kommen als Secret in die GitHub-Einstellungen des Repos (Schritt 1.3) oder in deinen Passwortmanager.
- Ein **Secret** ist ein geheimer Wert, den GitHub speichert und danach nie wieder anzeigt. Eine **Variable** ist ein nicht geheimer Wert, der lesbar bleibt. Beides legst du im Repo an (Schritt 1.3).
- **CI** (Continuous Integration) heißt hier: GitHub baut, prüft und lädt die App automatisch hoch. Eine **Pipeline** oder ein **Workflow** ist so ein automatischer Ablauf. Ein **Release** ist eine veröffentlichte Version.
- Ohne ein Secret passiert nichts Schlimmes. Der betroffene Schritt wird übersprungen oder baut unsigniert. Die Zusammenfassung des Laufs nennt den fehlenden Namen, nie den Wert.
- Erst die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) abarbeiten, dann veröffentlichen.
- Preise und Formulare der Anbieter ändern sich. Die Angaben stammen aus unserer Recherche vom November 2026. Im Zweifel gilt, was der Anbieter gerade anzeigt. Wo wir etwas nicht belegen konnten, steht "prüfen".
- Rechts- und Steuerfragen sind hier eine Vorprüfung. Sie ersetzen keinen Anwalt und keinen Steuerberater.
- Apple ist **nicht Teil der ersten Veröffentlichung**. Der Code ist vorbereitet, Abschnitt 15 beschreibt, was später nötig ist.

Haken setzen, sobald ein Schritt erledigt und geprüft ist.

## Reihenfolge im Überblick

| Nr. | Abschnitt | Hängt ab von | Dauer, grob |
|---|---|---|---|
| 1 | Vorbereitung | nichts | 1 Tag |
| 2 | Verträge und Bestätigungen | 1 | Wochen (Dritte antworten) |
| 3 | Rechtstexte und Pflichtangaben | 2 teilweise | Tage |
| 4 | Domain, DNS, HTTPS, CDN | 1 | Tage |
| 5 | Web-Hosting und automatisches Ausrollen | 4 | 1 Tag |
| 6 | Google Play | 1, 3 | Tage plus 14 Tage Test (privates Konto) |
| 7 | Microsoft Store | 1, 3 | Tage |
| 8 | Linux: Flathub und Snap | 4, 5 | Tage bis Wochen |
| 9 | Statistik und Absturzberichte (optional) | 2 (AVV) | 1 Tag |
| 10 | Search Console, GA4 und GTM | 5 | 1 Tag |
| 11 | Vertrauens-Badges | 5 | je nach Anbieter |
| 12 | Signierte Releases (GPG optional), Scanner-Konten (optional) | 1 | 1 bis 2 Stunden |
| 13 | Datenschutzangaben je Store | 3, 6 bis 9 | 1 Tag |
| 14 | Bilder und Screenshots | 6 bis 8 | Tage |
| 15 | Apple (später) | 1 | Wochen |
| 16 | Abnahme | alles | 1 Tag |
| 17 | Recht, Datenschutz, Jugendschutz, Verarbeitungsverzeichnis | 2, 3 | Tage, dann laufend |
| 18 | Konten, Kosten und Steuern | 1 | Wochen (D-U-N-S bis 30 Tage) |
| 19 | Technik und Betrieb | 4, 5 | 1 bis 2 Tage, dann laufend |
| 20 | Support und Pflege, Fristenkalender | 16 | laufend |

Abschnitt 2 und die D-U-N-S-Nummer (Schritt 18.1) zuerst anstoßen, weil Antworten von Dritten am längsten dauern. Die Abschnitte 6 bis 8 laufen parallel.

## Übersicht: Was kostet das?

| Dienst | Kosten | Wofür |
|---|---|---|
| Google Play Console | 25 US-Dollar einmalig (abgerufen 26.11.2026) | Android |
| Microsoft Partner Center | kostenlos für Einzelpersonen und Firmen über storedeveloper.microsoft.com (abgerufen 26.11.2026) | Windows-Store |
| Flathub, Snap Store | kostenlos | Linux |
| GitHub Releases | kostenlos | Installer für Windows, Linux, macOS, Android-APK |
| Apple Developer Program | 99 US-Dollar pro Mitgliedsjahr, Preis in Landeswährung (abgerufen 26.11.2026) | iOS, macOS-Store, CarPlay |
| D-U-N-S-Nummer | kostenlos bei Dun & Bradstreet, bis zu 30 Tage (laut Google, abgerufen 26.11.2026) | Organisationskonten Google, Apple, Microsoft |
| Domain `linefm.de` | laut Registrar-Rechnung | Web, App-Links, Flathub-Bestätigung |
| Sentry, Firebase, Umami | je nach Tarif, kostenlose Stufen vorhanden (nicht live geprüft) | Statistik und Absturzberichte nach Einwilligung |
| Cloudflare Pages | kostenlos | Web, falls gewählt |
| eigener Server oder Plesk | vorhanden | Web, falls gewählt |
| Sigstore, GitHub-Attestierung | kostenlos | Signatur der Releases (Abschnitt 12) |
| Google Analytics 4, Tag Manager, Search Console | kostenlos | Reichweitenmessung Web (Abschnitt 10) |

---

## 1. Vorbereitung

### 1.1 Zugang zum Repository

- **Was:** Einladung zum Repository `VectoDE/linefm-radio-app` annehmen, Rolle Collaborator.
- **Wozu:** Ohne Schreibrecht auf die Repo-Einstellungen kannst du keine Secrets eintragen.
- **Wo eintragen:** nichts. Die Einladung kommt per E-Mail von GitHub.
- **Woher:** Tim Hauke (VectoDE) verschickt sie.
- **Prüfschritt:** Im Repository erscheint der Reiter "Settings".
- [ ] erledigt

### 1.2 Passwortmanager und Namen

- **Was:** Passwortmanager bereithalten. Zustimmung zu App-Name "LINEFM Radio" und Paket-ID `de.linefm.app` geben.
- **Wozu:** Die Paket-ID lässt sich im Play Store später nicht mehr ändern. Schlüssel und Passwörter brauchen einen sicheren Ort.
- **Wo eintragen:** Zustimmung schriftlich in der [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md), Abschnitt A2.
- **Woher:** eigene Entscheidung.
- **Prüfschritt:** Abschnitt A2 der Checkliste ist mit Datum abgehakt.
- [ ] erledigt

### 1.3 So legst du Secrets und Variablen an

- **Was:** Die Technik, mit der alle späteren Werte ins Repo kommen.
- **Wozu:** Die automatischen Abläufe (Bauen, Signieren, Hochladen) lesen ihre Zugangsdaten nur von dort.
- **Wo eintragen:** Repository > Settings > Secrets and variables > Actions. Tab "Secrets" > "New repository secret" für geheime Werte. Tab "Variables" > "New repository variable" für nicht geheime. Name exakt übernehmen, Wert einfügen, speichern.
- **Woher:** Die Bezugsquelle jedes Werts steht im jeweiligen Schritt und gesammelt in Anhang A. Dateien (Schlüssel, Zertifikate) trägst du als Base64 ein: `base64 -w0 datei` (Linux, macOS) oder `[Convert]::ToBase64String([IO.File]::ReadAllBytes("datei"))` (PowerShell).
- **Prüfschritt:** Der Name erscheint in der Liste. Der Wert eines Secrets ist danach nie mehr sichtbar, nur überschreibbar.
- Details und die Spalte "Wer" (LineFM Studios oder Entwickler) stehen in [secrets.md](secrets.md). Den Zusammenhang der Abläufe erklärt [stores-pipelines.md](stores-pipelines.md).
- [ ] erledigt

### 1.4 Schriftliche Zustimmung zur Veröffentlichung des Quellcodes

- **Was:** Das Repository ist seit dem 19.11.2026 öffentlich. Die Lizenz bleibt proprietär (alle Rechte vorbehalten). Du bestätigst schriftlich, dass der Quellcode öffentlich sichtbar sein darf.
- **Wozu:** Jeder kann den Code lesen, aber nicht frei nutzen. Das muss mit dem Rechteinhaber der Marke und der App geklärt sein, bevor Dritte darauf bauen.
- **Wo eintragen:** schriftlich (E-Mail oder Eintrag im Ticket reicht). Abschnitt A7 der [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) abhaken.
- **Woher:** deine Entscheidung. Den Wortlaut und die Frage, was "sichtbar, aber nicht frei nutzbar" für Weitergabe und Weiterentwicklung bedeutet, lässt du anwaltlich prüfen.
- **Prüfschritt:** Die Zustimmung liegt schriftlich vor und die anwaltliche Prüfung ist vermerkt.
- [ ] erledigt

---

## 2. Verträge und Bestätigungen

Alle Punkte hier sind Vorprüfung, keine Rechtsberatung. Lass Wortlaut und Folgen von einem Anwalt prüfen. Die Antworten gehören schriftlich in die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md), Abschnitt A.

### 2.1 laut.fm, GEMA und GVL

- **Was:** Schriftlich klären, ob die Musikrechte für die Wiedergabe über eine eigene App abgedeckt sind und ob für die Sender eine Lizenz über laut.fm besteht.
- **Wozu:** Die App nutzt die öffentliche laut.fm-Schnittstelle (Titel, Hörerzahl, Streams). Unsere Quelle belegt die Abdeckung nur durch einen Artikel von 2015. Ohne Bestätigung bleibt ein Rechtsrisiko.
- **Wo eintragen:** Antwort in Abschnitt A4 und A5 der Freigabe-Checkliste. Im Impressum steht bewusst keine Aussage wie "eigene Lizenz".
- **Woher:** Entscheidung des Inhabers: Die schriftliche Bestätigung zu GEMA und GVL holt LineFM Studios **bei laut.fm** ein (Adresse laut Freigabe-Checkliste: `team@laut.fm`, vor Gebrauch prüfen). Gefragt wird, ob die Wiedergabe der Streams in einer eigenen App eines Dritten unter die Lizenzverträge von laut.fm mit GEMA und GVL fällt.
- **Prüfschritt:** Es liegt eine schriftliche Antwort vor, die zur Aussage im Impressum passt.
- [ ] erledigt

### 2.2 Radio3FM und FobFM

- **Was:** Bestätigen lassen, dass Namen, Logos und Streams dieser beiden Sender in der App laufen dürfen. Die Texte nennen sie "Partnersender".
- **Wozu:** Nach unserer Recherche sind sie keine LINEFM-Sender bei laut.fm. Die Nutzung braucht eine ausdrückliche Freigabe.
- **Wo eintragen:** Abschnitt A1 und A5 der Freigabe-Checkliste.
- **Woher:** Betreiber der beiden Sender.
- **Prüfschritt:** Schriftliche Freigabe je Sender liegt vor. Ohne sie nehmen wir die Sender aus der App.
- [ ] erledigt

### 2.3 radiogruppe.de

- **Was:** Nutzung des RadioGruppe-Logos bestätigen. Es wird wie in der Web-App von `radiogruppe.de` geladen. Der Hinweis "LineFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe" bleibt, die Formulierung "offizielle App der RadioGruppe" nicht, solange du sie nicht bestätigst.
- **Wozu:** Markenrecht und ehrliche Aussage in den Stores.
- **Wo eintragen:** Abschnitt A1 und C der Freigabe-Checkliste.
- **Woher:** Du als Betreiber oder die RadioGruppe.
- **Prüfschritt:** Bestätigung liegt vor, Datenschutzabschnitt zu `radiogruppe.de` ist abgenickt.
- [ ] erledigt

### 2.4 Auftragsverarbeitung (AVV) für die Telemetrie

- **Was:** Einen Vertrag zur Auftragsverarbeitung nach Art. 28 DSGVO mit dem Betreiber der Statistik- oder Fehlerberichte-Instanz abschließen. Dasselbe mit Hosting- und CDN-Betreiber.
- **Wozu:** Harte Freigabesperre: Telemetrie bleibt aus, solange kein unterschriebener Vertrag vorliegt. Die Datenschutzerklärung sagt bei aktiver Telemetrie, dass diese Verträge bestehen.
- **Wo eintragen:** Abschnitt "Harte Freigabesperren" der Freigabe-Checkliste. Erst danach setzt du die Telemetrie-Variablen (Abschnitt 9).
- **Woher:** Beim eigenen Server schließt du den Vertrag mit dem Betreiber. Bei Cloudflare, Google und Apple gelten die Standardverträge der Anbieter. Ob ein US-Anbieter unter dem EU-US Data Privacy Framework (DPF) zertifiziert ist, zeigt <https://www.dataprivacyframework.gov/list>. Zertifizierungen laufen aus, also vor dem Start und danach regelmäßig nachsehen.
- **Prüfschritt:** Unterschriebene Verträge liegen vor, DPF-Status mit Datum notiert.
- [ ] erledigt

### 2.5 Nutzungsrechtevertrag

- **Was:** Schriftlich regeln, wer die Rechte am Code hat und was LineFM Studios damit tun darf (Weiterentwicklung durch Dritte, Weitergabe, Übergabe des Repos). Tim Hauke (VectoDE) hat die App unentgeltlich für LineFM Studios entwickelt. Marke, Logos und App-Icon gehören LineFM Studios.
- **Wozu:** Der Code steht unter "Alle Rechte vorbehalten". Ohne Vertrag bleibt unklar, wer ihn nutzen darf. Flathub und andere Stores verlangen außerdem eine ausdrückliche Erlaubnis zur Weitergabe (Schritt 8.1).
- **Wo eintragen:** Abschnitt A6 der Freigabe-Checkliste.
- **Woher:** Vertrag zwischen LineFM Studios und Tim Hauke, anwaltlich geprüft.
- **Prüfschritt:** Unterschriebener Vertrag liegt vor. Wartung nach dem Start (wer reagiert auf Fehler und Store-Rückfragen) ist benannt.
- [ ] erledigt

---

## 3. Rechtstexte und Pflichtangaben

Die Rechtstexte liegen als Entwurf in der App (`assets/legal/`) und als Webseiten (`/impressum/`, `/datenschutz/`, je mit `en/`). Die Betreiberdaten werden aus `https://linefm.de/impressum` übernommen. Du bestätigst und ergänzt sie.

### 3.1 Pflicht-Platzhalter ausfüllen

- **Was:** Alle Platzhalter mit deinen Angaben füllen. Die vollständige Tabelle mit Ort und Zweck steht in Anhang B.
- **Wozu:** Impressum und Datenschutz sind Pflicht (§ 5 DDG, DSGVO). Solange etwas offen ist, setzt die Webseite `noindex`, und der Release-Build bricht ab.
- **Wo eintragen:** In eine Datei `legal_values.json` schreiben (Schlüssel = Platzhalter ohne Klammern, Wert = Text). Nicht zutreffende Angaben als `"Nicht zutreffend."` eintragen, nie leer lassen. Die Datei nicht ins Repo einchecken. Für die CI gehört der Inhalt in die Variable `LEGAL_VALUES_JSON`.
- **Woher:** Aus deinen Unterlagen. Hosting-Anbieter und CDN-Betreiber nennt dir, wer sie verwaltet. Die zuständige Datenschutzbehörde richtet sich nach dem Sitz des Betreibers. Keine Angabe wird vom Entwickler erfunden.
- **Prüfschritt:** Der Entwickler lässt den Generator laufen und er meldet keinen offenen Pflicht-Platzhalter:

```bash
dart run tool/gen_legal_html.dart --values=legal_values.json --fill-assets --strict --providers=umami,sentry
```

  `--providers` nennt die aktivierten Telemetrie-Dienste, `--strict` bricht ab, solange Pflichtfelder offen sind.
- [ ] erledigt

### 3.2 Platzhalter außerhalb der Rechtstexte

- **Was:** Drei Angaben stehen nicht in `legal_values.json`, sondern direkt in `docs/BARRIEREFREIHEIT.md`: `{{BARRIEREFREIHEIT_KONTAKT}}`, `{{BARRIEREFREIHEIT_ANTWORTFRIST}}` und `{{SCHLICHTUNGS_BZW_MARKTUEBERWACHUNGSSTELLE}}`.
- **Wozu:** Die Erklärung zur Barrierefreiheit braucht einen Kontakt, eine Antwortfrist und die zuständige Beschwerdestelle. Mit `--strict` prüft der Generator die Datei auf offene Platzhalter.
- **Wo eintragen:** Direkt in `docs/BARRIEREFREIHEIT.md`, Abschnitt "Feedback und Kontakt".
- **Woher:** Du lieferst Kontakt und Frist. Die zuständige Stelle lässt du anwaltlich klären, ob die Erklärung für dein Angebot Pflicht ist (BFSG).
- **Prüfschritt:** In der Datei steht kein `{{` mehr.
- [ ] erledigt

### 3.3 Sicherheitskontakt (erledigt)

- **Was:** `{{SECURITY_KONTAKT}}` in `SECURITY.md`, `CODE_OF_CONDUCT.md` und `web/.well-known/security.txt` ist durch das GitHub-Meldeformular <https://github.com/VectoDE/linefm-radio-app/security/advisories/new> ersetzt. Es ist keine E-Mail nötig.
- **Wozu:** Sicherheitslücken lassen sich vertraulich melden.
- **Wo eintragen:** nichts zu tun.
- **Woher:** entfällt.
- **Prüfschritt:** Mit `--strict` meldet der Generator für diese Dateien keinen offenen Platzhalter mehr. Der Punkt gilt als erledigt.
- [x] erledigt

### 3.4 Texte lesen und abstimmen

- **Was:** Impressum und Datenschutzerklärung lesen und mit einem Anwalt abstimmen.
- **Wozu:** Die Texte sind ein Entwurf nach Stand November 2026. Offen sind Rundfunkrecht (MStV, Bagatellrundfunk), Speicher-Hinweis in den nativen Apps (Popup statt Banner) und der Wortlaut des Einwilligungsdialogs (Abschnitt A4 der Freigabe-Checkliste).
- **Wo eintragen:** Abschnitt A4 und C der Freigabe-Checkliste.
- **Woher:** Anwalt.
- **Prüfschritt:** `/impressum/` und `/datenschutz/` sind erreichbar, ohne offene Platzhalter und ohne `noindex`.
- [ ] erledigt

### 3.5 Einwilligungstext in der App

- **Was:** Der Dialog für Statistik und Fehlerberichte nennt den Empfänger (Betreiber der Umami- bzw. GlitchTip-Instanz) und sagt, dass technisch die IP-Adresse übertragen wird. Prüfe, ob das zu deiner Konfiguration passt.
- **Wozu:** Die Einwilligung muss informiert sein (DSGVO, TDDDG).
- **Wo eintragen:** Der Text liegt in den Sprachdateien der App (`lib/l10n/`), nicht in `assets/legal/`. Änderungen macht der Entwickler.
- **Woher:** Abstimmung mit der Datenschutzerklärung.
- **Prüfschritt:** Der Dialog erscheint nur, wenn Telemetrie konfiguriert ist.
- [ ] erledigt

---

## 4. Domain, DNS, HTTPS, CDN

### 4.1 DNS für app.linefm.de

- **Was:** Den Namen `app.linefm.de` auf den gewählten Hosting-Ort zeigen lassen.
- **Wozu:** Unter dieser Adresse läuft die Web-App. Auch die Links `https://app.linefm.de/?station=...` und die Bestätigungsdateien für Android und iOS hängen daran.
- **Wo eintragen:** Beim DNS-Anbieter der Domain `linefm.de` (bei Cloudflare unter DNS > Einträge). Cloudflare Pages: CNAME auf die `*.pages.dev`-Adresse des Projekts. Eigener Server: A- und AAAA-Eintrag auf die IP des Servers.
- **Woher:** Zieladresse nennt das gewählte Hosting (Abschnitt 5).
- **Prüfschritt:** `nslookup app.linefm.de` liefert die Zieladresse, die Seite lädt im Browser.
- [ ] erledigt

### 4.2 HTTPS-Zertifikat

- **Was:** Ein gültiges Zertifikat für `app.linefm.de` einrichten (Let's Encrypt oder Cloudflare).
- **Wozu:** Ohne HTTPS laufen Service Worker und die Installation als App nicht, und Browser warnen.
- **Wo eintragen:** Beim Hoster (Cloudflare: automatisch, bei eigenem Server per Certbot, bei Plesk "Let's Encrypt"-Erweiterung).
- **Woher:** kostenlos über Let's Encrypt oder Cloudflare.
- **Prüfschritt:** Das Schloss im Browser zeigt ein gültiges Zertifikat, <https://www.ssllabs.com/ssltest/> meldet kein Problem.
- [ ] erledigt

### 4.3 HSTS

- **Was:** Der Header `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` kommt aus den mitgelieferten Server-Konfigurationen. Die Anmeldung auf <https://hstspreload.org> ist ein eigener, freiwilliger Schritt.
- **Wozu:** HSTS zwingt Browser zu HTTPS. `preload` trägt die Domain in die Browser-Liste ein. Das gilt dann für `linefm.de` samt **allen** Subdomains und lässt sich nur langsam zurücknehmen.
- **Wo eintragen:** Header: in der Hosting-Konfiguration (`deploy/`), nichts von Hand. Preload: auf hstspreload.org, nur wenn alle Subdomains dauerhaft HTTPS haben. Das entscheidet der Betreiber der Hauptdomain.
- **Woher:** [hosting-uebersicht.md](hosting-uebersicht.md), Abschnitt "Security-Header".
- **Prüfschritt:** `curl -sI https://app.linefm.de/ | grep -i strict-transport` zeigt den Header.
- [ ] erledigt

### 4.4 CORS für cdn.linefm.de

- **Was:** Der Server hinter `cdn.linefm.de` sendet für `/images/icons/` den Header `Access-Control-Allow-Origin: *` (oder `https://app.linefm.de`).
- **Wozu:** Ohne ihn kann die Web-Version das Senderlogo nicht als Cover in der Mediensteuerung des Browsers zeigen. Die App läuft trotzdem.
- **Wo eintragen:** In der Server- oder CDN-Konfiguration von `cdn.linefm.de`.
- **Woher:** Wer das CDN betreibt (derselbe Name steht als `{{CDN_ANBIETER}}` in der Datenschutzerklärung).
- **Prüfschritt:** `curl -sI -H "Origin: https://app.linefm.de" https://cdn.linefm.de/images/icons/main.png | grep -i access-control` zeigt den Header.
- [ ] erledigt

---

## 5. Web-Hosting und automatisches Ausrollen

Die Web-App besteht nur aus Dateien. Such dir **einen** Weg aus. Jede Anleitung enthält fertige Konfigurationen, ein Überblick steht in [hosting-uebersicht.md](hosting-uebersicht.md).

### 5.1 Hosting wählen und einrichten

- **Was:** Einen der vier Wege einrichten: [nginx auf eigenem Server](hosting-nginx.md) (`deploy/nginx/`), [Docker mit Traefik](hosting-traefik.md) (`deploy/traefik/`), [Cloudflare Pages](hosting-cloudflare.md) (`deploy/cloudflare/`) oder [Plesk](hosting-plesk.md) (`deploy/plesk/`).
- **Wozu:** Hier läuft die Web-Version. Der Hoster steht als `{{HOSTING_ANBIETER}}` im Impressum und in der Datenschutzerklärung.
- **Wo eintragen:** Je nach Weg in der jeweiligen Anleitung.
- **Woher:** Dein Server, dein Cloudflare-Konto oder dein Plesk-Hoster.
- **Prüfschritt:** Nach dem ersten Ausrollen die Befehle am Ende von `hosting-uebersicht.md` ausführen: Header, ETag, 304-Antwort.
- [ ] erledigt

### 5.2 Secrets für das Ausrollen

- **Was:** Zugangsdaten für das gewählte Ziel eintragen.
- **Wozu:** `deploy-web.yml` rollt damit bei jedem Release (nur Endversionen) oder manuellem Start aus.
- **Wo eintragen:** Secrets und Variablen (Schritt 1.3). Die Umgebung `production` mit Genehmigern anlegen: Settings > Environments > "New environment" > `production` > "Required reviewers". Dann wartet jedes Ausrollen auf deine Freigabe.
- **Woher:** Je Ziel:
  - Cloudflare Pages: `CLOUDFLARE_API_TOKEN` (Dashboard > Mein Profil > API-Tokens, Berechtigung "Cloudflare Pages: Edit"), `CLOUDFLARE_ACCOUNT_ID` (Dashboard, rechte Spalte der Übersicht), Variable `CLOUDFLARE_PAGES_PROJECT` (`linefm-app`).
  - Eigener Server (SSH): `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`, Variablen `DEPLOY_PATH`, `DEPLOY_PORT`, `DEPLOY_RELOAD_COMMAND`. Befehle für Schlüssel und Host-Fingerabdruck stehen in [secrets.md](secrets.md).
  - Plesk (SSH): `PLESK_SSH_HOST`, `PLESK_SSH_USER`, `PLESK_SSH_KEY`, `PLESK_SSH_KNOWN_HOSTS`, Variablen `PLESK_DOCROOT`, `PLESK_SSH_PORT`.
  - Alle Ziele: Variable `WEB_DEPLOY_TARGETS` auf `cloudflare`, `ssh` oder `plesk` (kommagetrennt, auch mehrere). Ohne diese Variable rollt nichts aus.
  - Variable `WEB_BASE_URL` auf `https://app.linefm.de`.
- **Prüfschritt:** Actions > "deploy-web" läuft grün durch, die Zusammenfassung nennt kein fehlendes Secret.
- [ ] erledigt

### 5.3 Web-Variablen für Google-Dienste, Telemetrie und Vertrauen

Diese stehen in den Abschnitten 9, 10 und 11. Sie landen im fertigen Programm in `config/app.json` und sind öffentlich lesbar, deshalb nur als Variable, nie als Secret.

---

## 6. Google Play (Android)

Quellen: [Play Console](https://play.google.com/console), Signierung in [packaging/android/SIGNING.md](../packaging/android/SIGNING.md).

### 6.1 Entwicklerkonto

- **Was:** **Organisationskonto** von LineFM Studios anlegen (Entscheidung des Inhabers: in jedem Store das eigene Organisationskonto des Kunden), 25 US-Dollar einmalig zahlen, Organisation bestätigen (D-U-N-S-Nummer aus Schritt 18.1, Website, offizielle Telefonnummer und E-Mail der Organisation). Tim Hauke als Nutzer einladen (Nutzer und Berechtigungen > Neue Nutzer einladen, mit App-Rechten für Veröffentlichung).
- **Wozu:** Ohne Konto keine Veröffentlichung. Google verlangt die Identität auch für sideloadbare APKs ab 2027 (Entwicklerverifizierung).
- **Wo eintragen:** <https://play.google.com/console/signup>.
- **Woher:** Kreditkarte (keine Prepaid-Karte), D-U-N-S-Nummer. Name und Anschrift müssen exakt dem Eintrag bei Dun & Bradstreet entsprechen. Quelle: <https://support.google.com/googleplay/android-developer/answer/13628312> (abgerufen 26.11.2026). Store-Regeln: [G-25](STORE-RICHTLINIEN.md#g-25), [G-27](STORE-RICHTLINIEN.md#g-27), [D-02](STORE-RICHTLINIEN.md#d-02). Zum Vergleich: Ein **privates** Konto braucht für die Erstveröffentlichung einen geschlossenen Test mit mindestens 12 Testern über mindestens 14 Tage (Schritt 6.8). Ein Organisationskonto mit D-U-N-S-Nummer braucht das nicht. Die Regel ändert Google gelegentlich, vor dem Start prüfen.
- **Prüfschritt:** Die Console zeigt "Konto verifiziert".
- [ ] erledigt

### 6.2 App anlegen

- **Was:** "App erstellen": Name `LINEFM Radio`, Sprache Deutsch, Typ App, kostenlos. Erklärungen zu Richtlinien und US-Exportgesetzen bestätigen.
- **Wozu:** Legt den Eintrag mit der Paket-ID an.
- **Wo eintragen:** Play Console > "App erstellen".
- **Woher:** entfällt.
- **Prüfschritt:** Die App erscheint auf dem Dashboard.
- [ ] erledigt

### 6.3 Upload-Schlüssel und Secrets

- **Was:** **Play App Signing** aktiviert lassen (Standard). Google verwaltet dann den eigentlichen App-Schlüssel. Den Upload-Schlüssel erzeugst du einmalig (Befehl in `packaging/android/SIGNING.md`).
- **Wozu:** Mit dem Upload-Schlüssel signiert die Pipeline jeden Upload. Geht er verloren, setzt die Play Console ihn zurück.
- **Wo eintragen:** Datei `upload-keystore.jks` und Passwörter in den Passwortmanager. Secrets `ANDROID_KEYSTORE_BASE64` (Datei als Base64), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (zum Beispiel `upload`), `ANDROID_KEY_PASSWORD`.
- **Woher:** Du erzeugst die Schlüsseldatei selbst mit `keytool`.
- **Prüfschritt:** Der Release-Lauf baut ein signiertes AAB. Fehlt der Schlüssel, bricht `store-google.yml` mit klarer Meldung ab.
- [ ] erledigt

### 6.4 Dienstkonto für den automatischen Upload

- **Was:** In der Google Cloud Console ein Dienstkonto mit JSON-Schlüssel anlegen und in der Play Console einladen (Nutzer und Berechtigungen, Recht für Veröffentlichung auf Test- und Produktionsspuren).
- **Wozu:** Die Pipeline lädt damit jedes Release als Entwurf in die Spur "internal".
- **Wo eintragen:** Gesamter Inhalt der JSON-Datei als Secret `PLAY_SERVICE_ACCOUNT_JSON`. Optional Variable `BUILD_NUMBER_OFFSET`, nur wenn Play einen höheren `versionCode` verlangt (Standard 100).
- **Woher:** Google Cloud Console > IAM > Dienstkonten.
- **Prüfschritt:** Nach einem Release erscheint ein Entwurf in der Spur "internal".
- [ ] erledigt

### 6.5 Datenschutz und App-Inhalte

- **Was:** Play Console > Richtlinie > App-Inhalte. Datenschutzerklärung-URL `https://app.linefm.de/datenschutz/`. Werbung "nein": Die App selbst bindet keine Werbung ein, Werbespots im Programm kommen von den Sendern. Google kann das Werbe-Label selbst setzen (<https://support.google.com/googleplay/android-developer/answer/9859455>, abgerufen 26.11.2026). Zielgruppe "13 und älter" (keine Kinder), Altersfreigabe über den **IARC-Fragebogen** (Ziel 13+), App-Zugriff "keine Anmeldung nötig" (kein Testkonto), Werbe-ID-Erklärung "nein", Nachrichten-App "nein" (Medien-Streaming-Apps fallen laut Google nicht darunter, <https://support.google.com/googleplay/android-developer/answer/10523915>), Behörden-App "nein", Finanzfunktionen "nein", Gesundheit "nein". Laut Google sind Datenschutzerklärung, Werbung, Zielgruppe und Altersfreigabe für alle Apps Pflicht (Quelle oben). Welche weiteren Erklärungen die Console abfragt, zeigt sie selbst.
- **Wozu:** Alles muss ausgefüllt sein, sonst blockiert Google die Veröffentlichung.
- **Wo eintragen:** Play Console, App-Inhalte.
- **Woher:** Hinweise: Der Sender +RAP kann Kraftausdrücke senden, im Fragebogen ehrlich angeben. Die Werbe-ID wird nicht verwendet. Das Manifest entfernt `com.google.android.gms.permission.AD_ID` per `tools:node="remove"`. Nach dem Release-Build mit `aapt dump permissions app-release.apk` nachsehen, ob sie fehlt. Sonst müsste "Werbe-ID: ja" stehen. Die Antworten zu Datensicherheit stehen in Abschnitt 13.
- **Prüfschritt:** Alle Punkte unter App-Inhalte zeigen einen grünen Haken.
- Store-Regeln: [G-05](STORE-RICHTLINIEN.md#g-05), [G-12](STORE-RICHTLINIEN.md#g-12), [G-13](STORE-RICHTLINIEN.md#g-13), [G-19](STORE-RICHTLINIEN.md#g-19), [G-20](STORE-RICHTLINIEN.md#g-20), [G-24](STORE-RICHTLINIEN.md#g-24), [G-30](STORE-RICHTLINIEN.md#g-30)
- [ ] erledigt

### 6.6 Deklarationen: Vordergrunddienst und Vollbild-Benachrichtigung

- **Was:** Zwei Erklärungen in der Play Console abgeben: Vordergrunddienst-Typ `mediaPlayback` (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`) und `USE_FULL_SCREEN_INTENT` für den Radiowecker. Exakte Alarme (`SCHEDULE_EXACT_ALARM`) fragt die App beim Wecker selbst beim Nutzer ab, die App nutzt bewusst nicht `USE_EXACT_ALARM`.
- **Wozu:** Google lässt Apps mit Zielversion Android 14 oder höher ohne diese Erklärung nicht durch. Bei der Vollbild-Berechtigung gilt: Standardmäßig bekommen sie nur Anruf- und Wecker-Apps. **Risiko:** Bei einer Radio-App kann Google die Erklärung ablehnen. Dann entfernt der Entwickler die Berechtigung, und der Wecker meldet sich ohne Vollbild. Das stimmst du mit dem Entwickler ab.
- **Wo eintragen:** Play Console > Richtlinie > App-Inhalte > "Vordergrunddienste" und "Vollbild-Benachrichtigungen" (genauen Menünamen vor Ort prüfen).
- **Woher:** Fertige Texte auf Deutsch und Englisch, die Felder der Console und das Skript für das Demo-Video stehen in [STORE-TEXTE.md](STORE-TEXTE.md), Abschnitt "Play-Console-Deklarationen". Das Video nimmst du selbst auf (Hinweise dort).
- **Prüfschritt:** Beide Deklarationen zeigen den Status "Abgeschickt" bzw. "Genehmigt". Entscheidung zum Umgang mit einer Ablehnung ist festgehalten (Freigabe-Checkliste, Abschnitt C).
- Store-Regeln: [G-14](STORE-RICHTLINIEN.md#g-14), [G-15](STORE-RICHTLINIEN.md#g-15), [G-16](STORE-RICHTLINIEN.md#g-16), [G-17](STORE-RICHTLINIEN.md#g-17)
- [ ] erledigt

### 6.7 Store-Eintrag

- **Was:** Kurz- (80 Zeichen) und Langbeschreibung auf Deutsch und Englisch, Grafiken, Kategorie "Musik & Audio".
- **Wozu:** Das sieht jeder im Store.
- **Wo eintragen:** Play Console > Store-Präsenz. Texte aus [STORE-TEXTE.md](STORE-TEXTE.md). Icon 512 x 512 liegt in `assets/branding/play_store_512.png`. Weiteres in Abschnitt 14.
- **Woher:** STORE-TEXTE.md, Abschnitt "Google Play".
- **Prüfschritt:** Die Vorschau der Store-Seite zeigt alle Felder ohne Fehler.
- Store-Regeln: [G-06](STORE-RICHTLINIEN.md#g-06), [G-29](STORE-RICHTLINIEN.md#g-29)
- [ ] erledigt

### 6.8 Geschlossener Test (Pflicht nur für private Konten)

Google nennt die Testpflicht nur für **private** Konten, die nach dem 13.11.2023 angelegt wurden: mindestens 12 Tester, je 14 Tage durchgehend dabei (<https://support.google.com/googleplay/android-developer/answer/14151465>, abgerufen 26.11.2026). LineFM Studios nutzt ein Organisationskonto, für das die Seite keine solche Pflicht nennt. Zeigt die Console trotzdem den Hinweis, gilt die Console. Für Android Auto brauchst du ohnehin eine Testspur (Schritt 6.10).

- **Was (nur falls die Console es verlangt):** Testspur "Geschlossener Test" anlegen, Release hochladen, mindestens 12 Tester per E-Mail-Liste oder Google-Gruppe eintragen, 14 Tage laufen lassen, dann "Zugriff auf Produktion beantragen".
- **Wozu:** Google verlangt das für private Konten vor der ersten Veröffentlichung.
- **Wo eintragen:** Play Console > Test und Veröffentlichung > Geschlossener Test. Einladungstext und Testerliste-Vorlage in [STORE-TEXTE.md](STORE-TEXTE.md). Tester-E-Mail-Adressen nur solange speichern, wie der Test läuft.
- **Woher:** Deine Kontakte.
- **Prüfschritt:** Die Console zeigt nach Tag 14 mindestens 12 durchgehende Tester und schaltet "Produktion beantragen" frei.
- [ ] erledigt

### 6.9 App-Links für Android (assetlinks.json)

- **Was:** Zwei SHA-256-Fingerabdrücke als Variable `ANDROID_CERT_SHA256` eintragen. In der Datei `web/.well-known/assetlinks.json` steht dafür der Platzhalter `{{ANDROID_CERT_SHA256}}`, den der Web-Postbuild beim Build aus der Variable füllt.
- **Wozu:** Links `https://app.linefm.de/?station=...` öffnen dann direkt in der App statt im Browser.
- **Wo eintragen:** Repository-Variable `ANDROID_CERT_SHA256`, kommagetrennt (`AA:BB:…,CC:DD:…`, je 32 Byte). Schreibe die Datei nicht von Hand.
- **Woher:** Der **App-Signaturschlüssel** (Play Console > Test und Veröffentlichung > Einrichtung > App-Integrität > App-Signatur, gilt für Installationen aus Google Play) und der **Upload-Schlüssel** (dort oder lokal `keytool -list -v -keystore upload-keystore.jks`, gilt für die APK aus den GitHub-Releases).
- **Prüfschritt:** Nach dem nächsten Web-Deploy ist `https://app.linefm.de/.well-known/assetlinks.json` ohne Weiterleitung mit Status 200 und `application/json` erreichbar und enthält beide Fingerabdrücke. Danach bittest du den Entwickler, im Manifest `autoVerify` auf `true` zu setzen und neu zu veröffentlichen.
- [ ] erledigt

### 6.10 Android Auto

Quelle: <https://developer.android.com/training/cars/distribute> (abgerufen 26.11.2026).

- **Was:**
  1. Play Console > Test und Veröffentlichung > Erweiterte Einstellungen > Formfaktoren: "Android Auto" hinzufügen.
  2. Ein App-Bundle mit Auto-Unterstützung zuerst in einer **Testspur** veröffentlichen.
  3. Die Auto-Prüfung einplanen: Für offene Tests und Produktion blockiert sie die Veröffentlichung, für geschlossene Tests ist sie nur ein Hinweis. Das Ergebnis kommt per E-Mail.
  4. Wird ein Bundle abgelehnt: das abgelehnte Bundle aus der Spur entfernen, bevor du eine neue Version hochlädst.
  5. Vorher mit der Desktop Head Unit (DHU) prüfen (Freigabe-Checkliste B2).
- **Wozu:** Ohne Formfaktor erscheint die App nicht im Auto. Google prüft Auto-Apps gesondert nach der Qualitätsliste für Medien-Apps.
- **Wo eintragen:** Play Console. Ein Testkonto für die Prüfung ist nicht nötig, die App hat keine Anmeldung.
- **Woher:** Der Entwickler erklärt die DHU.
- **Prüfschritt:** Die Auto-Prüfung meldet per E-Mail "genehmigt".
- Store-Regeln: [G-21](STORE-RICHTLINIEN.md#g-21)
- [ ] erledigt

### 6.11 16-KB-Speicherseiten

- **Was:** Vor jedem Release prüfen, dass die nativen Bibliotheken auf 16-KB-Seiten ausgerichtet sind: `zipalign -c -P 16 -v 4 app-release.apk`. Das macht der Entwickler bzw. die CI.
- **Wozu:** Google lehnt Updates ab, die auf Geräten mit 16-KB-Speicherseiten nicht laufen.
- **Wo eintragen:** nichts. Die Play Console zeigt Warnungen im App-Bundle-Explorer.
- **Woher:** Entwickler.
- **Prüfschritt:** Die Prüfung meldet keinen Fehler, die Console keine Warnung.
- Store-Regeln: [G-22](STORE-RICHTLINIEN.md#g-22)
- [ ] erledigt

### 6.12 Entwicklerverifizierung für die APK außerhalb von Google Play

- **Was:** Die APK auf GitHub Releases bleibt (Entscheidung des Inhabers). Dafür registriert LineFM Studios die App bei Googles Android-Entwicklerverifizierung. Wer auch über Play vertreibt, macht das in der Play Console. Laut Google registriert Play 99 Prozent der Apps automatisch, übrige Apps und solche außerhalb von Play meldest du dort von Hand an.
- **Wozu:** Seit 30.09.2026 schützen zertifizierte Android-Geräte in Brasilien, Indonesien, Singapur und Thailand vor Apps unbestätigter Entwickler, 2027 folgt die weltweite Ausweitung. Ohne Registrierung lässt sich die GitHub-APK dann auf normalen Geräten kaum noch installieren. Quelle: <https://developer.android.com/developer-verification> (abgerufen 26.11.2026).
- **Wo eintragen:** Play Console, Bereich Entwicklerverifizierung (Menüname vor Ort prüfen). Registriert wird der Schlüssel, der die GitHub-APK signiert (Upload-Schlüssel, Schritt 6.3).
- **Woher:** Organisationskonto, Upload-Schlüssel. Gebühren und Details in der FAQ der Quellseite (nicht im Detail abgerufen).
- **Prüfschritt:** Die Console zeigt die App als registriert, auch für den Vertrieb außerhalb von Play.
- [ ] erledigt

### 6.13 Hinweise für die Prüfung

- **Was:** Im Feld für Prüfhinweise schreiben: keine Anmeldung nötig; wo der Wecker gestellt wird; wie Chromecast und Android Auto getestet werden; Herkunft der Inhalte (laut.fm-Vereinbarung, Schritt 17.7).
- **Wozu:** Prüfer, die eine Funktion nicht finden, lehnen ab.
- **Wo eintragen:** Play Console > App-Inhalte > App-Zugriff (Anweisungen). Microsoft: Partner Center > Einreichung > "Hinweise für die Zertifizierung".
- **Woher:** Textvorschläge in [STORE-TEXTE.md](STORE-TEXTE.md).
- **Prüfschritt:** Beide Felder ausgefüllt.
- Store-Regeln: [G-30](STORE-RICHTLINIEN.md#g-30), [M-03](STORE-RICHTLINIEN.md#m-03), [M-22](STORE-RICHTLINIEN.md#m-22)
- [ ] erledigt

---

## 7. Microsoft Partner Center (Windows-Store)

Quelle: [packaging/windows/README.md](../packaging/windows/README.md).

### 7.1 Konto und App-Name

- **Was:** Als **Firma** (Company account) über <https://storedeveloper.microsoft.com> registrieren, kostenlos (abgerufen 26.11.2026). Bestätigung per D-U-N-S-Nummer (schneller) oder Firmendokumenten (manuelle Prüfung, 2 bis 5 Werktage). Die E-Mail muss zur Domain der Firma passen, Gmail und ähnliche gehen nicht. Ein Einzelkonto lässt sich später nicht in ein Firmenkonto umwandeln. Danach Namen "LINEFM Radio" reservieren. Store-Regeln: [M-12](STORE-RICHTLINIEN.md#m-12), [M-20](STORE-RICHTLINIEN.md#m-20), [D-02](STORE-RICHTLINIEN.md#d-02).
- **Wozu:** Ohne Konto kein Store-Eintrag.
- **Wo eintragen:** <https://partner.microsoft.com/dashboard/registration>.
- **Woher:** Ausweis, Kontaktdaten.
- **Prüfschritt:** Die App erscheint im Partner Center unter "Apps und Spiele".
- [ ] erledigt

### 7.2 Produktidentität

- **Was:** Drei Werte aus Produktverwaltung > Produktidentität kopieren.
- **Wozu:** Der Build trägt sie in das Paket ein, sonst lehnt der Store es ab.
- **Wo eintragen:** Variablen `MS_STORE_IDENTITY_NAME` (`Package/Identity/Name`), `MS_STORE_PUBLISHER` (`Package/Identity/Publisher`, sieht aus wie `CN=XXXXXXXX-...`), `MS_STORE_PUBLISHER_DISPLAY_NAME` (`Package/Properties/PublisherDisplayName`) und `MS_STORE_PRODUCT_ID` (Store-Produkt-ID, 12 Zeichen, zum Beispiel `9NXXXXXXXXXX`).
- **Woher:** Partner Center, Produktverwaltung.
- **Prüfschritt:** Alle vier Variablen stehen in der Liste, der Windows-Build meldet keinen fehlenden Wert.
- [ ] erledigt

### 7.3 Azure-AD-Anwendung für die Pipeline

- **Was:** Partner Center > Konto-Einstellungen > Benutzer > Azure-AD-Anwendungen: Anwendung anlegen, Rolle "Manager".
- **Wozu:** `store-microsoft.yml` reicht damit den Entwurf ein. Abgeschickt wird im Partner Center.
- **Wo eintragen:** Secrets `MS_STORE_TENANT_ID` (Verzeichnis-/Tenant-ID), `MS_STORE_SELLER_ID` (Konto-Einstellungen > Organisationsprofil > Legal info), `MS_STORE_CLIENT_ID`, `MS_STORE_CLIENT_SECRET`.
- **Woher:** Partner Center und Azure-Portal. Das Client-Secret hat ein Ablaufdatum, notiere es.
- **Prüfschritt:** Nach einem Release erscheint ein Entwurf im Partner Center.
- [ ] erledigt

### 7.4 Zertifikat für den Installer (optional)

- **Was:** Codesigning-Zertifikat für den Installer auf GitHub.
- **Wozu:** Der Store braucht keins, Microsoft signiert selbst. Ohne Zertifikat zeigt Windows SmartScreen beim Installer eine Warnung.
- **Wo eintragen:** Secrets `WINDOWS_CERT_PFX_BASE64` und `WINDOWS_CERT_PASSWORD`.
- **Woher:** Ein Zertifikatsanbieter (kostenpflichtig, kostenlose Wege prüfen).
- **Prüfschritt:** Der Installer zeigt in den Dateieigenschaften eine digitale Signatur.
- **Was damit signiert wird:** die App-EXE, der Setup-Stub (er ist zugleich `uninstall.exe`), das Setup-Fenster `linefm_setup.exe` und die fertige `setup.exe`. Die CI prüft die Signatur der `setup.exe` mit `signtool verify`. Das Zertifikat sollte auf den Hersteller "LineFM Studios" lauten, so steht er auch in den Dateieigenschaften und unter "Installierte Apps".
- **Bedienung des Installers:** [BAUEN-UND-STARTEN.md](BAUEN-UND-STARTEN.md), Abschnitt "Windows: Installer benutzen".
- [ ] erledigt

### 7.5 Store-Eintrag

- **Was:** Beschreibung, 300 x 300-Logo, mindestens ein Screenshot, Altersfreigabe über den **IARC-Fragebogen** im Partner Center (Ziel 13+), Datenschutz-URL, Support-Kontakt (Schritt 20.1), Hinweise für die Zertifizierung (Schritt 6.13).
- **Wo eintragen:** Partner Center. Texte aus [STORE-TEXTE.md](STORE-TEXTE.md), Abschnitt "Microsoft Store".
- **Wozu / Woher:** Sichtbar im Store. Datenschutz-URL `https://app.linefm.de/datenschutz/`.
- **Prüfschritt:** Die Einreichung zeigt keine offenen Pflichtfelder.
- Store-Regeln: [M-05](STORE-RICHTLINIEN.md#m-05), [M-07](STORE-RICHTLINIEN.md#m-07), [M-18](STORE-RICHTLINIEN.md#m-18), [M-22](STORE-RICHTLINIEN.md#m-22)
- [ ] erledigt

---

## 8. Linux: Flathub und Snap Store

### 8.1 Flathub

Quelle: [packaging/flathub/README.md](../packaging/flathub/README.md).

- **Was:** Domain bestätigen, Weitergabe erlauben, dann einreichen.
- **Wozu:** Flathub prüft, dass `de.linefm.app` dir gehört, und braucht die Erlaubnis zur Weiterverteilung. LINEFM Radio ist proprietär. Das ist bei Flathub erlaubt, wenn du die Weitergabe ausdrücklich erlaubst. Schriftlich bestätigen (Nutzungsrechtevertrag, Schritt 2.5).
- **Wo eintragen:**
  1. Datei `https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` auf der Hauptdomain bereitstellen. Den Inhalt nennt Flathub bei der Einreichung. Das geht nur über `linefm.de`, die du verwaltest.
  2. Altersangabe (OARS, Alterseinstufung bei Linux-Stores) in der Metainfo bestätigen, wegen Kraftausdrücken bei +RAP.
  3. Screenshots im Netz bereitstellen, URLs in der Metainfo eintragen (dort stehen Platzhalter).
  4. Einreichung per Änderungsvorschlag gegen `flathub/flathub`. Der Entwickler bereitet ihn vor. Du reichst mit deinem GitHub-Konto ein oder gibst Tim Hauke die Vollmacht.
- **Woher:** Inhalt der Verifizierungsdatei von Flathub.
- **Prüfschritt:** `curl -s https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` liefert den Inhalt. Flathub bestätigt die Verifizierung.
- **Ehrlicher Hinweis:** Unser Paket enthält die fertig gebaute Binärdatei, nicht den Quelltext. Flathub verlangt bei nicht offener Software meist den Bau aus dem Quelltext oder besondere Regeln. Es kann sein, dass Flathub ablehnt oder eine Ausnahme verlangt. Das klärst du nur durch Nachfragen bei den Flathub-Betreuern (Ticket im Repo `flathub/flathub`). Scheitert es, bleiben Snap Store und der Tarball auf GitHub.
- [ ] erledigt

### 8.2 Snap Store

- **Was:** Konto von LineFM Studios anlegen, Snap-Namen `linefm-radio` mit diesem Konto registrieren (nicht mit einem Entwicklerkonto), Zugangsdaten für die Pipeline erzeugen. Im Snap-Dashboard Kontakt `support@linefm.de`, Website `/support/` und Datenschutz-URL eintragen.
- **Wozu:** `store-snap.yml` lädt jedes Release in den Kanal "edge".
- **Wo eintragen:** Secret `SNAPCRAFT_STORE_CREDENTIALS`.
- **Woher:** Konto auf <https://snapcraft.io/> (Ubuntu One). Name per `snapcraft register linefm-radio`. Zugangsdaten per `snapcraft export-login`, der volle Befehl steht in [secrets.md](secrets.md). Sie laufen ab, dann wiederholen.
- **Prüfschritt:** Nach einem Release erscheint die Version im Kanal "edge". Dann "candidate" und "stable". Ob die Tray-Funktion unter der strikten Snap-Absicherung läuft, ist noch ungetestet.
- Store-Regeln: [S-03](STORE-RICHTLINIEN.md#s-03), [S-06](STORE-RICHTLINIEN.md#s-06), [S-07](STORE-RICHTLINIEN.md#s-07), [S-08](STORE-RICHTLINIEN.md#s-08)
- [ ] erledigt

---

## 9. Statistik und Absturzberichte (optional)

Ohne Konfiguration sendet die App nichts und fragt nicht nach Einwilligung. Technische Details: [telemetry.md](telemetry.md).

### 9.1 Anbieter wählen und betreiben

- **Was:** Umami (Statistik), GlitchTip oder Sentry (Abstürze), Firebase (beides). Selbst hosten geht mit den Docker-Compose-Dateien in `deploy/telemetry/`.
- **Wozu:** Du siehst Nutzung und Abstürze. Nach Einwilligung der Nutzer.
- **Wo eintragen:** Auf dem eigenen Server. **Vor der Veröffentlichung:** Umami legt beim ersten Start das Konto `admin` mit dem Passwort `umami` an. Ändere es sofort nach der ersten Anmeldung, bevor Umami aus dem Internet erreichbar ist. GlitchTip hat die Registrierung aus, das erste Konto entsteht auf der Kommandozeile (Ablauf in telemetry.md).
- **Woher:** Eigene Installation oder Cloud-Konto. Zuerst den AVV (Schritt 2.4).
- **Prüfschritt:** Anmeldung mit dem neuen Passwort klappt, das Standardpasswort nicht mehr.
- [ ] erledigt

### 9.2 Werte eintragen

- **Was:** Öffentliche IDs als Repository-Variablen setzen.
- **Wozu:** Sie aktivieren den Anbieter im Build. Es sind keine Geheimnisse, sie stehen im fertigen Programm.
- **Wo eintragen:** Variablen `UMAMI_URL`, `UMAMI_WEBSITE_ID`, `SENTRY_DSN`, `SENTRY_ENVIRONMENT`. Für Firebase Secret `FIREBASE_CONFIG_JSON` (JSON mit `FIREBASE_*`-Schlüsseln). Lokal: `config/app.yaml` nach Vorlage `config/app.example.yaml`, nicht einchecken (siehe [Konfiguration](KONFIGURATION.md)).
- **Woher:** Umami: Website-ID in den Website-Einstellungen. Sentry/GlitchTip: DSN im Projekt. Firebase: Projekteinstellungen > Web-App.
- **Prüfschritt:** Nach der Einwilligung in der App erscheint ein Ereignis in Umami bzw. ein Testabsturz in GlitchTip. Ohne Einwilligung geht nichts raus. Nach jeder Änderung die Web-Version neu bauen und die Server-Header neu ausrollen, sonst blockiert die Sicherheitsrichtlinie die neuen Domains.
- [ ] erledigt

### 9.3 Datenschutzangaben ergänzen

- **Was:** Betreiber und Speicherdauer eintragen.
- **Wozu:** Mit aktiver Telemetrie sind sie Pflicht, leere Werte zählen als offen.
- **Wo eintragen:** In `legal_values.json` bzw. `LEGAL_VALUES_JSON`: `{{TELEMETRIE_AUFBEWAHRUNG}}`, `{{UMAMI_BETREIBER}}`, `{{SENTRY_BETREIBER}}`.
- **Woher:** Dein Betreiber der Instanz, deine Löschfristen.
- **Prüfschritt:** Generator mit `--strict` und passendem `--providers` läuft ohne Fehler.
- [ ] erledigt

---

## 10. Search Console, GA4 und GTM

Das gilt nur für die Web-Version. Alles ist aus, solange du keine Werte einträgst.

### 10.1 Search Console

- **Was:** Die Domain bei Google Search Console bestätigen und die Sitemap einreichen. Erst wenn die Domain live ist.
- **Wozu:** Du siehst Suchanfragen, Indexierung und Fehler.
- **Wo eintragen:** <https://search.google.com/search-console>. Bevorzugt eine **Domain-Property** für `linefm.de` mit einem DNS-TXT-Eintrag beim DNS-Anbieter. Alternativ eine **URL-Präfix-Property** mit Meta-Tag: den Code aus "HTML-Tag" als Variable `GSC_VERIFICATION` eintragen. Der Web-Postbuild setzt das Meta-Tag `google-site-verification` ein, ohne Wert entfernt er es. Danach Sitemap `https://app.linefm.de/sitemap.xml` einreichen.
- **Woher:** Search Console zeigt den TXT-Wert bzw. den Tag-Code.
- **Prüfschritt:** Search Console meldet "Inhaberschaft bestätigt". Die Sitemap zeigt Status "Erfolgreich".
- [ ] erledigt

### 10.2 GA4 und Tag Manager

- **Was:** Optionale Reichweitenmessung mit Google Analytics 4, direkt oder über den Google Tag Manager (GTM).
- **Wozu:** Du siehst, wie viele Menschen die Web-Version nutzen und welche Bereiche sie aufrufen. Die App fragt separat nach "Reichweitenmessung mit Google" (Google, USA-Übermittlung, EU-US Data Privacy Framework, Zweck). Standard ist abgelehnt. Erst nach Zustimmung lädt die App Google (Consent Mode v2, die `ad_*`-Signale bleiben abgelehnt). Die Sicherheitsrichtlinie (CSP) wird beim Web-Build nur dann um `googletagmanager.com` und `google-analytics.com` erweitert, wenn du Werte setzt.
- **Wo eintragen:** Repository-Variablen `GTM_ID` (Form `GTM-XXXXXXX`) und/oder `GA4_MEASUREMENT_ID` (Form `G-XXXXXXXXXX`). Sie landen in `config/app.json`. Neu bauen und ausrollen.
- **Woher:** GTM-ID: <https://tagmanager.google.com> > Container. Mess-ID: <https://analytics.google.com> > Verwaltung > Datenstreams.
- **Einstellungen in GA4:** Datenaufbewahrung auf 2 Monate, Google-Signale aus, Datenfreigabe aus. Die Auftragsverarbeitungsbedingungen in der GA4-Verwaltung akzeptieren (Schritt 2.4). **In GTM keine Tags vom Typ "Benutzerdefiniertes HTML"**, die CSP blockt Inline-Skripte.
- **Datenschutz:** Der Abschnitt "Google Analytics" in der Datenschutzerklärung erscheint automatisch, wenn die Werte gesetzt sind. Dann ist der Platzhalter `{{GA4_AUFBEWAHRUNG}}` Pflicht: Trage in `legal_values.json` bzw. `LEGAL_VALUES_JSON` die Speicherdauer ein, die du in GA4 eingestellt hast (zum Beispiel "2 Monate"). Anwalt abstimmen lassen.
- **Prüfschritt:** Browser-Entwicklertools > Netzwerk: Vor der Zustimmung keine Anfrage an `google*`, nach der Zustimmung wird `gtm.js` geladen. In GA4 zeigt Berichte > Echtzeit den Besuch.
- [ ] erledigt

---

## 11. Vertrauens-Badges: Gridinsoft und Trustpilot

### 11.1 Gridinsoft

- **Was:** Eintrag für `app.linefm.de` bei Gridinsoft (gridinsoft.com, Website-Reputation und Sicherheitsprüfung) und das offizielle Badge einbinden.
- **Wozu:** Vertrauenssignal im Footer oder Vertrauensbereich der Web-App.
- **Wo eintragen:** Variable `TRUST_GRIDINSOFT_URL` mit dem Link zum Profil.
- **Woher:** Das Profil legst **du** (LineFM Studios) bei Gridinsoft an. Das Ergebnis muss echt sein. Ohne Eintrag erscheint kein Badge.
- **Prüfschritt:** Nach dem Neubau zeigt die Web-App das Badge, der Link öffnet das Profil.
- [ ] erledigt

### 11.2 Trustpilot

- **Was:** Unternehmensprofil bei Trustpilot anlegen und das offizielle Badge einbinden.
- **Wozu:** Öffentliche Bewertungen als Vertrauenssignal.
- **Wo eintragen:** Variable `TRUST_TRUSTPILOT_URL`.
- **Woher:** Das Profil legst du an. Badge nur zeigen, wenn der Eintrag existiert und die Bewertung echt ist.
- **Prüfschritt:** Wie bei Gridinsoft.
- [ ] erledigt

---

## 12. Signierte Releases und Sicherheits-Scanner

### 12.1 Automatische Signatur (nichts zu tun)

- **Was:** Jedes Release bekommt automatisch eine GitHub-Attestierung (Build-Provenance, ein Herkunftsnachweis) und cosign-Signaturen (keyless über Sigstore) als `*.sigstore.json` je Datei.
- **Wozu:** Nutzer können prüfen, dass eine Datei unverändert ist und aus diesem Repository stammt.
- **Wo eintragen:** nichts. Es läuft ohne Zutun.
- **Woher:** entfällt.
- **Prüfschritt:** Am Release hängen `*.sigstore.json`-Dateien. Die Prüfbefehle stehen in [RELEASE-VERIFIZIEREN.md](RELEASE-VERIFIZIEREN.md).
- [ ] geprüft

### 12.2 GPG-Signatur (optional)

- **Was:** Zusätzlich eine GPG-Signatur der Prüfsummen.
- **Wozu:** Wer GPG nutzt, prüft `SHA256SUMS.txt` gegen einen öffentlichen Schlüssel.
- **Wo eintragen:** Secrets `GPG_PRIVATE_KEY` (ASCII-armored privater Schlüssel) und `GPG_PASSPHRASE`.
- **Woher:** Du oder der Inhaber erzeugt den Schlüssel selbst: `gpg --full-generate-key` (ed25519 oder RSA 4096). Export des privaten Schlüssels: `gpg --armor --export-secret-keys <ID>`. Den öffentlichen Schlüssel veröffentlichen, zum Beispiel auf keys.openpgp.org, und in der Doku verlinken. Den privaten Schlüssel sicher sichern.
- **Prüfschritt:** Die Zusammenfassung des Release-Laufs nennt "GPG-Signatur (SHA256SUMS.txt.asc): aktiv" und den Fingerabdruck, und die Datei `SHA256SUMS.txt.asc` hängt am Release.
- [ ] erledigt

### 12.3 Scorecard-Token und Code Scanning (optional)

- **Was:** `SCORECARD_TOKEN` ist ein nur lesender Fine-grained-Token für `scorecard.yml`. Die Variable `CODE_SCANNING_ENABLED` auf `true` lädt CodeQL-Ergebnisse auch in einem privaten Repo hoch.
- **Wozu:** Ohne Token fallen einzelne Scorecard-Checks (zum Beispiel Branch-Protection) niedriger aus. In einem öffentlichen Repo läuft Code Scanning ohnehin.
- **Wo eintragen:** Secret `SCORECARD_TOKEN`, Variable `CODE_SCANNING_ENABLED`.
- **Woher:** GitHub > Settings > Developer settings > Fine-grained tokens. Code Scanning in privaten Repos braucht GitHub Code Security.
- **Prüfschritt:** Der Scorecard-Lauf ist grün, das Badge in der README zeigt einen Wert.

#### Token für Sicherheitsfunde (nicht vorgesehen)

- **Entscheidung des Inhabers (22.11.2026):** Es gibt kein `SECURITY_ALERTS_TOKEN`. Nichts einzurichten.
- **Folge:** `security-alerts.yml` gleicht regulär nur Code Scanning ab. Dependabot- und Secret-Scanning-Alerts prüft der Betreiber in der Security-Ansicht des Repositories (siehe SECURITY.md).

---

## 13. Datenschutzangaben je Store

Die Angaben müssen zur Datenschutzerklärung passen. Im Zweifel anwaltlich prüfen lassen.

### 13.1 Google Play: Datensicherheit

- **Was:** Das Formular "Datensicherheit" in der Play Console.
- **Wozu:** Google zeigt die Antworten auf der Store-Seite. Falsche Angaben können zur Ablehnung führen.
- **Wo eintragen:** Play Console > Richtlinie > App-Inhalte > Datensicherheit.
- **Woher:** Die Antworten hängen an deiner Konfiguration:
  - Keine Telemetrie und kein Cast genutzt: Die App erhebt und teilt keine Daten. Favoriten, Verlauf und Einstellungen bleiben auf dem Gerät.
  - **Cast immer mit bedenken:** Das Cast-SDK der Google Play-Dienste sendet laut Google Nutzungsdaten. Die App startet es erst beim Tippen auf den Cast-Knopf, doch das Plugin kann es auf Android schon beim Beenden der App initialisieren (siehe [ENTWICKLUNG.md](ENTWICKLUNG.md), Abschnitt Google Cast). Gib "App-Aktivität" und "Geräte- oder andere IDs" mit Zweck "App-Funktionen" und Weitergabe an Google an, auch ohne eigene Telemetrie. Die genauen Daten stehen in der aktuellen Google-Dokumentation zum Cast-SDK, vor dem Ausfüllen nachlesen.
  - Umami, GlitchTip, Sentry oder Firebase aktiv: Nutzungsdaten (App-Aktivität) und Absturzdaten angeben, Verschlüsselung bei der Übertragung "ja", Löschung auf Anfrage nach deinem tatsächlichen Verfahren.
  - Google Analytics (nur Web): betrifft die Web-Version, nicht die App.
- **Prüfschritt:** Die Antworten stimmen mit Abschnitt 7 und 11 der Datenschutzerklärung überein. Löschung und Speicherdauer wie in Schritt 17.13.
- Store-Regeln: [G-12](STORE-RICHTLINIEN.md#g-12), [G-13](STORE-RICHTLINIEN.md#g-13)
- [ ] erledigt

### 13.2 Microsoft Store

- **Was:** Datenschutz-URL und Altersfreigabe im Einreichungsformular.
- **Wozu:** Pflichtfelder im Partner Center.
- **Wo eintragen:** Partner Center, Einreichung > Eigenschaften und Altersfreigabe. Ob es einen eigenen Datenfragebogen gibt, vor Ort prüfen.
- **Woher:** URL `https://app.linefm.de/datenschutz/`.
- **Prüfschritt:** Die Einreichung hat keine offenen Pflichtfelder.
- [ ] erledigt

### 13.3 Flathub und Snap Store

- **Was:** Flathub braucht die Altersangabe (OARS) in der Metainfo. Für den Snap Store prüfen, ob ein Datenschutzlink im Eintrag verlangt wird.
- **Wozu:** Pflichtangaben der Linux-Stores.
- **Wo eintragen:** Metainfo `linux/de.linefm.app.metainfo.xml`, Snap-Eintrag im Dashboard.
- **Woher:** Wie in Schritt 8.1. Einen Datenfragebogen wie bei Google gibt es dort nach unserem Stand nicht, im Zweifel prüfen.
- **Prüfschritt:** Die Metainfo besteht die Prüfung des Flathub-Builds.
- Store-Regeln: [D-04](STORE-RICHTLINIEN.md#d-04), [F-10](STORE-RICHTLINIEN.md#f-10), [S-08](STORE-RICHTLINIEN.md#s-08)
- [ ] erledigt

### 13.4 Apple App-Privacy (später)

- **Was:** "App-Datenschutz" (Privacy Nutrition Label) in App Store Connect.
- **Wozu:** Apple verlangt es vor der Einreichung.
- **Wo eintragen:** App Store Connect > App-Datenschutz. Erst mit Schritt 15.
- **Woher:** Gleiche Fakten wie bei Google. Apples Fragebogen im Zweifel vor Ort lesen.
- **Prüfschritt:** Der Status ist "Veröffentlicht".
- Store-Regeln: [A-12](STORE-RICHTLINIEN.md#a-12), [A-13](STORE-RICHTLINIEN.md#a-13), [A-14](STORE-RICHTLINIEN.md#a-14), [A-15](STORE-RICHTLINIEN.md#a-15)
- [ ] erledigt (Apple ist offen)

---

## 14. Bilder und Screenshots

### 14.1 Screenshots für die Stores

- **Was:** Screenshots für Telefon, Tablet und Desktop. Empfohlen: Stationen, Player, Verlauf, Favoriten, Wecker, dunkel und hell.
- **Wozu:** Pflicht in den Stores.
- **Wo eintragen:** In den Konsolen der Stores. Maße:
  - Google Play: 2 bis 8 Telefon-Screenshots, 16:9 bis 9:16, Kanten 320 bis 3840 px. Feature-Grafik 1024 x 500. Für Tablets je 7 und 10 Zoll empfohlen.
  - Microsoft Store: mindestens 1, empfohlen 4 oder mehr, 1366 x 768 oder größer.
  - Flathub: mindestens 1, über URL erreichbar.
- **Woher:** Der Entwickler erzeugt sie auf den Geräten oder Emulatoren. Du gibst sie frei. Sie zeigen die echte App ohne Fantasiedaten und ohne fremde Cover in Großansicht.
- **Prüfschritt:** Alle Pflichtgrößen sind hochgeladen.
- Store-Regeln: [G-06](STORE-RICHTLINIEN.md#g-06), [A-03](STORE-RICHTLINIEN.md#a-03), [F-10](STORE-RICHTLINIEN.md#f-10)
- [ ] erledigt

### 14.2 Alt-Texte

- **Was:** Bildbeschreibungen für Screenreader zu allen Bildern.
- **Wozu:** Barrierefreiheit.
- **Wo eintragen:** Bei den Bildern in den Stores und auf der Web-Seite.
- **Woher:** Du schreibst sie kurz und sachlich.
- **Prüfschritt:** Kein Bild ohne Beschreibung.
- [ ] erledigt

---

## 15. Apple (vorbereitet, vorerst nicht veröffentlicht)

iOS, macOS, CarPlay und AirPlay sind im Code vorbereitet. Apple (iOS und Mac App Store) kommt **nicht in die erste Veröffentlichung**, sondern später in einer gemeinsamen Runde für iOS und Mac. Für diese Runde gelten alle Schritte dieses Abschnitts plus die Apple-Teile aus 13.4 (App-Datenschutz), 17.5 (DSA-Händlerstatus), 18.2 und 18.3 (Konto, Vereinbarungen, Steuern), 19.3 (Zertifikate), 20.1 (Support-URL) und dem Fristenkalender 20.5. Regeln: [STORE-RICHTLINIEN.md, Apple](STORE-RICHTLINIEN.md#apple-app-store).

### 15.0 Vorbedingungen der Apple-Runde (später)

- **Was:** Vor dem Start der Apple-Runde: D-U-N-S liegt vor (18.1), Website und E-Mail auf der eigenen Domain (Apple verlangt beides für Organisationen), `support@linefm.de` und `/support/` erreichbar (20.1), Altersfragebogen 13+ beantwortet, Screenshots für iPhone, iPad und Mac (Abschnitt 14), Prüfnotizen mit Hinweis auf die laut.fm-Vereinbarung (17.7), Mac-Sandbox-Export über den Speichern-Dialog umgesetzt, Wecker mit AlarmKit ab iOS 26 und Hinweis auf den Benachrichtigungs-Rückfall in App- und Store-Text.
- **Wozu:** Ohne diese Punkte lehnt Apple ab oder die Anmeldung hängt.
- **Wo eintragen:** App Store Connect, Entwicklerportal.
- **Woher:** die genannten Schritte.
- **Prüfschritt:** Alle Unterpunkte abgehakt, erst dann `APPLE_PUBLISHING_ENABLED` setzen (15.6).
- Store-Regeln: [A-01](STORE-RICHTLINIEN.md#a-01), [A-17](STORE-RICHTLINIEN.md#a-17), [A-20](STORE-RICHTLINIEN.md#a-20), [A-22](STORE-RICHTLINIEN.md#a-22), [A-23](STORE-RICHTLINIEN.md#a-23)
- [ ] erledigt (Apple-Runde, später)

### 15.1 Konto und Team-ID

- **Was:** Apple Developer Program beitreten (99 US-Dollar pro Jahr, für eine Firma wird eine D-U-N-S-Nummer verlangt). Team-ID notieren.
- **Wozu:** Grundlage für alles Weitere.
- **Wo eintragen:** Secret `APPLE_TEAM_ID`. Außerdem steht der Name als `{{APPLE_TEAM_ID}}` in `packaging/ios/ExportOptions-*.plist.template` und in `web/.well-known/apple-app-site-association`. Das Skript und der Web-Postbuild setzen ihn aus dem Secret ein.
- **Woher:** <https://developer.apple.com/programs/>, Account > Mitgliedschaft, 10 Zeichen.
- **Prüfschritt:** Die ID ist 10 Zeichen lang und im Secret hinterlegt.
- Store-Regeln: [A-24](STORE-RICHTLINIEN.md#a-24), [A-26](STORE-RICHTLINIEN.md#a-26)
- [ ] erledigt

### 15.2 App-ID und App Store Connect

- **Was:** Bundle-ID `de.linefm.app` unter Zertifikate, IDs & Profile registrieren (Background Modes Audio, später CarPlay). App in App Store Connect anlegen (Name "LINEFM Radio", Sprache Deutsch).
- **Wozu:** Ohne App-Eintrag kein Upload.
- **Wo eintragen:** developer.apple.com und App Store Connect.
- **Woher:** eigene Eingabe.
- **Prüfschritt:** Die App erscheint in App Store Connect.
- [ ] erledigt

### 15.3 API-Schlüssel

- **Was:** API-Schlüssel für App Store Connect erzeugen (Nutzer und Zugriff > Integrationen).
- **Wozu:** Die Pipeline lädt damit hoch.
- **Wo eintragen:** Secrets `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8` (Inhalt der `.p8`-Datei als Text, nicht Base64).
- **Woher:** App Store Connect.
- **Prüfschritt:** Alle drei stehen in der Secret-Liste.
- [ ] erledigt

### 15.4 Zertifikate und Profile

- **Was:** "Apple Distribution" (iOS und Mac) und "Mac Installer Distribution" (nur Mac App Store) als `.p12` exportieren. Je ein App-Store-Profil für `de.linefm.app` und `de.linefm.app.widget` (iOS) sowie `de.linefm.app` (macOS). Für das signierte DMG außerhalb des Stores zusätzlich ein "Developer ID Application"-Zertifikat.
- **Wozu:** Apple signiert und prüft jede App.
- **Wo eintragen:** Secrets `APPLE_DISTRIBUTION_CERT_P12_BASE64`, `APPLE_DISTRIBUTION_CERT_PASSWORD`, `APPLE_MAC_INSTALLER_CERT_P12_BASE64`, `APPLE_MAC_INSTALLER_CERT_PASSWORD`, `APPLE_IOS_PROVISIONING_PROFILES_BASE64` (je Profil eine Zeile Base64), `APPLE_MACOS_PROVISIONING_PROFILE_BASE64`, `APPLE_DEVELOPER_ID_CERT_P12_BASE64`, `APPLE_DEVELOPER_ID_CERT_PASSWORD`.
- **Woher:** Apple-Entwicklerportal und Schlüsselbund (macOS). Die Pipeline `store-apple.yml` nutzt kein fastlane, Details in [secrets.md](secrets.md).
- **Prüfschritt:** Alle Secrets stehen in der Liste.
- [ ] erledigt

### 15.5 Namen der Provisioning-Profile für den Export

- **Was:** Die Platzhalter `{{PROVISIONING_PROFILE_APPSTORE_NAME}}` und `{{PROVISIONING_PROFILE_ADHOC_NAME}}` in `packaging/ios/ExportOptions-appstore.plist.template` bzw. `ExportOptions-adhoc.plist.template`.
- **Wozu:** Xcode braucht den Profilnamen beim Export.
- **Wo eintragen:** Die füllt der Entwickler beim Apple-Start mit `sed`, siehe [packaging/ios/README.md](../packaging/ios/README.md). Du lieferst nur den Profilnamen.
- **Woher:** Developer-Portal (bei fastlane match: `match AppStore de.linefm.app` bzw. `match AdHoc de.linefm.app`).
- **Prüfschritt:** Der Export läuft ohne Fehler "No profile found".
- [ ] erledigt

### 15.6 Schalter, CarPlay, Links, Review

- **Was:** Variable `APPLE_PUBLISHING_ENABLED` erst auf `true` setzen, wenn alles vorliegt. CarPlay-Audio-Berechtigung beantragen (Formular im Entwicklerportal, "CarPlay App Entitlement Request", Kategorie Audio). AASA-Datei prüfen (Links direkt in der iOS-App, Universal Links).
- **Wozu:** Solange der Schalter nicht `true` ist, laufen `store-apple.yml` und die Signaturschritte in `build.yml` nicht. Apple prüft CarPlay von Hand, das dauert Wochen. Ohne Freigabe zeigt die App kein CarPlay.
- **Wo eintragen:** Variable `APPLE_PUBLISHING_ENABLED`. Die AASA-Vorlage liegt in `web/.well-known/apple-app-site-association`, die Fähigkeit "Associated Domains" (`applinks:app.linefm.de`) steht in `Runner.entitlements`.
- **Woher:** Apple-Entwicklerportal.
- **Prüfschritt:** `https://app.linefm.de/.well-known/apple-app-site-association` ist ohne Dateiendung, mit `application/json` und ohne Weiterleitung erreichbar.
- macOS ohne Apple-Konto: Es gibt ein unsigniertes DMG auf GitHub Releases mit Öffnen-Anleitung ([packaging/macos/LIES-MICH-ZUERST.txt](../packaging/macos/LIES-MICH-ZUERST.txt)).
- Store-Regeln: [A-07](STORE-RICHTLINIEN.md#a-07), [A-21](STORE-RICHTLINIEN.md#a-21), [A-29](STORE-RICHTLINIEN.md#a-29), [A-33](STORE-RICHTLINIEN.md#a-33)
- Review-Risiko: Apple lehnt reine Webseiten-Hüllen ab (Richtlinien 4.2 und 4.3). Die App bringt Favoriten, Verlauf, Sleeptimer, Wecker, Sperrbildschirm-Steuerung und CarPlay als Mehrwert mit.
- [ ] erledigt

---

## 16. Abnahme

### 16.1 Prüfschritt über alles

- **Was:** Die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) komplett abarbeiten. Der Release-Build mit `--strict` muss durchlaufen.
- **Wozu:** Ohne offene Platzhalter und mit bestätigten Verträgen darfst du veröffentlichen.
- **Wo eintragen:** Abschnitt D der Freigabe-Checkliste, Antwort an Tim Hauke "Freigabe erteilt" mit Datum.
- **Woher:** entfällt.
- **Prüfschritt:** Alle Punkte oben abgehakt oder bewusst als "offen" begründet.
- [ ] erledigt

### 16.2 Automatische Gegenprüfung dieser Liste

Der Test `test/tool/einrichtung_vollstaendig_test.dart` prüft bei jedem Lauf, dass jeder Platzhalter und jedes Secret und jede Variable aus dem Repo in dieser Datei in Backticks genannt ist. Fehlt ein Name, schlägt der Test fehl. Wer einen neuen Platzhalter oder ein neues Secret anlegt, ergänzt die Anhänge A und B in derselben Änderung.

### 16.3 Wenn etwas hakt

- Frag im Repo unter Tickets oder Discussions nach. Beschreibe, welchen Schritt du gerade machst und was du siehst.
- Bei Fehlermeldungen von Stores: Meldung kopieren, Screenshot anhängen, keine Passwörter.
- Zeitaufwand der Prüfungen einplanen: Google Play einige Tage, CarPlay-Antrag Wochen, Flathub je nach Betreuern.

---

## 17. Recht und Datenschutz im Betrieb

Vorprüfung, keine Rechtsberatung. Jeden Punkt lässt du von einem Anwalt bestätigen. Die Store-Regeln zum Datenschutz: [D-04](STORE-RICHTLINIEN.md#d-04), [G-12](STORE-RICHTLINIEN.md#g-12), [G-13](STORE-RICHTLINIEN.md#g-13), [A-09](STORE-RICHTLINIEN.md#a-09), [A-15](STORE-RICHTLINIEN.md#a-15), [M-05](STORE-RICHTLINIEN.md#m-05), [W-03](STORE-RICHTLINIEN.md#w-03).

### 17.1 Impressum nach § 5 DDG

- **Was:** Das Impressum unter `/impressum/` (de und en) und in der App vollständig machen: Name, Rechtsform, ladungsfähige Anschrift, Vertretung, E-Mail, zweiter schneller Kontaktweg, Register und USt-IdNr., falls vorhanden, sowie die Angaben nach § 18 MStV.
- **Wozu:** Pflicht für jedes geschäftsmäßige Telemedium. Google, Apple und Microsoft verlangen dieselben Angaben zusätzlich in der Console (Schritt 17.5).
- **Wo eintragen:** Werte wie in Schritt 3.1 (Anhang B). Dieselbe Anschrift in allen Store-Konsolen verwenden.
- **Woher:** Handelsregister bzw. Gewerbeanmeldung, eigene Unterlagen.
- **Prüfschritt:** `/impressum/` zeigt keine `{{`-Reste. Die Anschrift ist überall gleich geschrieben: Impressum, D-U-N-S-Eintrag, Play Console, App Store Connect, Partner Center.
- [ ] erledigt

### 17.2 Datenschutzerklärung und Einwilligung (DSGVO, TDDDG)

- **Was:** Die Datenschutzerklärung nennt jeden Empfänger: laut.fm, Apple iTunes-Suche (Cover), `cdn.linefm.de`, `radiogruppe.de`, Google Cast, Hoster, sowie **Sentry, Firebase und Umami**. Die drei Telemetrie-Dienste laufen nach Entscheidung des Inhabers in den Store-Builds nur nach Einwilligung und sind in allen Store-Formularen als optional angegeben. Im Web kommt GA4/GTM hinzu (Schritt 10.2).
- **Wozu:** Ohne Einwilligung kein Zugriff auf das Endgerät für nicht notwendige Zwecke (§ 25 TDDDG). Die Store-Formulare müssen zur Erklärung passen, sonst droht Ablehnung oder Sperre.
- **Wo eintragen:** `legal_values.json` bzw. `LEGAL_VALUES_JSON`, Generator mit `--providers=umami,sentry` plus Firebase, falls aktiv. Store-Formulare: Abschnitt 13.
- **Woher:** Deine Konfiguration, die AVV aus Schritt 17.3.
- **Prüfschritt:** Ohne Einwilligung zeigt der Netzwerkmitschnitt keine Anfrage an Sentry, Firebase, Umami oder Google. Widerruf in den Einstellungen stoppt die Übertragung sofort.
- **Externe Links:** Die App lädt Inhalte von und verlinkt auf Dritte: `music.youtube.com` und `open.spotify.com` (Song suchen), `radiogruppe.de`, `cdn.linefm.de`, `api.laut.fm`, die Streams und die iTunes-Suche. Prüfe mit dem Anwalt, dass die Datenschutzerklärung jeden davon nennt und bei Links sagt, dass beim Öffnen die Regeln des Zielanbieters gelten. Die vollständige Liste liefert der Entwickler aus dem Code.
- Store-Regeln: [D-04](STORE-RICHTLINIEN.md#d-04), [G-04](STORE-RICHTLINIEN.md#g-04), [G-12](STORE-RICHTLINIEN.md#g-12), [A-09](STORE-RICHTLINIEN.md#a-09), [A-15](STORE-RICHTLINIEN.md#a-15), [M-05](STORE-RICHTLINIEN.md#m-05)
- [ ] erledigt

### 17.3 AVV je Auftragsverarbeiter

- **Was:** Für jeden Dienst, der personenbezogene Daten in deinem Auftrag verarbeitet, einen Vertrag nach Art. 28 DSGVO abschließen und ablegen.
- **Wozu:** Harte Freigabesperre für die Telemetrie (Freigabe-Checkliste).
- **Wo eintragen:** Ablage im Passwortmanager oder Vertragsordner. Liste:

| Dienst | Rolle | Wo es den Vertrag gibt | DPF prüfen |
|---|---|---|---|
| Sentry (Functional Software) | Absturzberichte | im Sentry-Konto unter den rechtlichen Einstellungen (vor Ort prüfen) | ja, US-Anbieter |
| GlitchTip, selbst gehostet | Absturzberichte | entfällt, wenn auf eigenem Server; sonst mit dem Hoster | nein |
| Firebase (Google) | Statistik, Absturzberichte | Firebase-Konsole, Projekteinstellungen, Datenschutz (Data Processing Terms, vor Ort prüfen) | ja |
| Umami, selbst gehostet | Statistik | AVV mit dem Server-Hoster | je nach Hoster |
| Umami Cloud | Statistik | beim Anbieter anfragen | je nach Anbieter |
| Google Analytics 4 | Web-Statistik | GA4 > Verwaltung > Kontoeinstellungen, Datenverarbeitungsbedingungen | ja |
| Cloudflare | Hosting, CDN, DNS | Cloudflare-DPA, Teil der Nutzungsbedingungen | ja |
| eigener Server oder Plesk-Hoster | Hosting, Server-Logs | beim Hoster | je nach Hoster |
| Betreiber von `cdn.linefm.de` | Logos | beim Betreiber | je nach Betreiber |

- **Woher:** Die Anbieter. Die genauen Menüpfade haben wir nicht live geprüft. DPF-Liste: <https://www.dataprivacyframework.gov/list>.
- **Prüfschritt:** Für jede Zeile mit aktivem Dienst liegt ein Vertrag mit Datum vor, der DPF-Status ist mit Abrufdatum notiert.
- [ ] erledigt

### 17.4 Barrierefreiheit (BFSG)

- **Was:** Entscheidung des Inhabers: Es gibt eine **freiwillige** Erklärung zur Barrierefreiheit als Seite `/barrierefreiheit/` (de und en) in der Web-App, Inhalt aus [BARRIEREFREIHEIT.md](BARRIEREFREIHEIT.md) (Schritt 3.2). Unabhängig davon klärst du mit dem Anwalt, ob das BFSG Pflichten auslöst (Kleinstunternehmen mit Dienstleistungen sind ausgenommen).
- **Wozu:** Seit 28.06.2025 gelten die Anforderungen für bestimmte Dienstleistungen im elektronischen Geschäftsverkehr. Ob eine kostenlose Radio-App darunter fällt, ist eine Rechtsfrage.
- **Wo eintragen:** Platzhalter in `docs/BARRIEREFREIHEIT.md`. Die Seite `/barrierefreiheit/` baut der Entwickler und verlinkt sie im Fuß der Web-App und in der App unter "Über".
- **Woher:** Anwalt. Gesetzestext: <https://www.gesetze-im-internet.de/bfsg/> (nicht live abgerufen).
- **Prüfschritt:** `https://app.linefm.de/barrierefreiheit/` und `/en/barrierefreiheit/` antworten mit 200, ohne `{{`-Reste. Die BFSG-Einschätzung des Anwalts liegt schriftlich vor.
- [ ] erledigt

### 17.5 Händlerstatus nach DSA bei Apple und Google

- **Was:** In App Store Connect und in der Play Console angeben, ob LineFM Studios als Händler (Trader) im Sinne des Digital Services Act handelt, und die Kontaktdaten bestätigen.
- **Wozu:** Apple verlangt die Angabe für jedes Konto, auch ohne EU-Vertrieb, und fragt spätestens bei der nächsten Einreichung danach. Als Händler zeigt Apple in der EU Anschrift, Telefon und E-Mail auf der Produktseite. Wer kein Händler ist, bei dem weist Apple EU-Kunden darauf hin, dass Verbraucherrechte nicht gelten. Google fragt dasselbe in der Play Console ab.
- **Wo eintragen:** App Store Connect > Business > Compliance (Rolle Account Holder oder Admin). Play Console > Einstellungen > Entwicklerkonto (Menüname vor Ort prüfen).
- **Woher:** Für Firmen nimmt Apple die Anschrift aus dem D-U-N-S-Eintrag, dazu Telefon und E-Mail (per Code bestätigt) und einen Nachweis zu Name und Anschrift. Quelle Apple: <https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/> (abgerufen 26.11.2026). Zu Google: Die Kontoangaben stehen auf <https://support.google.com/googleplay/android-developer/answer/13628312> (abgerufen 26.11.2026), den Wortlaut zum Händlerstatus haben wir dort nicht im Detail geprüft. Als Händler verlangt Apple zusätzlich Zahlungskontodaten, falls noch keine hinterlegt sind. Ob du Händler bist, entscheidest du mit dem Anwalt. Eine GmbH oder ein Gewerbe ist es in aller Regel.
- **Prüfschritt:** Beide Konsolen zeigen den Status als bestätigt. Die angezeigten Daten stimmen mit dem Impressum überein.
- Store-Regeln: [G-26](STORE-RICHTLINIEN.md#g-26), [A-25](STORE-RICHTLINIEN.md#a-25). Apple erst in der späteren Apple-Runde.
- [ ] erledigt

### 17.6 Markenrechte LINEFM

- **Was:** Prüfen, ob die Marke LINEFM eingetragen ist und wem sie gehört. Falls nicht: Anmeldung beim DPMA oder EUIPO erwägen.
- **Wozu:** Stores reagieren auf Markenbeschwerden. Mit eingetragener Marke kannst du Nachahmer melden und eigene Einreichungen belegen.
- **Wo eintragen:** Ergebnis in Abschnitt A1 der Freigabe-Checkliste.
- **Woher:** Recherche in DPMAregister (<https://register.dpma.de>) und TMview, Anwalt. Gebühren nicht live abgerufen.
- **Prüfschritt:** Registernummer oder bewusste Entscheidung gegen eine Anmeldung ist notiert.
- [ ] erledigt

### 17.7 laut.fm-Vereinbarung

- **Was:** Die Vereinbarung mit laut.fm liegt beim Kunden und bleibt dort (Entscheidung des Inhabers). Bei der Einreichung nennst du sie, wenn ein Store nach Rechten an Inhalten fragt.
- **Wozu:** Google und Apple fragen bei Streaming-Apps nach dem Recht, die Inhalte zu verbreiten. Ohne Beleg droht die Ablehnung wegen geistigen Eigentums.
- **Wo eintragen:** Play Console: Hinweis im Feld für Prüfer (Schritt 6.13); bei einer Beschwerde wegen geistigen Eigentums lädst du den Nachweis über die Seite "Richtlinienstatus" hoch. App Store Connect (spätere Apple-Runde): Frage "Content Rights" in den App-Informationen beantworten, Hinweis in den Review-Notizen, Nachweis bei Bedarf als Anhang. Partner Center: Hinweise für die Zertifizierung. Snap und Flathub: auf Nachfrage.
- **Woher:** deine Unterlagen.
- **Prüfschritt:** Abschnitt A5 der Freigabe-Checkliste abgehakt, Vereinbarung griffbereit.
- Store-Regeln: [D-03](STORE-RICHTLINIEN.md#d-03), [G-03](STORE-RICHTLINIEN.md#g-03), [G-32](STORE-RICHTLINIEN.md#g-32), [A-10](STORE-RICHTLINIEN.md#a-10), [M-14](STORE-RICHTLINIEN.md#m-14), [S-04](STORE-RICHTLINIEN.md#s-04)
- [ ] erledigt

### 17.8 Radio3FM und FobFM

- **Was:** Schriftliche Freigabe beider Sender (Schritt 2.2) als Datei ablegen, damit du sie Prüfern zeigen kannst.
- **Wozu:** Gleicher Grund wie 17.7.
- **Wo eintragen:** Abschnitt A1 der Freigabe-Checkliste, Ablage beim Kunden.
- **Woher:** Betreiber der Sender.
- **Prüfschritt:** Zwei Freigaben mit Datum liegen vor. Ohne sie fliegen die Sender aus der App.
- Store-Regeln: [D-03](STORE-RICHTLINIEN.md#d-03), [G-02](STORE-RICHTLINIEN.md#g-02)
- [ ] erledigt

### 17.9 Lizenzen und Seite /lizenz/

- **Was:** Die Seite `/lizenz/` (de und en) in der Web-App nennt die Lizenz der App und alle Fremdlizenzen (libmpv, FFmpeg und die Pakete aus [LIZENZEN-DRITTE.md](LIZENZEN-DRITTE.md)). Ihre URL steht in der Flathub-Metainfo und kann in den Store-Einträgen stehen.
- **Wozu:** LGPL und GPL verlangen Lizenztext und Hinweis auf den Quellcode der Bibliotheken. Flathub prüft die Lizenz-URL.
- **Wo eintragen:** nichts von Hand, die Seite kommt mit dem Web-Build. Du gibst den Wortlaut zur App-Lizenz frei (Schritt 2.5).
- **Woher:** Repo.
- **Prüfschritt:** `https://app.linefm.de/lizenz/` und `/en/lizenz/` antworten mit 200. In der App öffnet "Lizenzen" die Liste.
- Store-Regeln: [F-07](STORE-RICHTLINIEN.md#f-07), [W-04](STORE-RICHTLINIEN.md#w-04)
- [ ] erledigt

### 17.10 Jugendschutz (JMStV)

- **Was:** Die App richtet sich an Nutzer ab 13 Jahren (Entscheidung des Inhabers), in allen Stores mit Altersfreigabe 13+. Die Sender spielen Musik mit gelegentlich derber Sprache. Der Anwalt prüft, ob nach dem Jugendmedienschutz-Staatsvertrag ein Jugendschutzbeauftragter zu benennen ist (§ 7 JMStV) und ob weitere Pflichten bestehen.
- **Wozu:** Für geschäftsmäßige Telemedien mit möglicherweise entwicklungsbeeinträchtigenden Inhalten kann ein Jugendschutzbeauftragter Pflicht sein.
- **Wo eintragen:** Ergebnis in Abschnitt A4 der Freigabe-Checkliste. Ist ein Beauftragter nötig, kommen Name und Kontakt ins Impressum (der Entwickler legt dafür einen Platzhalter an).
- **Woher:** Anwalt. Gesetzestext nicht live abgerufen.
- **Prüfschritt:** Schriftliche Einschätzung liegt vor.
- Store-Regeln: [G-19](STORE-RICHTLINIEN.md#g-19), [G-20](STORE-RICHTLINIEN.md#g-20), [A-17](STORE-RICHTLINIEN.md#a-17), [M-18](STORE-RICHTLINIEN.md#m-18), [F-10](STORE-RICHTLINIEN.md#f-10)
- [ ] erledigt

### 17.11 Verzeichnis der Verarbeitungstätigkeiten (Art. 30 DSGVO)

- **Was:** Das ausgefüllte Muster [VERARBEITUNGSVERZEICHNIS.md](VERARBEITUNGSVERZEICHNIS.md) übernehmen, prüfen und als dein eigenes Verzeichnis pflegen. Es listet jeden Datenfluss mit Zweck, Rechtsgrundlage, Empfängern, Drittlandübermittlung und Speicherdauer.
- **Wozu:** Das Verzeichnis ist Pflicht des Verantwortlichen. Aufsichtsbehörden können es anfordern. Es ist die Grundlage für Datenschutzerklärung und Store-Formulare.
- **Wo eintragen:** In deine Unterlagen. Das Muster im Repo bleibt Vorlage, die gepflegte Fassung liegt bei dir.
- **Woher:** Muster im Repo, deine Konfiguration, die AVV aus Schritt 17.3.
- **Prüfschritt:** Jede aktive Zeile ist geprüft und datiert, die Speicherdauern stimmen mit der Datenschutzerklärung überein.
- [ ] erledigt

### 17.12 Datenpanne: Meldeweg (Art. 33 und 34 DSGVO)

- **Was:** Festlegen, wer bei einer Datenpanne entscheidet und meldet. Beispiele: offenes Umami- oder GlitchTip-Konto, geleakter Sentry- oder Firebase-Zugang, kompromittierter Server, Meldung eines Auftragsverarbeiters.
- **Wozu:** Meldung an die Aufsichtsbehörde binnen 72 Stunden ab Kenntnis, wenn ein Risiko für Betroffene besteht (Art. 33). Bei hohem Risiko auch Benachrichtigung der Betroffenen (Art. 34). Jede Panne wird dokumentiert, auch ohne Meldung.
- **Wo eintragen:** Meldewege in [betrieb/INCIDENT.md](betrieb/INCIDENT.md) (Schritt 19.7). Meldung über das Online-Formular der zuständigen Landesdatenschutzbehörde (dieselbe wie `{{AUFSICHTSBEHOERDE_DATENSCHUTZ}}`).
- **Woher:** Ablauf: 1. Vorfall eindämmen (Zugang sperren, Schlüssel tauschen). 2. Verantwortlicher bei LineFM Studios entscheidet mit dem Anwalt über die Meldepflicht. 3. Meldung binnen 72 Stunden. 4. Dokumentation im Vorfallsbericht. Die AVV verpflichten die Anbieter, dir Pannen unverzüglich zu melden.
- **Prüfschritt:** Namen, Vertretung und Behördenformular sind in INCIDENT.md eingetragen.
- [ ] erledigt

### 17.13 Speicherdauern

- **Was:** Für jeden Datenfluss eine Speicherdauer festlegen, im Dienst einstellen und gleichlautend in Datenschutzerklärung, Verarbeitungsverzeichnis und Store-Formularen angeben.

| Daten | Vorschlag | Wo einstellen | Platzhalter |
|---|---|---|---|
| Server-Logs der Web-App | 7 Tage, IP gekürzt | Hoster bzw. nginx/Traefik | `{{LOG_AUFBEWAHRUNG}}` |
| Umami, Sentry/GlitchTip, Firebase | 90 Tage | Einstellungen des jeweiligen Dienstes | `{{TELEMETRIE_AUFBEWAHRUNG}}` |
| GA4 (nur Web) | 2 Monate | GA4 > Verwaltung > Datenaufbewahrung | `{{GA4_AUFBEWAHRUNG}}` |
| Support-E-Mails | bis zur Erledigung, danach gesetzliche Aufbewahrung, falls sie greift | Postfach | in der Datenschutzerklärung prüfen |
| Testerlisten Google | bis Testende | Play Console | entfällt |

- **Wozu:** Google fragt im Formular Datensicherheit, ob und wie Daten gelöscht werden. Abweichende Angaben sind ein Ablehnungsgrund.
- **Wo eintragen:** Siehe Tabelle, Werte in `legal_values.json` bzw. `LEGAL_VALUES_JSON`.
- **Woher:** Die Vorschläge sind Erfahrungswerte, keine Rechtsauskunft. Mit dem Anwalt abstimmen.
- **Prüfschritt:** Einstellung im Dienst, Datenschutzerklärung und Store-Formular nennen dieselbe Dauer.
- Store-Regeln: [G-12](STORE-RICHTLINIEN.md#g-12), [G-31](STORE-RICHTLINIEN.md#g-31), [A-31](STORE-RICHTLINIEN.md#a-31)
- [ ] erledigt

---

## 18. Konten, Kosten und Steuern

Alle Konten laufen auf LineFM Studios als Organisation. Gebühren abgerufen am 26.11.2026 auf den genannten offiziellen Seiten. Steuerliches ist nur eine Vorprüfung. Was davon für dich gilt, klärst du mit deinem Steuerberater.

### 18.1 D-U-N-S-Nummer

- **Was:** Eine D-U-N-S-Nummer für LineFM Studios beantragen oder die vorhandene nachschlagen.
- **Wozu:** Pflicht für das Google-Organisationskonto und das Apple-Organisationskonto, bei Microsoft der schnellere Weg. Name und Anschrift müssen exakt mit Impressum und Handelsregister übereinstimmen.
- **Wo eintragen:** Bei Dun & Bradstreet. Apple bietet eine eigene Suche im Anmeldeablauf.
- **Woher:** kostenlos, laut Google bis zu 30 Tage Bearbeitung (<https://support.google.com/googleplay/android-developer/answer/13628312>, abgerufen 26.11.2026).
- **Prüfschritt:** Die neunstellige Nummer ist im Passwortmanager notiert, der Eintrag zeigt die richtige Anschrift.
- [ ] erledigt

### 18.2 Kontenübersicht

| Konto | Gebühr | Bestätigung | Wer ist Inhaber | Quelle |
|---|---|---|---|---|
| Google Play Console (Organisation) | 25 US-Dollar einmalig | D-U-N-S, Website, Telefon und E-Mail der Organisation, je per Code bestätigt | LineFM Studios | <https://support.google.com/googleplay/android-developer/answer/6112435>, abgerufen 26.11.2026 |
| Apple Developer Program (Organisation) | 99 US-Dollar pro Mitgliedsjahr, in Landeswährung | D-U-N-S, rechtsfähige Organisation (kein reiner Handelsname), Website auf eigener Domain, E-Mail auf der Domain, Apple-Account mit Zwei-Faktor-Anmeldung | LineFM Studios, Account Holder mit Vertretungsmacht | <https://developer.apple.com/programs/enroll/>, abgerufen 26.11.2026 |
| Microsoft Partner Center (Company) | kostenlos | D-U-N-S oder Firmendokumente, E-Mail auf der Firmendomain | LineFM Studios | <https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account>, abgerufen 26.11.2026 |
| Snapcraft (Ubuntu One) | kostenlos (nicht live geprüft) | E-Mail | LineFM Studios | <https://snapcraft.io/> |
| Flathub | kostenlos (nicht live geprüft) | GitHub-Konto, Domain-Bestätigung (Schritt 19.9) | LineFM Studios | <https://docs.flathub.org/> |
| GitHub | kostenlos für öffentliche Repos | Zwei-Faktor-Anmeldung | Tim Hauke (Repo), LineFM Studios als Collaborator | <https://github.com/pricing> (nicht live geprüft) |
| Cloudflare | kostenlose Stufe reicht für Pages und DNS (nicht live geprüft) | E-Mail | LineFM Studios | <https://www.cloudflare.com/plans/> |
| Sentry | kostenlose Stufe vorhanden (nicht live geprüft) | E-Mail | LineFM Studios | <https://sentry.io/pricing/> |
| Firebase | Spark-Tarif kostenlos (nicht live geprüft) | Google-Konto | LineFM Studios | <https://firebase.google.com/pricing> |
| Umami | selbst gehostet kostenlos, Cloud nach Tarif (nicht live geprüft) | eigener Server | LineFM Studios | <https://umami.is/pricing> |
| Domain-Registrar für `linefm.de` | laut Rechnung | Inhaberdaten bei DENIC | LineFM Studios | eigener Vertrag |

- **Was:** Jedes Konto anlegen, das du brauchst, mit einer Funktionsadresse (zum Beispiel `apps@linefm.de`, nicht die private Adresse), Zwei-Faktor-Anmeldung und Notfall-Codes im Passwortmanager. Mindestens zwei Personen mit Admin-Recht je Konto.
- **Wozu:** Verlässt eine Person das Team, bleibt das Konto erreichbar. Fällt ein Konto weg, lässt sich die App bei Google und Apple nicht in ein anderes Konto übernehmen, ohne einen Transfer zu beantragen.
- **Wo eintragen:** Passwortmanager, Spalte "Konto, Inhaber, Zweitadmin, Notfall-Codes, Verlängerung".
- **Woher:** siehe Tabelle.
- **Prüfschritt:** Für jede Zeile sind Inhaber, Zweitadmin und Ablaufdatum der Mitgliedschaft (Apple, Domain) notiert.
- Store-Regeln zu Konten: [D-02](STORE-RICHTLINIEN.md#d-02), [G-25](STORE-RICHTLINIEN.md#g-25), [A-24](STORE-RICHTLINIEN.md#a-24), [M-20](STORE-RICHTLINIEN.md#m-20), [S-07](STORE-RICHTLINIEN.md#s-07), [F-12](STORE-RICHTLINIEN.md#f-12).
- [ ] erledigt

### 18.3 Vereinbarungen, Zahlungs- und Steuerangaben in den Konsolen

- **Was:** Die Vereinbarungen jeder Console annehmen. Zahlungsprofil, Bankverbindung und Steuerformulare sind bei einer kostenlosen App ohne Käufe nach Angaben der Stores nicht nötig. Ausnahme: Als DSA-Händler verlangt Apple Zahlungskontodaten (Schritt 17.5, spätere Apple-Runde).
- **Wozu:** Ohne angenommene Vereinbarung stoppen die Uploads. Apple legt neue Fassungen regelmäßig vor.
- **Wo eintragen:** Play Console > Einstellungen. App Store Connect > Geschäftliches (Vertrag für kostenlose Apps). Partner Center > Konto-Einstellungen.
- **Woher:** Quellen in den Store-Punkten. Fragt eine Console beim Anlegen dennoch Steuerangaben ab (zum Beispiel US-Formular W-8BEN-E), mit dem Steuerberater ausfüllen.
- **Prüfschritt:** Keine Console zeigt einen roten Hinweis zu Vereinbarungen.
- Store-Regeln: [G-28](STORE-RICHTLINIEN.md#g-28), [A-27](STORE-RICHTLINIEN.md#a-27), [M-21](STORE-RICHTLINIEN.md#m-21), [S-07](STORE-RICHTLINIEN.md#s-07)
- [ ] erledigt

### 18.4 Steuerliche Vorprüfung

- **Was:** Kosten der Konten (Google, Apple, Domain, Server) als Betriebsausgaben erfassen. Rechnungen von Google (Irland), Apple (Irland bzw. Luxemburg) und Cloudflare (USA) können unter das Reverse-Charge-Verfahren fallen.
- **Wozu:** Saubere Buchhaltung. Die App erzielt keinen Umsatz, solange sie kostenlos ist und keine Werbung zeigt.
- **Wo eintragen:** Buchhaltung.
- **Woher:** Rechnungen aus den Konsolen. **Das ist keine Steuerberatung, bitte mit dem Steuerberater klären.**
- **Prüfschritt:** Der Steuerberater hat die Einordnung bestätigt.
- [ ] erledigt

---

## 19. Technik und Betrieb

Das Betriebshandbuch mit Deploy, Rollback und Wiederherstellung ist [betrieb/RUNBOOK.md](betrieb/RUNBOOK.md), der Störungsablauf [betrieb/INCIDENT.md](betrieb/INCIDENT.md), die Bedrohungen [betrieb/BEDROHUNGSMODELL.md](betrieb/BEDROHUNGSMODELL.md).

### 19.1 Domains und DNS

- **Was:** Die Domain `linefm.de` mit den Subdomains `app.linefm.de` (Web-App) und `cdn.linefm.de` (Logos) dauerhaft absichern: automatische Verlängerung beim Registrar an, Registrar-Sperre (Transfer Lock) an, DNSSEC an, wenn der DNS-Anbieter es kann.
- **Wozu:** Läuft die Domain aus, fallen Web-App, App-Links (`assetlinks.json`, `apple-app-site-association`), die Flathub-Bestätigung und die Datenschutz-URL in allen Stores gleichzeitig aus. Die Stores können die App dann sperren.
- **Wo eintragen:** Beim Registrar und beim DNS-Anbieter.
- **Woher:** Registrar-Konto (Schritt 18.2).
- **Prüfschritt:** Ablaufdatum im Fristenkalender (Abschnitt 20.5). `dig +dnssec linefm.de` zeigt `ad`, falls DNSSEC aktiv ist.
- [ ] erledigt

### 19.2 Web-Hosting und TLS

- **Was:** Hosting aus Abschnitt 5, Zertifikat aus Schritt 4.2. Verlängerung prüfen: Let's Encrypt erneuert automatisch nach 60 Tagen, Cloudflare ebenfalls.
- **Wozu:** Abgelaufenes Zertifikat heißt: Web-App nicht erreichbar, App-Links ungültig.
- **Wo eintragen:** nichts zusätzlich.
- **Woher:** [betrieb/RUNBOOK.md](betrieb/RUNBOOK.md), Abschnitt "Zertifikate und Domain".
- **Prüfschritt:** Quartalsweise der `openssl`-Befehl aus dem Runbook. Der Uptime-Monitor (Schritt 19.6) meldet Ausfälle.
- [ ] erledigt

### 19.3 Signierschlüssel und ihre Sicherung

- **Was:** Für jeden Schlüssel eine verschlüsselte Sicherung an zwei getrennten Orten anlegen (Passwortmanager plus Offline-Kopie, zum Beispiel verschlüsselter USB-Stick im Tresor).

| Schlüssel | Wofür | Was bei Verlust passiert | Ablauf |
|---|---|---|---|
| Android-Upload-Schlüssel (`upload-keystore.jks`) | jeder Upload zu Google Play, APK auf GitHub | Zurücksetzen über die Play Console möglich, dauert Tage. APK-Nutzer müssen neu installieren | `keytool`-Gültigkeit, Standard im Befehl 10.000 Tage |
| Apple-Zertifikate (Distribution, Mac Installer, Developer ID) | iOS, Mac App Store, DMG | neu ausstellen, alte widerrufen | ein Jahr (Distribution) bzw. fünf Jahre (Developer ID), im Entwicklerportal ablesen |
| Apple-Provisioning-Profile | Export der Apps | neu erzeugen | ein Jahr bzw. mit dem Zertifikat |
| App-Store-Connect-API-Schlüssel (`.p8`) | Upload aus der Pipeline | widerrufen, neu erzeugen; die Datei lässt sich nur einmal herunterladen | kein Ablauf |
| Windows-Codesigning-Zertifikat (PFX) | Installer auf GitHub | neu kaufen, SmartScreen-Ruf beginnt neu | laut Zertifikat |
| MSIX für den Store | signiert Microsoft selbst | entfällt | entfällt |
| Azure-AD-Client-Secret (`MS_STORE_CLIENT_SECRET`) | Einreichung beim Microsoft Store | neu erzeugen | maximal 24 Monate, Datum notieren |
| Snap-Anmeldedaten (`SNAPCRAFT_STORE_CREDENTIALS`) | Upload Snap Store | neu exportieren | laut `snapcraft export-login` |
| Updater-Schlüssel (Ed25519, Secret `UPDATER_ED25519_PRIVATE_KEY` in der Umgebung `release`) | signiert die Update-Hinweise der direkten Downloads (Windows-Setup, macOS-DMG) | Nutzer der direkten Downloads bekommen keine Updates mehr bzw. müssen neu installieren | kein Ablauf |
| GPG-Schlüssel (optional) | `SHA256SUMS.txt.asc` | neuen Schlüssel veröffentlichen | laut Schlüssel |
| SSH-Schlüssel für das Ausrollen | Web-Deploy | neu erzeugen, auf dem Server tauschen | kein Ablauf |

- **Wozu:** Ein verlorener Schlüssel kann Updates für Wochen blockieren.
- **Wo eintragen:** Passwortmanager, Offline-Kopie. In GitHub nur als Secret (Anhang A). Der Updater-Schlüssel kommt als Secret in die geschützte Umgebung `release` (Settings > Environments, mit "Required reviewers"), nicht als normales Repo-Secret. Der Updater ist nach Entscheidung des Inhabers nur in den direkten Downloads aktiv und in allen Store-Builds per Build-Schalter entfernt, eine CI-Prüfung erzwingt das. Name des Secrets: `UPDATER_ED25519_PRIVATE_KEY`, angelegt unter Settings > Environments > `release` > Environment secrets. Den öffentlichen Schlüssel baut der Entwickler in die App ein. **Sicherung und Wechsel:** LineFM Studios ist Eigentümer und verwahrt den privaten Schlüssel (Passwortmanager plus Offline-Kopie). Der Entwickler erzeugt ihn gemeinsam mit dir und tauscht ihn bei Verdacht auf Missbrauch: neuen Schlüssel erzeugen, eine App-Version ausliefern, die übergangsweise beide öffentlichen Schlüssel annimmt, danach den alten löschen. Ohne Verdacht ist kein regelmäßiger Wechsel vorgesehen.
- **Woher:** Die jeweiligen Schritte (6.3, 7.3, 7.4, 8.2, 12.2, 15.3, 15.4, 5.2).
- Store-Regeln: [D-01](STORE-RICHTLINIEN.md#d-01), [A-04](STORE-RICHTLINIEN.md#a-04), [M-02](STORE-RICHTLINIEN.md#m-02), [S-05](STORE-RICHTLINIEN.md#s-05), [F-11](STORE-RICHTLINIEN.md#f-11)
- **Prüfschritt:** Einmal im Jahr eine Sicherung testweise zurückspielen (Fingerabdruck mit `keytool -list -v` bzw. `openssl pkcs12 -info` vergleichen).
- [ ] erledigt

### 19.4 Secrets-Abgleich

- **Was:** Alle Secrets und Variablen aus Anhang A eintragen, soweit du den jeweiligen Kanal nutzt. Anhang A ist vollständig: Jeder Name, den ein Workflow unter `.github/workflows/` liest, steht dort, das prüft der Test aus Schritt 16.2. Details je Wert: [secrets.md](secrets.md).
- **Wozu:** Fehlende Werte lassen Schritte still ausfallen.
- **Wo eintragen:** Schritt 1.3. Werte für `deploy-web.yml` gehören in die Umgebung `production`.
- **Woher:** Anhang A, Spalte "Bezugsquelle".
- **Prüfschritt:** Ein Release-Lauf nennt in der Zusammenfassung keinen fehlenden Namen.
- [ ] erledigt

### 19.5 Release-Ablauf

- **Was:** Ein Release entsteht über ein Tag `vX.Y.Z`. `release.yml` baut alle Plattformen, signiert (Sigstore, Attestierung, optional GPG), hängt die Dateien an das GitHub-Release, dann laden `store-google.yml` (Spur "internal"), `store-microsoft.yml` (Entwurf), `store-snap.yml` (Kanal "edge") und `store-apple.yml` (wenn `APPLE_PUBLISHING_ENABLED` gesetzt ist) hoch, und `deploy-web.yml` rollt das Web nach deiner Freigabe aus. Flathub bekommt ein Update per Änderungsvorschlag (`flathub-prep.yml` bereitet ihn vor).
- **Wozu:** Die Pipelines laden nur hoch. **Die Veröffentlichung in den Stores gibst du selbst frei**: Play Console (Spur hochstufen, gestaffelter Rollout), Partner Center (Einreichung abschicken), Snap (Kanal hochstufen), App Store Connect (zur Prüfung einreichen).
- **Wo eintragen:** nichts. Ablauf: [stores-pipelines.md](stores-pipelines.md), Prüfung: [RELEASE-VERIFIZIEREN.md](RELEASE-VERIFIZIEREN.md).
- **Woher:** entfällt.
- **Prüfschritt:** Vor jeder Freigabe die Freigabe-Checkliste, Abschnitt E, durchgehen. Gestaffelten Rollout bei Google mit 10 bis 20 Prozent beginnen und die Absturzrate beobachten.
- Store-Regeln zu Updates: [D-01](STORE-RICHTLINIEN.md#d-01), [G-23](STORE-RICHTLINIEN.md#g-23), [G-34](STORE-RICHTLINIEN.md#g-34), [A-32](STORE-RICHTLINIEN.md#a-32)
- [ ] erledigt

### 19.6 Überwachung

- **Was:** `uptime.yml` prüft alle 30 Minuten Web-App und laut.fm-Schnittstelle und öffnet bei Ausfall ein Ticket mit dem Label `uptime`. Benachrichtigung einschalten: im Repository oben "Watch" > "Custom" > Tickets.
- **Wozu:** Ohne Benachrichtigung merkt niemand das Ticket. GitHub startet geplante Läufe nicht minutengenau, das ist ein Hinweis, keine Garantie.
- **Wo eintragen:** Variable `WEB_BASE_URL` (Schritt 5.2) aktiviert den Monitor. Zusätzlich ein externer Monitor, weil `uptime.yml` mit GitHub zusammen ausfallen kann. Empfehlung: **UptimeRobot Free**: 50 Monitore, Prüfung alle 5 Minuten, laut Anbieter auch für kommerzielle Projekte (<https://uptimerobot.com/pricing/>, abgerufen 26.11.2026). Alternative Better Stack Free: 10 Monitore, E-Mail-Alarm, aber laut Preisseite nur für private Projekte (<https://betterstack.com/pricing>, abgerufen 26.11.2026), passt daher nicht. Das Konto legt LineFM Studios mit `support@linefm.de` oder einer Betriebsadresse an. Monitore: `https://app.linefm.de/`, `https://app.linefm.de/datenschutz/`, `https://cdn.linefm.de/images/icons/main.png`, `https://api.laut.fm/`. Alarm per E-Mail an mindestens zwei Personen. Ob E-Mail-Alarme im Free-Tarif enthalten sind, zeigt die Preisseite nicht eindeutig, nach dem Anlegen mit einem Testalarm prüfen.
- **Woher:** entfällt.
- **Prüfschritt:** Actions > "Uptime" läuft grün. Im externen Monitor einen Monitor kurz pausieren bzw. auf eine falsche URL stellen: die Alarm-Mail kommt an. Absturzberichte in Sentry, Firebase Crashlytics und Play Console (Android Vitals) einmal pro Woche ansehen.
- [ ] erledigt

### 19.7 Notfallplan

- **Was:** [betrieb/INCIDENT.md](betrieb/INCIDENT.md) lesen und die Meldewege eintragen: wer wird bei Ausfall benachrichtigt, wer entscheidet über Rollback, wer spricht mit Stores und Nutzern. Fälle, die vorbereitet sein müssen: Web-App down, Stream bei laut.fm down, Schlüssel kompromittiert (sofort widerrufen, Secret tauschen, neues Release), Store sperrt die App (Begründung lesen, Einspruch über die Console), Konto-Zugang verloren.
- **Wozu:** Im Ernstfall fehlt sonst die Zeit zum Nachdenken.
- **Wo eintragen:** `docs/betrieb/INCIDENT.md`, Abschnitt "Meldewege" (der Entwickler trägt Namen ein, wenn du sie lieferst).
- **Woher:** Deine Organisation.
- **Prüfschritt:** Einmal im Jahr eine Übung nach dem Abschnitt "Übungen".
- [ ] erledigt

### 19.8 Abhängigkeiten aktuell halten

- **Was:** Dependabot öffnet jeden Montag Änderungsvorschläge für GitHub Actions und Dart-Pakete (`.github/dependabot.yml`, 7 Tage Wartezeit nach Erscheinen). Sicherheitsmeldungen erscheinen im Reiter "Security".
- **Wozu:** Veraltete Pakete heißen Sicherheitslücken und irgendwann Ablehnung in den Stores (Ziel-API, Xcode-Version, Seitengröße 16 KB bei Android).
- **Wo eintragen:** nichts. Wer die Vorschläge prüft und zusammenführt, regelt der Wartungsvertrag (Schritt 2.5).
- **Woher:** entfällt.
- **Prüfschritt:** Monatlich: keine offenen Dependabot-Vorschläge älter als 30 Tage, keine offene kritische Sicherheitsmeldung.
- [ ] erledigt

### 19.9 Aufgaben am Tag des Live-Gangs

- **Was:**
  1. **Flathub-Domainbestätigung:** Die Datei `https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` mit dem Inhalt, den Flathub nach der Aufnahme im Entwicklerportal anzeigt, auf der Hauptdomain ablegen (Schritt 8.1). Ohne Weiterleitung, Typ `text/plain`.
  2. **Brotli auf dem Server:** Für nginx das Modul `ngx_brotli` aktivieren bzw. bei Plesk und Traefik die Kompression laut [hosting-uebersicht.md](hosting-uebersicht.md) einschalten. Cloudflare macht es selbst.
  3. **Telemetrie-Adressen in der Sicherheitsrichtlinie:** Nach dem Setzen von `UMAMI_URL`, `SENTRY_DSN` oder Firebase die Web-App neu bauen und die Server-Header neu ausrollen, sonst blockiert die CSP die Anfragen (Schritt 9.2). Läuft Umami oder GlitchTip auf eigenem Server, dort die Server-Logs auf die in der Datenschutzerklärung genannte Dauer begrenzen und IP-Adressen kürzen bzw. nicht speichern.
  4. Search Console und Sitemap (Schritt 10.1), Vertrauens-Badges (Abschnitt 11).
- **Wozu:** Diese Punkte gehen erst, wenn die Domain live ist.
- **Wo eintragen:** siehe je Punkt.
- **Woher:** Flathub-Portal, Hoster.
- **Prüfschritt:** `curl -sI https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` zeigt 200. `curl -sI -H "Accept-Encoding: br" https://app.linefm.de/main.dart.js | grep -i content-encoding` zeigt `br`. Nach Einwilligung erscheint ein Ereignis in Umami.
- Store-Regeln: [F-04](STORE-RICHTLINIEN.md#f-04), [W-01](STORE-RICHTLINIEN.md#w-01), [W-03](STORE-RICHTLINIEN.md#w-03)
- [ ] erledigt

---

## 20. Support und Pflege

### 20.1 Support-Kontakt und Support-URL

- **Was:** Die Adresse `support@linefm.de` anlegen (macht LineFM Studios) und die Seite `/support/` der Web-App (de: `https://app.linefm.de/support/`, en: `https://app.linefm.de/en/support/`) als Support-URL nutzen. Beides in jedes Support-Feld jedes Stores eintragen.
- **Wozu:** Google verlangt eine Kontakt-E-Mail, Apple eine Support-URL, Microsoft Support-Kontaktdaten. Fehlende oder tote Kontakte sind ein häufiger Ablehnungsgrund.
- **Wo eintragen:** Play Console > Store-Präsenz > Kontaktdaten. App Store Connect > App-Informationen > Support-URL. Partner Center > Store-Eintrag. Flathub-Metainfo (`<url type="contact">` und `<url type="support">`, der Entwickler trägt sie ein). Snap: Dashboard und Snap-Metadaten (Kontakt, Website).
- **Woher:** Entscheidung des Inhabers. Antwortzeit festlegen (Empfehlung: zwei Werktage). Apple-Felder trägst du erst in der späteren Apple-Runde ein.
- **Prüfschritt:** Testmail an die Adresse kommt an, die URL antwortet mit 200.
- Store-Regeln: [G-29](STORE-RICHTLINIEN.md#g-29), [A-28](STORE-RICHTLINIEN.md#a-28), [M-22](STORE-RICHTLINIEN.md#m-22), [S-08](STORE-RICHTLINIEN.md#s-08), [F-13](STORE-RICHTLINIEN.md#f-13), [W-05](STORE-RICHTLINIEN.md#w-05)
- [ ] erledigt

### 20.2 Bewertungen beantworten

- **Was:** Bewertungen in Google Play, App Store und Microsoft Store wöchentlich lesen und sachlich beantworten. Fehlerberichte daraus als Ticket im Repo anlegen.
- **Wozu:** Antworten verbessern die Bewertung und zeigen den Stores, dass die App gepflegt ist.
- **Wo eintragen:** Play Console > Bewertungen, App Store Connect > Bewertungen, Partner Center > Rezensionen.
- **Woher:** entfällt. Keine Bewertungen kaufen oder gegen Vorteile tauschen, das verbieten alle Stores.
- **Prüfschritt:** Keine Bewertung mit Fehlerbeschreibung bleibt länger als eine Woche unbeantwortet.
- [ ] erledigt

### 20.3 Meldung von Sicherheitslücken

- **Was:** Meldungen kommen über das GitHub-Formular aus `SECURITY.md` und `web/.well-known/security.txt` (Schritt 3.3). Benachrichtigung für "Security alerts" einschalten.
- **Wozu:** Wer eine Lücke findet, braucht einen vertraulichen Weg. Die Datei `security.txt` hat ein Ablaufdatum (`Expires: 2027-05-19`) und muss vorher erneuert werden.
- **Wo eintragen:** GitHub > Settings > Notifications. Erneuerung von `security.txt` macht der Entwickler.
- **Woher:** entfällt.
- **Prüfschritt:** `https://app.linefm.de/.well-known/security.txt` zeigt ein `Expires` in der Zukunft.
- [ ] erledigt

### 20.4 Monatliche Prüfung der Store-Richtlinien

- **Was:** Ein geplanter Workflow prüft monatlich alle in [STORE-RICHTLINIEN.md](STORE-RICHTLINIEN.md) verlinkten Richtlinienseiten auf Erreichbarkeit und Änderungen und öffnet bei Änderung ein Ticket. Das Ticket trägt das Label `store-policy`. **Zuständig:** Der Entwickler liest es binnen fünf Werktagen, fasst die Änderung zusammen und weist es dir zu, wenn du in einer Console handeln musst. Nennt der Store eine kürzere Frist, gilt sie.
- **Wozu:** Stores ändern ihre Regeln ohne Vorwarnung, oft mit kurzen Fristen.
- **Wo eintragen:** Benachrichtigung für Tickets (Schritt 19.6) reicht.
- **Woher:** entfällt.
- **Prüfschritt:** Jeden Monat ein grüner Lauf oder ein bearbeitetes Ticket.
- [ ] erledigt

### 20.5 Fristenkalender

Trag diese Termine mit Erinnerung vier Wochen vorher in einen gemeinsamen Kalender ein.

| Wann | Was | Wer | Quelle |
|---|---|---|---|
| jährlich, Stichtag bisher 31. August | Google Play: neue Apps und Updates müssen die aktuelle Ziel-API haben. Seit 31.08.2026 Android 16 (API 36), Verlängerung auf Antrag bis 01.11.2026 | Entwickler | <https://developer.android.com/google/play/requirements/target-sdk>, abgerufen 26.11.2026; [G-11](STORE-RICHTLINIEN.md#g-11), [G-34](STORE-RICHTLINIEN.md#g-34) |
| jährlich, meist Frühjahr (ab der Apple-Runde) | Apple: Uploads nur mit aktuellem Xcode. Seit 28.04.2026 Xcode 26 mit iOS-26-SDK | Entwickler | <https://developer.apple.com/news/upcoming-requirements/>, abgerufen 26.11.2026; [A-18](STORE-RICHTLINIEN.md#a-18), [A-32](STORE-RICHTLINIEN.md#a-32) |
| jährlich zum Beitrittsdatum (ab der Apple-Runde) | Apple-Mitgliedschaft verlängern (99 US-Dollar), sonst verschwinden die Apps aus dem Store | LineFM Studios | <https://developer.apple.com/programs/enroll/>; [A-26](STORE-RICHTLINIEN.md#a-26) |
| jährlich (ab der Apple-Runde) | Apple-Distribution-Zertifikat und Profile erneuern | Entwickler | Entwicklerportal |
| laut Datum | Developer-ID-Zertifikat, Windows-Zertifikat, Azure-Client-Secret, Snap-Anmeldedaten erneuern | LineFM Studios und Entwickler | Schritt 19.3 |
| jährlich laut Registrar | Domain `linefm.de` verlängern | LineFM Studios | Registrar |
| jährlich und bei Aufforderung | Play-Erklärungen erneut bestätigen: Datensicherheit, Vordergrunddienst, Vollbild-Intent, Zielgruppe | LineFM Studios | [G-34](STORE-RICHTLINIEN.md#g-34) |
| bei Aufforderung (ab der Apple-Runde) | neue Apple-Vereinbarungen annehmen, sonst stoppen die Uploads | LineFM Studios | [A-27](STORE-RICHTLINIEN.md#a-27) |
| spätestens 19.05.2027, dann halbjährlich | `security.txt` erneuern | Entwickler | Schritt 20.3 |
| monatlich | Store-Richtlinien-Prüfung, Dependabot, Sicherheitsmeldungen | Entwickler | Schritte 19.8, 20.4 |
| quartalsweise | TLS-Ablauf, laut.fm-Schnittstelle, Wiederherstellungsübung | Entwickler | [betrieb/RUNBOOK.md](betrieb/RUNBOOK.md) |
| jährlich | DPF-Status der US-Anbieter, AVV noch gültig, Datenschutzerklärung und Store-Formulare abgleichen, Altersfragebögen (Apple fragt bei neuen Systemen nach) | LineFM Studios | Schritte 17.2, 17.3 |
| jährlich | Wiederherstellung einer Schlüsselsicherung testen, Notfallübung | beide | Schritte 19.3, 19.7 |

- [ ] Kalender angelegt

### 20.6 Ablehnungen und Sperren

- **Was:** Lehnt ein Store ab oder sperrt die App: Begründung lesen, Ursache beheben, neu einreichen. Hältst du die Ablehnung für falsch, Einspruch einlegen: Play Console über "Richtlinienstatus", Apple über das App Review Board (spätere Apple-Runde), Microsoft über den Einspruchsweg der Zertifizierung, Snap und Flathub im jeweiligen Forum bzw. in der Einreichung.
- **Wozu:** Wiederholte Verstöße können bei Google zur Kontosperre führen. Schnelle, sachliche Antworten verkürzen die Prüfung.
- **Wo eintragen:** in der jeweiligen Console. Ticket im Repo mit Meldung und Screenshot, ohne Passwörter.
- **Woher:** Der Entwickler hilft bei der Ursache.
- **Prüfschritt:** Jede Ablehnung hat ein Ticket mit Ergebnis.
- Store-Regeln: [G-33](STORE-RICHTLINIEN.md#g-33), [A-30](STORE-RICHTLINIEN.md#a-30), [M-23](STORE-RICHTLINIEN.md#m-23)
- [ ] verstanden

---

## Anhang A: Alle Secrets und Variablen

Art: S = Secret, V = Variable. "Pflicht" heißt: ohne den Wert fehlt die Funktion, die in der Spalte "Ziel" steht. Ausführliche Herkunft: [secrets.md](secrets.md).

| Name | Art | Ziel | Bezugsquelle | Schritt |
|---|---|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | S | Google Play | selbst erzeugte `upload-keystore.jks` als Base64 | 6.3 |
| `ANDROID_KEYSTORE_PASSWORD` | S | Google Play | beim Erzeugen vergeben | 6.3 |
| `ANDROID_KEY_ALIAS` | S | Google Play | beim Erzeugen vergeben | 6.3 |
| `ANDROID_KEY_PASSWORD` | S | Google Play | beim Erzeugen vergeben | 6.3 |
| `PLAY_SERVICE_ACCOUNT_JSON` | S | Google Play | Google Cloud Console, Dienstkonto | 6.4 |
| `BUILD_NUMBER_OFFSET` | V | Google Play | Zahl, nur bei Bedarf, Standard 100 | 6.4 |
| `ANDROID_CERT_SHA256` | V | App-Links Android | Play Console, App-Integrität, plus Upload-Schlüssel | 6.9 |
| `MS_STORE_TENANT_ID` | S | Microsoft Store | Azure AD, Verzeichnis-ID | 7.3 |
| `MS_STORE_SELLER_ID` | S | Microsoft Store | Partner Center, Organisationsprofil | 7.3 |
| `MS_STORE_CLIENT_ID` | S | Microsoft Store | Azure-AD-Anwendung | 7.3 |
| `MS_STORE_CLIENT_SECRET` | S | Microsoft Store | Azure-AD-Anwendung | 7.3 |
| `MS_STORE_PRODUCT_ID` | V | Microsoft Store | Partner Center, Produktidentität | 7.2 |
| `MS_STORE_IDENTITY_NAME` | V | Microsoft Store | Partner Center, Produktidentität | 7.2 |
| `MS_STORE_PUBLISHER` | V | Microsoft Store | Partner Center, Produktidentität | 7.2 |
| `MS_STORE_PUBLISHER_DISPLAY_NAME` | V | Microsoft Store | Partner Center, Produktidentität | 7.2 |
| `WINDOWS_CERT_PFX_BASE64` | S | Windows-Installer (optional) | Zertifikatsanbieter | 7.4 |
| `WINDOWS_CERT_PASSWORD` | S | Windows-Installer (optional) | Zertifikatsanbieter | 7.4 |
| `SNAPCRAFT_STORE_CREDENTIALS` | S | Snap Store | `snapcraft export-login` | 8.2 |
| `APPLE_PUBLISHING_ENABLED` | V | Apple | `true`, erst wenn alles vorliegt | 15.6 |
| `APPLE_TEAM_ID` | S | Apple, AASA-Datei | Apple Developer, Mitgliedschaft | 15.1 |
| `APP_STORE_CONNECT_API_KEY_ID` | S | Apple | App Store Connect | 15.3 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | S | Apple | App Store Connect | 15.3 |
| `APP_STORE_CONNECT_API_KEY_P8` | S | Apple | App Store Connect | 15.3 |
| `APPLE_DISTRIBUTION_CERT_P12_BASE64` | S | Apple | Entwicklerportal, Schlüsselbund | 15.4 |
| `APPLE_DISTRIBUTION_CERT_PASSWORD` | S | Apple | beim Export vergeben | 15.4 |
| `APPLE_MAC_INSTALLER_CERT_P12_BASE64` | S | Apple (Mac-Store) | Entwicklerportal, Schlüsselbund | 15.4 |
| `APPLE_MAC_INSTALLER_CERT_PASSWORD` | S | Apple (Mac-Store) | beim Export vergeben | 15.4 |
| `APPLE_IOS_PROVISIONING_PROFILES_BASE64` | S | Apple | Entwicklerportal | 15.4 |
| `APPLE_MACOS_PROVISIONING_PROFILE_BASE64` | S | Apple | Entwicklerportal | 15.4 |
| `APPLE_DEVELOPER_ID_CERT_P12_BASE64` | S | Apple (DMG) | Entwicklerportal, Schlüsselbund | 15.4 |
| `APPLE_DEVELOPER_ID_CERT_PASSWORD` | S | Apple (DMG) | beim Export vergeben | 15.4 |
| `CLOUDFLARE_API_TOKEN` | S | Web: Cloudflare Pages | Cloudflare, Mein Profil, API-Tokens | 5.2 |
| `CLOUDFLARE_ACCOUNT_ID` | S | Web: Cloudflare Pages | Cloudflare, Dashboard | 5.2 |
| `CLOUDFLARE_PAGES_PROJECT` | V | Web: Cloudflare Pages | `linefm-app` | 5.2 |
| `DEPLOY_HOST` | S | Web: eigener Server | Server | 5.2 |
| `DEPLOY_USER` | S | Web: eigener Server | Server | 5.2 |
| `DEPLOY_SSH_KEY` | S | Web: eigener Server | `ssh-keygen -t ed25519` | 5.2 |
| `DEPLOY_KNOWN_HOSTS` | S | Web: eigener Server | `ssh-keyscan -t ed25519 <host>` | 5.2 |
| `DEPLOY_PATH` | V | Web: eigener Server | Zielordner, zum Beispiel `/var/www/linefm-app` | 5.2 |
| `DEPLOY_PORT` | V | Web: eigener Server | SSH-Port, Standard 22 | 5.2 |
| `DEPLOY_RELOAD_COMMAND` | V | Web: eigener Server | Befehl nach dem Umschalten | 5.2 |
| `PLESK_SSH_HOST` | S | Web: Plesk | Plesk-Server | 5.2 |
| `PLESK_SSH_USER` | S | Web: Plesk | Systembenutzer des Abonnements | 5.2 |
| `PLESK_SSH_KEY` | S | Web: Plesk | `ssh-keygen -t ed25519` | 5.2 |
| `PLESK_SSH_KNOWN_HOSTS` | S | Web: Plesk | `ssh-keyscan -t ed25519 <host>` | 5.2 |
| `PLESK_DOCROOT` | V | Web: Plesk | zum Beispiel `httpdocs` | 5.2 |
| `PLESK_SSH_PORT` | V | Web: Plesk | SSH-Port, Standard 22 | 5.2 |
| `WEB_DEPLOY_TARGETS` | V | Web (alle Ziele) | `cloudflare`, `ssh`, `plesk` | 5.2 |
| `WEB_BASE_URL` | V | Web | `https://app.linefm.de` | 5.2 |
| `LEGAL_VALUES_JSON` | V | Rechtstexte | JSON mit den Platzhaltern (Anhang B) | 3.1 |
| `UMAMI_URL` | V | Telemetrie | Umami-Instanz | 9.2 |
| `UMAMI_WEBSITE_ID` | V | Telemetrie | Umami, Website-Einstellungen | 9.2 |
| `SENTRY_DSN` | V | Telemetrie | GlitchTip oder Sentry, Projekt | 9.2 |
| `SENTRY_ENVIRONMENT` | V | Telemetrie | zum Beispiel `production` | 9.2 |
| `FIREBASE_CONFIG_JSON` | S | Telemetrie (optional) | Firebase, Web-App-Konfiguration | 9.2 |
| `GSC_VERIFICATION` | V | Search Console | Search Console, "HTML-Tag" | 10.1 |
| `GTM_ID` | V | GTM (Web) | tagmanager.google.com, Container | 10.2 |
| `PAGESPEED_API_KEY` | S | Web quality gate (pages.yml), optional; without it Lighthouse runs on the runner | console.cloud.google.com, API key restricted to PageSpeed Insights API | docs/PERFORMANCE.md |
| `FEATURES_JSON` | V | Funktionsschalter (`showListenerCount`), Standard alles aus, siehe [Konfiguration](KONFIGURATION.md) | z. B. `{"showListenerCount": true}` | – |
| `GA4_MEASUREMENT_ID` | V | GA4 (Web) | analytics.google.com, Datenstreams | 10.2 |
| `TRUST_GRIDINSOFT_URL` | V | Vertrauens-Badge | Profil bei Gridinsoft | 11.1 |
| `TRUST_TRUSTPILOT_URL` | V | Vertrauens-Badge | Profil bei Trustpilot | 11.2 |
| `GPG_PRIVATE_KEY` | S | Signierte Releases (optional) | `gpg --armor --export-secret-keys <ID>` | 12.2 |
| `NVD_API_KEY` | S | OWASP dependency-check im Workflow `dast.yml` (optional, ohne Schlüssel wird der Job übersprungen) | kostenloser Schlüssel von nvd.nist.gov/developers/request-an-api-key | – |
| `UPDATER_ED25519_PRIVATE_KEY` | S (Umgebung `release`) | Updater der direkten Downloads (Windows-Setup, macOS-DMG), nie in Store-Builds | selbst erzeugter Ed25519-Schlüssel, Befehl liefert der Entwickler | 19.3 |
| `GPG_PASSPHRASE` | S | Signierte Releases (optional) | beim Erzeugen vergeben | 12.2 |
| `SCORECARD_TOKEN` | S | OpenSSF Scorecard (optional) | GitHub, Fine-grained token | 12.3 |
| `CODE_SCANNING_ENABLED` | V | CodeQL (optional) | `true` | 12.3 |

## Anhang B: Alle Platzhalter

Du schreibst die Werte in `legal_values.json` bzw. die Variable `LEGAL_VALUES_JSON` (Schritt 3.1), sofern in der Spalte "Ort" nichts anderes steht. "Pflicht" laut `assets/legal/placeholders.json`. Nicht zutreffende Angaben als `"Nicht zutreffend."` eintragen.

| Platzhalter | Pflicht | Ort im Repo | Zweck |
|---|---|---|---|
| `{{BETREIBER_NAME}}` | ja | Impressum, Datenschutz | Name des Betreibers (§ 5 DDG) |
| `{{BETREIBER_RECHTSFORM}}` | ja | Impressum, Datenschutz | Rechtsform |
| `{{BETREIBER_STRASSE}}` | ja | Impressum, Datenschutz | ladungsfähige Anschrift, kein Postfach |
| `{{BETREIBER_PLZ_ORT}}` | ja | Impressum, Datenschutz | PLZ und Ort |
| `{{BETREIBER_VERTRETER}}` | ja | Impressum | vertretungsberechtigte Person |
| `{{BETREIBER_EMAIL}}` | ja | Impressum, Datenschutz | Kontakt und Datenschutzanfragen |
| `{{BETREIBER_TELEFON}}` | ja | Impressum | zweiter schneller Kontaktweg |
| `{{REGISTERGERICHT}}` | nein | Impressum | falls eingetragen |
| `{{REGISTERNUMMER}}` | nein | Impressum | falls eingetragen |
| `{{USTID}}` | nein | Impressum | USt-IdNr. oder Wirtschafts-IdNr., falls vorhanden |
| `{{AUFSICHTSBEHOERDE_MEDIEN}}` | ja | Impressum | zuständige Medienanstalt, falls zulassungspflichtig (Bagatellrundfunk prüfen lassen) |
| `{{VERANTWORTLICHER_MSTV}}` | ja | Impressum | verantwortliche Person nach § 18 Abs. 2 MStV |
| `{{DATENSCHUTZBEAUFTRAGTER}}` | ja | Datenschutz | Name und Kontakt oder Hinweis, dass keiner benannt werden muss |
| `{{AUFSICHTSBEHOERDE_DATENSCHUTZ}}` | ja | Datenschutz | Landesdatenschutzbehörde nach Sitz |
| `{{HOSTING_ANBIETER}}` | ja | Datenschutz | Hoster der Web-Version |
| `{{CDN_ANBIETER}}` | ja | Datenschutz | Betreiber von `cdn.linefm.de` |
| `{{LOG_AUFBEWAHRUNG}}` | ja | Datenschutz | Speicherdauer der Server-Protokolle, zum Beispiel 7 Tage |
| `{{TELEMETRIE_AUFBEWAHRUNG}}` | nur mit Telemetrie | Datenschutz | Speicherdauer der Statistik- und Fehlerdaten |
| `{{UMAMI_BETREIBER}}` | nur mit Umami | Datenschutz | Betreiber der Umami-Instanz |
| `{{SENTRY_BETREIBER}}` | nur mit Sentry oder GlitchTip | Datenschutz | Betreiber der Instanz |
| `{{GA4_AUFBEWAHRUNG}}` | nur mit `GTM_ID` oder `GA4_MEASUREMENT_ID` | Datenschutz | Speicherdauer der GA4-Daten, wie in GA4 > Verwaltung > Datenaufbewahrung eingestellt, zum Beispiel 2 Monate |
| `{{BARRIEREFREIHEIT_KONTAKT}}` | ja | `docs/BARRIEREFREIHEIT.md` | Kontakt für Barrieren, direkt in der Datei eintragen |
| `{{BARRIEREFREIHEIT_ANTWORTFRIST}}` | ja | `docs/BARRIEREFREIHEIT.md` | Antwortfrist, direkt in der Datei eintragen |
| `{{SCHLICHTUNGS_BZW_MARKTUEBERWACHUNGSSTELLE}}` | ja | `docs/BARRIEREFREIHEIT.md` | zuständige Beschwerdestelle, anwaltlich prüfen |
| `{{SECURITY_KONTAKT}}` | erledigt | `SECURITY.md`, `CODE_OF_CONDUCT.md`, `web/.well-known/security.txt` | ersetzt durch das GitHub-Meldeformular (Schritt 3.3) |
| `{{ANDROID_CERT_SHA256}}` | über Variable | `web/.well-known/assetlinks.json` | wird beim Web-Build aus `ANDROID_CERT_SHA256` gefüllt (Schritt 6.9) |
| `{{APPLE_TEAM_ID}}` | über Secret | `web/.well-known/apple-app-site-association`, `packaging/ios/ExportOptions-*.plist.template` | wird aus `APPLE_TEAM_ID` gefüllt (Schritt 15.1) |
| `{{PROVISIONING_PROFILE_APPSTORE_NAME}}` | Apple-Start | `packaging/ios/ExportOptions-appstore.plist.template` | Profilname für den Export, füllt der Entwickler (Schritt 15.5) |
| `{{PROVISIONING_PROFILE_ADHOC_NAME}}` | Apple-Start | `packaging/ios/ExportOptions-adhoc.plist.template` | Profilname für den Ad-hoc-Export, füllt der Entwickler (Schritt 15.5) |
