# Einrichtung für jaybelife

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

- Passwörter, Schlüssel und Tokens (geheime Zugangscodes) gehören **nie** in eine E-Mail, einen Chat oder ein Issue. Sie kommen als Secret in die GitHub-Einstellungen des Repos (Schritt 1.3) oder in deinen Passwortmanager.
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

Abschnitt 2 zuerst anstoßen, weil Antworten von Dritten am längsten dauern. Die Abschnitte 6 bis 8 laufen parallel.

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
- Details und die Spalte "Wer" (jaybelife oder Entwickler) stehen in [secrets.md](secrets.md). Den Zusammenhang der Abläufe erklärt [stores-pipelines.md](stores-pipelines.md).
- [ ] erledigt

### 1.4 Schriftliche Zustimmung zur Veröffentlichung des Quellcodes

- **Was:** Das Repository ist seit dem 19.11.2026 öffentlich. Die Lizenz bleibt proprietär (alle Rechte vorbehalten). Du bestätigst schriftlich, dass der Quellcode öffentlich sichtbar sein darf.
- **Wozu:** Jeder kann den Code lesen, aber nicht frei nutzen. Das muss mit dem Rechteinhaber der Marke und der App geklärt sein, bevor Dritte darauf bauen.
- **Wo eintragen:** schriftlich (E-Mail oder Eintrag im Issue reicht). Abschnitt A7 der [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) abhaken.
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
- **Woher:** laut.fm fragen (Adresse laut Freigabe-Checkliste: `team@laut.fm`, vor Gebrauch prüfen). GEMA und GVL fragst du mit der Frage, ob die Nutzung als App-Wiedergabe unter die Verträge von laut.fm fällt.
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

- **Was:** Nutzung des RadioGruppe-Logos bestätigen. Es wird wie in der Web-App von `radiogruppe.de` geladen. Der Hinweis "Ein Angebot von RadioGruppe Deutschland" bleibt, die Formulierung "offizielle App der RadioGruppe" nicht, solange du sie nicht bestätigst.
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

- **Was:** Schriftlich regeln, wer die Rechte am Code hat und was jaybelife damit tun darf (Weiterentwicklung durch Dritte, Weitergabe, Übergabe des Repos). Tim Hauke (VectoDE) hat die App unentgeltlich für jaybelife entwickelt. Marke, Logos und App-Icon gehören jaybelife.
- **Wozu:** Der Code steht unter "Alle Rechte vorbehalten". Ohne Vertrag bleibt unklar, wer ihn nutzen darf. Flathub und andere Stores verlangen außerdem eine ausdrückliche Erlaubnis zur Weitergabe (Schritt 8.1).
- **Wo eintragen:** Abschnitt A6 der Freigabe-Checkliste.
- **Woher:** Vertrag zwischen jaybelife und Tim Hauke, anwaltlich geprüft.
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

- **Was:** Konto anlegen, 25 US-Dollar einmalig zahlen, Identität bestätigen (Ausweis, Adresse, Telefon). Tim Hauke als Nutzer einladen (Nutzer und Berechtigungen > Neue Nutzer einladen, mit App-Rechten für Veröffentlichung).
- **Wozu:** Ohne Konto keine Veröffentlichung. Google verlangt die Identität auch für sideloadbare APKs ab 2027 (Entwicklerverifizierung).
- **Wo eintragen:** <https://play.google.com/console/signup>.
- **Woher:** Kreditkarte, Ausweis. Ein **privates** Konto braucht für die Erstveröffentlichung einen geschlossenen Test mit mindestens 12 Testern über mindestens 14 Tage (Schritt 6.8). Ein Organisationskonto mit D-U-N-S-Nummer braucht das nicht. Die Regel ändert Google gelegentlich, vor dem Start prüfen.
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

- **Was:** Play Console > Richtlinie > App-Inhalte. Datenschutzerklärung-URL `https://app.linefm.de/datenschutz/`, Werbung "Keine Werbung", Zielgruppe (nicht für Kinder), Inhaltseinstufung per Fragebogen, Kontaktdaten der Store-Seite, Behördenapp "nein", Finanzfunktionen "nein", Gesundheit "nein".
- **Wozu:** Alles muss ausgefüllt sein, sonst blockiert Google die Veröffentlichung.
- **Wo eintragen:** Play Console, App-Inhalte.
- **Woher:** Hinweise: Der Sender +RAP kann Kraftausdrücke senden, im Fragebogen ehrlich angeben. Die Werbe-ID wird nicht verwendet. Das Manifest entfernt `com.google.android.gms.permission.AD_ID` per `tools:node="remove"`. Nach dem Release-Build mit `aapt dump permissions app-release.apk` nachsehen, ob sie fehlt. Sonst müsste "Werbe-ID: ja" stehen. Die Antworten zu Datensicherheit stehen in Abschnitt 13.
- **Prüfschritt:** Alle Punkte unter App-Inhalte zeigen einen grünen Haken.
- [ ] erledigt

### 6.6 Deklarationen: Vordergrunddienst und Vollbild-Benachrichtigung

- **Was:** Zwei Erklärungen in der Play Console abgeben: Vordergrunddienst-Typ `mediaPlayback` (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`) und `USE_FULL_SCREEN_INTENT` für den Radiowecker. Exakte Alarme (`SCHEDULE_EXACT_ALARM`) fragt die App beim Wecker selbst beim Nutzer ab, die App nutzt bewusst nicht `USE_EXACT_ALARM`.
- **Wozu:** Google lässt Apps mit Zielversion Android 14 oder höher ohne diese Erklärung nicht durch. Bei der Vollbild-Berechtigung gilt: Standardmäßig bekommen sie nur Anruf- und Wecker-Apps. **Risiko:** Bei einer Radio-App kann Google die Erklärung ablehnen. Dann entfernt der Entwickler die Berechtigung, und der Wecker meldet sich ohne Vollbild. Das stimmst du mit dem Entwickler ab.
- **Wo eintragen:** Play Console > Richtlinie > App-Inhalte > "Vordergrunddienste" und "Vollbild-Benachrichtigungen" (genauen Menünamen vor Ort prüfen).
- **Woher:** Fertige Texte auf Deutsch und Englisch, die Felder der Console und das Skript für das Demo-Video stehen in [STORE-TEXTE.md](STORE-TEXTE.md), Abschnitt "Play-Console-Deklarationen". Das Video nimmst du selbst auf (Hinweise dort).
- **Prüfschritt:** Beide Deklarationen zeigen den Status "Abgeschickt" bzw. "Genehmigt". Entscheidung zum Umgang mit einer Ablehnung ist festgehalten (Freigabe-Checkliste, Abschnitt C).
- [ ] erledigt

### 6.7 Store-Eintrag

- **Was:** Kurz- (80 Zeichen) und Langbeschreibung auf Deutsch und Englisch, Grafiken, Kategorie "Musik & Audio".
- **Wozu:** Das sieht jeder im Store.
- **Wo eintragen:** Play Console > Store-Präsenz. Texte aus [STORE-TEXTE.md](STORE-TEXTE.md). Icon 512 x 512 liegt in `assets/branding/play_store_512.png`. Weiteres in Abschnitt 14.
- **Woher:** STORE-TEXTE.md, Abschnitt "Google Play".
- **Prüfschritt:** Die Vorschau der Store-Seite zeigt alle Felder ohne Fehler.
- [ ] erledigt

### 6.8 Geschlossener Test (nur privates Konto)

- **Was:** Testspur "Geschlossener Test" anlegen, Release hochladen, mindestens 12 Tester per E-Mail-Liste oder Google-Gruppe eintragen, 14 Tage laufen lassen, dann "Zugriff auf Produktion beantragen".
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

---

## 7. Microsoft Partner Center (Windows-Store)

Quelle: [packaging/windows/README.md](../packaging/windows/README.md).

### 7.1 Konto und App-Name

- **Was:** Als Einzelentwickler registrieren (kostenlos, Identitätsprüfung), Namen "LINEFM Radio" reservieren.
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

- **Was:** Beschreibung, 300 x 300-Logo, mindestens ein Screenshot, Altersfreigabe, Datenschutz-URL.
- **Wo eintragen:** Partner Center. Texte aus [STORE-TEXTE.md](STORE-TEXTE.md), Abschnitt "Microsoft Store".
- **Wozu / Woher:** Sichtbar im Store. Datenschutz-URL `https://app.linefm.de/datenschutz/`.
- **Prüfschritt:** Die Einreichung zeigt keine offenen Pflichtfelder.
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
  4. Einreichung per Pull Request gegen `flathub/flathub`. Der Entwickler bereitet ihn vor. Du reichst mit deinem GitHub-Konto ein oder gibst Tim Hauke die Vollmacht.
- **Woher:** Inhalt der Verifizierungsdatei von Flathub.
- **Prüfschritt:** `curl -s https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` liefert den Inhalt. Flathub bestätigt die Verifizierung.
- **Ehrlicher Hinweis:** Unser Paket enthält die fertig gebaute Binärdatei, nicht den Quelltext. Flathub verlangt bei nicht offener Software meist den Bau aus dem Quelltext oder besondere Regeln. Es kann sein, dass Flathub ablehnt oder eine Ausnahme verlangt. Das klärst du nur durch Nachfragen bei den Flathub-Betreuern (Issue im Repo `flathub/flathub`). Scheitert es, bleiben Snap Store und der Tarball auf GitHub.
- [ ] erledigt

### 8.2 Snap Store

- **Was:** Konto anlegen, Snap-Namen `linefm-radio` registrieren, Zugangsdaten für die Pipeline erzeugen.
- **Wozu:** `store-snap.yml` lädt jedes Release in den Kanal "edge".
- **Wo eintragen:** Secret `SNAPCRAFT_STORE_CREDENTIALS`.
- **Woher:** Konto auf <https://snapcraft.io/> (Ubuntu One). Name per `snapcraft register linefm-radio`. Zugangsdaten per `snapcraft export-login`, der volle Befehl steht in [secrets.md](secrets.md). Sie laufen ab, dann wiederholen.
- **Prüfschritt:** Nach einem Release erscheint die Version im Kanal "edge". Dann "candidate" und "stable". Ob die Tray-Funktion unter der strikten Snap-Absicherung läuft, ist noch ungetestet.
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
- **Wo eintragen:** Variablen `UMAMI_URL`, `UMAMI_WEBSITE_ID`, `SENTRY_DSN`, `SENTRY_ENVIRONMENT`. Für Firebase Secret `FIREBASE_CONFIG_JSON` (JSON mit `FIREBASE_*`-Schlüsseln). Lokal: `config/app.json` nach Vorlage `config/app.example.json`, nicht einchecken.
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
- **Woher:** Das Profil legst **du** (jaybelife) bei Gridinsoft an. Das Ergebnis muss echt sein. Ohne Eintrag erscheint kein Badge.
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
- **Prüfschritt:** Die Antworten stimmen mit Abschnitt 7 und 11 der Datenschutzerklärung überein.
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
- [ ] erledigt

### 13.4 Apple App-Privacy (später)

- **Was:** "App-Datenschutz" (Privacy Nutrition Label) in App Store Connect.
- **Wozu:** Apple verlangt es vor der Einreichung.
- **Wo eintragen:** App Store Connect > App-Datenschutz. Erst mit Schritt 15.
- **Woher:** Gleiche Fakten wie bei Google. Apples Fragebogen im Zweifel vor Ort lesen.
- **Prüfschritt:** Der Status ist "Veröffentlicht".
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

iOS, macOS, CarPlay und AirPlay sind im Code vorbereitet. Wenn du Apple später aktivieren willst:

### 15.1 Konto und Team-ID

- **Was:** Apple Developer Program beitreten (99 US-Dollar pro Jahr, für eine Firma wird eine D-U-N-S-Nummer verlangt). Team-ID notieren.
- **Wozu:** Grundlage für alles Weitere.
- **Wo eintragen:** Secret `APPLE_TEAM_ID`. Außerdem steht der Name als `{{APPLE_TEAM_ID}}` in `packaging/ios/ExportOptions-*.plist.template` und in `web/.well-known/apple-app-site-association`. Das Skript und der Web-Postbuild setzen ihn aus dem Secret ein.
- **Woher:** <https://developer.apple.com/programs/>, Account > Mitgliedschaft, 10 Zeichen.
- **Prüfschritt:** Die ID ist 10 Zeichen lang und im Secret hinterlegt.
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

- Frag im Repo unter Issues oder Discussions nach. Beschreibe, welchen Schritt du gerade machst und was du siehst.
- Bei Fehlermeldungen von Stores: Meldung kopieren, Screenshot anhängen, keine Passwörter.
- Zeitaufwand der Prüfungen einplanen: Google Play einige Tage, CarPlay-Antrag Wochen, Flathub je nach Betreuern.

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
| `GA4_MEASUREMENT_ID` | V | GA4 (Web) | analytics.google.com, Datenstreams | 10.2 |
| `TRUST_GRIDINSOFT_URL` | V | Vertrauens-Badge | Profil bei Gridinsoft | 11.1 |
| `TRUST_TRUSTPILOT_URL` | V | Vertrauens-Badge | Profil bei Trustpilot | 11.2 |
| `GPG_PRIVATE_KEY` | S | Signierte Releases (optional) | `gpg --armor --export-secret-keys <ID>` | 12.2 |
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
| `{{APP_AUFTRAGGEBER}}` | ja | Impressum | für wen die App entwickelt wurde, Schreibweise gibt der Inhaber vor |
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
