# Einrichtung für LineFM Studios

Diese Liste enthält alles, was du als Betreiber wissen, besorgen und eintragen musst, damit LINEFM Radio in den Stores und im Web erscheint und einwandfrei läuft. Alles andere ist vorbereitet. Du brauchst kein Programmierwissen. Wo ein Entwickler etwas tun muss, steht es dabei.

Die App selbst bauen, herunterladen und öffnen, ohne den Entwickler zu fragen: [BAUEN-UND-STARTEN.md](BAUEN-UND-STARTEN.md).

**Kurz gesagt:** Du legst Konten an, klickst dich durch Formulare der Stores, trägst Passwörter und Namen an einer Stelle auf GitHub ein und holst schriftliche Zustimmungen ein. Alles, was Befehle braucht, macht der Entwickler. Fang bei Abschnitt 1 an und arbeite die Tabelle "Arbeitsreihenfolge" weiter unten von oben nach unten ab. Unbekannte Wörter stehen in der Tabelle "Die wichtigsten Begriffe".

## So liest du diese Liste

Jeder Schritt hat eine Nummer (zum Beispiel 6.4) und diese sechs Angaben:

- **Was:** die Aufgabe.
- **Wozu:** was ohne den Schritt fehlt oder nicht geht.
- **Wo eintragen:** der genaue Ort, mit Link oder Menüpfad.
- **Woher:** wo du den Wert bekommst.
- **Prüfschritt:** woran du erkennst, dass es funktioniert.
- **Wenn es nicht klappt:** die häufigsten Ursachen und was du dann tust.

Menüpfade schreiben wir so: `Settings > Secrets and variables > Actions` heißt: erst auf "Settings" klicken, dann links auf "Secrets and variables", dann auf "Actions". GitHub, Cloudflare und Microsoft zeigen ihre Menüs oft auf Englisch, auch wenn du Deutsch eingestellt hast. Dort stehen deshalb die englischen Namen. Auch bei Google nennen wir die englischen Namen, weil die Google-Dokumentation nur sie nennt. Deutsche Entsprechungen sind meist ähnlich und bei Bedarf selbst zu erkennen (nicht geprüft).

**Hinweis zu Prüfschritten vor Version 1.0.0:** Einige Prüfungen (Microsoft Store, Webseite ausrollen) gehen erst mit Version 1.0.0. Dann gilt der Schritt vorerst als erledigt, wenn alle Namen eingetragen sind. Den Haken setzt du erst nach dem ersten Release ab 1.0.0, wenn die Prüfung wirklich gelaufen ist. Das gilt für **alle** Store-Abläufe und das Ausrollen der Webseite, nicht nur für Microsoft: Vor 1.0.0 startest du sie bei Bedarf von Hand (Schritt 1.5), um deine Einträge zu testen. Steht ein Schritt nicht in deinem Umfang (zum Beispiel ein optionaler Dienst, den du bewusst nicht nutzt), schreibe "entfällt" daneben und hake ihn ab. Die Haken pflegt am Ende der Entwickler im Repository, du meldest den Stand per Mail. **Zwei Stände:** "eingetragen" (alle Werte sind gesetzt) genügt, damit die Version vorankommt. "Geprüft" (der Ablauf lief grün) kommt danach. Für die Versionsnummer 1.0.0 zählen nur offene Aufgaben für dich, nicht Apple-Schritte, nicht "entfällt"-Schritte und nicht die Prüfungen, die erst nach 1.0.0 möglich sind.

**Wann laufen die automatischen Abläufe?** Jede Änderung auf dem Hauptzweig `main` erzeugt automatisch eine neue Version auf GitHub (Ablauf "Release"). Solange die Version einen Zusatz wie `-alpha`, `-beta` oder `-rc` trägt, ist sie nur eine Vorabversion auf GitHub. Die Stores und das Ausrollen der Webseite starten automatisch erst ab Version 1.0.0. Diese Version entsteht von selbst: Der Ablauf zählt die Version bei jeder Änderung hoch, vergibt `-beta`, wenn keine Funktionswünsche mehr offen sind, `-rc`, wenn nur noch Aufgaben für LineFM Studios offen sind, und `1.0.0`, wenn gar nichts mehr offen ist. Du löst sie nicht aus, du kannst sie nur durch das Erledigen deiner offenen Aufgaben möglich machen. "Offen" heißt: Es gibt noch Tickets im Repository, die diese Aufgaben beschreiben. Den aktuellen Stand erklärt dir der Entwickler. Apple zählt nicht zum ersten Umfang (Abschnitt 15). Vorher kannst du einige Abläufe von Hand anstoßen, um deine Einträge zu testen (Schritt 1.5).

Wichtig vorab:

- Passwörter, Schlüssel und Tokens (geheime Zugangscodes) gehören **nie** in eine E-Mail, einen Chat oder ein Ticket. Sie kommen als Secret in die GitHub-Einstellungen des Repos (Schritt 1.3) oder in deinen Passwortmanager.
- Ein **Secret** ist ein geheimer Wert, den GitHub speichert und danach nie wieder anzeigt. Eine **Variable** ist ein nicht geheimer Wert, der lesbar bleibt. Beides legst du im Repo an (Schritt 1.3).
- **CI** (Continuous Integration) heißt hier: GitHub baut, prüft und lädt die App automatisch hoch. Eine **Pipeline** oder ein **Workflow** ist so ein automatischer Ablauf. Ein **Release** ist eine veröffentlichte Version.
- Fehlt ein **optionales** Secret, wird der betroffene Schritt übersprungen oder baut unsigniert. Fehlen **Pflichtangaben** (zum Beispiel die Rechtstexte aus Schritt 3.1 oder die Signierschlüssel für die Stores), bricht der betroffene Ablauf mit einer klaren Meldung ab. Die Zusammenfassung des Laufs nennt den fehlenden Namen, nie den Wert.
- Erst die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) abarbeiten, dann veröffentlichen.
- Preise und Formulare der Anbieter ändern sich. Die Angaben stammen aus unserer Recherche vom November 2026. Im Zweifel gilt, was der Anbieter gerade anzeigt. Wo wir etwas nicht belegen konnten, steht "prüfen".
- **Anwalt:** Alles Rechtliche in dieser Anleitung ist eine Vorprüfung und ersetzt weder Anwalt noch Steuerberater. Sammle die offenen Rechtsfragen und lass sie in einem Termin prüfen. Die Sammelliste steht in Anhang D, die Einzelthemen in Abschnitt 17. Wo ein Schritt davon abhängt, steht kurz "(Anwalt)". Einen passenden Anwalt findest du über die Rechtsanwaltskammer deines Bezirks oder über eine Empfehlung aus deinem Netzwerk, achte auf Erfahrung mit IT-, Medien- und Datenschutzrecht.
- Apple ist **nicht Teil der ersten Veröffentlichung**. Der Code ist vorbereitet, Abschnitt 15 beschreibt, was später nötig ist.

Haken setzen, sobald ein Schritt erledigt und geprüft ist. Die Haken setzt du in deiner eigenen Kopie dieser Seite (Datei aus dem Repository herunterladen, in einem Texteditor öffnen und `[ ]` durch `[x]` ersetzen) oder schickst dem Entwickler eine kurze Mail ("6.4 erledigt"), er trägt es ein. Es gibt je Schritt einen Haken. Bei Dauerpflichten (19.x, 20.x) sind es zwei: "eingerichtet" und "regelmäßig erledigt". Anhang D ist nur deine Kurzliste und enthält je Eintrag einen eigenen Haken, der Haken im Schritt bleibt der maßgebliche. Er gilt, wenn alles eingetragen **und** geprüft ist. Prüfungen, die erst ab Version 1.0.0 gehen, bleiben bis dahin offen.

**Haken und Tickets, ein Beispiel:** Schritt 6.4 hat zwei Teile, Dienstkonto anlegen (du) und Test-Upload (Pipeline). Hast du beides erledigt und der Entwurf liegt in der Spur "internal", setzt du den Haken bei 6.4. Tickets (die Aufgabenliste des Entwicklers auf GitHub) sind etwas anderes als deine Haken: Ein Ticket gilt erst als erledigt, wenn dein Haken gesetzt ist **und** die automatische Prüfung grün ist. Die Haken in dieser Datei sind deine Sicht, die Tickets seine.

**Wer:** Jeder Schritt nennt in der Zeile "Wer", wer handelt. *Betreiber* bist du, *Entwickler* und *Repo-Eigentümer* ist Tim Hauke (Eigentümer darf zusätzlich Umgebungen und Repo-Einstellungen ändern). Dateien wandern immer so: Der Entwickler liefert sie als Download oder per Mail, du gibst Zugangsdaten und Passwörter nie weiter, sondern trägst Secrets selbst ein.

**Wer macht was:** Steht bei einem Schritt **[Entwickler]**, brauchst du dafür keine Befehle einzugeben. Der Entwickler (Tim Hauke) erledigt das mit dir zusammen. Alles andere klickst du selbst im Browser. Steht in einem Schritt ein Befehl für die Kommandozeile (zum Beispiel `keytool`, `dig`, `curl`, `snapcraft`, `docker`, `gpg`, `openssl`, `gh`, `base64`), gib ihn nicht selbst ein, sondern gib den Schritt an den Entwickler weiter. Ausnahme sind einfache Prüfbefehle, bei denen die Windows-Schreibweise direkt dabeisteht (`nslookup`, `Get-FileHash`, `curl.exe`). Für DNS- und Zertifikatsprüfungen gibt es Browser-Alternativen, sie stehen bei den Schritten.

**Windows:** Wo ein Schritt einen Befehl mit `grep` oder `dig` zeigt, gilt unter Windows PowerShell: `curl.exe -sI <Adresse> | Select-String <Wort>` statt `curl ... | grep -i <Wort>` (`curl.exe` mit Endung, sonst startet PowerShell einen anderen Befehl), `Resolve-DnsName <Name>` statt `dig`. Im Browser gehen für Zertifikate <https://www.ssllabs.com/ssltest/> und für Antwort-Kopfzeilen die Entwicklerwerkzeuge des Browsers (Reiter "Netzwerk"). Die Windows-Schreibweisen haben wir nicht auf deinem Rechner geprüft.

**Rollen:** *Du* (Betreiber) bist LineFM Studios, die Person, die diese Anleitung abarbeitet. *Entwickler* und *Repository-Eigentümer* ist Tim Hauke. Mit *Inhaber* ist in den Schritten dieselbe Person gemeint wie du (der Betreiber). *Kunde* meint dein Unternehmen als Auftraggeber der App, also dich. Die Vereinbarung mit laut.fm hast du bereits und behältst sie selbst (Schritte 2.1, 17.7). Die Konten (Google, Microsoft und weitere) sind Organisationskonten deines Unternehmens. Name und Rechtsform des Konto-Inhabers trägst du in Schritt 1.6 ein, wir raten sie nicht. *LINEFM Gruppe* und *RadioGruppe* sind die Sender-Partner im Umfeld von LineFM Studios, ihre Zustimmung holst du selbst ein (Schritte 2.2, 2.3). *Verantwortlicher* im Sinne des Medienstaatsvertrags und der Datenschutz-Grundverordnung ist die Person oder Firma, die du in Schritt 3.1 benennst (in der Regel du als Geschäftsführung von LineFM Studios). Die *zweite Person* (Zweitadmin, Vertretung) ist jemand aus deinem Unternehmen, den du benennst (Schritt 18.2). Fällt im Text eine andere Rolle, steht sie mit Namen dabei.

**Die wichtigsten Begriffe:**

| Begriff | Bedeutung |
|---|---|
| Telemetrie | Statistik und Absturzberichte der App, nur nach Einwilligung (Abschnitt 9) |
| noindex | Anweisung an Suchmaschinen, die Seite noch nicht aufzunehmen |
| Property | ein Eintrag in der Google Search Console oder in Google Analytics für eine Webseite |
| DNSSEC | Signatur für DNS-Einträge, schützt vor gefälschten Antworten |
| ETag | Kennung einer Datei, mit der der Browser unnötige Downloads spart |
| Collaborator | eine Person mit eingeschränktem Zugriff auf ein Repository, sie wird per E-Mail eingeladen |
| Environment (Umgebung) | ein geschützter Bereich im Repository für Secrets, den nur der Eigentümer anlegen darf |
| Tenant (Verzeichnis) | das Firmenverzeichnis bei Microsoft (Entra), in dem Anwendungen und Nutzer liegen |
| Keystore | Datei mit dem Signaturschlüssel der Android-App |
| AAB, APK | Paketformate der Android-App (AAB für Google Play, APK zum direkten Installieren) |
| MSIX | Paketformat der Windows-App |
| CNAME, A, AAAA, TXT | Arten von DNS-Einträgen, die du beim Domain-Anbieter einträgst |
| CORS, CSP | Browser-Regeln, die festlegen, welche Webseiten Daten laden dürfen |
| CDN | Server, der Dateien (hier die Sender-Logos) schnell ausliefert |
| SHA-256-Fingerabdruck | eine Prüfsumme, mit der Android erkennt, dass eine App echt ist |
| IARC, OARS | Fragebögen, aus denen die Stores die Altersfreigabe berechnen |
| Metainfo | Beschreibungsdatei der Linux-App für Flathub |
| Sigstore | Dienst, der Releases kryptografisch signiert |
| GitHub | Webseite, auf der der Code der App liegt und automatisch gebaut wird |
| Repository (Repo) | der Projektordner der App auf GitHub: <https://github.com/VectoDE/linefm-radio-app> |
| `main` | die gültige Fassung des Codes im Repository |
| Release | eine fertige Version mit Nummer, zum Beispiel `v0.1.0-alpha.15` |
| Ablauf (Workflow) | ein automatischer Vorgang auf GitHub, zum Beispiel "App bauen" oder "in den Play Store laden" |
| Secret | geheimer Wert (Passwort, Schlüssel), den GitHub nach dem Speichern nie wieder anzeigt |
| Variable | nicht geheimer Wert, der lesbar bleibt |
| Token | ein langes Passwort für Programme statt für Menschen |
| Base64 | eine Datei, umgewandelt in eine lange Textzeile, damit sie in ein Textfeld passt |
| DNS | das Telefonbuch des Internets: ordnet `app.linefm.de` einem Server zu |
| AVV | Vertrag zur Auftragsverarbeitung nach Art. 28 DSGVO |
| API, SDK | Schnittstelle bzw. Baukasten, über den Programme miteinander oder mit einem Dienst sprechen |
| JSON | einfaches Textformat für Einstellungen und Daten, Datei endet auf `.json` |
| PNG, JPEG, SVG | Bildformate (SVG ist eine Vektorgrafik, die beliebig skaliert) |
| EXE, DMG | Installationsdateien für Windows (EXE) und macOS (DMG) |
| CI | automatische Prüfung und Bauen auf GitHub bei jeder Änderung |
| TLS, HSTS | Verschlüsselung der Verbindung (das Schloss im Browser) bzw. die Anweisung, nur noch verschlüsselt zu verbinden |
| SSH | verschlüsselter Fernzugang zu einem Server, mit dem der Entwickler dort arbeitet |
| Docker, nginx, Traefik, Plesk | Software auf dem Server: Docker verpackt Programme, nginx und Traefik leiten Web-Anfragen weiter, Plesk ist eine Verwaltungsoberfläche vieler Hoster |
| authorized_keys | Datei auf dem Server, in der steht, welche Schlüssel sich anmelden dürfen |
| Staging | eine Testumgebung vor dem echten Betrieb |
| Service Worker | Skript im Browser, das die Web-App offline nutzbar macht und Dateien zwischenspeichert |
| Port 80 | der Eingang für unverschlüsselte Web-Anfragen, wird nur zum Umleiten auf HTTPS gebraucht |
| Registrar, Transfer Lock | Firma, bei der die Domain registriert ist, bzw. die Sperre gegen ungewollten Umzug der Domain |
| DENIC | die zentrale Registrierungsstelle für `.de`-Domains |
| CAA | DNS-Eintrag, der festlegt, welche Stellen Zertifikate für die Domain ausstellen dürfen |
| Brotli, Header | Brotli ist eine Komprimierung für schnelleres Laden, Header sind Zusatzangaben im Web-Verkehr |
| DAST | Sicherheitstest, der die laufende Web-App von außen angreift (nur gegen eigene Systeme) |
| Dependabot, Scorecard, CodeQL | GitHub-Werkzeuge: melden veraltete Bausteine, bewerten die Projektsicherheit und suchen Fehler im Code |
| NVD, OSV | öffentliche Datenbanken bekannter Sicherheitslücken |
| OWASP | Organisation, die gängige Sicherheitsregeln für Web-Apps veröffentlicht |
| DSN | Adresse, an die die App Absturzberichte schickt |
| Sentry, GlitchTip, Firebase, Umami | Telemetrie-Dienste: Sentry und GlitchTip sammeln Absturzberichte, Firebase Crashlytics ebenfalls (von Google), Umami zählt Nutzung ohne Cookies. In dieser Anleitung heißt die Absturzberichte-Lösung "Sentry" (GlitchTip ist der kompatible Ersatz) |
| Consent Mode v2 | Google-Verfahren, bei dem Tags erst nach deiner Einwilligungsabfrage Daten senden |
| GA4, GTM | Google Analytics 4 (Besucherstatistik) und Google Tag Manager (Verwaltung der Messcodes) |
| GEMA, GVL | Verwertungsgesellschaften, die Musikrechte (GEMA) bzw. Leistungsschutzrechte (GVL) verwalten |
| MStV, Bagatellrundfunk | Medienstaatsvertrag der Länder, und die Ausnahme für kleine Angebote, die keine Rundfunklizenz brauchen |
| DDG, TDDDG, BFSG | Gesetze: Impressumspflicht (DDG), Datenschutz bei Cookies und Endgeräten (TDDDG), Barrierefreiheit (BFSG) |
| DSA, Händlerstatus | EU-Gesetz über digitale Dienste. Im Store musst du erklären, ob du als Händler (Trader) auftrittst |
| DPF | Datenschutzabkommen EU-USA, Grundlage für Datenübermittlung an US-Anbieter |
| FSM, JMStV | Selbstkontrolle für Medien bzw. Staatsvertrag zum Jugendmedienschutz |
| KI | künstliche Intelligenz |
| Dienstkonto, IAM | technisches Konto bei Google Cloud für Programme (Dienstkonto) und dessen Rechteverwaltung (IAM) |
| Spur (Track), Entwurf | Veröffentlichungsstufe in Google Play (internal, closed, production) bzw. noch nicht abgeschickte Einreichung |
| DHU | Desktop Head Unit, Testprogramm für Android Auto am Rechner |
| SmartScreen, PFX | Windows-Schutz, der unbekannte Installer warnt, bzw. Datei mit Zertifikat und Schlüssel |
| PEM, CSR, RSA | Dateiformat für Schlüssel, Zertifikatsanfrage und Verschlüsselungsverfahren |
| ADB, NDK | Werkzeuge der Android-Entwicklung (Verbindung zum Gerät bzw. Baukasten für Maschinencode) |
| GPL, LGPL | Open-Source-Lizenzen mit Pflichten bei Weitergabe |
| DPMA, EUIPO | Markenämter (Deutschland bzw. EU) |
| AASA | Datei `apple-app-site-association`, die Apple-Links der Domain freigibt |
| KB | Kilobyte, hier die Seitengröße (16-KB-Seiten) bei Android |
| Tickets | Einträge in der Fehler- und Aufgabenliste des Repositorys auf GitHub |
| Tag (Versionsmarke), Branch (Zweig) | Marke für eine Version im Code (zum Beispiel `v1.0.0`) bzw. eine Arbeitslinie des Codes. `main` ist der Hauptzweig |
| Platzhalter, Generator | Platzhalter sind Stellen wie `{{BETREIBER_NAME}}`, die durch deinen Wert ersetzt werden. Der Generator ist das Programm des Entwicklers, das daraus die Webseiten und Texte baut |
| Änderungsvorschlag, forken, klonen, committen | Entwicklerwörter: ein Vorschlag, Code zu ändern, eine Kopie eines fremden Repositorys anlegen, ein Repository herunterladen, Änderungen speichern. Das macht der Entwickler |
| versionCode, Manifest, Postbuild | Laufende Nummer jeder Android-Version, Steckbrief-Datei der App, Arbeitsschritt nach dem Bauen der Web-App. Entwicklerthemen |
| Zielversion (Ziel-API), Vordergrunddienst, Vollbild-Intent, Werbe-ID | Android-Begriffe: Android-Version, auf die die App ausgelegt ist; Dienst, der im Hintergrund Ton spielt; Vollbild-Benachrichtigung (Wecker); Geräte-Kennung für Werbung. In der Play Console gibst du Erklärungen dazu ab |
| App-Bundle | anderes Wort für die AAB-Datei |
| Sitemap, robots.txt, Meta-Tag, `<head>` | Seitenverzeichnis für Suchmaschinen, Datei mit Zugangsregeln für Suchmaschinen, unsichtbarer Hinweis im Kopf einer Webseite, Kopfbereich der Webseite |
| Let's Encrypt, Certbot | kostenlose Zertifikatsstelle bzw. das Programm, das ihre Zertifikate automatisch erneuert |
| Kanal edge, candidate, stable | Stufen im Snap Store von Test (edge) bis öffentlich (stable) |
| GPG, cosign, Attestierung | Verfahren, Dateien kryptografisch zu unterschreiben und die Herkunft nachzuweisen |
| Semgrep, Trivy, zizmor, Code Scanning, Branch-Protection, Fine-grained Token | Sicherheitswerkzeuge und GitHub-Funktionen, die der Entwickler betreibt: Code-Prüfer, Schwachstellen-Scanner, Schutzregeln für den Hauptzweig, Token mit eng begrenzten Rechten |
| gestaffelter Rollout, Managed Publishing | Veröffentlichung zuerst für einen Teil der Nutzer bzw. Freigabe erst auf deinen Klick |
| msstore, Client-Secret, Globaler Administrator (das bist du mit dem Konto aus Schritt 7.1) | Kommandozeile für den Microsoft Store, Passwort einer registrierten Anwendung, Rolle mit allen Rechten im Microsoft-Verzeichnis |
| TalkBack, VoiceOver, NVDA, Tray | Screenreader (Android, Apple, Windows) bzw. das Symbol der App im Infobereich der Taskleiste |
| DS-Daten, Registry Lock | Signatur-Daten für DNSSEC beim Domain-Anbieter, bzw. zusätzliche Sperre gegen Änderungen an der Domain |
| Bundle-ID, Provisioning Profile, Xcode, Account Holder | Apple-Begriffe (spätere Runde): Kennung der App, Datei mit Installationsrechten, Entwicklungsprogramm auf dem Mac, Hauptverantwortlicher des Apple-Kontos |
| Deploy (Ausrollen), Rollback | die Web-Version auf den Server bringen bzw. auf die vorige Version zurückgehen |
| Runner, Lighthouse, Label | der GitHub-Rechner, auf dem ein Ablauf läuft; Qualitätsmessung einer Webseite; Markierung an einem Ticket (zum Beispiel `uptime`) |
| Subdomain | Unteradresse einer Domain, zum Beispiel `app.linefm.de` |
| Maintainer, Linter, Tarball, `extra-data` | Entwicklerbegriffe aus der Flathub-Einreichung: Betreuer der App bei Flathub (der Entwickler), automatische Formprüfung, gepacktes Archiv, Verfahren für fremde Download-Dateien |
| Ubuntu One | Anmeldedienst von Canonical, den der Snap Store für sein Konto nutzt |
| hybride Signierung, Play App Signing | Google verwaltet den App-Schlüssel, du hältst nur den Upload-Schlüssel |
| Android Vitals | Auswertung von Abstürzen und Ruckeln in der Play Console |
| Reverse-Charge | Steuerschuld liegt beim Empfänger, steht auf Rechnungen von Google und Apple aus Irland |
| Container (GTM), Datenstream (GA4) | Sammelordner für Messcodes im Tag Manager bzw. die Messquelle einer Webseite in Google Analytics |
| Netzwerkmitschnitt | Browser-Entwicklertools (Taste F12) > Reiter "Netzwerk": zeigt, welche Server die Seite anfragt |
| Lauf | ein einzelner Durchgang eines automatischen Ablaufs, mit grünem Haken oder rotem Kreuz |
| Merge, Commit | Merge: eine geprüfte Änderung wird in die Hauptlinie `main` übernommen. Commit: ein gespeicherter Änderungsstand im Repository |
| Terminal | ein Fenster, in das man Befehle tippt (unter Windows PowerShell). Du brauchst es für diese Liste nicht, es ist für den Entwickler |
| Play Console | Verwaltungsoberfläche von Google, in der du die Android-App einreichst und verwaltest |
| Partner Center | Verwaltungsoberfläche von Microsoft, in der du die Windows-App einreichst und verwaltest |
| Flathub, Snap Store | Zwei Linux-App-Läden. Dort liegt die Linux-Fassung der App |
| Paket-ID (`de.linefm.app`) | Eindeutiger Name der App in den Stores. Nach dem ersten Upload bei Google lässt er sich nicht mehr ändern |
| Cloud-Projekt | Sammelort bei Google Cloud, in dem das Dienstkonto für den automatischen Upload angelegt wird |
| Codesigning-Zertifikat | Digitaler Ausweis, mit dem ein Windows-Installer unterschrieben wird, damit Windows ihn weniger oft warnt |
| Formfaktor | Gerätetyp, für den Screenshots gemacht werden, zum Beispiel Handy, Tablet oder Desktop |
| Feature-Grafik | Breites Bild (1024 x 500 Pixel) oben im Google-Play-Eintrag der App |
| Alpha-Kanal, Transparenz | Teil eines Bildes, der durchsichtig ist. Manche Stores verbieten ihn in Icons |
| libmpv | Abspiel-Baustein, den die Windows- und Linux-App nutzt, um Streams zu spielen. Hat eine eigene Lizenz |
| Medienanstalt | Landesbehörde, die Rundfunk und rundfunkähnliche Angebote beaufsichtigt und prüft, ob eine Zulassung nötig ist |
| Instanz | Eine laufende Installation eines Dienstes, zum Beispiel dein eigener Umami- oder Sentry-Server |
| Freigabesperre | Regel in der Freigabe-Checkliste: Solange eine Voraussetzung fehlt (zum Beispiel ein unterschriebener Vertrag), wird nichts freigegeben |
| Upload-Schlüssel | Schlüssel, mit dem du Uploads zu Google Play unterschreibst. Google verwaltet den eigentlichen App-Schlüssel selbst |
| Verwertungsgesellschaft | Organisation, die Rechte von Urhebern einsammelt und Gebühren verteilt (hier GEMA und GVL) |
| Anwendung (App-Registrierung) in Entra | Eintrag im Microsoft-Verzeichnis, über den die automatische Einreichung zum Microsoft Store zugreift. Hat ein Client-Secret als Passwort |
| Verifizierungsdatei (`.well-known`) | Kleine Datei in einem festen Ordner der Domain, mit der du gegenüber Flathub, Google oder Apple beweist, dass die Domain dir gehört |
| Zwei-Faktor-Anmeldung (2FA) | zweite Sicherung beim Einloggen, zum Beispiel ein Code aus einer App auf dem Handy, zusätzlich zum Passwort |
| Vorabversion (Prerelease) | eine Version, die nur zum Testen gedacht ist (erkennbar an `-alpha`, `-beta`, `-rc`), sie erscheint nicht in den Stores |
| "Run workflow" | der grüne Knopf auf GitHub, mit dem du einen automatischen Ablauf von Hand startest |
| GitHub Pages | kostenloser Webauftritt von GitHub, hier nur die Entwicklerseite, nicht die echte Web-App |
| SonarCloud, Snyk | zwei Prüfdienste für Code-Qualität und unsichere Bibliotheken, Abläufe liegen bereit (Schritt 12.6) |
| Open Source (FLOSS) | Software, deren Quelltext jeder nutzen und weitergeben darf, LINEFM Radio ist das nicht |
| Docker Compose | Datei, die beschreibt, welche Docker-Programme zusammen auf dem Server starten |
| TXT-Eintrag | DNS-Eintrag mit einem Text, mit dem du gegenüber Google oder anderen beweist, dass dir die Domain gehört. Er sieht bei Google so aus: `google-site-verification=...` |
| Badge | kleines Siegel-Bild mit Status, zum Beispiel in der README oder im Footer der Webseite |
| TrustBox | Bewertungs-Baustein von Trustpilot, den man in eine Webseite einbaut |
| Asset | eine Datei, die zu einer Version gehört, zum Beispiel der Installer auf der Release-Seite |
| Open-Graph-Bild | Vorschaubild, das erscheint, wenn jemand einen Link der Webseite teilt |
| Emulator | Programm, das ein Handy am Rechner nachahmt, damit man die App ohne echtes Gerät testen kann |
| Notarisierung | Prüfung durch Apple, ohne die macOS-Programme außerhalb des App Stores nur mit Warnung starten (spätere Runde) |
| Gatekeeper | Schutzfunktion von macOS, die nicht geprüfte Programme blockiert |
| Universal Links | Apple-Verfahren, bei dem Links der Domain direkt die App öffnen (siehe AASA) |
| `.p12`, `.p8` | Dateiformate für Apple-Schlüssel und Zertifikate, geheim zu halten (spätere Runde) |
| Alt-Text | kurze Bildbeschreibung für Screenreader und für den Fall, dass das Bild nicht lädt |
| Autoplay | Ton oder Video startet von selbst. Bei Radio-Apps in Stores und im Auto streng geregelt |
| Cast, Chromecast | Übertragen des Radiotons vom Handy auf einen Lautsprecher oder Fernseher im Netzwerk |
| OpenSSF | Stiftung für Open-Source-Sicherheit, vergibt die Scorecard-Bewertung und das Best-Practices-Badge |
| Aufsichtsbehörde (Datenschutz) | Landesbehörde, die die Einhaltung des Datenschutzes überwacht und bei Datenpannen gemeldet wird. Zuständig ist das Bundesland, in dem LineFM Studios sitzt |
| Auftragsverarbeiter | Dienstleister, der in deinem Auftrag Daten verarbeitet (zum Beispiel Hoster, Sentry, Umami). Mit jedem schließt du einen AVV |
| Azure AD (Entra) | Älterer Name des Microsoft-Verzeichnisdienstes, in dem die Zugangsdaten für den Microsoft Store liegen. Siehe auch "Tenant" am Anfang |
| Betriebshandbuch (Runbook) | Die Datei [betrieb/RUNBOOK.md](betrieb/RUNBOOK.md) mit den Abläufen für Betrieb, Ausrollen und Wiederherstellung. Sie ist für den Entwickler, du bekommst die Ergebnisse |
| Cloudflare Pages | Hosting-Dienst von Cloudflare für die Web-App, eine der drei Möglichkeiten in Abschnitt 5 |
| Console, Konsole | Verwaltungsoberfläche eines Stores im Browser: Play Console (Google), App Store Connect (Apple), Partner Center (Microsoft) |
| Data Processing Addendum | Englischer Name für den Auftragsverarbeitungsvertrag (AVV) |
| Datenpanne | Unbefugte kommen an Daten, oder Daten gehen verloren. Meldefrist an die Aufsichtsbehörde: 72 Stunden ab Kenntnis (Schritt 17.12) |
| Drittland | Land außerhalb der EU und des EWR. Datenübermittlung dorthin braucht eine eigene Grundlage, bei den USA zum Beispiel das DPF |
| Dun & Bradstreet, D-U-N-S-Nummer | Auskunftei bzw. die neunstellige Firmenkennnummer, die Google, Apple und Microsoft für Organisationskonten verlangen (Schritt 18.1) |
| Ed25519 | Art des Signierschlüssels für den Updater der direkten Downloads. Das Erzeugen ist Sache des Entwicklers |
| Einwilligung (Consent) | Zustimmung der Nutzer, zum Beispiel zu Statistik und Absturzberichten. Ohne sie dürfen diese Dienste nicht laufen |
| Fingerabdruck (eines Schlüssels) | Kurze Prüfsumme, mit der man erkennt, ob zwei Schlüssel identisch sind, ohne den Schlüssel selbst zu zeigen |
| Funktionsadresse, Verteiler | E-Mail-Adresse für eine Aufgabe statt für eine Person (zum Beispiel `support@linefm.de`), bzw. Adresse, die an mehrere Personen weiterleitet |
| Handelsregister, Rechtsform, Rechtsträger | Amtliches Firmenverzeichnis; Form des Unternehmens (zum Beispiel GmbH); die Firma als rechtliche Person mit ihrem exakten Namen, nicht der Markenname |
| Hoster | Firma, die den Server betreibt, auf dem die Web-App liegt |
| Impressum, ladungsfähige Anschrift | Pflichtseite mit den Angaben zum Betreiber; Hausanschrift, an der man dir Post zustellen kann (kein Postfach) |
| IP-Adresse (gekürzt) | Kennung eines Geräts im Netz. Gekürzt heißt: der hintere Teil wird abgeschnitten, damit sie sich schwerer einer Person zuordnen lässt |
| Jugendschutzbeauftragter | Benannte Person im Unternehmen, die zu Jugendschutz berät. Ob du eine brauchst, klärt der Anwalt (Schritt 17.10) |
| Kleinstunternehmen | Unternehmen mit weniger als 10 Beschäftigten und höchstens 2 Millionen Euro Jahresumsatz oder höchstens 2 Millionen Euro Jahresbilanzsumme (§ 2 Nr. 17 BFSG, <https://www.gesetze-im-internet.de/bfsg/__2.html>, abgerufen 27.11.2026). Für sie gelten beim BFSG Ausnahmen |
| Notfall-Codes | Ersatz-Codes für die Anmeldung, wenn das Handy für die Zwei-Faktor-Anmeldung nicht verfügbar ist. Gehören in den Passwortmanager |
| Offline-Kopie | Sicherung auf einem Datenträger, der nicht am Internet hängt, zum Beispiel verschlüsselter USB-Stick im Tresor |
| Passwortmanager | Programm, das Passwörter und Schlüssel verschlüsselt speichert. Hier liegen auch Verträge und Notfall-Codes |
| personenbezogene Daten | Alle Daten, die sich einer Person zuordnen lassen, auch IP-Adressen und Geräte-Kennungen |
| Preload (HSTS) | Eintrag in einer Liste der Browser, damit sie die Domain nur noch verschlüsselt aufrufen. Nur sinnvoll, wenn alle Subdomains HTTPS haben |
| Prüfsummen-Datei (`SHA256SUMS.txt`) | Liste mit Prüfsummen der Release-Dateien, damit du erkennst, ob eine Datei unverändert ist |
| security.txt | Kleine Textdatei auf der Web-App, die Sicherheitsforschern sagt, wie sie dich erreichen. Hat ein Ablaufdatum (Schritt 20.3) |
| Signierschlüssel, Upload-Schlüssel | Geheimer Schlüssel, mit dem eine App unterschrieben wird, wie ein Siegel. Ohne ihn gibt es keine Updates (Schritt 19.3) |
| Statuscode 200 | Antwort eines Servers, die "Seite gefunden" heißt. Der Entwickler prüft sie mit einem Befehl |
| TRANSIT | Übergangszustand einer .de-Domain beim Umzug zu einem anderen Anbieter (Schritt 19.1) |
| Uptime-Monitor | Dienst, der regelmäßig prüft, ob eine Seite erreichbar ist, und bei Ausfall eine Mail schickt (Schritt 19.6) |
| USt-IdNr. | Umsatzsteuer-Identifikationsnummer. Falls vorhanden, gehört sie ins Impressum |
| W-8BEN-E | US-Steuerformular für ausländische Firmen, das manche Stores abfragen. Mit dem Steuerberater ausfüllen |
| Werte-Datei (`legal_values.json`) | Datei, in der deine Firmenangaben für die Rechtstexte stehen. Du lieferst die Werte, der Entwickler trägt sie ein |
| Zahlungsprofil | Bankverbindung und Steuerdaten bei einem Store. Bei einer kostenlosen App ohne Käufe nach Angaben der Stores nicht nötig |
| Zertifikat (TLS) | Digitaler Ausweis einer Web-Adresse. Er erscheint als Schloss im Browser und muss vor Ablauf erneuert werden |

## Reihenfolge im Überblick

| Nr. | Abschnitt | Hängt ab von | Dauer, grob |
|---|---|---|---|
| 1 | Vorbereitung | nichts | 1 Tag |
| 2 | Verträge und Bestätigungen | 1 | Wochen (Dritte antworten) |
| 3 | Rechtstexte und Pflichtangaben | 2 teilweise | Tage |
| 4 | Domain, DNS, HTTPS, CDN | 1.6 (Hosting gewählt), 5.1 (Hosting-Ziel steht) | Tage |
| 5 | Web-Hosting und automatisches Ausrollen | 1.6 | 1 Tag |
| 6 | Google Play | 1, 3, 4 und 5 (Datenschutz-URL muss live sein), 18.1 (D-U-N-S), 20.1 (Support-Postfach) | Tage plus 14 Tage Test (privates Konto) |
| 7 | Microsoft Store | 1, 3, 4 und 5, 18.1, 20.1, 7.6 (Lizenzklärung) | Tage |
| 8 | Linux: Flathub und Snap | 4, 5 | Tage bis Wochen |
| 9 | Statistik und Absturzberichte (optional) | 2 (AVV) | 1 Tag |
| 10 | Search Console, GA4 und GTM | 5 | 1 Tag |
| 11 | Vertrauens-Badges | 5 | je nach Anbieter |
| 12 | Signierte Releases (GPG optional), Scanner-Konten (optional) | 1 | 1 bis 2 Stunden |
| 13 | Datenschutzangaben je Store | 3, 6 bis 9 | 1 Tag |
| 14 | Bilder und Screenshots | früh anstoßen, die Stores in 6 bis 8 brauchen sie | Tage |
| 15 | Apple (später) | 1 | Wochen |
| 16 | Abnahme | alles | 1 Tag |
| 17 | Recht, Datenschutz, Jugendschutz, Verarbeitungsverzeichnis | 2, 3 | Tage, dann laufend |
| 18 | Konten, Kosten und Steuern | 1 | Wochen (D-U-N-S bis 30 Tage) |
| 19 | Technik und Betrieb | 4, 5 | 1 bis 2 Tage, dann laufend |
| 20 | Support und Pflege, Fristenkalender | 20.1 (Postfach) sofort, der Rest nach 16 | laufend |

Abschnitt 2 und die D-U-N-S-Nummer (Schritt 18.1) zuerst anstoßen, weil Antworten von Dritten am längsten dauern. Lege außerdem früh das Postfach `support@linefm.de` an (Schritt 20.1) und entscheide, ob du Statistik und Absturzberichte nutzt (Abschnitt 9, optional, dann ohne Einwilligungsrisiko weglassen), denn davon hängen die Verträge in Abschnitt 2 und die Rechtstexte in Abschnitt 3 ab. Die Abschnitte 6 bis 8 laufen parallel. Die Hosting-Wahl (Abschnitt 5) und die DNS-Einträge (Abschnitt 4) bedingen sich: Zuerst Hosting wählen, dann DNS auf dessen Zieladresse stellen, dann das Zertifikat.

## Arbeitsreihenfolge

Die Schrittnummern bleiben stabil. In dieser Reihenfolge arbeitest du sie ab, wenn du nichts überspringen willst:

| Phase | Schritte | Warum zuerst |
|---|---|---|
| 1. Grundlagen | 1.1, 1.2, 1.3, 1.5 (1.4 bleibt bis zum Anwaltstermin in Phase 3 offen) | Zugang, Passwortmanager, Secrets |
| 2. Entscheiden | 1.6 | Hosting, Telemetrie, Stores und Konto-Inhaber bestimmen den Rest |
| 3. Lange Wartezeiten anstoßen | 20.5 (gemeinsamen Kalender anlegen, Fristen eintragen, sobald sie anfallen), 18.1 (D-U-N-S), 2.1 bis 2.3 (Bestätigungen), 20.1 (nur das Postfach, die Support-Seite folgt nach der Web-Phase) und 18.2 (Konten-Regeln, die Haken je Konto erst am Ende von Phase 8), Anwaltstermin vereinbaren (Anhang D) | Dritte antworten spät, Konten brauchen Adressen, mehrere Schritte brauchen den Anwalt |
| 3a. Pflichtwerte | 3.1 (Werte und Platzhalter), 3.2, 3.5, 3.6 (Telemetrie-Entscheidung festlegen, danach 3.1 und 17.13 abschließen, der Dienst selbst folgt in 9.1 bis 9.3), 17.7, 17.8, 17.10, 17.13 | Der Release-Build bricht bei offenen Platzhaltern ab, Store-Formulare brauchen diese Antworten |
| 4. Web | 5.1, 5.2, 4.1, 4.2, 4.4, 19.1 (Verlängerung und Transfer-Sperre der Domain, vor 4.3), 4.3 | Datenschutz-URL und Domain müssen live sein. "Domain live" heißt hier: Die Web-App ist unter linefm.de erreichbar. Der "Tag des Live-Gangs" der Apps in den Stores ist etwas anderes (Phase 11) |
| 5. Rechtstexte | 3.3, 3.4, 3.1 abschließen (danach Web neu bauen, Schritt 1.5), Nutzungsbedingungen-Seite (Händlerstatus, Schritt 17.5: Anwalt), 2.4, 2.5, 17.3, 17.1, 17.2, 17.4, 17.6, 17.9, 17.11, 17.12, 18.3, 18.4 | Stores verlangen die URLs und Texte |
| 6. Google | 14 (Bilder müssen jetzt bereitliegen), 6.1, 17.5, 6.2, 6.3 (Schlüsselsicherung sofort, Schritt 19.3), 6.4, 6.5 bis 6.13 (6.9 erst nach dem ersten Upload), 13.1, 17.5 | |
| 7. Microsoft | 7.1, 7.6, 7.2, 13.2, 7.5, 7.7, 7.8, 7.3, 7.4 | 7.6, 13.2 und 7.8 vor 7.3, Bilder aus 14 liegen bereit |
| 8. Linux | 8.2 (Anmeldedaten sofort sichern, Schritt 19.3), 13.3, dann 8.1 (Einreichung bei Flathub, Verifizierungsdatei erst nach Aufnahme) | |
| 9. Optional | 9 (Telemetrie), 10.1, 10.3, 10.2, 11, 12 | 10.3 vor 10.2 |
| 10. Bilder | 14 (wird schon in Phase 6 gebraucht, deshalb dort eingeordnet und hier nur früh anstoßen, die Stores brauchen sie in Phase 6, 7 und 8) | |
| 11. Abnahme | 16, 19.4, 19.5, 19.9 | |
| 12. Dauerbetrieb | 19.2, 19.3, 19.6 bis 19.8, 20.2 bis 20.7 | Einrichten, dann regelmäßig |
| später (Apple-Runde) | 15 | bewusst nicht Teil der ersten Veröffentlichung, Rollen dort jeweils im Schritt |

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
| Windows-Signierzertifikat | entfällt vorerst, Installer wird unsigniert ausgeliefert (Schritt 7.4) | Signatur des Windows-Installers |
| Azure-Konto für den Microsoft-Tenant | nicht ermittelt (Schritt 7.8) | Pipeline-Zugang zum Partner Center |
| Google-Cloud-Projekt | kostenlos laut Anbieter für diese Nutzung, nicht geprüft (Schritt 6.4) | Pipeline-Zugang zu Google Play |
| Trustpilot | kostenloses Konto, nur das kostenlose Widget, kein bezahlter Tarif (Schritt 11.2) | Bewertungsanzeige |
| SonarCloud, Snyk | je ein kostenloser Tarif (nicht live geprüft, Schritt 12.6) | Code-Qualität und Abhängigkeiten, Konten legt der Repo-Eigentümer an, Abläufe liegen bereit |
| Markenanmeldung | Gebühren nicht abgerufen (Schritt 17.6) | falls gewünscht |
| Anwalt, Steuerberater | nach Aufwand | Rechts- und Steuerfragen |
| eigener Server oder Plesk | vorhanden | Web, falls gewählt |
| Sigstore, GitHub-Attestierung | kostenlos | Signatur der Releases (Abschnitt 12) |
| Google Analytics 4, Tag Manager, Search Console | kostenlos | Reichweitenmessung Web (Abschnitt 10) |

---

## 1. Vorbereitung

### 1.1 Zugang zum Repository

- **Wer:** Betreiber (Konto anlegen, Benutzernamen an den Entwickler mailen), Repo-Eigentümer (lädt ein).
- **Was:** Du brauchst ein GitHub-Konto (kostenlos, <https://github.com/signup>, Zwei-Faktor-Anmeldung danach einschalten: oben rechts auf dein Profilbild klicken > Settings > "Password and authentication", nicht geprüft). Schicke Tim Hauke vorab deinen GitHub-Benutzernamen (oder die Mail-Adresse des Kontos), sonst kann er dich nicht einladen. Die Einladung geht an die Mail-Adresse dieses Kontos. Die Einladung zum Repository `VectoDE/linefm-radio-app` nimmst du an: Mail öffnen, auf den Link klicken, dann auf "Accept invitation". Deine Rolle heißt Collaborator (Mitarbeiter mit eingeschränktem Zugriff).
- **Wozu:** Ohne Schreibrecht auf die Repo-Einstellungen kannst du keine Secrets eintragen.
- **Wo eintragen:** nichts. Die Einladung kommt per E-Mail von GitHub.
- **Woher:** Tim Hauke (VectoDE) verschickt sie.
- **Prüfschritt:** Das Repository öffnet sich ohne Fehlermeldung. Ob ein Collaborator in einem persönlichen Repo den Reiter "Settings" sieht, belegt die GitHub-Doku nicht (nicht geprüft). Ob du Secrets anlegen darfst, zeigt sich in Schritt 1.3.
- **Wenn es nicht klappt:** Keine E-Mail da: Spam-Ordner prüfen, dann <https://github.com/VectoDE/linefm-radio-app/invitations> öffnen, dort liegt die Einladung auch. Die Einladung geht an die E-Mail-Adresse deines GitHub-Kontos. Ablauf der Einladung und der Link `/invitations` sind in der GitHub-Doku nicht belegt (nicht geprüft). Findest du sie nicht, bitte Tim Hauke, sie neu zu schicken. Er legt sie unter Settings > Collaborators > Add people an (<https://docs.github.com/en/account-and-profile/how-tos/setting-up-and-managing-your-personal-account-on-github/managing-access-to-your-personal-repositories/inviting-collaborators-to-a-personal-repository>, abgerufen 26.11.2026).
- [ ] erledigt

### 1.2 Passwortmanager und Namen

- **Wer:** Betreiber.
- **Was:** Einen Passwortmanager bereithalten, also ein Programm, das Passwörter und Schlüssel verschlüsselt speichert. Kostenlose Möglichkeiten: **Bitwarden Free** (<https://bitwarden.com/pricing/>, Konto für Einzelpersonen mit unbegrenzten Passwörtern und Geräten, laut Anbieter immer kostenlos, abgerufen 27.11.2026) oder **KeePassXC** (<https://keepassxc.org/>, quelloffen unter GPLv3, die Datenbank ist eine verschlüsselte Datei auf deinem Rechner, abgerufen 27.11.2026). Lege zusätzlich eine Offline-Kopie der Datei oder der Notfall-Codes an einem zweiten Ort an. Zustimmung zu App-Name "LINEFM Radio" und Paket-ID `de.linefm.app` geben. Die Paket-ID ist die technische Kennung der App, wie eine Hausnummer: Nutzer sehen sie nie, sie lässt sich aber nicht mehr ändern. Du stimmst zu, indem du in der Freigabe-Checkliste bei Abschnitt A2 den Haken setzt und das Datum einträgst.
- **Wozu:** Die Paket-ID lässt sich im Play Store später nicht mehr ändern. Schlüssel und Passwörter brauchen einen sicheren Ort.
- **Wo eintragen:** Zustimmung schriftlich in der [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md), Abschnitt A2.
- **Woher:** eigene Entscheidung.
- **Prüfschritt:** Abschnitt A2 der Checkliste ist mit Datum abgehakt.
- **Wenn es nicht klappt:** Unsicher beim Namen: Nichts eintragen und zuerst nachfragen. Die Paket-ID ist nach dem ersten Play-Upload endgültig.
- [ ] erledigt

### 1.3 So legst du Secrets und Variablen an

- **Wer:** Betreiber trägt Secrets und Variablen ein, Entwickler liefert den Base64-Befehl und die Textzeile (sicherer Weg, nie per offener Mail), Repo-Eigentümer legt die Umgebung `production` an.
- **Was:** Du lernst hier, wie du einen geheimen oder normalen Wert in GitHub einträgst. Das brauchst du in fast allen späteren Schritten. Den Befehl für Base64 (eine Datei als lange Textzeile) gibt am besten der Entwickler ein, oder er sendet dir die Textzeile über einen sicheren Weg. Du musst keinen Befehl selbst ausführen: Bekommst du eine lange Textzeile, kopierst du sie unverändert in das Feld "Secret" (ohne Leerzeichen davor oder dahinter).
- **Wozu:** Die automatischen Abläufe (Bauen, Signieren, Hochladen) lesen ihre Zugangsdaten nur von dort.
- **Wo eintragen:** Öffne <https://github.com/VectoDE/linefm-radio-app> (angemeldet). Dann oben auf den Reiter "Settings" klicken, links auf "Secrets and variables", dann auf "Actions". Dort Tab "Secrets" > "New repository secret" für geheime Werte. Tab "Variables" > "New repository variable" für nicht geheime. Name exakt übernehmen (Groß- und Kleinschreibung beachten), Wert einfügen, "Add secret" bzw. "Add variable" klicken. Siehst du "Settings" nicht, steht es im Menü "..." oder "More" neben den Reitern. **Wer darf was:** Repository-Secrets und -Variablen darf ein Collaborator anlegen. **Environments** (zum Beispiel `production`) und deren Secrets darf in einem Repo eines persönlichen Kontos nur der Eigentümer anlegen, das ist Tim Hauke (Quellen: <https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets>, <https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments>, abgerufen 26.11.2026). Ein Secret darf höchstens 48 KB groß sein.
- **Woher:** **Umgebungen (Environments):** Die Abläufe unter `.github/workflows/` nutzen genau zwei: `production` (`deploy-web.yml`, Genehmigung vor dem Ausrollen, legt der Repo-Eigentümer an: Settings > Environments > "New environment", "Required reviewers" setzen, "Prevent self-review" **nicht** anhaken, damit du als Betreiber ein Ausrollen selbst starten und selbst freigeben kannst) und `github-pages` (legt GitHub für die Entwicklerseite selbst an). Weitere Umgebungen, etwa für Stores, gibt es nicht, Store-Secrets sind normale Repo-Secrets. Stand 26.11.2026, geprüft per Suche nach `environment:` in den Abläufen. Die Bezugsquelle jedes Werts steht im jeweiligen Schritt und gesammelt in Anhang A. Dateien (Schlüssel, Zertifikate) trägst du als Base64 ein: `base64 -w0 datei` (Linux, macOS) oder `[Convert]::ToBase64String([IO.File]::ReadAllBytes("datei"))` (PowerShell).
- **Prüfschritt:** Der Name erscheint in der Liste. Der Wert eines Secrets wird danach nicht mehr angezeigt (so ist es bei GitHub üblich, in der Doku nicht wörtlich belegt), du kannst ihn nur überschreiben.
- Details und die Spalte "Wer" (LineFM Studios oder Entwickler) stehen in [secrets.md](secrets.md). Den Zusammenhang der Abläufe erklärt [stores-pipelines.md](stores-pipelines.md).
- **Wenn es nicht klappt:** Du siehst unter Settings "Secrets and variables" nicht: Dir fehlt die Rolle am Repository (Schritt 1.1 nicht angenommen oder nicht ausreichend). Bitte Tim Hauke, dir den Zugriff zu geben oder den Wert für dich einzutragen. Meldung, der Name sei ungültig: Er enthält ein Leerzeichen oder einen Bindestrich oder beginnt mit einer Ziffer (GitHub-Namensregel, in der Doku nicht wörtlich geprüft). Falsch geschriebener Name: Ein Ablauf liest ihn nicht. Lösch ihn (Mülleimer-Symbol) und leg ihn neu an. Wert über 48 KB: dem Entwickler melden. In Läufen aus Forks oder von Dependabot stehen Secrets nicht zur Verfügung, das ist normal.
- [ ] erledigt

### 1.4 Schriftliche Zustimmung zur Veröffentlichung des Quellcodes

- **Wer:** Betreiber bestätigt, Repo-Eigentümer ist Empfänger. Die Bestätigung bleibt außerhalb des Repositorys.
- **Was:** Das Repository ist seit dem 19.11.2026 öffentlich. Die Lizenz bleibt proprietär (alle Rechte vorbehalten, der Code ist also lesbar, aber nicht frei nutzbar). Du bestätigst schriftlich, dass der Quellcode öffentlich sichtbar sein darf.
- **Wozu:** Jeder kann den Code lesen, aber nicht frei nutzen. Das muss mit dem Rechteinhaber der Marke und der App geklärt sein, bevor Dritte darauf bauen.
- **Wo eintragen:** schriftlich: Schick Tim Hauke eine kurze E-Mail mit der Bestätigung (ein Eintrag im Ticket geht auch). Danach Abschnitt A7 der [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) abhaken.
- **Woher:** deine Entscheidung. Den Wortlaut und die Frage, was "sichtbar, aber nicht frei nutzbar" für Weitergabe und Weiterentwicklung bedeutet, lässt du anwaltlich prüfen.
- **Prüfschritt:** Die Zustimmung liegt schriftlich vor und die anwaltliche Prüfung ist vermerkt.
- **Wenn es nicht klappt:** Unklar, was die Freigabe bedeutet: erst klären, dann zustimmen. Bis dahin bleibt der Punkt offen.
- [ ] erledigt

### 1.5 Einen Ablauf starten und das Ergebnis lesen

- **Wer:** Betreiber (Ablauf starten und Ergebnis lesen). Bei Fehlern schickt er den roten Schritt an den Entwickler.
- **Was:** So siehst du nach, ob deine Einträge wirken.
- **Wozu:** Jeder Schritt mit einem Secret oder einer Variable endet mit "Lauf wird grün". Hier steht, wo du das siehst.
- **Wo eintragen:** nichts. Du schaust unter <https://github.com/VectoDE/linefm-radio-app/actions> nach (Repository öffnen, oben auf den Reiter "Actions" klicken).
  1. Links steht die Liste der Abläufe, zum Beispiel "Release", "Store Google Play", "Deploy Web". Welcher Ablauf welches Secret liest, steht in Anhang C.
  2. Von Hand starten (nur wenn du Schreibrecht hast): Ablauf links anklicken, über der Lauf-Liste "Run workflow" aufklappen, den Branch (Zweig) `main` lassen, einen Tag (Versionsmarke) nur dann eintragen, wenn der Ablauf danach fragt (zum Beispiel `v0.1.0-alpha.15`, die aktuellen stehen unter <https://github.com/VectoDE/linefm-radio-app/releases>), dann den grünen Knopf "Run workflow" drücken. Fehlt der Knopf, startet dieser Ablauf nur automatisch.
  3. Ergebnis: Ein grüner Haken heißt erfolgreich, ein rotes X heißt fehlgeschlagen, ein grauer Kreis mit Strich heißt übersprungen. Lauf anklicken, dann steht unten die "Summary" (Zusammenfassung). Einen Job anklicken zeigt das Protokoll, fehlgeschlagene Schritte sind aufgeklappt. Quellen: <https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow>, <https://docs.github.com/en/actions/how-tos/monitor-workflows/use-workflow-run-logs> (abgerufen 26.11.2026). Wie die selbst geschriebenen Job-Zusammenfassungen der Abläufe in der Oberfläche heißen, haben wir nicht geprüft. Fehlt ein Secret, nennt sie dort seinen Namen, nie den Wert.
  4. **Web neu bauen und ausrollen:** Viele Fehlerhinweise in dieser Anleitung sagen "Web-Version neu bauen und ausrollen". Das heißt: Bei jeder Änderung auf `main` baut der Ablauf "Release" die Web-Version mit. Ausgerollt wird sie vom Ablauf "Deploy Web" (nicht zu verwechseln mit "Pages": Dieser Ablauf misst die Qualität der Web-Version und veröffentlicht die Entwicklerseite auf GitHub Pages, "Deploy Web" rollt die echte Web-App aus). Vor Version 1.0.0 startest du "Deploy Web" von Hand (Punkt 2), danach läuft er automatisch. Er wartet auf deine Freigabe in der Umgebung `production` (siehe Wenn es nicht klappt). Hast du einen Wert in den Secrets oder Variablen geändert, der die Web-Version betrifft (zum Beispiel `LEGAL_VALUES_JSON`), sage dem Entwickler Bescheid, er stößt den Neubau an.
  So sieht die Übersicht aus (Stand 27.11.2026, ohne Anmeldung aufgenommen, daher ohne Knopf "Run workflow"; mit Schreibrecht erscheint er über der Lauf-Liste):

  ![Seite "Actions" im Repository: links die Liste aller Abläufe, rechts die letzten Läufe mit grünem Haken oder rotem Kreuz](assets/einrichtung/actions-uebersicht.png)

  Ein einzelner Ablauf, hier "Release". Jede Zeile ist ein Lauf, Haken oder Kreuz stehen links, Dauer und Zeitpunkt rechts:

  ![Ablauf "Release" in der Liste: 46 Läufe, die neuesten oben, grüne Haken und rote Kreuze links, Branch main in der Mitte](assets/einrichtung/actions-release-ablauf.png)

  Die fertigen Versionen stehen unter Releases. Die obere ist die neueste, "Pre-release" bedeutet Vorabversion (nur zum Testen):

  ![Seite "Releases": neueste Version 0.1.0-alpha.31 mit Kennzeichen Pre-release, Änderungsliste und links die Liste älterer Versionen](assets/einrichtung/releases-uebersicht.png)

  Die Entwicklerseite auf GitHub Pages (<https://vectode.github.io/linefm-radio-app/>) sieht so aus. Sie wird vom Ablauf "Pages" veröffentlicht:

  ![Entwicklerseite auf GitHub Pages mit dem Titel LINEFM Radio](assets/einrichtung/pages-entwicklerseite.png)

  **Nicht abgebildet (nur Text):** Die Seiten `Settings > Secrets and variables`, `Settings > Environments` und die Freigabe "Review deployments" sind nur mit Anmeldung und Rechten am Repository sichtbar. Wir haben sie nicht aufgenommen, weil nur öffentliche Seiten fotografiert wurden und ein Bild dieser Seiten Secret-Namen oder Konten zeigen könnte. Die Beschreibung in Schritt 1.3 steht daher nur als Text. Bildschirmfotos der Konsolen von Google, Microsoft, Apple, Cloudflare, Flathub und Snap fehlen aus demselben Grund.
- **Woher:** entfällt.
- **Prüfschritt:** Du findest den letzten Lauf von "Release" und kannst seine Zusammenfassung öffnen.
- **Wenn es nicht klappt:** Rotes X ohne Hinweis auf ein Secret: Den roten Job anklicken, die rot markierte Zeile kopieren und dem Entwickler schicken, mit Link zum Lauf. Keine Werte von Secrets mitschicken. Ein Lauf wartet mit "Waiting for review": Lauf öffnen > "Review deployments" > Umgebung anhaken > "Approve and deploy" (oder "Reject"). Fehlt der Knopf "Run workflow": Der Ablauf startet nur automatisch oder dir fehlt das Schreibrecht, frag Tim Hauke.
- [ ] erledigt

### 1.6 Vier Entscheidungen vorab

- **Wer:** Betreiber entscheidet, Entwickler berät.
- **Was:** Entscheide diese vier Dinge, bevor du Abschnitt 2 bis 5 und 9 abarbeitest. Sie bestimmen, welche Verträge, Rechtstexte und Konten du brauchst.
  1. **Hosting der Web-App** (Schritt 5.1): Das ist der Ort im Internet, an dem die Web-Version der App liegt. Zur Wahl stehen Cloudflare Pages, eigener Server mit nginx oder Traefik oder Plesk. Der Hoster steht später im Impressum und in der Datenschutzerklärung. Kostenlos und ohne eigenen Server geht nur Cloudflare Pages (siehe Kostenübersicht oben). Das ist eine Empfehlung nach Aufwand, die Entscheidung triffst du mit dem Entwickler.
  2. **Statistik und Absturzberichte** (Abschnitt 9): ja oder nein, und mit welchem Anbieter. Selbst gehostete Dienste (Umami, Sentry in der Variante GlitchTip) brauchen einen eigenen Server mit Docker, den Cloudflare Pages nicht bietet. Ohne Server bleiben gehostete Dienste (Sentry, Firebase, Tarife nicht geprüft). Die einfachste Variante ist "nein" (Fall A in [STORE-DATENSCHUTZANGABEN.md](STORE-DATENSCHUTZANGABEN.md)): Dann entfallen die Auftragsverarbeitung für Telemetrie (Schritt 2.4), mehrere Platzhalter und viele Angaben in den Store-Formularen. Entscheidung des Betreibers, sie lässt sich später ändern.
  3. **Welche Stores zuerst:** Google Play, Microsoft, Flathub und Snap sind der erste Umfang, Apple später (Abschnitt 15). Jeder Store zusätzlich heißt: ein Konto, ein Formularsatz, eine Prüfung.
  4. **Registrar und DNS-Anbieter von `linefm.de`:** Wo wurde die Domain gekauft (Registrar, steht auf der Rechnung) und wo liegen die DNS-Einträge (Cloudflare oder beim Registrar)? Das brauchst du für 4.1, 8.1 und 19.1. Weißt du es nicht, frag den Entwickler oder schau auf der Rechnung nach.
- **Wozu:** Ohne diese Entscheidungen drehen sich Schritte im Kreis: Der Vertrag in 2.4 braucht den Telemetrie-Anbieter aus 9.1, die DNS-Einträge in 4.1 brauchen das Hosting aus 5.1.
- **Wo eintragen:** Schicke die Antworten per Mail an den Entwickler und lege sie in deinen Unterlagen ab. **Konto-Inhaber (Betreiber trägt ein):** Name der Firma laut Handelsregister bzw. Gewerbeanmeldung: ____________________; Rechtsform: ____________________. Diese Angaben stehen später unverändert in Google Play, Microsoft, D-U-N-S und im Impressum. **Betreiber von DNS und CDN (Betreiber trägt ein):** Name der Firma oder Person, die die DNS-Einträge von `linefm.de` und das CDN (zum Beispiel Cloudflare) verwaltet: ____________________; Konto-E-Mail dort: ____________________. **Zweite Person mit Admin-Recht (Betreiber trägt ein, siehe Schritt 18.2):** Name: ____________________; E-Mail: ____________________.
- **Woher:** eigene Entscheidung, Kosten siehe Übersicht oben.
- **Prüfschritt:** Alle vier sind schriftlich festgehalten.
- **Wenn es nicht klappt:** Du kannst dich nicht entscheiden: Nimm Cloudflare Pages, keine Telemetrie, vier Stores (Google, Microsoft, Flathub, Snap). Das ist die kleinste Variante und lässt sich später erweitern.
- [ ] erledigt


---

## 2. Verträge und Bestätigungen

Alle Punkte hier sind Vorprüfung, keine Rechtsberatung. Lass Wortlaut und Folgen von einem Anwalt prüfen. Die Antworten gehören schriftlich in die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md), Abschnitt A.

### 2.1 laut.fm, GEMA und GVL

- **Wer:** Betreiber (hat die Vereinbarung und behält sie selbst).
- **Was:** Schriftlich klären, ob die Musikrechte für die Wiedergabe über eine eigene App abgedeckt sind und ob für die Sender eine Lizenz über laut.fm besteht. GEMA und GVL sind die Verwertungsgesellschaften, die Musikrechte verwalten. Du schickst die Mustermail unten an laut.fm und legst die Antwort ab.
- **Wozu:** Die App nutzt die öffentliche laut.fm-Schnittstelle (Titel, Hörerzahl, Streams). Unsere Quelle belegt die Abdeckung nur durch einen Artikel von 2015. Ohne Bestätigung bleibt ein Rechtsrisiko.
- **Wo eintragen:** Antwort in Abschnitt A4 und A5 der Freigabe-Checkliste. Im Impressum steht bewusst keine Aussage wie "eigene Lizenz".
- **Mustermail** (an die Adresse unter "Woher", Absender: LineFM Studios; Betreff: "Anfrage zur Wiedergabe der laut.fm-Streams in einer eigenen App"):

  > Guten Tag, wir sind LineFM Studios und betreiben die App "LINEFM Radio" (Android, Windows, Linux, Web). Die App spielt die öffentlichen laut.fm-Streams unserer Sender ab und zeigt Titel, Hörerzahl und Sendeplan aus der öffentlichen laut.fm-Schnittstelle. Bitte bestätigen Sie uns schriftlich, ob die Wiedergabe der Streams in einer eigenen App eines Dritten durch Ihre Lizenzverträge mit GEMA und GVL abgedeckt ist, und ob Sie der Nutzung der Schnittstelle in dieser Form zustimmen. Falls Bedingungen gelten (Namensnennung, Logos), nennen Sie uns diese bitte. Vielen Dank und freundliche Grüße, [Name, Funktion, Telefon]

  Die Mail ist ein Vorschlag und ersetzt keine Rechtsberatung. Prüfe sie vor dem Versand und lege die Antwort mit Datum ab.
- **Woher:** Entscheidung des Inhabers: Die schriftliche Bestätigung zu GEMA und GVL holst du, da die Vereinbarung bei dir liegt, **bei laut.fm** ein (Adresse laut Freigabe-Checkliste: `team@laut.fm`, vor Gebrauch prüfen). Gefragt wird, ob die Wiedergabe der Streams in einer eigenen App eines Dritten unter die Lizenzverträge von laut.fm mit GEMA und GVL fällt.
- **Prüfschritt:** Es liegt eine schriftliche Antwort vor, die zur Aussage im Impressum passt.
- **Wenn es nicht klappt:** Keine Antwort nach zwei Wochen: freundlich nachfassen und das Datum notieren. Ohne Antwort bleibt die Freigabesperre bestehen (die Telemetrie und die Store-Einreichung bleiben gesperrt, bis die Voraussetzung erfüllt ist).
- [ ] erledigt

### 2.2 Radio3FM und FobFM

- **Wer:** Betreiber holt die Bestätigungen ein und legt die Dateien selbst ab (Schritt 17.8).
- **Was:** Bestätigen lassen, dass Namen, Logos und Streams dieser beiden Sender in der App laufen dürfen. Die Texte nennen sie "Partnersender".
- **Wozu:** Nach unserer Recherche sind sie keine LINEFM-Sender bei laut.fm. Die Nutzung braucht eine ausdrückliche Freigabe.
- **Wo eintragen:** Abschnitt A1 und A5 der Freigabe-Checkliste.
- **Mustermail** (je Sender; Betreff: "Freigabe zur Nutzung von Name, Logo und Stream in der LINEFM-App"):

  > Guten Tag, LineFM Studios betreibt die App "LINEFM Radio". Wir möchten Ihren Sender [Name] als Partnersender in der App zeigen: Sendername, Logo und Stream-Adresse, Wiedergabe über die App und die Web-App `app.linefm.de`. Bitte bestätigen Sie uns schriftlich, dass wir Name, Logo und Stream in dieser Form in der App und in den Store-Einträgen (Google Play, Microsoft Store, Flathub, Snap Store) nutzen dürfen, und ob dafür Bedingungen gelten. Eine Antwort per E-Mail genügt. Freundliche Grüße, [Name, Funktion]

  Die Antwort legst du mit Datum ab (Schritt 17.8).
- **Woher:** Ansprechpartner bei den beiden Sendern (Sender-Betreiber). Die Kontaktadresse steht meist im Impressum der Sender-Webseite (nicht geprüft).
- **Prüfschritt:** Schriftliche Freigabe je Sender liegt vor. Ohne sie nehmen wir die Sender aus der App.
- **Wenn es nicht klappt:** Ein Sender lehnt ab oder antwortet nicht: Dem Entwickler Bescheid geben, er nimmt den Sender aus der App.
- [ ] erledigt

### 2.3 radiogruppe.de

- **Wer:** Betreiber.
- **Was:** Nutzung des RadioGruppe-Logos bestätigen. Es wird wie in der Web-App von `radiogruppe.de` geladen. Der Hinweis "LINEFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe" bleibt, die Formulierung "offizielle App der RadioGruppe" nicht, solange du sie nicht bestätigst.
- **Wozu:** Markenrecht und ehrliche Aussage in den Stores.
- **Wo eintragen:** Abschnitt A1 und C der Freigabe-Checkliste.
- **Mustermail** (an die RadioGruppe; Betreff: "Nutzung des RadioGruppe-Logos in der LINEFM-App"):

  > Guten Tag, in der App "LINEFM Radio" von LineFM Studios wird das Logo der RadioGruppe Deutschland von `radiogruppe.de` geladen und mit dem Hinweis "LINEFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe" angezeigt. Bitte bestätigen Sie uns schriftlich, dass wir das Logo in dieser Form nutzen dürfen, und ob Sie damit einverstanden sind, dass der Abruf direkt von Ihrer Webseite erfolgt. Freundliche Grüße, [Name, Funktion]
- **Woher:** Du als Betreiber oder die RadioGruppe.
- **Prüfschritt:** Bestätigung liegt vor, Der Datenschutzabschnitt zu `radiogruppe.de` ist vom Anwalt oder von dir gelesen und freigegeben.
- **Wenn es nicht klappt:** Keine Bestätigung: Der Hinweis auf die RadioGruppe bleibt neutral formuliert, das Logo nimmt der Entwickler heraus.
- [ ] erledigt

### 2.4 Auftragsverarbeitung (AVV) für die Telemetrie

- **Wer:** Betreiber schließt den Vertrag, Entwickler nennt die Anbieter.
- **Was:** Vorher Schritt 1.6 entscheiden, ob Telemetrie genutzt wird. Entfällt sie, entfällt dieser Teil des Vertrags. Einen Vertrag zur Auftragsverarbeitung (AVV, nach Art. 28 DSGVO) mit dem Server-Anbieter der Statistik- oder Fehlerberichte-Instanz abschließen. Ein AVV ist ein Vertrag, in dem ein Dienstleister zusagt, personenbezogene Daten nur nach deinen Weisungen zu verarbeiten. Die meisten Anbieter stellen ihn als Formular im Kundenkonto bereit. Dasselbe mit Hosting- und CDN-Anbieter. Die vollständige Liste aller Dienste mit Fundort der Verträge steht in Schritt 17.3, dort legst du die Verträge ab. Dieser Schritt ist der frühe Teil (vor der Freigabe der Telemetrie), 17.3 die vollständige Prüfung.
- **Wozu:** Harte Freigabesperre (der Schritt bleibt blockiert, bis die Bedingung erfüllt ist): Telemetrie bleibt aus, solange kein unterschriebener Vertrag vorliegt. Die Datenschutzerklärung sagt bei aktiver Telemetrie, dass diese Verträge bestehen.
- **Wo eintragen:** Abschnitt "Harte Freigabesperren" der Freigabe-Checkliste. Erst danach setzt du die Telemetrie-Variablen (Abschnitt 9).
- **Woher:** Beim eigenen Server schließt du den Vertrag mit dem Server-Anbieter. Bei Cloudflare, Google und Apple gelten die Standardverträge der Anbieter. Ob ein US-Anbieter unter dem EU-US Data Privacy Framework (DPF) zertifiziert ist, zeigt <https://www.dataprivacyframework.gov/list>. Zertifizierungen laufen aus, also vor dem Start und danach regelmäßig nachsehen.
- **Prüfschritt:** Unterschriebene Verträge liegen vor, DPF-Status mit Datum notiert.
- **Wenn es nicht klappt:** Anbieter bietet keinen AVV an: Diesen Anbieter nicht nutzen und die Telemetrie aus lassen. Die App läuft ohne sie.
- [ ] erledigt

### 2.5 Nutzungsrechtevertrag

- **Wer:** Betreiber und Repo-Eigentümer schließen den Vertrag, ein Anwalt prüft.
- **Was:** Ein Vertrag, der schriftlich regelt, wer die Rechte am Code hat und was LineFM Studios damit tun darf (Weiterentwicklung durch Dritte, Weitergabe, Übergabe des Repos). Tim Hauke (VectoDE) hat die App unentgeltlich für LineFM Studios entwickelt. Marke, Logos und App-Icon gehören LineFM Studios. Das Urheberrecht am Code bleibt beim Entwickler, die Nutzungsrechte sind übertragbar. Ein Muster gibt es nicht, der Vertrag wird von einem Anwalt aufgesetzt. Dieselbe Vereinbarung regelt die Wartung nach dem Start: wer auf Fehler, Store-Rückfragen und Abhängigkeits-Vorschläge (Schritt 19.8) reagiert und binnen welcher Frist.
- **Wozu:** Der Code steht unter "Alle Rechte vorbehalten". Ohne Vertrag bleibt unklar, wer ihn nutzen darf. Flathub und andere Stores verlangen außerdem eine ausdrückliche Erlaubnis zur Weitergabe (Schritt 8.1).
- **Wo eintragen:** Abschnitt A6 der Freigabe-Checkliste.
- **Woher:** Vertrag zwischen LineFM Studios und Tim Hauke, anwaltlich geprüft.
- **Prüfschritt:** Unterschriebener Vertrag liegt vor. Wartung nach dem Start (wer reagiert auf Fehler und Store-Rückfragen) ist benannt.
- **Wenn es nicht klappt:** Uneinigkeit über den Inhalt: Bis zur Einigung keine Store-Einreichung, die eine Weitergabeerlaubnis verlangt (Flathub).
- [ ] erledigt

---

## 3. Rechtstexte und Pflichtangaben

Die Rechtstexte liegen als Entwurf in der App (`assets/legal/`) und als Webseiten (`/impressum/`, `/datenschutz/`, je mit `en/`). Die Betreiberdaten werden aus `https://linefm.de/impressum` übernommen. Du bestätigst und ergänzt sie.

### 3.1 Pflicht-Platzhalter ausfüllen

- **Wer:** Betreiber liefert die Werte, Entwickler trägt sie in `legal_values.json` ein (du schickst sie ihm verschlüsselt oder gibst sie per Bildschirmfreigabe durch). Alternativ trägst du den Inhalt selbst in die Variable `LEGAL_VALUES_JSON` ein, dann ist der Entwickler nicht beteiligt.
- **Was:** Platzhalter sind Stellen in den Rechtstexten wie `{{BETREIBER_NAME}}`, die mit deinen echten Angaben ersetzt werden. Fülle alle mit deinen Angaben. Die vollständige Tabelle mit Ort und Zweck steht in Anhang B. Zwei Teile: **Teil a (jetzt, Phase 3a):** Betreiber-, Hoster-, Kontakt- und Telemetrie-Angaben (Name, Anschrift, E-Mail, Telefon, Register, Hoster, CDN-Anbieter, Telemetrie-Werte aus Schritt 3.6). **Teil b (nach dem Anwaltstermin, Phase 5):** Medienanstalt (die Landesbehörde, die Rundfunk beaufsichtigt) und Verantwortlicher nach dem Medienstaatsvertrag, Datenschutzbeauftragter, zuständige Datenschutzbehörde. Der Haken gilt erst, wenn beide Teile fertig sind.
- **Wozu:** Impressum und Datenschutz sind Pflicht (§ 5 DDG, DSGVO). Solange etwas offen ist, setzt die Webseite `noindex`, und der Release-Build bricht ab.
- **Wo eintragen:** Weitergabe an den Entwickler: Schicke die Datei verschlüsselt (zum Beispiel als Passwort-geschütztes Archiv, Passwort getrennt über einen zweiten Weg) oder trage den Inhalt selbst in die Variable `LEGAL_VALUES_JSON` ein (Schritt 1.3: Settings > Secrets and variables > Actions > Tab "Variables" > "New repository variable", Name `LEGAL_VALUES_JSON`, das Wertfeld nimmt mehrzeiligen Text). In eine Datei `legal_values.json` schreiben (Schlüssel = Platzhalter ohne Klammern, Wert = Text). Nicht zutreffende Angaben als `"Nicht zutreffend."` eintragen, nie leer lassen. Die Datei nicht ins Repository hochladen. Für die automatischen Abläufe gehört der Inhalt in die Variable `LEGAL_VALUES_JSON`.
  Beispiel mit erfundenen Werten (Schlüssel = Platzhalter ohne Klammern, alle Pflichtwerte aus Anhang B müssen vorkommen, mit Hilfetext je Pflichtwert: Medienanstalt und Verantwortlicher klärt der Anwalt, Hoster und CDN-Betreiber nennt dir, wer sie verwaltet). Die Datei ist reiner Text: mit dem Windows-Editor oder VS Code anlegen, als UTF-8 speichern, Endung `.json`, und dem Entwickler per verschlüsseltem Weg geben (nicht per normaler Mail an Dritte):

```json
{
  "BETREIBER_NAME": "Beispiel Medien GmbH",
  "BETREIBER_RECHTSFORM": "GmbH",
  "BETREIBER_STRASSE": "Musterstraße 1",
  "BETREIBER_PLZ_ORT": "12345 Musterstadt",
  "BETREIBER_VERTRETER": "Erika Beispiel, Geschäftsführerin",
  "BETREIBER_EMAIL": "kontakt@beispiel.example",
  "BETREIBER_TELEFON": "+49 123 4567890",
  "REGISTERGERICHT": "Nicht zutreffend.",
  "REGISTERNUMMER": "Nicht zutreffend.",
  "USTID": "Nicht zutreffend.",
  "AUFSICHTSBEHOERDE_MEDIEN": "Name der zuständigen Landesmedienanstalt",
  "VERANTWORTLICHER_MSTV": "Erika Beispiel",
  "DATENSCHUTZBEAUFTRAGTER": "Nicht benannt, nach Prüfung nicht erforderlich.",
  "AUFSICHTSBEHOERDE_DATENSCHUTZ": "Landesdatenschutzbehörde des Bundeslandes, in dem der Sitz liegt",
  "HOSTING_ANBIETER": "Name deines Hosters",
  "CDN_ANBIETER": "Name des Betreibers von cdn.linefm.de",
  "LOG_AUFBEWAHRUNG": "7 Tage"
}
```

  Jede Zeile außer der letzten endet mit einem Komma, Texte stehen in geraden Anführungszeichen. Die Werte im Beispiel sind frei erfunden, nimm deine echten.
- **Woher:** Aus deinen Unterlagen. Hosting-Anbieter und CDN-Betreiber nennt dir, wer sie verwaltet. Die zuständige Datenschutzbehörde richtet sich nach dem Sitz des Betreibers. Keine Angabe wird vom Entwickler erfunden.
- **Prüfschritt:** Der Entwickler lässt den Generator laufen und er meldet keinen offenen Pflicht-Platzhalter:

```bash
dart run tool/gen_legal_html.dart --values=legal_values.json --fill-assets --strict --providers=umami,sentry
```

  Den Befehl gibt der **[Entwickler]** ein. `--providers` nennt die aktivierten Telemetrie-Dienste (bei Fall A aus Schritt 1.6 weglassen), `--strict` bricht ab, solange Pflichtfelder offen sind.
- **Wenn es nicht klappt:** Der Generator meldet einen offenen Platzhalter: Der Name in der Meldung fehlt in deiner Datei oder ist leer. Ergänze ihn. Du kennst Medienanstalt oder Verantwortlichen noch nicht: Keinen Hilfetext eintragen, er würde im Impressum erscheinen. Veröffentliche erst, wenn der Anwalt beides geklärt hat. Meldung zu ungültigem JSON: Meist fehlt ein Komma oder ein Anführungszeichen. Prüfe die Datei auf <https://jsonlint.com> (nur mit Beispielwerten, nicht mit echten Daten, falls dir das lieber ist).
- [ ] erledigt

### 3.2 Platzhalter außerhalb der Rechtstexte

- **Wer:** Betreiber liefert die Werte per Mail, Entwickler trägt sie in `docs/BARRIEREFREIHEIT.md` ein.
- **Was:** Drei Angaben stehen nicht in `legal_values.json`, sondern direkt in `docs/BARRIEREFREIHEIT.md`: `{{BARRIEREFREIHEIT_KONTAKT}}` (eine E-Mail-Adresse für Rückmeldungen zur Barrierefreiheit, zum Beispiel `support@linefm.de`), `{{BARRIEREFREIHEIT_ANTWORTFRIST}}` (in wie vielen Werktagen du antwortest, die Frist legst du fest) und `{{SCHLICHTUNGS_BZW_MARKTUEBERWACHUNGSSTELLE}}` (die Behörde, an die sich Nutzer beschweren können).
- **Wozu:** Die Erklärung zur Barrierefreiheit braucht einen Kontakt, eine Antwortfrist und die zuständige Beschwerdestelle. Mit `--strict` prüft der Generator die Datei auf offene Platzhalter.
- **Wo eintragen:** Direkt in `docs/BARRIEREFREIHEIT.md`, Abschnitt "Feedback und Kontakt". Das trägt der Entwickler ein, du schickst ihm die Werte per Mail.
- **Woher:** Du lieferst Kontakt und Frist. Die zuständige Stelle lässt du anwaltlich klären, ob die Erklärung für dein Angebot Pflicht ist (BFSG).
- **Prüfschritt:** In der Datei steht kein `{{` mehr.
- **Wenn es nicht klappt:** Du weißt die Beschwerdestelle nicht: Den Platzhalter nicht mit einem geratenen Wert füllen.
- [ ] erledigt

### 3.3 Sicherheitskontakt (erledigt)

- **Wer:** Entwickler (bereits erledigt).
- **Was:** `{{SECURITY_KONTAKT}}` in `SECURITY.md`, `CODE_OF_CONDUCT.md` und `web/.well-known/security.txt` ist durch das GitHub-Meldeformular <https://github.com/VectoDE/linefm-radio-app/security/advisories/new> ersetzt. Es ist keine E-Mail nötig.
- **Wozu:** Sicherheitslücken lassen sich vertraulich melden.
- **Wo eintragen:** nichts zu tun.
- **Woher:** entfällt.
- **Prüfschritt:** Mit `--strict` meldet der Generator für diese Dateien keinen offenen Platzhalter mehr. Der Punkt gilt als erledigt.
- **Wenn es nicht klappt:** Der Generator meldet trotzdem einen offenen Platzhalter: In den drei Dateien steht noch `{{SECURITY_KONTAKT}}`, den Entwickler fragen. Das Meldeformular lässt sich nicht öffnen: In GitHub angemeldet sein und beim Entwickler nachfragen, ob "Private vulnerability reporting" im Repository aktiv ist, sonst den Entwickler fragen.
- [x] erledigt

### 3.4 Texte lesen und abstimmen

- **Wer:** Betreiber mit Anwalt.
- **Was:** Impressum und Datenschutzerklärung lesen und mit einem Anwalt abstimmen.
- **Wozu:** Die Texte sind ein Entwurf nach Stand November 2026. Offen sind Rundfunkrecht (MStV, Bagatellrundfunk), Speicher-Hinweis in den nativen Apps (Popup statt Banner) und der Wortlaut des Einwilligungsdialogs (Abschnitt A4 der Freigabe-Checkliste).
- **Wo eintragen:** Abschnitt A4 und C der Freigabe-Checkliste.
- **Woher:** Anwalt.
- **Prüfschritt:** `/impressum/` und `/datenschutz/` sind erreichbar, ohne offene Platzhalter und ohne `noindex`.
- **Wenn es nicht klappt:** Seite zeigt noch `{{`: Schritt 3.1 ist nicht vollständig oder die Web-Version wurde danach nicht neu gebaut.
- [ ] erledigt

### 3.5 Einwilligungstext in der App

- **Wer:** Betreiber prüft, Entwickler ändert den Text in der App.
- **Was:** Der Dialog für Statistik und Fehlerberichte nennt den Empfänger (Server-Anbieter der Umami- bzw. Sentry-Instanz (GlitchTip), Instanz heißt: der laufende Dienst auf einem Server) und sagt, dass technisch die IP-Adresse übertragen wird. Prüfe, ob das zu deiner Konfiguration passt.
- **Wozu:** Die Einwilligung muss informiert sein (DSGVO, TDDDG).
- **Wo eintragen:** Der Text liegt in den Sprachdateien der App (`lib/l10n/`), nicht in `assets/legal/`. Änderungen macht der Entwickler.
- **Woher:** Abstimmung mit der Datenschutzerklärung.
- **Prüfschritt:** Der Dialog erscheint nur, wenn Telemetrie konfiguriert ist.
- **Wenn es nicht klappt:** Text passt nicht: dem Entwickler den gewünschten Wortlaut schicken. Den Text in den Sprachdateien änderst du nicht selbst.
- [ ] erledigt

### 3.6 Telemetrie-Entscheidung in die Pflichtwerte übertragen

- **Wer:** Betreiber entscheidet (Schritt 1.6), Entwickler trägt die Werte ein.
- **Was:** Wenn du in Schritt 1.6 Telemetrie gewählt hast, brauchen Schritt 3.1 (Anbieterliste und Betreiber-Platzhalter wie `{{UMAMI_BETREIBER}}`), Schritt 17.13 (Speicherdauer `{{TELEMETRIE_AUFBEWAHRUNG}}`) und Abschnitt 9 (Dienst einrichten) dieselben Antworten. Lege sie hier einmal fest: Anbieter (Umami, Sentry oder Firebase), Server-Anbieter, Speicherdauer (Vorschlag 90 Tage). Erst danach schließt der Entwickler 3.1 und 17.13 ab. Hast du Telemetrie ausgeschlossen, trägst du bei 3.1 die Telemetrie-Anbieter als nicht genutzt ein und überspringst 17.13 für diese Zeile.
- **Wozu:** Die Festlegung geht jetzt, der Prüfschritt "Dauer im Dienst eingestellt" erst nach Abschnitt 9. Setze den Haken deshalb erst dann. Der Release-Build bricht bei offenen Telemetrie-Platzhaltern ab, aber der Dienst selbst entsteht erst in Abschnitt 9. Ohne diese Festlegung widersprechen sich Rechtstexte und Dienst.
- **Wo eintragen:** In der Datei aus Schritt 3.1 (`legal_values.json`) und später im Dienst (Schritt 9.3).
- **Woher:** Deine Entscheidung aus Schritt 1.6, der Vertrag aus Schritt 2.4.
- **Prüfschritt:** Anbieter, Server-Anbieter und Speicherdauer stehen in der Datei aus 3.1 und sind in 17.13 und 9.3 gleich.
- **Wenn es nicht klappt:** Du weißt den Server-Anbieter noch nicht: Telemetrie zunächst ausgeschlossen lassen und später nachziehen.
- [ ] erledigt

---

## 4. Domain, DNS, HTTPS, CDN

### 4.1 DNS für app.linefm.de

- **Wer:** Betreiber (DNS-Konto), Entwickler sagt dir die Einträge.
- **Was:** Voraussetzung ist die Hosting-Entscheidung aus Schritt 1.6. Den Namen `app.linefm.de` auf den gewählten Hosting-Ort zeigen lassen.
- **Wozu:** Unter dieser Adresse läuft die Web-App. Auch die Links `https://app.linefm.de/?station=...` und die Bestätigungsdateien für Android und iOS hängen daran.
- **Wo eintragen:** Beim DNS-Anbieter der Domain `linefm.de` (bei Cloudflare: <https://dash.cloudflare.com> öffnen, die Domain `linefm.de` anklicken, links DNS > Records > "Add record" > Typ wählen > "Save"). Cloudflare Pages: **Zuerst** im Pages-Projekt unter Workers & Pages > Projekt > "Custom domains" > "Set up a domain" `app.linefm.de` eintragen. Liegt `linefm.de` bei Cloudflare, legt Cloudflare den CNAME danach selbst an. Liegt die Domain woanders, dort einen CNAME auf `<projekt>.pages.dev` anlegen (ein CNAME ist eine Weiterleitung im Domain-System: `app.linefm.de` zeigt auf eine andere Adresse) (Quelle: <https://developers.cloudflare.com/pages/configuration/custom-domains/>, abgerufen 26.11.2026). Ob `linefm.de` bei Cloudflare liegt, ist offen. Eigener Server: A- und AAAA-Eintrag auf die IP des Servers.
- **Woher:** Zieladresse nennt das gewählte Hosting (Abschnitt 5).
- **Prüfschritt:** Windows-Taste drücken, `cmd` eintippen, Enter, dann `nslookup app.linefm.de` eingeben: Es erscheint die Zieladresse. Die Seite lädt im Browser.
- **Wenn es nicht klappt:** `nslookup` liefert nichts ("Non-existent domain"): Der Eintrag fehlt oder ist noch nicht verteilt. Bis zu 24 Stunden warten, dann den Eintrag beim DNS-Anbieter prüfen. Fehler 522 bei Cloudflare: Der CNAME wurde angelegt, bevor die Domain im Pages-Projekt unter "Custom domains" eingetragen war. Dort eintragen, nach kurzer Zeit geht es. Kein Zertifikat: Prüfen, ob CAA-Einträge für die Domain existieren, die die Zertifikatsstellen von Cloudflare nicht erlauben.
- [ ] erledigt

### 4.2 HTTPS-Zertifikat

- **Wer:** Betreiber und Entwickler gemeinsam, je nach Hosting.
- **Was:** Ein gültiges Zertifikat für `app.linefm.de` einrichten (Let's Encrypt oder Cloudflare). Das Zertifikat ist der digitale Ausweis der Webseite, durch ihn erscheint das Schloss im Browser. Bei Cloudflare Pages passiert das von selbst, du musst dann nichts tun.
- **Wozu:** Ohne HTTPS laufen Service Worker und die Installation als App nicht, und Browser warnen.
- **Wo eintragen:** Beim Hoster (Cloudflare: automatisch, bei eigenem Server per Certbot nach <https://certbot.eff.org/instructions>, bei Plesk "Let's Encrypt"-Erweiterung). Let's-Encrypt-Zertifikate gelten 90 Tage, die Erneuerung muss automatisch laufen (<https://letsencrypt.org/docs/faq/>, abgerufen 26.11.2026). Die Plesk-Erweiterung und die Certbot-Automatik haben wir nicht im Einzelnen geprüft.
- **Woher:** kostenlos über Let's Encrypt oder Cloudflare.
- **Prüfschritt:** Das Schloss im Browser zeigt ein gültiges Zertifikat, <https://www.ssllabs.com/ssltest/> meldet kein Problem.
- **Wenn es nicht klappt:** Browser warnt vor dem Zertifikat: Es ist für einen anderen Namen ausgestellt oder abgelaufen. Beim Hoster neu ausstellen lassen. Let's Encrypt braucht dafür einen funktionierenden DNS-Eintrag aus Schritt 4.1 und für die Prüfung per HTTP erreichbaren Port 80 (Platzhalter wie `*.linefm.de` gehen nur per DNS-Prüfung). Die Ausstellung scheitert wiederholt: Zum Üben die Staging-Umgebung von Let's Encrypt nutzen, die echte hat Grenzen (zum Beispiel fünf fehlgeschlagene Prüfungen pro Stunde, <https://letsencrypt.org/docs/rate-limits/>).
- [ ] erledigt

### 4.3 HSTS

- **Wer:** Entwickler setzt um, Betreiber entscheidet über Preload.
- **Was:** Ein Header ist eine Zusatzangabe, die der Server jeder Seite mitschickt. Der Header `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` kommt aus den mitgelieferten Server-Konfigurationen, du musst ihn nicht selbst setzen. Ohne besonderen Grund lass Preload weg (so rät es auch hstspreload.org). Die Anmeldung auf <https://hstspreload.org> ist ein eigener, freiwilliger Schritt.
- **Wozu:** HSTS zwingt Browser zu HTTPS. `preload` trägt die Domain in die Browser-Liste ein. Das gilt dann für `linefm.de` samt **allen** Subdomains und lässt sich nur langsam zurücknehmen.
- **Wo eintragen:** Header: in der Hosting-Konfiguration (`deploy/`), nichts von Hand. Preload: auf hstspreload.org, nur wenn alle Subdomains dauerhaft HTTPS haben. Das entscheidet der Betreiber der Hauptdomain. Die Anmeldung gilt für die Basisdomain `linefm.de`, der Header muss dort kommen (nicht nur auf `app`), mit `max-age` mindestens 31536000, `includeSubDomains` und `preload`, und HTTP muss auf HTTPS umleiten. hstspreload.org rät selbst davon ab, Preload ohne Not zu setzen. Quelle: <https://hstspreload.org> (abgerufen 26.11.2026).
- **Woher:** [hosting-uebersicht.md](hosting-uebersicht.md), Abschnitt "Security-Header".
- **Prüfschritt:** `curl -sI https://app.linefm.de/ | grep -i strict-transport` zeigt den Header. Unter Windows PowerShell: `curl.exe -sI https://app.linefm.de/ | Select-String strict-transport`.
- **Wenn es nicht klappt:** Header fehlt: Die mitgelieferte Server-Konfiguration ist nicht aktiv. Abschnitt "Security-Header" in hosting-uebersicht.md nachlesen oder den Entwickler fragen. Preload nie beantragen, solange eine Subdomain von `linefm.de` noch ohne HTTPS läuft. Meldet hstspreload.org einen Fehler: Header auf `linefm.de`, Weiterleitung und alle Subdomains prüfen. Die Aufnahme dauert Monate, die Rücknahme ebenfalls.
- [ ] erledigt

### 4.4 CORS für cdn.linefm.de

- **Wer:** Entwickler, bei fehlendem Zugriff Betreiber über den CDN-Anbieter.
- **Was:** CORS ist eine Browser-Regel, die erlaubt, dass eine Webseite Bilder von einer anderen Adresse lädt. Der Server hinter `cdn.linefm.de` sendet für `/images/icons/` den Header `Access-Control-Allow-Origin: *` (oder `https://app.linefm.de`).
- **Wozu:** Ohne ihn kann die Web-Version das Senderlogo nicht als Cover in der Mediensteuerung des Browsers zeigen. Die App läuft trotzdem.
- **Wo eintragen:** In der Server- oder CDN-Konfiguration von `cdn.linefm.de`.
- **Woher:** Wer das CDN betreibt (derselbe Name steht als `{{CDN_ANBIETER}}` in der Datenschutzerklärung).
- **Prüfschritt:** `curl -sI -H "Origin: https://app.linefm.de" https://cdn.linefm.de/images/icons/main.png | grep -i access-control` zeigt den Header.
- **Wenn es nicht klappt:** Header fehlt: Du (Betreiber) schreibst dem CDN-Anbieter von `cdn.linefm.de` (die Adresse steht in deinem Vertrag oder im Hosting-Konto): "Bitte setzt für `https://cdn.linefm.de/images/icons/` den Antwort-Header `Access-Control-Allow-Origin: *` (oder `https://app.linefm.de`) und bestätigt mir die Änderung." Danach prüft der Entwickler den Header. Die App funktioniert bis dahin, nur ohne Cover im Browser.
- [ ] erledigt

---

## 5. Web-Hosting und automatisches Ausrollen

Die Web-App besteht nur aus Dateien. Such dir **einen** Weg aus. Jede Anleitung enthält fertige Konfigurationen, ein Überblick steht in [hosting-uebersicht.md](hosting-uebersicht.md).

### 5.1 Hosting wählen und einrichten

- **Wer:** Entwickler richtet ein, Betreiber legt die Konten beim Hoster an.
- **Was:** Entscheide dich (Schritt 1.6) und richte einen der vier Wege ein. Am einfachsten und kostenlos ist Cloudflare Pages (Konto: <https://dash.cloudflare.com/sign-up>): [nginx auf eigenem Server](hosting-nginx.md) (`deploy/nginx/`), [Docker mit Traefik](hosting-traefik.md) (`deploy/traefik/`), [Cloudflare Pages](hosting-cloudflare.md) (`deploy/cloudflare/`) oder [Plesk](hosting-plesk.md) (`deploy/plesk/`).
- **Wozu:** Hier läuft die Web-Version. Der Hoster steht als `{{HOSTING_ANBIETER}}` im Impressum und in der Datenschutzerklärung.
- **Wo eintragen:** Je nach Weg in der jeweiligen Anleitung.
- **Woher:** Dein Server, dein Cloudflare-Konto oder dein Plesk-Hoster.
- **Prüfschritt:** **[Entwickler]** (die Befehle brauchen die Secrets aus Schritt 5.2, deshalb nach 5.2): Nach dem ersten Ausrollen die Befehle am Ende von `hosting-uebersicht.md` ausführen: Header, ETag, 304-Antwort.
- **Wenn es nicht klappt:** Seite lädt nicht oder zeigt einen Fehler: Den Abschnitt "Fehlersuche" der gewählten Hosting-Anleitung durchgehen. Bei Plesk oder eigenem Server die Protokolle des Webservers ansehen.
- [ ] erledigt

### 5.2 Secrets für das Ausrollen

- **Wer:** Betreiber trägt ein, Entwickler nennt die Namen.
- **Was:** Zugangsdaten für das gewählte Ziel eintragen.
- **Wozu:** `deploy-web.yml` rollt damit bei jedem Release (nur Endversionen) oder manuellem Start aus.
- **Wo eintragen:** Jeden Wert trägst du wie in Schritt 1.3 ein (Repository > Settings > Secrets and variables > Actions). Die Umgebung `production` mit Genehmigern legt **Tim Hauke als Repository-Eigentümer** an, ein Collaborator darf das nicht: Settings > Environments > "New environment" > Name `production` > "Configure environment" > "Required reviewers" anhaken > dich als Prüfer eintragen > "Prevent self-review" **nicht** anhaken (Entscheidung vom 27.11.2026: Du startest das Ausrollen und gibst es selbst frei, eine zweite Person ist dafür nicht nötig) > "Save protection rules" (bis zu 6 Prüfer). Dann wartet jedes Ausrollen auf deine Freigabe. Je nach gewählten Zielen sind das bis zu drei Freigaben pro Lauf (Cloudflare, SSH, Plesk). Wird das Repo privat, sind die Schutzregeln im kostenlosen GitHub-Tarif unwirksam (<https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments>, abgerufen 26.11.2026).
- **Woher:** Je Ziel:
  - Cloudflare Pages: `CLOUDFLARE_API_TOKEN`: Cloudflare-Dashboard > My Profile > API Tokens (<https://dash.cloudflare.com/profile/api-tokens>) oder, für Automatik besser, Manage Account > Account API Tokens > "Create Token" > "Custom Token" > "Get started" > Name vergeben > Berechtigung "Account" > "Cloudflare Pages" > "Edit" > "Continue to summary" > "Create Token". Cloudflare zeigt den Token nur einmal, sofort kopieren. `CLOUDFLARE_ACCOUNT_ID`: Dashboard > Workers & Pages > Bereich "Account Details" > Kopierknopf neben "Account ID". Variable `CLOUDFLARE_PAGES_PROJECT` (`linefm-app`): Das Pages-Projekt muss vorher existieren. Wie es angelegt wird, beschreibt die Cloudflare-Seite nicht (nicht geprüft), das macht der Entwickler mit dir. Am 27.11.2026 erneut gegen die Cloudflare-Seite geprüft: Berechtigung "Account > Cloudflare Pages > Edit" bestätigt; die Account-ID steht laut dieser Seite im Bereich "API" der Seite "Zone Overview" (der oben genannte Weg über "Workers & Pages" ist dort nicht belegt, nimm im Zweifel die zweite Quelle). Quellen: <https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/>, <https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/> (abgerufen 26.11.2026).
  - Eigener Server (SSH, die Werte liefert dir der Entwickler oder dein Server-Betreuer, du kopierst sie nur): `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`, Variablen `DEPLOY_PATH`, `DEPLOY_PORT`, `DEPLOY_RELOAD_COMMAND`. Befehle für Schlüssel und Host-Fingerabdruck stehen in [secrets.md](secrets.md).
  - Plesk (SSH, die Werte liefert dir der Entwickler oder dein Hoster): `PLESK_SSH_HOST`, `PLESK_SSH_USER`, `PLESK_SSH_KEY`, `PLESK_SSH_KNOWN_HOSTS`, Variablen `PLESK_DOCROOT`, `PLESK_SSH_PORT`.
  - Alle Ziele: Variable `WEB_DEPLOY_TARGETS` auf `cloudflare`, `ssh` oder `plesk` (kommagetrennt, auch mehrere). Ohne diese Variable rollt nichts aus.
  - Variable `WEB_BASE_URL` auf `https://app.linefm.de`.
- **Prüfschritt:** Actions > "Deploy Web" (Schritt 1.5) läuft grün durch, die Zusammenfassung nennt kein fehlendes Secret.
- **Wenn es nicht klappt:** Lauf rot mit "Permission denied (publickey)": Der öffentliche Schlüssel liegt nicht in `~/.ssh/authorized_keys` des Benutzers auf dem Server, oder Benutzer oder Host stimmen nicht. Meldung "Host key verification failed": `DEPLOY_KNOWN_HOSTS` bzw. `PLESK_SSH_KNOWN_HOSTS` neu mit `ssh-keyscan` erzeugen. Cloudflare meldet "Authentication error": Token falsch kopiert, ohne die Berechtigung "Cloudflare Pages: Edit" oder falsche Konto-ID. Neuen Token erzeugen und das Secret überschreiben. Lauf hängt bei "Waiting for review": Er wartet auf deine Freigabe für `production`: Lauf öffnen > "Review deployments" > `production` anhaken > "Approve and deploy". Fehlt der Knopf, bist du nicht als Prüfer eingetragen, bitte Tim Hauke. Ist "Prevent self-review" an und du hast den Lauf selbst gestartet, kannst du ihn nicht freigeben. Umgebung `production` lässt sich nicht anlegen: Das darf nur der Eigentümer.
- [ ] erledigt

### 5.3 Web-Variablen für Google-Dienste, Telemetrie und Vertrauen

- **Wer:** Betreiber trägt Werte ein, Entwickler nennt Namen.
Hier musst du nichts tun. Welche Werte du eintragen musst, steht in den Abschnitten 9, 10 und 11, dort trägst du sie ein. Sie werden in die fertige Web-App übernommen und sind für jeden Besucher lesbar, deshalb legst du sie nur als Variable an, nie als Secret. Einzige Ausnahme ist `FIREBASE_CONFIG_JSON`: Die Abläufe unter `.github/workflows/` lesen es ausschließlich als Secret (`secrets.FIREBASE_CONFIG_JSON`), eine Variable liest dort niemand. Der Inhalt ist zwar kein Geheimnis, muss aber trotzdem als Secret angelegt werden, damit der Ablauf ihn findet (Stand 26.11.2026, per Suche in den Abläufen geprüft).

---

## 6. Google Play (Android)

Quellen: [Play Console](https://play.google.com/console), Signierung in [packaging/android/SIGNING.md](../packaging/android/SIGNING.md).

### 6.1 Entwicklerkonto

- **Wer:** Betreiber (Konto), Repo-Eigentümer wird als Nutzer eingeladen.
- **Was:** Vorher klären: Wer ist Konto-Inhaber und welche Rechtsform hat er (Schritt 1.6)? Neue Konten müssen den Händlerstatus nach dem Digital Services Act sofort erklären (Schritt 17.5). **Organisationskonto** (ein Konto auf die Firma, nicht auf dich privat) von LineFM Studios anlegen (Entscheidung des Inhabers: in jedem Store das eigene Organisationskonto des Kunden), 25 US-Dollar einmalig zahlen, Organisation bestätigen (D-U-N-S-Nummer aus Schritt 18.1, Website, offizielle Telefonnummer und E-Mail der Organisation). Tim Hauke als Nutzer einladen (Nutzer und Berechtigungen > Neue Nutzer einladen, mit App-Rechten für Veröffentlichung).
- **Wozu:** Ohne Konto keine Veröffentlichung. Google verlangt die Identität auch für sideloadbare APKs ab 2027 (Entwicklerverifizierung). "Sideloadbar" heißt: Die APK wird nicht über den Play Store, sondern als Datei direkt installiert, zum Beispiel von GitHub.
- **Wo eintragen:** <https://play.google.com/console/signup> öffnen, mit dem Google-Konto der Firma anmelden und den Seiten der Anmeldung folgen: Kontotyp "Organization" wählen, Firmendaten und D-U-N-S-Nummer eintragen, 25 US-Dollar zahlen, Identität bestätigen (die Einmalcodes siehe unter "Woher").
- **Woher:** Kreditkarte (keine Prepaid-Karte), D-U-N-S-Nummer. Name und Anschrift müssen exakt dem Eintrag bei Dun & Bradstreet entsprechen. Quelle: <https://support.google.com/googleplay/android-developer/answer/13628312> (abgerufen 26.11.2026). Laut Google werden vier Kanäle per Einmalcode bestätigt: Kontakt-E-Mail, Kontakt-Telefon, Entwickler-E-Mail und Entwickler-Telefon, sie müssen für die Lebensdauer des Kontos erreichbar bleiben. Die Telefonnummer der Organisation soll die öffentliche Geschäftsnummer sein. Akzeptiert werden Mastercard, Visa und American Express, Prepaid-Karten nicht. Nach der Anmeldung wartet der Ablauf: Google-Konto (mindestens 18 Jahre), Vertrag "Google Play Developer Distribution Agreement" annehmen, Gebühr zahlen, Kontotyp "Organization", Identität prüfen (<https://support.google.com/googleplay/android-developer/answer/6112435>). Tim Hauke einladen: "Users and permissions" > "Invite new users", Rechte je App "Release apps to testing tracks" und "Release to production, exclude devices, and use Play App Signing", "Invite user". Er muss sich mit genau der Adresse anmelden, an die die Einladung ging, sie läuft nach 30 Tagen ab (<https://support.google.com/googleplay/android-developer/answer/2528691>). Ob Google eine Website verlangt, ist auf der Google-Seite nicht belegt (nicht geprüft). Verstöße gegen Richtlinien können zur Entfernung von App oder Konto führen. Store-Regeln: [G-10](STORE-RICHTLINIEN.md#g-10), [G-25](STORE-RICHTLINIEN.md#g-25), [G-27](STORE-RICHTLINIEN.md#g-27), [G-53](STORE-RICHTLINIEN.md#g-53), [D-02](STORE-RICHTLINIEN.md#d-02). Zum Vergleich: Ein **privates** Konto braucht für die Erstveröffentlichung einen geschlossenen Test mit mindestens 12 Testern über mindestens 14 Tage (Schritt 6.8). Ein Organisationskonto mit D-U-N-S-Nummer braucht das nicht. Die Regel ändert Google gelegentlich, vor dem Start prüfen.
- **Prüfschritt:** Die Console zeigt keinen Hinweis zur Verifizierung mehr, und unter "Manage account" > "Account details" stehen die Organisationsdaten korrekt. Den Text "Konto verifiziert" nennt die Google-Doku nicht. Der eingeladene Nutzer steht auf "Active".
- **Wenn es nicht klappt:** Zahlung abgelehnt: Prepaid-Karten nimmt Google nicht an, eine normale Karte von Mastercard, Visa oder American Express nehmen. Bei ungültigen Angaben erstattet Google die Gebühr nicht. Zahlungsmethode zeigt "Verifications pending": "Verify" klicken und die Einzahlungsprüfung abschließen oder Bankunterlagen hochladen, das kann bis zu fünf Tage dauern. Banner "Your organization name or address is no longer verified": Name und Anschrift müssen exakt dem Dun-&-Bradstreet-Eintrag entsprechen (Schritt 18.1), im Banner "View details" > "How to fix" > "Review details" (nur der Kontoinhaber), im Zahlungscenter "Review updates" > "Confirm". Einladung kommt nicht an oder 403 bei einer App: Der Kontoinhaber muss dem Nutzer Rechte für die App geben.
- [ ] erledigt

### 6.2 App anlegen

- **Wer:** Betreiber.
- **Was:** "Create app" (App erstellen): Name `LINEFM Radio`, **Paketname** `de.linefm.app` (dauerhaft, lässt sich nicht löschen oder wiederverwenden), Standardsprache Deutsch, Typ "App", kostenlos, Kontakt-E-Mail für Nutzer, unter "Declarations" die Erklärungen zu den Richtlinien und zu US-Exportgesetzen bestätigen und die Bedingungen für Play App Signing akzeptieren, erneut "Create app" (<https://support.google.com/googleplay/android-developer/answer/9859152>, abgerufen 26.11.2026).
- **Wozu:** Legt den Eintrag mit der Paket-ID an.
- **Wo eintragen:** Play Console (<https://play.google.com/console>) > oben rechts "Create app" (deutsch: "App erstellen"). Der Paketname ist die technische Kennung der App, sie bleibt für immer gleich.
- **Woher:** Kontakt-E-Mail: eine Funktionsadresse von LineFM Studios (zum Beispiel `support@linefm.de`, Schritt 20.1).
- **Prüfschritt:** Die App erscheint in der Console. Eine eigene Anzeige auf dem Dashboard beschreibt die Google-Doku nicht (nicht geprüft). Ist der Paketname schon vergeben, verlangt die Console einen anderen.
- **Wenn es nicht klappt:** Paketname ist schon vergeben: Dann gibt es bereits eine App mit `de.linefm.app`, vermutlich in einem anderen Konto. Kläre das mit dem Entwickler.
- [ ] erledigt

### 6.3 Upload-Schlüssel und Secrets

- **Wer:** Entwickler erzeugt den Schlüssel, Betreiber sichert Datei und Passwörter und trägt die Secrets ein.
- **Was:** **[Entwickler]** (Befehl `keytool`): Er erzeugt die Schlüsseldatei, du sicherst Datei und Passwörter (Schritt 19.3). Der Upload-Schlüssel ist eine Datei, mit der die Pipeline beweist, dass ein Upload von euch kommt. Ohne ihn lädt niemand etwas in den Play Store hoch. **Play App Signing** aktiviert lassen (Standard). Google verwaltet dann den eigentlichen App-Schlüssel, neue Apps werden laut Google automatisch mit hybrider Signierung aufgenommen (Seite "Protected with Play" > "Play Store protection" > "Manage Play app signing", <https://support.google.com/googleplay/android-developer/answer/9842756>, abgerufen 26.11.2026). Den Upload-Schlüssel (Java-Keystore, RSA mit mindestens 2048 Bit) erzeugt der Entwickler einmalig (Befehl in `packaging/android/SIGNING.md`).
- **Wozu:** Mit dem Upload-Schlüssel signiert die Pipeline jeden Upload. Geht er verloren, beantragst du den Reset in der Console, der Entwickler erzeugt dafür einen neuen Schlüssel und exportiert sein Zertifikat als PEM-Datei (`keytool -export -rfc`). Du klickst unter "Manage Play app signing" im Abschnitt "Upload key certificate" auf "Request upload key reset", gibst einen Grund an und lädst `upload_certificate.pem` hoch.
- **Wo eintragen:** Datei `upload-keystore.jks` und Passwörter in den Passwortmanager. Als Secrets (Schritt 1.3) trägst du ein: `ANDROID_KEYSTORE_BASE64` (die Datei als Base64, die Textzeile liefert dir der Entwickler), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (zum Beispiel `upload`), `ANDROID_KEY_PASSWORD`.
- **Woher:** Der Entwickler erzeugt die Schlüsseldatei mit `keytool` und übergibt sie dir zur Sicherung.
- **Prüfschritt:** Der Release-Lauf baut ein signiertes AAB. Fehlt der Schlüssel, bricht `store-google.yml` mit klarer Meldung ab.
- **Wenn es nicht klappt:** Lauf rot mit "Keystore was tampered with, or password was incorrect": Das Passwort in `ANDROID_KEYSTORE_PASSWORD` passt nicht zur Datei. Meldung zu einem fehlenden Alias: `ANDROID_KEY_ALIAS` prüfen (`keytool -list -keystore upload-keystore.jks` zeigt ihn). Upload-Schlüssel verloren: In der Play Console einen neuen Upload-Schlüssel beantragen ("Manage Play app signing", siehe Schritt 6.3).
- [ ] erledigt

### 6.4 Dienstkonto für den automatischen Upload

- **Wer:** Betreiber legt das Cloud-Projekt mit dem Organisationskonto aus Schritt 6.1 und das Dienstkonto samt JSON-Schlüssel an, Entwickler begleitet. Den ersten Upload in die Play Console macht der Betreiber, der Entwickler begleitet. Die AAB-Datei dafür lädt der Betreiber aus dem Release auf GitHub herunter (die Echtheitsprüfung nach Schritt 16.4 macht der Entwickler vorher für dich) (Datei mit der Endung `.aab` unter Assets), der Entwickler zeigt, welche.
- **Was:** Ein Dienstkonto ist ein technisches Konto für ein Programm, kein Mensch. Ablauf in Kurzform: 1. Cloud-Projekt anlegen, 2. ersten Upload von Hand in der Play Console machen, 3. "Google Play Android Developer API" aktivieren, 4. Dienstkonto samt JSON-Schlüssel anlegen, 5. das Dienstkonto in der Play Console einladen (Nutzer und Berechtigungen, Recht für Veröffentlichung auf Test- und Produktionsspuren), 6. den JSON-Inhalt als Secret eintragen. Die Klickwege stehen unter "Woher".
- **Wozu:** Die Pipeline lädt damit jedes Release als Entwurf in die Spur "internal".
- **Wo eintragen:** Gesamter Inhalt der JSON-Datei als Secret `PLAY_SERVICE_ACCOUNT_JSON` (Datei mit dem Windows-Editor öffnen, alles markieren, kopieren, im Secret-Feld einfügen, Schritt 1.3). Optional Variable `BUILD_NUMBER_OFFSET`, nur wenn Play einen höheren `versionCode` verlangt (Standard 100).
- **Woher:** Wenn du noch kein Google-Cloud-Projekt hast: <https://console.cloud.google.com/projectcreate>, Namen vergeben (zum Beispiel "LINEFM Store"), "Create". Das Projekt ist kostenlos und braucht keine Zahlungsdaten für diese Nutzung (nicht geprüft). Der **erste** App-Upload in die Play Console muss von Hand erfolgen (Spur "internal", AAB-Datei aus dem Release herunterladen), die Pipeline lädt erst danach hoch (der Entwickler begleitet das). Dann im Cloud-Projekt die "Google Play Android Developer API" aktivieren ("Enable", <https://developers.google.com/android-publisher/getting_started>). Dann Google Cloud Console > "IAM & Admin" > "Service accounts" (<https://console.cloud.google.com/iam-admin/serviceaccounts>), Projekt wählen. "Create service account", Name eingeben, "Done". Dann die E-Mail-Adresse des Dienstkontos anklicken > Reiter "Keys" > "Add key" > "Create new key" > Typ "JSON" > "Create". Die JSON-Datei wird einmal heruntergeladen und lässt sich nicht erneut laden. Sicher ablegen (Passwortmanager), nicht ins Repository hochladen. Quellen: <https://docs.cloud.google.com/iam/docs/service-accounts-create>, <https://docs.cloud.google.com/iam/docs/keys-create-delete> (abgerufen 26.11.2026). Dann in der Play Console "Users and permissions" > "Invite new users", die E-Mail-Adresse des Dienstkontos (endet auf `iam.gserviceaccount.com`) eintragen, Rechte "Release apps to testing tracks" und "Release to production, exclude devices, and use Play App Signing", "Invite user". Das Konto steht dann als "Active" in der Liste. Die Wartezeit, bis die Rechte wirken, nennt Google nicht (nicht geprüft), erfahrungsgemäß kann es dauern.
- **Prüfschritt:** Nach einem Release erscheint ein Entwurf in der Spur "internal".
- **Wenn es nicht klappt:** Lauf rot mit "The caller does not have permission": Das Dienstkonto ist in der Play Console nicht eingeladen oder hat für diese App keine Veröffentlichungsrechte. Rechte prüfen, nach Änderungen bis zu 24 Stunden warten. Ist "Create new key" gesperrt, verbietet eine Organisationsrichtlinie (`iam.disableServiceAccountKeyCreation`) Schlüssel: Ein Administrator der Google-Organisation (das bist du mit dem Konto aus Schritt 6.1, sonst frag den Entwickler) muss das Projekt davon ausnehmen. Meldung "Package not found": Die App ist in der Console noch nicht angelegt oder es wurde noch nie ein Build von Hand hochgeladen. **[Entwickler]** Der Betreiber lädt das erste App-Paket (AAB, die Android-Datei für den Play Store) einmal von Hand hoch. Meldung zum versionCode: `BUILD_NUMBER_OFFSET` höher setzen, zum Beispiel 200.
- [ ] erledigt

### 6.5 Datenschutz und App-Inhalte

- **Wer:** Betreiber trägt ein. Den Befehl `aapt dump permissions` führt der Entwickler aus.
- **Was:** In der Play Console zuerst die App `LINEFM Radio` anklicken, dann im Menü links "Monitor and improve" > "Policy and programs" > "App content" (deutsche Menünamen nicht geprüft). Datenschutzerklärung-URL `https://app.linefm.de/datenschutz/`. Werbung "nein": Die App selbst bindet keine Werbung ein, Werbespots im Programm kommen von den Sendern. Zur Werbung zählen laut Google auch Anzeigen aus SDKs von Dritten, falsche Angaben können zur Sperre führen (<https://support.google.com/googleplay/android-developer/answer/9859455>, abgerufen 26.11.2026). Dass Google das Werbe-Label selbst setzen kann, ist dort nicht belegt (nicht geprüft). Zielgruppe "13 und älter" (keine Kinder), Altersfreigabe über den **IARC-Fragebogen** (Fragen zu Gewalt, Sprache und Ähnlichem, aus denen Google die Altersfreigabe berechnet, Ziel 13+), App-Zugriff "keine Anmeldung nötig" (kein Testkonto), Werbe-ID-Erklärung "nein", Nachrichten-App "nein" (Medien-Streaming-Apps fallen laut Google nicht darunter, <https://support.google.com/googleplay/android-developer/answer/10523915>), Behörden-App "nein", Finanzfunktionen "nein", Gesundheit "nein". Die Datenschutzerklärung ist laut Google auch ohne sensible Daten Pflicht und muss öffentlich ohne Login unter gültigem HTTPS erreichbar sein, als normale Webseite (kein PDF). Ohne Altersfreigabe kann Google die App entfernen. Dass auch Werbung und Zielgruppe für alle Apps Pflicht sind, steht dort nicht ausdrücklich. Jede Erklärung öffnest du über "Start declaration" (oder "Manage"), erledigte wandern vom Reiter "Needs attention" nach "Actioned". Welche weiteren Erklärungen die Console abfragt, zeigt sie selbst. **Antwortvorschlag für den Altersfragebogen (IARC)**, abgeleitet aus [STORE-RICHTLINIEN.md](STORE-RICHTLINIEN.md) (G-19) und [STORE-DATENSCHUTZANGABEN.md](STORE-DATENSCHUTZANGABEN.md). Die Fragen im Fragebogen selbst haben wir nicht live gesehen (nicht geprüft), die Themenbereiche sind die üblichen:

  | Thema | Antwort | Grund |
  |---|---|---|
  | App-Art | Musik- und Audio-App, kein Spiel | Radiostreams |
  | Gewalt, Blut | Nein | nicht in der App |
  | Sexuelle Inhalte, Nacktheit | Nein | nicht in der App |
  | Derbe Sprache | **Ja, gelegentlich** | Die abgespielten Streams anderer können Kraftausdrücke in Liedern enthalten. Ziel-Einstufung 13+ **[Betreiber und Anwalt]** |
  | Drogen, Alkohol, Tabak | Nein | nicht in der App |
  | Glücksspiel | Nein | nicht in der App |
  | Nutzer können miteinander interagieren oder Inhalte teilen | Nein | kein Chat, keine Kommentare |
  | Standort wird geteilt | Nein | keine Standortabfrage |
  | Digitale Käufe, Werbung | Nein | beides gibt es nicht |
  | Zielgruppe | 13 und älter, nicht an Kinder gerichtet | Entscheidung des Inhabers, siehe Schritt 17.10 |

  Antworte nach tatsächlichem Verhalten. Kommt eine höhere Einstufung heraus, entscheidest du mit dem Anwalt (Schritt 17.10). Nicht geprüft: IARC-Fragebogen im Einzelnen, Werbe-ID, Behörden-, Finanz- und Gesundheitserklärung, die Auswahl für Apps ohne Anmeldung.
- **Wozu:** Alles muss ausgefüllt sein, sonst blockiert Google die Veröffentlichung.
- **Wo eintragen:** Play Console, App-Inhalte.
- **Woher:** Hinweise: Der Sender +RAP kann Kraftausdrücke senden, im Fragebogen ehrlich angeben. Die Werbe-ID wird nicht verwendet. Das Manifest entfernt `com.google.android.gms.permission.AD_ID` per `tools:node="remove"`. Nach dem Release-Build mit `aapt dump permissions app-release.apk` nachsehen, ob sie fehlt. Sonst müsste "Werbe-ID: ja" stehen. Das prüft der Entwickler, bitte ihn vor deiner Antwort um Bestätigung. Die Antworten zu Datensicherheit stehen in Abschnitt 13.
- **Prüfschritt:** Alle Punkte unter "App content" zeigen einen grünen Haken, außer der Datensicherheit, die du in Schritt 13.1 ausfüllst.
- **Neue Einstufung:** Ändern sich Inhalte oder Funktionen so, dass der IARC-Fragebogen betroffen ist (zum Beispiel neue Sender), reichst du ihn neu ein.
- Store-Regeln: [G-05](STORE-RICHTLINIEN.md#g-05), [G-12](STORE-RICHTLINIEN.md#g-12), [G-13](STORE-RICHTLINIEN.md#g-13), [G-19](STORE-RICHTLINIEN.md#g-19), [G-20](STORE-RICHTLINIEN.md#g-20), [G-24](STORE-RICHTLINIEN.md#g-24), [G-30](STORE-RICHTLINIEN.md#g-30), [G-35](STORE-RICHTLINIEN.md#g-35), [G-36](STORE-RICHTLINIEN.md#g-36), [G-37](STORE-RICHTLINIEN.md#g-37), [G-38](STORE-RICHTLINIEN.md#g-38), [G-39](STORE-RICHTLINIEN.md#g-39), [G-40](STORE-RICHTLINIEN.md#g-40), [G-49](STORE-RICHTLINIEN.md#g-49)
- **Wenn es nicht klappt:** Ein Punkt bleibt ohne Haken: Ihn öffnen, Google nennt das fehlende Feld. Datenschutz-URL abgelehnt: Prüfen, ob sie ohne Login erreichbar ist, gültiges HTTPS hat und eine normale Webseite ist. Eine Erklärung wurde abgelehnt: Unter "Manage" korrigieren, "Save", dann in "Publishing overview" bei "Changes ready to send for review" "Send for review" klicken. Bei der Werbe-ID-Frage den Entwickler fragen, bevor du "ja" angibst.
- [ ] erledigt

### 6.6 Deklarationen: Vordergrunddienst und Vollbild-Benachrichtigung

- **Wer:** Betreiber, Entwickler liefert die Antworttexte.
- **Was:** Google fragt, warum die App im Hintergrund Ton spielen darf (Radio) und warum der Wecker den Bildschirm einschalten darf. Dafür gibst du zwei Erklärungen in der Play Console ab: Vordergrunddienst-Typ `mediaPlayback` (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`) und `USE_FULL_SCREEN_INTENT` für den Radiowecker. Exakte Alarme (`SCHEDULE_EXACT_ALARM`) fragt die App beim Wecker selbst beim Nutzer ab, die App nutzt bewusst nicht `USE_EXACT_ALARM`.
- **Wozu:** Google lässt Apps mit Zielversion Android 14 oder höher ohne diese Erklärung nicht durch. Bei der Vollbild-Berechtigung gilt: Standardmäßig bekommen sie nur Anruf- und Wecker-Apps. **Risiko:** Bei einer Radio-App kann Google die Erklärung ablehnen. Dann entfernt der Entwickler die Berechtigung, und der Wecker meldet sich ohne Vollbild. Laut Google ist als Alternative auch die Nutzerabfrage mit sinnvollem Weiterlaufen ohne Erlaubnis möglich, das stimmst du mit dem Entwickler ab. Die Anzeige "Abgeschickt" oder "Genehmigt" nennt die Google-Doku nicht (<https://support.google.com/googleplay/android-developer/answer/13392821>, abgerufen 26.11.2026, nicht geprüft).
- **Wo eintragen:** Play Console > "Monitor and improve" > "Policy and programs" > "App content" (deutsche Menünamen nicht geprüft) > "Vordergrunddienste" und "Vollbild-Benachrichtigungen" (genauen Menünamen vor Ort prüfen).
- **Woher:** Fertige Texte auf Deutsch und Englisch, die Felder der Console und das Skript für das Demo-Video stehen in [STORE-TEXTE.md](STORE-TEXTE.md), Abschnitt "Play-Console-Deklarationen". Das Video nimmst du selbst auf, zum Beispiel mit der Bildschirmaufnahme deines Android-Handys (Hinweise dort).
- **Prüfschritt:** Beide Deklarationen zeigen den Status "Abgeschickt" bzw. "Genehmigt". Entscheidung zum Umgang mit einer Ablehnung ist festgehalten (Freigabe-Checkliste, Abschnitt C).
- **Inhalt der Vordergrunddienst-Erklärung:** je Typ der Anwendungsfall, was der Nutzer merkt, wenn das System den Dienst beendet, und ein Video. Beim Vollbild-Intent fragt die App den Nutzer, weil die Berechtigung seit 22.01.2025 nur Anruf- und Wecker-Apps standardmäßig bekommen.
- Store-Regeln: [G-14](STORE-RICHTLINIEN.md#g-14), [G-15](STORE-RICHTLINIEN.md#g-15), [G-16](STORE-RICHTLINIEN.md#g-16), [G-17](STORE-RICHTLINIEN.md#g-17), [G-43](STORE-RICHTLINIEN.md#g-43), [G-44](STORE-RICHTLINIEN.md#g-44)
- **Wenn es nicht klappt:** Google lehnt den Vordergrunddienst ab: Das Video muss zeigen, wie der Nutzer die Wiedergabe selbst startet, automatisch startende Wiedergabe zählt nicht. Neu aufnehmen. Google lehnt die Vollbild-Erklärung ab: an den Entwickler weitergeben, er entfernt die Berechtigung oder baut die Nutzerabfrage mit Rückfall, danach neu einreichen. Video wird abgelehnt: Es muss den Wecker in der echten App zeigen, Hinweise in STORE-TEXTE.md. Ob Google bei einem Radiowecker die Kernfunktion "Wecker" anerkennt, ist Ermessen von Google und nicht dokumentiert.
- [ ] erledigt

### 6.7 Store-Eintrag

- **Wer:** Betreiber trägt ein, Entwickler liefert Texte und Bilder.
- **Was:** Kurz- (80 Zeichen) und Langbeschreibung auf Deutsch und Englisch, Grafiken, Kategorie "Musik & Audio".
- **Wozu:** Das sieht jeder im Store.
- **Wo eintragen:** Play Console > "Grow users" > "Store presence" > "Main store listing" (<https://support.google.com/googleplay/android-developer/answer/9866151>, abgerufen 26.11.2026; Kategorie und Tags unter "Store settings"). Pflicht zum Veröffentlichen: mindestens zwei Screenshots über alle Gerätetypen, dazu eine **Feature-Grafik 1024 x 500** (das große Bild oben auf der Store-Seite; JPEG oder 24-Bit-PNG ohne Alpha, also ohne Transparenz, mit Alternativtext). Texte aus [STORE-TEXTE.md](STORE-TEXTE.md). Icon 512 x 512 (32-Bit-PNG mit Alpha, höchstens 1024 KB) liegt in `assets/branding/play_store_512.png`. Weiteres in Abschnitt 14.
- **Woher:** STORE-TEXTE.md, Abschnitt "Google Play".
- **Prüfschritt:** Die Vorschau der Store-Seite zeigt alle Felder ohne Fehler.
- Store-Regeln: [G-06](STORE-RICHTLINIEN.md#g-06), [G-29](STORE-RICHTLINIEN.md#g-29)
- **Wenn es nicht klappt:** Eine Grafik wird abgelehnt: Maße, Dateiformat und Alphakanal prüfen (Icon mit Alpha, Feature-Grafik ohne Alpha). Kurzbeschreibung zu lang: höchstens 80 Zeichen, keine Emojis oder Symbole. Änderungen an Kategorie und Tags können bis zu 24 Stunden brauchen. Ein Preview-Video muss eine einzelne öffentliche oder nicht gelistete YouTube-URL sein.
- [ ] erledigt

### 6.8 Geschlossener Test (Pflicht nur für private Konten)

- **Wer:** Betreiber.
Kurz: Mit dem Firmenkonto brauchst du das vermutlich nicht. Mach diesen Schritt nur, wenn die Play Console ihn verlangt, und schreibe sonst "entfällt" daneben (Regel aus der Einleitung).

Google nennt die Testpflicht nur für **private** Konten, die nach dem 13.11.2023 angelegt wurden: mindestens 12 Tester, je 14 Tage durchgehend dabei (<https://support.google.com/googleplay/android-developer/answer/14151465>, abgerufen 26.11.2026). LineFM Studios nutzt ein Organisationskonto, für das die Seite keine solche Pflicht nennt. Zeigt die Console trotzdem den Hinweis, gilt die Console. Nach dem Test: Dashboard > "Apply for production" mit den drei Abschnitten "About your closed test", "About your app/game", "About your production readiness" (nicht ohne "Next" oder "Apply" verlassen, sonst gehen die Eingaben verloren). Die Prüfung dauert in der Regel höchstens sieben Tage. Der Menüpfad für "Closed testing" steht in der Google-Doku nicht ausdrücklich (nicht geprüft). Für Android Auto brauchst du ohnehin eine Testspur (Schritt 6.10).

- **Was (nur falls die Console es verlangt):** Testspur "Geschlossener Test" anlegen, Release hochladen, mindestens 12 Tester per E-Mail-Liste oder Google-Gruppe eintragen, 14 Tage laufen lassen, dann "Zugriff auf Produktion beantragen".
- **Wozu:** Google verlangt das für private Konten vor der ersten Veröffentlichung.
- **Wo eintragen:** Play Console > Test und Veröffentlichung > Geschlossener Test. Einladungstext und Testerliste-Vorlage in [STORE-TEXTE.md](STORE-TEXTE.md). Tester-E-Mail-Adressen nur solange speichern, wie der Test läuft.
- **Woher:** Deine Kontakte.
- **Prüfschritt:** Die Console zeigt nach Tag 14 mindestens 12 durchgehende Tester und schaltet "Produktion beantragen" frei.
- **Wenn es nicht klappt:** Zähler steht still: Ein Tester hat sich abgemeldet oder die App nicht installiert. Die 14 Tage zählen nur mit mindestens 12 durchgehend angemeldeten Testern. Ersatz einladen und weiterlaufen lassen.
- [ ] erledigt

### 6.9 App-Links für Android (assetlinks.json)

- **Wer:** Betreiber trägt die Variable ein, Entwickler prüft mit `adb` und setzt `autoVerify` im Manifest.
- **Was:** Erst nach dem ersten Upload möglich (Schritt 6.4). Die SHA-256-Fingerabdrücke (Prüfsummen, an denen Android die echte App erkennt; bei hybrider Signierung drei, sonst zwei, die Console zeigt es) als Variable `ANDROID_CERT_SHA256` eintragen. In der Datei `web/.well-known/assetlinks.json` steht dafür der Platzhalter `{{ANDROID_CERT_SHA256}}`, den der Web-Postbuild beim Build aus der Variable füllt.
- **Wozu:** Links `https://app.linefm.de/?station=...` öffnen dann direkt in der App statt im Browser.
- **Wo eintragen:** Repository-Variable `ANDROID_CERT_SHA256`, kommagetrennt (`AA:BB:…,CC:DD:…`, je 32 Byte). Schreibe die Datei nicht von Hand.
- **Woher:** Der **App-Signaturschlüssel** (Play Console > "Protected with Play" > "Play Store protection" > "Manage Play app signing" > "App signing key", gilt für Installationen aus Google Play; bei der hybriden Signierung neuer Apps nennt Google **drei** Fingerabdrücke, zähle vor Ort nach, welche die Console zeigt) und der **Upload-Schlüssel** (dort oder lokal `keytool -list -v -keystore upload-keystore.jks`, gilt für die APK aus den GitHub-Releases).
- **Prüfschritt:** Nach dem nächsten Web-Deploy (Datei muss unter `https://app.linefm.de/.well-known/assetlinks.json` liegen) ist `https://app.linefm.de/.well-known/assetlinks.json` ohne Weiterleitung erreichbar (Browser: Adresse öffnen, es erscheint reiner Text mit den Fingerabdrücken und die Adresszeile bleibt gleich. Status und Dateityp prüft der Entwickler mit `curl -I`) und enthält alle Fingerabdrücke aus der Console (zwei oder drei). Danach bittest du den Entwickler, im Manifest `autoVerify` auf `true` zu setzen und neu zu veröffentlichen.
- **Wenn es nicht klappt:** Datei zeigt noch `{{ANDROID_CERT_SHA256}}` oder fehlt: Variable falsch geschrieben oder die Web-Version wurde danach nicht neu gebaut und ausgerollt. Links öffnen weiter im Browser: Android liest die Datei bei Installation oder App-Update, ab Android 15 prüft das System periodisch nach, Änderungen brauchen bis zu sieben Tage. Zum Testen die App deinstallieren und neu installieren. Pro Gerät kann nur eine App je Domain zugeordnet sein. Der Entwickler prüft mit `adb shell pm get-app-links de.linefm.app`: `verified` heißt Erfolg (<https://developer.android.com/training/app-links/verify-android-applinks>, abgerufen 26.11.2026). Zuordnung testen auch mit <https://developers.google.com/digital-asset-links/tools/generator>. Nicht geprüft: "ohne Weiterleitung, Status 200, `application/json`" und das Format der Fingerabdrücke.
- [ ] erledigt

### 6.10 Android Auto

- **Wer:** Betreiber klickt in der Play Console, Entwickler macht die Tests mit dem DHU.
Quelle: <https://developer.android.com/training/cars/distribute> (abgerufen 26.11.2026).

- **Was:**
  1. Play Console > "Advanced settings" > Bereich "Form factors" (Gerätearten) > "Add form factor" > "Android Auto" (deutsche Namen nicht geprüft).
  2. Ein App-Bundle mit Auto-Unterstützung zuerst in einer **Testspur** (zum Beispiel "internal") veröffentlichen.
  3. Die Auto-Prüfung einplanen: Für offene Tests und Produktion blockiert sie die Veröffentlichung, für geschlossene Tests ist sie nur ein Hinweis. Das Ergebnis kommt per E-Mail.
  4. Wird ein Bundle abgelehnt: das abgelehnte Bundle aus der Spur entfernen, bevor du eine neue Version hochlädst.
  5. Vorher mit der Desktop Head Unit (DHU) prüfen (Freigabe-Checkliste B2).
- **Wozu:** Ohne Formfaktor erscheint die App nicht im Auto. Google prüft Auto-Apps gesondert nach der Qualitätsliste für Medien-Apps.
- **Wo eintragen:** Play Console. Ein Testkonto für die Prüfung ist nicht nötig, die App hat keine Anmeldung.
- **Woher:** Der Entwickler erklärt die DHU.
- **Prüfschritt:** Die Auto-Prüfung meldet per E-Mail "genehmigt".
- Store-Regeln: [G-21](STORE-RICHTLINIEN.md#g-21)
- **Wenn es nicht klappt:** Ein Bundle wird abgelehnt: das abgelehnte Bundle aus der Spur entfernen, bevor du eine neue Version hochlädst. Interne Tests werden nicht geprüft, geschlossene nur mit Hinweis, offene und Produktion blockierend. Die Prüfung dauert länger als bei Telefon-Apps. Die Ablehnungsmail nennt die Mängel. Nicht geprüft: Desktop Head Unit und die Qualitätsliste für Medien-Apps.
- [ ] erledigt

### 6.11 16-KB-Speicherseiten

- **Wer:** Entwickler.
- **Was:** Vor jedem Release prüfen, dass die nativen Bibliotheken auf 16-KB-Seiten ausgerichtet sind: `zipalign -c -P 16 -v 4 app-release.apk`. Das macht der Entwickler bzw. die CI.
- **Wozu:** Laut Google müssen Apps mit Zielversion Android 15 und höher auf 64-Bit-Geräten 16-KB-Seiten unterstützen, ab 1. Februar 2027 lassen sich Updates ohne diese Unterstützung nicht mehr veröffentlichen (<https://developer.android.com/guide/practices/page-sizes>, abgerufen 26.11.2026).
- **Wo eintragen:** nichts, du musst hier nichts tun. Die Play Console zeigt eine Kompatibilitätswarnung (den "App-Bundle-Explorer" nennt die Doku nicht).
- **Woher:** Entwickler.
- **Prüfschritt:** Die Prüfung meldet in der letzten Zeile "Verification successful", die Console zeigt keine Warnung.
- Store-Regeln: [G-22](STORE-RICHTLINIEN.md#g-22)
- **Wenn es nicht klappt:** `zipalign` meldet einen Fehler oder Bibliotheken stehen auf `UNALIGNED`: Das ist Sache des Entwicklers (Android Gradle Plugin ab 8.5.1, NDK r28 oder höher, vorgebaute Bibliotheken von Drittanbietern in 16-KB-tauglicher Version holen). Bei nativem Code von SDKs unbedingt prüfen.
- [ ] erledigt

### 6.12 Entwicklerverifizierung für die APK außerhalb von Google Play

- **Wer:** Betreiber registriert die App bei Google, Entwickler liefert Paketname und Schlüsselabdruck.
- **Was:** Kurz: Google will wissen, wer hinter einer App steht. Für die Version aus dem Play Store läuft das meist automatisch, hier geht es um die APK-Datei von GitHub. Die APK auf GitHub Releases bleibt (Entscheidung des Inhabers). Dafür registriert LineFM Studios die App bei Googles Android-Entwicklerverifizierung. Wer auch über Play vertreibt, macht das in der Play Console. Laut Google registriert Play 99 Prozent der Apps automatisch, übrige Apps und solche außerhalb von Play meldest du dort von Hand an.
- **Wozu:** Seit 30.09.2026 schützen zertifizierte Android-Geräte in Brasilien, Indonesien, Singapur und Thailand vor Apps unbestätigter Entwickler, 2027 folgt die weltweite Ausweitung. Die Pflicht gilt zunächst nur für Apps aus teilnehmenden Stores auf zertifizierten Geräten, bei direkt installierten APKs wird sie in dieser ersten Phase laut Google-FAQ noch nicht durchgesetzt. Nicht registrierte Apps lassen sich später nur über einen "Advanced flow" in den Entwickleroptionen (mit Wartezeit) oder per ADB installieren. FAQ: <https://developer.android.com/developer-verification/guides/faq.md.txt> (abgerufen 26.11.2026). Quelle: <https://developer.android.com/developer-verification> (abgerufen 26.11.2026).
- **Wo eintragen:** Play Console, Bereich Entwicklerverifizierung (Menüname vor Ort prüfen). Registriert wird der Paketname, was den Nachweis der privaten Signaturschlüssel einschließen kann. Der Ort ist die Seite "Android developer verification" in der Play Console, dort steht der Status je App (<https://developer.android.com/developer-verification/guides/google-play-console.md.txt>). Dass gerade der Upload-Schlüssel der GitHub-APK registriert wird, ist nicht belegt, bei Play App Signing erfolgt die Zuordnung automatisch (nicht geprüft).
- **Woher:** Organisationskonto, Upload-Schlüssel. Die 25 US-Dollar gelten laut FAQ für das Konto in der separaten Android Developer Console (nur für den Vertrieb ganz außerhalb von Play), für ein bestehendes Play-Konto nennt die Play-Seite keine zusätzliche Gebühr.
- **Prüfschritt:** Die Console zeigt die App als registriert, auch für den Vertrieb außerhalb von Play.
- Store-Regeln: [G-41](STORE-RICHTLINIEN.md#g-41), [G-52](STORE-RICHTLINIEN.md#g-52)
- **Wenn es nicht klappt:** Der Paketname ist schon bei einem anderen Entwickler registriert: Die Paket-ID bleibt fest (Schritt 6.2). Stattdessen die Registrierung bei Google beantragen (zusätzliche Prüfung). Ein Signaturschlüssel ist verloren: Dann lässt sich das Paket nicht registrieren, Schlüssel sicher verwahren (Schritt 19.3).
- [ ] erledigt

### 6.13 Hinweise für die Prüfung

- **Wer:** Betreiber trägt ein, Entwickler liefert den Text.
- **Was:** Im Feld für Prüfhinweise schreiben: keine Anmeldung nötig; wo der Wecker gestellt wird; wie Chromecast und Android Auto getestet werden; Herkunft der Inhalte (laut.fm-Vereinbarung, Schritt 17.7).
- **Wozu:** Prüfer, die eine Funktion nicht finden, lehnen ab.
- **Wo eintragen:** Play Console > "Monitor and improve" > "Policy and programs" > "App content" > "Sign-in details" (Feld "Any other instructions" für Hinweise). Microsoft: Partner Center > Einreichung > "Hinweise für die Zertifizierung".
- **Woher:** Textvorschläge in [STORE-TEXTE.md](STORE-TEXTE.md).
- **Prüfschritt:** Das Google-Feld ist ausgefüllt. Das Microsoft-Feld folgt in Schritt 7.7.
- Store-Regeln: [G-30](STORE-RICHTLINIEN.md#g-30), [M-03](STORE-RICHTLINIEN.md#m-03), [M-22](STORE-RICHTLINIEN.md#m-22)
- **Wenn es nicht klappt:** Die Angaben werden abgelehnt: Unter "Manage" korrigieren, "Save", dann in "Publishing overview" bei "Changes ready to send for review" "Send for review" klicken. Die Google-Doku sagt nichts dazu, was bei einer App ohne Anmeldung einzutragen ist. Der Inhalt der Prüfhinweise ist unsere Empfehlung, keine Google-Vorgabe. Die Microsoft-Hinweise stehen in Schritt 7.7.
- [ ] erledigt

---

## 7. Microsoft Partner Center (Windows-Store)

Quelle: [packaging/windows/README.md](../packaging/windows/README.md).

### 7.1 Konto und App-Name

- **Wer:** Betreiber.
- **Was:** Als **Firma** (Company account) über <https://storedeveloper.microsoft.com> registrieren, kostenlos (abgerufen 26.11.2026). Bestätigung per D-U-N-S-Nummer (schneller) oder Firmendokumenten (manuelle Prüfung, 2 bis 5 Werktage). Die E-Mail muss zur Domain der Firma passen, Gmail und ähnliche gehen nicht. Ein Einzelkonto lässt sich später nicht in ein Firmenkonto umwandeln. Danach Namen "LINEFM Radio" reservieren. Store-Regeln: [M-12](STORE-RICHTLINIEN.md#m-12), [M-20](STORE-RICHTLINIEN.md#m-20), [D-02](STORE-RICHTLINIEN.md#d-02).
- **Wozu:** Ohne Konto kein Store-Eintrag.
- **Wo eintragen:** Nur der Einstieg über <https://storedeveloper.microsoft.com> ("Get started", dann "Company account (free)") führt in den kostenlosen Ablauf, andere Wege zeigen den alten. Der alte Link `partner.microsoft.com/dashboard/registration` ist in der Doku nicht als Einstieg genannt, nicht geprüft, ob er noch gilt. Im Formular: Firma, "Email for verification" (Arbeitsadresse auf der Firmendomain, Gmail und Yahoo gehen nicht), D-U-N-S-Nummer (9 Ziffern) oder amtliche Firmendokumente (Handelsregisterauszug, Gewerbeanmeldung). Passt die Domain nicht zur Firma, verlangt Microsoft einen Domainnachweis. Nach der Prüfung "Publish to Store", dann öffnet sich "Apps & Games overview" (Direktlink <https://aka.ms/submitwindowsapp>). Quelle: <https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account> (abgerufen 26.11.2026). Wie genau der Namen reserviert wird, steht auf <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/reserve-your-apps-name>, die Schaltflächen dort haben wir nicht geprüft. Deutsche Menünamen sind nicht belegt, die Doku ist englisch.
- **Woher:** Ausweis, Kontaktdaten.
- **Prüfschritt:** Die "Verification summary" zeigt die drei Prüfungen als abgeschlossen. Nach der Namensreservierung erscheint die App im Partner Center unter "Apps & Games". Es kann bis zu 5 Minuten (Kachel) und bis zu 30 Minuten (Prüfstatus) dauern.
- **Wenn es nicht klappt:** Die Prüfung läuft nicht automatisch durch: Sie geht in die manuelle Prüfung (2 bis 5 Werktage, Mail kommt). Verlangt Microsoft Unterlagen, steht die Aufgabe auf der "Verification summary". Pro Prüfart sind höchstens drei Widersprüche möglich, deshalb nur aktuelle, richtige Dokumente hochladen. Falsche Firmenangabe: Du kannst sie ändern, die Prüfung startet dann von vorn. Du siehst "Apps & Games" nicht: Ein Kollege hat womöglich den Tenant schon eingerichtet, dann muss ein Owner oder Manager dir unter Account settings > User management eine Rolle geben. Aus Versehen als Einzelperson registriert: Es braucht ein neues Firmenkonto, eine Umwandlung gibt es nicht. Name "LINEFM Radio" schon vergeben: Mit dem Entwickler klären.
- [ ] erledigt

### 7.2 Produktidentität

- **Wer:** Betreiber kopiert die Werte und trägt sie als Variablen selbst ein, Entwickler nennt die Namen.
- **Was:** Vier Angaben kopieren (Name, Herausgeber, Anzeigename des Herausgebers und die Store-ID): Im Partner Center die App öffnen, links "Product management" aufklappen, "Product identity" wählen (<https://learn.microsoft.com/en-us/windows/apps/publish/view-app-identity-details>, abgerufen 26.11.2026). Deutsche Menünamen nicht belegt.
- **Wozu:** Der Build trägt sie in das Paket ein, sonst lehnt der Store es ab.
- **Wo eintragen:** Je eine Variable pro Wert (Schritt 1.3, Tab "Variables" > "New repository variable"): `MS_STORE_IDENTITY_NAME` (`Package/Identity/Name`), `MS_STORE_PUBLISHER` (`Package/Identity/Publisher`, Form `CN=…`, nicht in der Doku belegt), `MS_STORE_PUBLISHER_DISPLAY_NAME` (`Package/Properties/PublisherDisplayName`) und `MS_STORE_PRODUCT_ID` (Store-ID, laut Microsoft auf derselben Seite, Länge und Format haben wir nicht geprüft).
- **Woher:** Partner Center, Produktverwaltung.
- **Prüfschritt:** Alle vier Variablen stehen in der Liste, der Windows-Build meldet keinen fehlenden Wert.
- **Wenn es nicht klappt:** Das Paket wird abgelehnt: Name, Publisher oder PublisherDisplayName im Paket weichen von "Product identity" ab. Genau neu von dort kopieren, ohne Leerzeichen am Ende. Package Family Name und Package SID stehen auch dort, werden aber hier nicht gebraucht.
- [ ] erledigt

### 7.3 Azure-AD-Anwendung für die Pipeline

- **Wer:** Betreiber klickt im Partner Center und in Entra und trägt die Secrets selbst ein, Entwickler schaut per Bildschirmfreigabe zu und nennt die Namen. Die erste Veröffentlichung macht der Betreiber von Hand, das Paket dafür bekommt er vom Entwickler aus dem Release.
- **Was:** Damit GitHub später selbst Updates im Microsoft Store einreichen darf, bekommt es einen eigenen Zugang (eine "Anwendung" in deinem Microsoft-Verzeichnis). Reihenfolge für Microsoft (eine Liste, nur hier): 1. 7.1 Konto, 2. 7.6 Lizenz, 3. 7.2 Produktidentität, 4. 7.5 Store-Eintrag und 7.7 Hinweise, 5. 7.8 Entra-Verzeichnis und Anwendung (macht nur die Anwendung, noch kein Client-Secret), 6. dieser Schritt: Client-Secret erzeugen, Partner-Center-Rolle "Manager" für die Anwendung vergeben, vier Secrets eintragen. Zuerst die App **einmal von Hand** im Partner Center veröffentlichen (das Paket dafür lädst du aus einem Release herunter, der Entwickler zeigt dir wie) (Name reservieren, erste Einreichung samt Altersfragebogen, Veröffentlichung abwarten). Die Pipeline nutzt die Store-CLI `msstore`, und die kann laut Microsoft keine App anlegen und nicht die erste Veröffentlichung machen. Updates per CLI gehen derzeit nur für kostenlose Produkte (<https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/overview>, abgerufen 26.11.2026). Danach: Partner Center > Zahnrad-Symbol oben rechts > "Account settings" > "User management" > Reiter "Microsoft Entra applications" (früher Azure AD) > Anwendung hinzufügen, Rolle "Manager". Vorher muss ein Entra-Verzeichnis (Tenant) mit dem Partner-Center-Konto verbunden sein: "Account settings" > "Tenants" > "Associate Microsoft Entra ID with your Partner Center account", mit Entra-Zugangsdaten anmelden, "Confirm" (<https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/associate-existing-azure-ad-tenant-with-partner-center-account>). Ein privates Microsoft-Konto reicht für die CLI nicht, sie braucht Entra-Zugangsdaten. **[Entwickler]** Diesen Schritt macht der Entwickler mit dir per Bildschirmfreigabe.
- **Wozu:** `store-microsoft.yml` reicht damit den Entwurf ein (`--noCommit`, die Einreichung bleibt im Entwurf). Abgeschickt wird im Partner Center. Ein erneutes `publish` verwirft einen vorhandenen Entwurf. Deshalb gilt: Erst die Pipeline einmal laufen lassen, dann Beschreibung, Bilder, Altersfreigabe (Schritt 7.5) und Zertifizierungshinweise (Schritt 7.7) im Entwurf prüfen und ergänzen. Die Einträge aus der Handveröffentlichung bleiben für die erste Einreichung erhalten.
- **Wo eintragen:** Secrets `MS_STORE_TENANT_ID` (Verzeichnis-/Tenant-ID: <https://entra.microsoft.com/> > Identity > Overview > "Tenant ID"), `MS_STORE_CLIENT_ID` (Entra admin center > Identity > Applications > App registrations > die Anwendung > "Application (client) ID"), `MS_STORE_CLIENT_SECRET` (App registrations > die Anwendung > "Certificates & secrets" > "Client secrets" > "New client secret", Beschreibung und Ablauf wählen, "Add", den Wert **sofort** kopieren, er wird nur einmal angezeigt) und `MS_STORE_SELLER_ID` (Account settings > Organization profile > Identifiers, Reiter "Publisher"; alternativ Legal info > Reiter "Developer". Die Microsoft-Doku nennt beide Orte uneinheitlich, nicht abschließend geprüft). Quelle: <https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/github-actions> (abgerufen 26.11.2026).
- **Woher:** Partner Center und Entra admin center. Das Client-Secret hat ein Ablaufdatum (höchstens 24 Monate, Microsoft empfiehlt unter 12), notiere es im Fristenkalender (Schritt 20.5, den du schon in Phase 3 anlegst). Um die Anwendung in Entra anzulegen, kann ein Globaler Administrator des Verzeichnisses nötig sein.
- **Prüfschritt:** Nach einem Release erscheint ein Entwurf im Partner Center.
- **Wenn es nicht klappt:** Lauf rot mit "AADSTS7000215" oder "invalid client secret": Das Client-Secret ist falsch oder abgelaufen. Unter "Certificates & secrets" ein neues erzeugen und `MS_STORE_CLIENT_SECRET` überschreiben. Meldung "Unauthorized": Die Anwendung hat im Partner Center nicht die Rolle "Manager" oder der Tenant ist nicht mit dem Konto verbunden. Die Einreichung bricht ab, weil die App noch nie veröffentlicht war: erste Veröffentlichung von Hand nachholen (siehe oben). Beide Fehlertexte stammen aus der Praxis, die Microsoft-Doku nennt keine Codes (nicht geprüft).
- [ ] erledigt

### 7.4 Zertifikat für den Installer (optional)

- **Wer:** Betreiber kauft das Zertifikat, Entwickler richtet die Signatur ein.
- **Was:** Entscheidung vom 27.11.2026: Der Windows-Installer wird vorerst **ohne Signatur** ausgeliefert, du kaufst jetzt kein Zertifikat. Du musst hier nichts tun: Schreibe "entfällt" daneben und hake den Schritt ab (Regel aus der Einleitung). Dieser Schritt bleibt für später, falls du ein Codesigning-Zertifikat (eine digitale Unterschrift für Programme) für den Installer auf GitHub willst. Ohne Zertifikat zeigt Windows SmartScreen beim ersten Start des Installers die Meldung "Der Computer wurde durch Windows geschützt". Nutzer klicken "Weitere Informationen" und dann "Trotzdem ausführen". Diesen Hinweis legst du mit dem Entwickler auf die Download-Seite und in die Release-Beschreibung (Wortlaut der Meldung erfahrungsgemäß, nicht gegen die Microsoft-Doku geprüft). Der Store-Weg (Schritt 7.1 bis 7.3) ist nicht betroffen, Microsoft signiert dort selbst.
- **Wozu:** Der Store braucht keins, Microsoft signiert selbst (<https://learn.microsoft.com/en-us/windows/apps/publish/store-readiness-checklist>, abgerufen 26.11.2026). Ohne Zertifikat zeigt Windows SmartScreen beim Installer erfahrungsgemäß eine Warnung (in den Microsoft-Seiten nicht belegt, nicht geprüft). Optionen für Signierung: <https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options>, nicht gelesen.
- **Wo eintragen:** Secrets `WINDOWS_CERT_PFX_BASE64` und `WINDOWS_CERT_PASSWORD`.
- **Woher:** Ein Zertifikatsanbieter (kostenpflichtig, kostenlose Wege prüfen).
- **Prüfschritt:** Ohne Zertifikat entfällt die Prüfung. Mit Zertifikat zeigt der Installer in den Dateieigenschaften eine digitale Signatur.
- **Was damit signiert wird:** die App-EXE, der Setup-Stub (er ist zugleich `uninstall.exe`), das Setup-Fenster `linefm_setup.exe` und die fertige `setup.exe`. Die CI prüft die Signatur der `setup.exe` mit `signtool verify`. Das Zertifikat sollte auf den Hersteller "LineFM Studios" lauten, so steht er auch in den Dateieigenschaften und unter "Installierte Apps".
- **Bedienung des Installers:** [BAUEN-UND-STARTEN.md](BAUEN-UND-STARTEN.md), Abschnitt "Windows: Installer benutzen".
- Store-Regeln: [D-09](STORE-RICHTLINIEN.md#d-09)
- **Wenn es nicht klappt:** Windows warnt trotz Zertifikat: Neue Zertifikate brauchen eine Weile, bis SmartScreen ihnen vertraut. Lauf rot bei `signtool`: Passwort in `WINDOWS_CERT_PASSWORD` prüfen und die Datei neu als Base64 eintragen (Schritt 1.3).
- [ ] erledigt

### 7.5 Store-Eintrag

- **Wer:** Betreiber trägt ein, Entwickler liefert Texte und Bilder.
- **Was:** Beschreibung, 300 x 300-Logo, mindestens ein Screenshot, Altersfreigabe über den **IARC-Fragebogen** (derselbe Fragenkatalog wie bei Google, übernimm die Antworten aus Schritt 6.5; Seite "Age ratings", Fragebogen beantworten, "Save and generate"; die Einstufung ergibt sich aus den Antworten, ein festes 13+ wählst du nicht, Ziel: Einstufung ab 13 wie in allen Stores (Schritt 17.10), danach prüfen), Datenschutz-URL (Seite "Properties", Abschnitt "Privacy policy", bei Desktop-Apps laut Microsoft immer Pflicht), Support-Kontakt (Properties, "Support info", Adresse aus Schritt 20.1), Hinweise für die Zertifizierung (so nennt Microsoft die Prüfung vor der Veröffentlichung, Schritt 7.7). Quellen: <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/age-ratings>, <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/enter-app-properties>, <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/manage-submission-options> (abgerufen 26.11.2026). Nicht geprüft: Logo- und Screenshot-Maße, die Option für Werbung in den Produktdeklarationen, deutsche Menünamen. Bestätige außerdem deine E-Mail unter <https://partner.microsoft.com/dashboard/actioncenter/mypreferences>, damit Mails von Microsoft ankommen.
- **Wo eintragen:** Partner Center (<https://aka.ms/submitwindowsapp>), dort `LINEFM Radio` anklicken und die Einreichung öffnen. Texte aus [STORE-TEXTE.md](STORE-TEXTE.md), Abschnitt "Microsoft Store".
- **Wozu / Woher:** Sichtbar im Store. Datenschutz-URL `https://app.linefm.de/datenschutz/`.
- **Prüfschritt:** Die Einreichung zeigt keine offenen Pflichtfelder.
- **Werbung:** In den Produkteigenschaften "nein" (kein Werbe-SDK, Spots kommen von den Sendern).
- **Texte und Screenshots zur Einstufung 13+ passend:** Auch sichtbare Songtitel in Screenshots prüfen.
- **Erreichbarkeit:** laut.fm und die Webressourcen der App müssen während der Zertifizierung laufen. Nicht einreichen, während eine Störung bekannt ist.
- Store-Regeln: [M-05](STORE-RICHTLINIEN.md#m-05), [M-07](STORE-RICHTLINIEN.md#m-07), [M-18](STORE-RICHTLINIEN.md#m-18), [M-22](STORE-RICHTLINIEN.md#m-22), [M-26](STORE-RICHTLINIEN.md#m-26), [M-27](STORE-RICHTLINIEN.md#m-27), [M-29](STORE-RICHTLINIEN.md#m-29)
- **Wenn es nicht klappt:** Zertifizierung scheitert: Häufige Gründe sind eine fehlende Datenschutz-URL, eine fehlende Testanleitung in den Zertifizierungshinweisen oder ein Dienst (laut.fm), der während der Prüfung offline ist. Screenshots abgelehnt: Sie müssen echte PNG-Dateien sein und die aktuelle Version zeigen. Altersfreigabe in einem Land ausgeschlossen: In der Mail von IARC steht ein Widerspruchslink. Rote Felder in der Einreichung: Jedes anklicken, Microsoft nennt den fehlenden Wert. Vor dem Einreichen das Windows App Certification Kit laufen lassen (Entwickler).
- [ ] erledigt

### 7.6 Lizenz der Windows-Abspielbibliothek

- **Wer:** Betreiber mit Anwalt, Entwickler liefert die technischen Angaben.
- **Was:** Die Windows-Version spielt den Ton über die fertig gebaute Bibliothek libmpv ab (ein Baustein eines Dritten, der Audio abspielt). Deren Lizenz (GPL oder LGPL, je nach Bauweise) muss vor dem Microsoft Store geklärt sein.
- **Wozu:** Je nach Lizenz gelten Pflichten, zum Beispiel Quelltext oder Lizenztext mitzuliefern. Das kann mit der proprietären App kollidieren.
- **Wo eintragen:** Ergebnis in die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md), Abschnitt C.
- **Woher:** Anwalt, mit der Lizenzliste aus [LIZENZEN-DRITTE.md](LIZENZEN-DRITTE.md).
- **Prüfschritt:** Eine schriftliche Einschätzung liegt vor.
- **Wenn es nicht klappt:** Ist die Lizenz nicht vereinbar, sucht der Entwickler einen anderen Weg. Bis dahin keine Einreichung im Microsoft Store.
- [ ] erledigt

### 7.7 Hinweise für die Zertifizierung (Microsoft)

- **Wer:** Betreiber trägt ein, Entwickler liefert den Text.
- **Was:** Im Partner Center beim Einreichen erklären, wie Prüfer die App testen: keine Anmeldung nötig; wo der Wecker gestellt wird; dass die Streams von laut.fm kommen und woher die Rechte stammen (Schritt 17.7); dass die App eine Internetverbindung braucht.
- **Wozu:** Prüfer, die eine Funktion nicht finden oder die Quelle der Inhalte nicht kennen, lehnen ab.
- **Wo eintragen:** Partner Center > die App > Einreichung > "Submission options" > "Notes for certification" (englische Namen, deutsche nicht geprüft; Quelle: <https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/manage-submission-options>, abgerufen 26.11.2026).
- **Woher:** Textvorschläge in [STORE-TEXTE.md](STORE-TEXTE.md).
- **Prüfschritt:** Das Feld ist ausgefüllt, die Einreichung zeigt dort keine roten Felder.
- **Wenn es nicht klappt:** Die Zertifizierung scheitert mit Rückfrage zu Funktionen: Den Wortlaut der Rückmeldung lesen, den fehlenden Hinweis ergänzen und neu einreichen. Das Feld ist nur in einer offenen Einreichung bearbeitbar.
- [ ] erledigt


### 7.8 Entra-Verzeichnis und Anwendung für die Pipeline anlegen

- **Wer:** Betreiber klickt, Entwickler schaut per Bildschirmfreigabe zu und erklärt.
- **Was:** Für Schritt 7.3 brauchst du ein Microsoft-Entra-Verzeichnis (Tenant) und darin eine registrierte Anwendung. Kurz: erst nachsehen, ob schon ein Verzeichnis existiert, sonst eines anlegen, dann die Anwendung anlegen. Zuerst prüfen, ob dein Partner-Center-Konto schon eines hat: Partner Center > Zahnrad-Symbol oben rechts > "Account settings" > "Tenants". Gibt es keines, legst du eines an: <https://portal.azure.com> > "Microsoft Entra ID" > "Overview" > "Manage tenants" > "Create" > Typ "Microsoft Entra ID" > "Organization name", "Initial domain name", Land > "Review + Create" > "Create" (Quelle: <https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant>, abgerufen 26.11.2026). Laut Microsoft können nur zahlende Kunden so einen weiteren Tenant anlegen, ein Gratis- oder Testkonto nicht. Wer keinen hat, kann sich bei Microsoft für ein Azure-Konto anmelden, das den Tenant mitbringt (Azure-Gratiskonto, Kosten und Bedingungen dort prüfen, nicht geprüft). Die Verbindung des Tenants mit dem Partner Center und das Hinzufügen der Anwendung mit der Rolle "Manager" beschreibt Schritt 7.3: Mache zuerst den Tenant und die App-Registrierung hier, dann Schritt 7.3. Die Anwendung selbst legst du im Entra admin center an: <https://entra.microsoft.com> > "Entra ID" > "App registrations" > "New registration" (Name zum Beispiel "LINEFM Store Pipeline", nur dieser Verzeichnis-Mandant, "Register"). Der Menüpfad "App registrations" stammt aus der Microsoft-Doku zur Pipeline (Quelle: <https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/github-actions>), die Schaltfläche "New registration" haben wir nicht live geprüft.
- **Wozu:** Die Pipeline meldet sich mit dieser Anwendung beim Partner Center an. Ohne sie kein automatischer Upload.
- **Wo eintragen:** Die vier Werte landen als Secrets (Schritt 7.3).
- **Woher:** Entra admin center und Partner Center. **[Entwickler]** macht das mit dir per Bildschirmfreigabe.
- **Prüfschritt:** Unter "App registrations" steht die Anwendung, im Partner Center unter "Microsoft Entra applications" ist sie erst nach Schritt 7.3 mit Rolle "Manager" eingetragen.
- **Wenn es nicht klappt:** "Create" ist grau oder "Microsoft Entra ID" nicht wählbar: Dein Konto ist nicht zahlend oder hat die Rolle "Tenant Creator" nicht (Microsoft-Hinweis). Dann den Weg über das Azure-Konto gehen oder den Entwickler fragen.
- [ ] erledigt


---

## 8. Linux: Flathub und Snap Store

### 8.1 Flathub

Quelle: [packaging/flathub/README.md](../packaging/flathub/README.md).

- **Wer:** Entwickler reicht bei Flathub ein (Betreiber stimmt vorab zu). Betreiber legt die Verifizierungsdatei auf der Hauptdomain `linefm.de` ab (die Datei liefert der Entwickler, sobald Flathub den Inhalt nennt). Die Screenshots für Flathub hostet der Entwickler (Schritt 14.1).
- **Was:** Flathub ist der große App-Laden für Linux. Die Einreichung macht der Entwickler. Du stimmst vorab per Mail zu und legst später eine Textdatei auf `linefm.de` ab. Vorher Schritt 13.3 (Altersangabe in der Metainfo). Domain bestätigen, Weitergabe erlauben, dann einreichen.
- **Wozu:** Flathub prüft, dass `de.linefm.app` dir gehört, und braucht die Erlaubnis zur Weiterverteilung. LINEFM Radio ist proprietär. Das ist bei Flathub erlaubt, wenn du die Weitergabe ausdrücklich erlaubst. Schriftlich bestätigen (Nutzungsrechtevertrag, Schritt 2.5).
- **Wo eintragen:**
  1. Datei `https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` auf der Hauptdomain bereitstellen, **nach** der Aufnahme der App bei Flathub (die Verifizierung geht erst, wenn du Zugriff auf das Flathub-Repository der App hast, die Einladung kommt bei Aufnahme). Den Inhalt zeigt dir das Flathub Developer Portal unter "Verification" (bei Flathub anmelden, "Developer Portal", App wählen, "Verification"; <https://docs.flathub.org/docs/for-app-authors/verification>, abgerufen 26.11.2026). HTTPS ist Pflicht, Weiterleitungen werden befolgt. Der Ablauf: erst einreichen, nach der Aufnahme das Portal öffnen, dann die Datei ablegen (Quelle: <https://docs.flathub.org/docs/for-app-authors/verification>, abgerufen 26.11.2026). Das geht nur über `linefm.de`, die du verwaltest. Wie du die Datei ablegst, hängt davon ab, wo `linefm.de` liegt (Schritt 1.6, Punkt 4): meist legst du sie beim Webhoster in der Dateiverwaltung in den Ordner `.well-known` im Hauptverzeichnis der Domain ab, der Entwickler zeigt es dir (nicht geprüft).
  2. Altersangabe (OARS, Alterseinstufung bei Linux-Stores) in der Metainfo bestätigen, wegen Kraftausdrücken bei +RAP.
  3. Screenshots im Netz bereitstellen, URLs in der Metainfo eintragen (dort stehen Platzhalter).
  4. Einreichung als Änderungsvorschlag gegen den Zweig `new-pr` (nicht `master`) von `flathub/flathub`: forken (die Option "Copy the master branch only" **nicht** anhaken), `new-pr` klonen, Dateien committen, Änderungsvorschlag mit Titel "Add de.linefm.app" öffnen (<https://docs.flathub.org/docs/for-app-authors/submission>, abgerufen 26.11.2026). Nach der Aufnahme lädt Flathub den Maintainer in ein neues Repo ein: Zwei-Faktor-Anmeldung bei GitHub aktivieren und die Einladung **innerhalb einer Woche** annehmen. Der Entwickler bereitet ihn vor. Der Entwickler reicht mit seinem GitHub-Konto ein, du stimmst vorab per Mail zu.
- **Woher:** Inhalt der Verifizierungsdatei von Flathub.
- **Prüfschritt:** `curl -s https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` liefert den Inhalt. Flathub bestätigt die Verifizierung.
- **Ehrlicher Hinweis:** Unser Paket enthält die fertig gebaute Binärdatei, nicht den Quelltext. Laut Flathub-Anforderungen müssen Einreichungen mit offenem Quelltext vollständig aus dem Quelltext gebaut werden, vorkompilierte Binärdateien dürfen nicht im Änderungsvorschlag liegen, und nicht weitergebbare Inhalte gehören in eine `extra-data`-Quelle (<https://docs.flathub.org/docs/for-app-authors/requirements>). Am 27.11.2026 erneut gelesen: Flathub verlangt, dass alles Gehostete weitergegeben werden darf, Vorkompiliertes darf nicht im Änderungsvorschlag liegen, Ausnahmen gibt es nur fallweise für bekannte Hersteller. Ob eine selbst gehostete, weitergebbare Binärdatei ohne `extra-data` akzeptiert wird, steht in der offiziellen Doku weiterhin nicht (nicht geprüft). Eine eigene Seite zu proprietärer Software gibt es auf docs.flathub.org nicht. Es kann sein, dass Flathub ablehnt oder eine Ausnahme verlangt. Das klärst du nur durch Nachfragen bei den Flathub-Betreuern (Ticket im Repo `flathub/flathub`). Scheitert es, bleiben Snap Store und der Tarball auf GitHub.
- **Wer pflegt das Flathub-Repo:** Nach der Aufnahme legt Flathub ein eigenes Repo für das Manifest an. Ein Mensch (LineFM Studios oder in deinem Auftrag Tim Hauke) legt es an und pflegt es. Flathub verbietet KI-erzeugte Inhalte in Manifesten sowie Einreichungen und Antworten durch KI. Der Anteil von KI an der App wird Flathub gegenüber offengelegt, nur dort.
- **Pflege sichtbar halten:** Flathub achtet auf nachvollziehbare Historie, echte Nutzung und sichtbare Pflege. Releases mit Datum in der Metainfo, Fragen der Betreuer zügig beantworten.
- **Gewählter Weg (27.11.2026):** Die Verifizierung läuft über die Datei unter `/.well-known/` auf `linefm.de`, nicht über einen DNS-TXT-Eintrag. Die Datei muss ohne Weiterleitung auf der Hauptdomain liegen, also dort, wo der Web-Server von `linefm.de` sie ausliefert. Der Entwickler prüft, dass die Hosting-Konfiguration `/.well-known/` durchreicht.
- Store-Regeln: [F-04](STORE-RICHTLINIEN.md#f-04), [F-12](STORE-RICHTLINIEN.md#f-12), [F-15](STORE-RICHTLINIEN.md#f-15), [F-16](STORE-RICHTLINIEN.md#f-16), [F-20](STORE-RICHTLINIEN.md#f-20)
- **Wenn es nicht klappt:** Flathub meldet "verification failed": Die Datei ist nicht unter genau dieser Adresse erreichbar oder enthält Leerzeichen. Mit dem Browser prüfen. Taucht die App im Portal nicht auf, dort "Refresh" drücken. Der Linter meldet Fehler: Typisch sind `content-rating-missing` (OARS fehlt), `appstream-missing-screenshots`, `releases-info-missing` (Version mit Datum fehlt, das Datum darf nicht in der Zukunft liegen). Die Meldung an den Entwickler schicken, er korrigiert die Metainfo. Betreuer verlangen einen Bau aus dem Quelltext: Siehe Hinweis oben, dann mit dem Entwickler entscheiden. Die Einreichung kann bei übermäßig KI-erzeugten Inhalten geschlossen werden.
- [ ] erledigt

### 8.2 Snap Store

- **Wer:** Entwickler führt die Befehle aus. Das Snap-Konto legt der Betreiber an. Zugangsdaten gibst du nie weiter: Der Entwickler tippt die Befehle per Bildschirmfreigabe, du meldest dich dabei selbst an und trägst das Secret selbst ein.
- **Was:** Der Snap Store ist der App-Laden für Linux von Canonical (Ubuntu). **[Entwickler]** (Befehle `snapcraft register` und `export-login`). Das Hochstufen von "edge" auf "candidate" und "stable" macht der Entwickler nach deiner Freigabe. Konto von LineFM Studios anlegen, Snap-Namen `linefm-radio` mit diesem Konto registrieren (nicht mit einem Entwicklerkonto), Zugangsdaten für die Pipeline erzeugen. Im Snap-Dashboard unter "Website and contact links" Kontakt `support@linefm.de` und Website eintragen (<https://forum.snapcraft.io/t/store-listing-and-branding/16397>). Ob es dort auch ein Feld für die Datenschutz-URL gibt, ist in der offiziellen Doku nicht belegt: im Dashboard nachsehen.
- **Wozu:** `store-snap.yml` lädt jedes Release in den Kanal "edge".
- **Wo eintragen:** Secret `SNAPCRAFT_STORE_CREDENTIALS`.
- **Woher:** Konto auf <https://snapcraft.io/> (Ubuntu One: dort oben rechts anmelden bzw. registrieren, Menünamen nicht geprüft). Name per `snapcraft register linefm-radio`: Er lässt sich danach nicht ändern, erlaubt sind höchstens 40 Zeichen aus Kleinbuchstaben, Ziffern und Bindestrichen (<https://ubuntu.com/docs/snapcraft/stable/how-to/publishing/register-a-snap/>, abgerufen 26.11.2026). Zugangsdaten per `snapcraft export-login <Datei>`, der volle Befehl steht in [secrets.md](secrets.md). Der Inhalt der Datei kommt ins Secret, mit `snapcraft whoami` lässt sich Konto und Ablauf prüfen. Ablauf gibt es nur, wenn `--expires` gesetzt wurde, einen Standardablauf nennt die Doku nicht (<https://ubuntu.com/docs/snapcraft/stable/how-to/publishing/authenticate/>).
- **Prüfschritt:** Nach einem Release erscheint die Version im Kanal "edge". Das Hochstufen auf "candidate" und "stable" ist nicht in der gelesenen Doku belegt (nicht geprüft; die aktuelle Kanal-Doku war am 27.11.2026 ohne Konto nicht lesbar, sie leitet auf eine Anmeldeseite um). Ob die Tray-Funktion unter der strikten Snap-Absicherung läuft, ist noch ungetestet.
- Store-Regeln: [S-03](STORE-RICHTLINIEN.md#s-03), [S-06](STORE-RICHTLINIEN.md#s-06), [S-07](STORE-RICHTLINIEN.md#s-07), [S-08](STORE-RICHTLINIEN.md#s-08), [S-09](STORE-RICHTLINIEN.md#s-09)
- **Wenn es nicht klappt:** Lauf rot mit "credentials expired" oder "invalid macaroon": Zugangsdaten mit `snapcraft export-login` neu erzeugen und das Secret überschreiben. Name schon vergeben: Den Namensstreit im Snap-Forum melden (Namenskonflikte haben wir nicht geprüft). Die Datei von `export-login` existiert schon: Der Befehl bricht ab, anderen Dateinamen wählen. Mit Snapcraft 7 erzeugte Daten gehen nur mit Snapcraft 7 oder neuer. Der Name in der `snapcraft.yaml` muss zum registrierten passen (Entwickler).
- [ ] erledigt

---

## 9. Statistik und Absturzberichte (optional)

Ohne Konfiguration sendet die App nichts und fragt nicht nach Einwilligung. Technische Details: [telemetry.md](telemetry.md). **Telemetrie** heißt hier: anonyme Nutzungszahlen (Statistik) und Absturzberichte. Ob du sie willst, hast du in Schritt 1.6 entschieden. Hast du dort "ohne Telemetrie" gewählt, überspringst du den ganzen Abschnitt 9, er braucht dann keinen Haken.

### 9.1 Anbieter wählen und betreiben

- **Wer:** Entwickler richtet ein. Betreiber entscheidet, zahlt den Server und schließt den AVV ab (Schritt 2.4).
- **Was:** Eine Software für Nutzungsstatistik und Absturzberichte auf einem eigenen Server in Betrieb nehmen. Zur Auswahl stehen: Umami (Nutzungsstatistik), GlitchTip oder Sentry (Absturzberichte) und Firebase (beides, ein Dienst von Google). "Selbst hosten" heißt: Die Software läuft auf einem Server, den du mietest. Der Entwickler startet sie dort mit den Docker-Compose-Dateien in `deploy/telemetry/` (Docker Compose startet mehrere Programme gemeinsam). Die Befehle (`openssl`, `docker compose`) führt er aus, nicht du.
- **Wozu:** Du siehst, wie die App genutzt wird und wo sie abstürzt. Erfasst wird erst, wenn der Nutzer in der App zugestimmt hat.
- **Wo eintragen:** Auf dem Server, nicht in GitHub. Das macht der Entwickler. **Vor dem Start** legt er in `deploy/telemetry/.env` den Wert `UMAMI_APP_SECRET` an (erzeugt mit `openssl rand -hex 32`), sonst startet Umami nicht. Danach startet er alles mit `docker compose up -d`. Umami legt beim ersten Start das Konto `admin` mit dem Passwort `umami` an. **Dein Teil:** Sobald dir der Entwickler die Adresse der Umami-Seite nennt, öffnest du sie im Browser, meldest dich mit `admin` und `umami` an und änderst das Passwort sofort in den Profil- bzw. Kontoeinstellungen (genauer Menüname nicht geprüft). Das neue Passwort kommt in den Passwortmanager (Schritt 1.2). Das muss passieren, bevor Umami aus dem Internet erreichbar ist: Bitte den Entwickler, die Seite bis dahin zu sperren. Ab Umami 3.5.0 erzwingt Umami den Wechsel selbst (<https://docs.umami.is/docs/install>, abgerufen 26.11.2026). GlitchTip hat die Registrierung aus, das erste Konto legt der Entwickler auf der Kommandozeile an (Ablauf in telemetry.md).
- **Woher:** Eigene Installation auf einem gemieteten Server oder ein Cloud-Konto beim Anbieter. Der AVV (Vertrag, der dem Anbieter erlaubt, in deinem Auftrag Daten zu verarbeiten, Schritt 2.4) kommt zuerst.
- **Prüfschritt:** Du meldest dich mit dem neuen Passwort an, das Standardpasswort `umami` wird abgelehnt.
- **Wenn es nicht klappt:** Das Meiste klärt der Entwickler, du gibst nur Bescheid. Umami startet nicht: Die Datei `deploy/telemetry/.env` mit `UMAMI_APP_SECRET=` fehlt oder ist leer. Anmeldung mit `admin`/`umami` klappt noch: Sofort das Passwort ändern und Umami so lange vom Internet trennen. Anderer Container startet nicht: Protokoll mit `docker compose logs` ansehen und an den Entwickler schicken. GlitchTip: Das erste Konto legt der Entwickler an (`docker compose exec glitchtip ./manage.py createsuperuser`, siehe telemetry.md).
- [ ] erledigt

### 9.2 Werte eintragen

- **Wer:** Betreiber trägt ein, Entwickler nennt die Werte.
- **Was:** Die Kennungen der Dienste (Adressen und IDs) in GitHub hinterlegen, damit der nächste Build die Dienste kennt. Der Entwickler nennt dir die Werte.
- **Wozu:** Ohne diese Werte bleibt die Telemetrie aus. Es sind keine Geheimnisse, sie stehen später im fertigen Programm. Ausnahme: `FIREBASE_CONFIG_JSON` legst du aus technischen Gründen als Secret an (siehe Schritt 5.3).
- **Wo eintragen:** In GitHub: Repository > `Settings > Secrets and variables > Actions` > Reiter "Variables" > "New repository variable", Name und Wert eintragen, "Add variable" (ausführlich in Schritt 1.3). Diese Variablen gibt es: `UMAMI_URL` (Adresse deiner Umami-Seite), `UMAMI_WEBSITE_ID` (Kennung der Website in Umami), `SENTRY_DSN` (die Adresse, an die die App Absturzberichte schickt, "DSN" genannt, gilt auch für GlitchTip) und `SENTRY_ENVIRONMENT` (Name der Umgebung, den der Entwickler vorgibt). Für Firebase legst du im Reiter "Secrets" > "New repository secret" das Secret `FIREBASE_CONFIG_JSON` an, Inhalt ist ein JSON-Text mit `FIREBASE_*`-Schlüsseln. Für die Arbeit am eigenen Rechner nutzt der Entwickler `config/app.yaml` nach Vorlage `config/app.example.yaml` (nicht einchecken, siehe [Konfiguration](KONFIGURATION.md)).
- **Woher:** Aus den Oberflächen der Dienste, oder der Entwickler nennt dir die Werte. Umami: Website-ID bei der Website in den Umami-Einstellungen (Website bearbeiten, Bereich "Tracking code"; den genauen Pfad nennt die Umami-Doku nicht, nicht geprüft). Sentry: Projekt > Einstellungen > "Client Keys (DSN)" (<https://docs.sentry.io/concepts/key-terms/dsn-explainer/>). GlitchTip: DSN steht auf der Seite mit der Fehlerliste direkt nach dem Anlegen des Projekts, später in den Projekteinstellungen. Firebase: Projektübersicht > Web-Symbol > "App registrieren" (Register app), das angezeigte `firebaseConfig`-Objekt als JSON eintragen; gibt es schon eine App, zuerst "Add app" (<https://firebase.google.com/docs/web/setup>). Nicht geprüft: deutsche Menünamen.
- **Prüfschritt:** Öffne die Web-Version und stimme der Statistik bzw. den Absturzberichten zu, wenn die App fragt. Kurz darauf erscheint ein Ereignis in Umami. Einen Testabsturz in Sentry (GlitchTip) löst der Entwickler aus. Ohne Zustimmung geht nichts raus. Nach jeder Änderung der Werte muss der Entwickler die Web-Version neu bauen und die Server-Header neu ausrollen (Header sind Browser-Regeln der Seite, darunter die Sicherheitsrichtlinie, die festlegt, mit welchen Servern die Seite sprechen darf), sonst blockiert sie die neuen Adressen.
- **Wenn es nicht klappt:** Kein Ereignis kommt an: Erst prüfen, ob du in der App zugestimmt hast. Dann prüfen, ob die Web-Version neu gebaut und die Header neu ausgerollt sind. Meldet die Browser-Konsole "Content Security Policy" (Browser mit F12 öffnen, Reiter "Konsole"), sind die Header veraltet: Entwickler Bescheid geben.
- [ ] erledigt

### 9.3 Datenschutzangaben ergänzen

- **Wer:** Betreiber liefert die Angaben, Entwickler trägt sie in die Dateien ein.
- **Was:** Name des Betreibers der Dienste und die Speicherdauer in die Datenschutzerklärung eintragen lassen.
- **Wozu:** Mit aktiver Telemetrie muss die Datenschutzerklärung sagen, wer die Daten verarbeitet und wie lange sie bleiben. Leere Werte zählen als offen und stoppen den Release-Build.
- **Wo eintragen:** Du schickst die Angaben dem Entwickler. Er trägt sie in die Datei `legal_values.json` bzw. die Variable `LEGAL_VALUES_JSON` ein (Schritt 3.1), bei den Platzhaltern `{{TELEMETRIE_AUFBEWAHRUNG}}` (wie lange Daten bleiben), `{{UMAMI_BETREIBER}}` (wer Umami betreibt) und `{{SENTRY_BETREIBER}}` (wer Sentry bzw. GlitchTip betreibt).
- **Woher:** Betreiber der Instanz: Name und Anschrift deines Server-Anbieters, bei eigenem Betrieb deine Firma. Speicherdauer: deine Entscheidung, zum Beispiel "90 Tage". Stimme sie mit dem Entwickler ab, damit die Software dieselbe Frist einhält, und lass sie vom Anwalt bestätigen.
- **Prüfschritt:** Der Entwickler startet den Generator (das Programm, das aus den Vorlagen die Rechtstexte erzeugt) im Strengmodus `--strict` mit passender Angabe `--providers`. Er läuft ohne Fehler durch.
- **Wenn es nicht klappt:** Das klärt der Entwickler. Generator meldet den Platzhalter weiter als offen: `--providers` passt nicht zu den gesetzten Diensten, oder der Wert ist leer.
- [ ] erledigt

### 9.4 Funktionsschalter (optional)

- **Wer:** Entwickler.
- **Was:** Variable `FEATURES_JSON` für Funktionen, die standardmäßig aus sind. Zurzeit gibt es einen Schalter: Die App zeigt bei jedem Sender, wie viele Menschen gerade zuhören (Hörerzahl).
- **Wozu:** Ohne Variable bleibt alles aus, die App läuft trotzdem vollständig.
- **Wo eintragen:** GitHub-Variable `FEATURES_JSON` anlegen (Weg: Schritt 1.3, Reiter "Variables"). Als Wert genau diesen Text einfügen, am besten von hier kopieren: `{"showListenerCount": true}`.
- **Woher:** deine Entscheidung. Details in [Konfiguration](KONFIGURATION.md).
- **Prüfschritt:** Starte den nächsten Build (Ablauf "Pages" für die Web-Version oder "Release", Schritt 1.5) und öffne danach die App. Sie zeigt die Hörerzahl.
- **Wenn es nicht klappt:** Build rot mit einem JSON-Fehler: Anführungszeichen müssen gerade sein (`"`), nicht typografisch. Am besten den Wert von hier kopieren.
- [ ] erledigt

---

## 10. Search Console, GA4 und GTM

Das gilt nur für die Web-Version. Alles ist aus, solange du keine Werte einträgst.

### 10.1 Search Console

- **Wer:** Betreiber (Google-Konto und DNS), Entwickler bei der Meta-Tag-Variante.
- **Was:** Google Search Console ist Googles kostenloses Werkzeug, das zeigt, wie die Seite in der Google-Suche abschneidet. Du beweist Google, dass die Domain dir gehört (Bestätigung), und reichst die Sitemap ein (eine Liste aller Seiten, damit Google sie findet). Erst wenn die Domain live ist.
- **Wozu:** Du siehst Suchanfragen, Indexierung und Fehler.
- **Wo eintragen:** <https://search.google.com/search-console>, angemeldet mit dem Google-Konto, das die Seite verwalten soll. Bevorzugt ist eine **Domain-Property** (ein Eintrag für `linefm.de` samt allen Unteradressen). Dafür brauchst du Zugang zum **DNS-Anbieter**, also dort, wo die Domain verwaltet wird (Abschnitt 4).
  1. Oben links im Eigenschaftsmenü "Property hinzufügen" (Add property) wählen.
  2. "Domain" wählen, `linefm.de` eintragen, weiter.
  3. Methode "Domain name provider", Typ "TXT": Search Console zeigt einen Text. Kopieren.
  4. Beim DNS-Anbieter einen neuen **TXT-Eintrag** anlegen: Name leer oder `@` (je nach Anbieter), Wert = der kopierte Text, genau wie angezeigt. Speichern.
  5. Zurück in Search Console "Verify" (Bestätigen) klicken. Klappt es nicht sofort, siehe unten.
  6. Den TXT-Eintrag danach **nicht löschen**, sonst geht die Bestätigung verloren.
  - **Alternative nur für die Web-Version:** eine **URL-Präfix-Property** `https://app.linefm.de/` mit Meta-Tag (ein unsichtbarer Code im Seitenkopf):
    1. "Property hinzufügen" > "URL-Präfix", `https://app.linefm.de/` eintragen, Methode "HTML tag".
    2. Aus dem angezeigten Tag nur den Code im Feld `content` kopieren (der lange Wert zwischen den Anführungszeichen).
    3. Den Code als GitHub-Variable `GSC_VERIFICATION` anlegen (Weg: Schritt 1.3).
    4. Der Entwickler baut die Web-App neu und rollt sie aus (Schritt 1.5, Punkt 4). Der Web-Build setzt dann das Meta-Tag `google-site-verification` ein, ohne Wert entfernt er es.
    5. **Erst danach** in Search Console "Verify" klicken, sonst findet Google den Tag nicht.
  - **Sitemap einreichen** (bei beiden Wegen): In der linken Menüleiste "Sitemaps" öffnen, im Feld "Add a new sitemap" die Adresse `https://app.linefm.de/sitemap.xml` eintragen, "Submit" klicken. Die Adresse muss zur Property passen. Du brauchst Inhaberrechte an der Property.
- **Woher:** Search Console zeigt den TXT-Wert bzw. den Tag-Code. Der TXT-Wert hat das Format `google-site-verification=<Zeichenfolge>`, die Zeichenfolge ist je Konto einmalig, immer genau den angezeigten Wert kopieren (Quelle abgerufen 27.11.2026). Quellen: <https://support.google.com/webmasters/answer/9008080> und <https://support.google.com/webmasters/answer/7451001> (abgerufen 26.11.2026). Deutsche Menünamen nicht geprüft, die Doku lag nur auf Englisch vor.
- **Prüfschritt:** Search Console meldet "Inhaberschaft bestätigt". Die Sitemap zeigt Status "Erfolgreich".
- **Wenn es nicht klappt:** "TXT-Eintrag nicht gefunden" (verification DNS TXT record was not found): ein bis zwei Tage warten, dann erneut "Verify". "Eintrag stimmt nicht überein" (did not match): Das Namensfeld muss leer oder `@` sein, der Text steht im Wertfeld, genau wie angezeigt. Meta-Tag nicht gefunden: Die live ausgelieferte Startseite im Browser öffnen, Rechtsklick > "Seitenquelltext anzeigen", mit Strg+F nach `google-site-verification` suchen. Der Tag muss im `<head>` stehen und der Code exakt der angezeigte sein. Sitemap "Konnte nicht abgerufen werden" (Could not fetch): Prüfen, ob `https://app.linefm.de/sitemap.xml` im Browser lädt, ob `robots.txt` (Datei, die Suchmaschinen Sperren mitteilt) sie sperrt und ob die Seite noch `noindex` setzt (eine Anweisung, die Google bittet, die Seite nicht aufzunehmen, Schritt 3.1).
- [ ] erledigt

### 10.2 GA4 und Tag Manager

- **Wer:** Betreiber, Entwickler baut die Web-App neu.
- **Was:** Optional: Reichweitenmessung mit Google Analytics 4 (GA4, Googles Besucherstatistik), direkt oder über den Google Tag Manager (GTM, ein Container, in dem Messcodes verwaltet werden).
- **Wozu:** Du siehst, wie viele Menschen die Web-Version nutzen und welche Bereiche sie aufrufen. Die App fragt separat nach "Reichweitenmessung mit Google" (Google, USA-Übermittlung, EU-US Data Privacy Framework, Zweck). Standard ist abgelehnt. Erst nach Zustimmung lädt die App Google (Consent Mode v2: Google-Dienste richten sich nach der Entscheidung des Nutzers, die `ad_*`-Signale für Werbung bleiben abgelehnt). Die Sicherheitsrichtlinie (CSP, eine Browser-Regel, die festlegt, welche Server die Seite kontaktieren darf) wird beim Web-Build nur dann um `googletagmanager.com` und `google-analytics.com` erweitert, wenn du Werte setzt.
- **Wo eintragen:** GitHub-Variablen (Weg: Schritt 1.3) `GTM_ID` (Form `GTM-XXXXXXX`) und/oder `GA4_MEASUREMENT_ID` (Form `G-XXXXXXXXXX`). Eine von beiden reicht. Sie landen in `config/app.json`. Danach muss der Entwickler neu bauen und ausrollen.
- **Woher:** GTM-ID: <https://tagmanager.google.com> > Container. Falls noch kein GA4-Konto existiert, zuerst Schritt 10.3. Mess-ID: <https://analytics.google.com> > "Admin" (Verwaltung, Zahnrad unten links) > Property settings > "Data streams" (Datenstreams) > den Web-Stream anklicken > Bereich "Stream details", Feld Mess-ID (beginnt mit `G-`). Du brauchst dafür mindestens die Rolle Bearbeiter (Editor). Hast du das Konto selbst angelegt, hast du sie. Andernfalls vergibt ein Administrator sie unter Admin > "Account access management" (Menüname nicht geprüft). Quelle: <https://support.google.com/analytics/answer/9539598> (abgerufen 26.11.2026). Wo in der Oberfläche die Container-ID `GTM-XXXXXXX` steht, nennt die Google-Doku nicht (nicht geprüft). Findest du sie nicht, schick dem Entwickler einen Screenshot des Containers.
- **Einstellungen in GA4** (Datenschutz-Voreinstellungen, alle unter dem Zahnrad "Admin" unten links):
  1. Datenaufbewahrung auf 2 Monate: "Data Settings" > "Data Retention", dort 2 Monate wählen (zur Wahl stehen 2 oder 14 Monate) und speichern. Sie wirkt laut Google nur auf Explorationen und Trichter, nicht auf Standardberichte.
  2. Google-Signale aus: "Data collection and modification" > "Data Collection", den Schalter "Enable Google signals data collection" ausschalten.
  3. Datenfreigabe aus: "Account details", dort die vier Freigabe-Haken "Google products & services", "Modeling contributions & business insights", "Technical support" und "Recommendations for your business" abwählen. Das gilt für das ganze Konto.
  4. Auftragsverarbeitungsbedingungen akzeptieren (Schritt 2.4): "Account details" > Abschnitt "Data Processing Amendment" > "Review Amendment" > "Done", dann nochmals "Done". Bei neuen Konten sind sie laut Google automatisch akzeptiert. Danach Kontaktdaten hinterlegen.
  Quellen: <https://support.google.com/analytics/answer/7667196>, <https://support.google.com/analytics/answer/9445345>, <https://support.google.com/analytics/answer/1011397> (abgerufen 26.11.2026). Nicht geprüft: deutsche Menünamen, Voreinstellung der Haken bei neuen Konten. **In GTM keine Tags vom Typ "Benutzerdefiniertes HTML"** (eigener Programmcode im Container), die Sicherheitsrichtlinie blockt Inline-Skripte.
- **Datenschutz:** Der Abschnitt "Google Analytics" in der Datenschutzerklärung erscheint automatisch, wenn die Werte gesetzt sind. Dann ist der Platzhalter `{{GA4_AUFBEWAHRUNG}}` Pflicht: Nenne dem Entwickler die Speicherdauer, die du in GA4 eingestellt hast (zum Beispiel "2 Monate"). Er trägt sie in `legal_values.json` bzw. `LEGAL_VALUES_JSON` ein (Schritt 3.1). Lass das mit dem Anwalt abstimmen.
- **Prüfschritt:** Web-Version im Browser öffnen, F12 drücken (Entwicklerwerkzeuge), Reiter "Netzwerk" (Network), Seite neu laden. Vor der Zustimmung keine Anfrage an `google*`, nach der Zustimmung wird `gtm.js` geladen. In GA4 zeigt Berichte > Echtzeit den Besuch.
- **Wenn es nicht klappt:** Einstellungen nicht auffindbar oder nicht änderbar: Dafür brauchst du die Rolle "Bearbeiter" oder höher im Konto bzw. in der Property. Echtzeit zeigt nichts: In der App der Reichweitenmessung zustimmen, dann neu laden, Werbeblocker abschalten. Steht vor der Zustimmung schon `google` im Netzwerk-Reiter: sofort dem Entwickler melden, das wäre ein Datenschutzfehler. Die Datenaufbewahrung scheint wirkungslos: Sie gilt nur für Explorationen und Trichter. Hinweis für den Entwickler: Der Consent-Standardwert `denied` muss vor dem Google-Tag gesetzt werden (<https://developers.google.com/tag-platform/security/guides/consent>).
- [ ] erledigt

### 10.3 GA4-Konto, Datenstream und Tag-Manager-Container anlegen

- **Wer:** Betreiber.
- **Was:** Falls noch nicht vorhanden: ein GA4-Konto mit Datenstream und einen Tag-Manager-Container anlegen. Du brauchst dafür ein Google-Konto (empfohlen: ein Firmenkonto, kein privates, mit einer zweiten Person als Administrator). Begriffe: Ein **Konto** (Account) enthält **Properties** (Messbereiche, hier eine für die Web-App). Eine Property enthält **Datenstreams** (die einzelne Datenquelle, hier die Webseite).
  1. GA4: <https://analytics.google.com> > "Start Measuring" (oder in "Admin" > "Create" > "Account") > Kontoname, bei den Freigabe-Optionen ("Data sharing settings") die vier Haken "Google products & services", "Modeling contributions & business insights", "Technical support" und "Recommendations for your business" abwählen (Einzelheiten und Quellen in Schritt 10.2, Abschnitt "Einstellungen in GA4") > "Next" > Property-Name, Zeitzone, Währung > "Create" > Bedingungen und Auftragsverarbeitung akzeptieren (Schritt 2.4). Dann "Admin" > "Data streams" > "Add stream" > "Web" > Adresse `https://app.linefm.de` und Name > "Create stream". Die Mess-ID (`G-…`) steht danach im Stream unter "Stream details" (Quelle: <https://support.google.com/analytics/answer/9304153>, abgerufen 26.11.2026).
  2. Tag Manager (optional, nur wenn du den Container nutzt statt GA4 direkt): <https://tagmanager.google.com> > "Accounts" > "Create Account" > Kontoname, Land > Containername `app.linefm.de`, Typ "Web" > "Create" > Bedingungen akzeptieren (Quelle: <https://support.google.com/tagmanager/answer/6103696>, abgerufen 26.11.2026). Wo die Container-ID `GTM-…` angezeigt wird, nennt diese Seite nicht, sie steht oben im Container-Arbeitsbereich (nicht geprüft). Welche Tags im Container laufen, richtet der Entwickler ein (GA4-Konfigurations-Tag mit Mess-ID, Auslöser erst nach Einwilligung).
- **Wozu:** Ohne Konto und Stream gibt es keine Mess-ID für Schritt 10.2. **GA4 direkt oder Tag Manager:** Direkt reicht für die Reichweite, der Container ist nur nötig, wenn weitere Tags geplant sind. Empfehlung nach Aufwand: GA4 direkt.
- **Wo eintragen:** GitHub-Variablen `GA4_MEASUREMENT_ID` oder `GTM_ID` (Schritt 10.2, Weg zum Anlegen: Schritt 1.3).
- **Woher:** Google Analytics, Google Tag Manager.
- **Prüfschritt:** Unter "Data streams" steht der Web-Stream mit Mess-ID.
- **Wenn es nicht klappt:** Du siehst "Create" nicht: Du hast keine Administrator-Rolle im Konto. Das Konto gehört einer anderen Person: Dann deren Konto nutzen oder ein neues anlegen. Echtzeit zeigt nichts: Schritt 10.2.
- [ ] erledigt


---

## 11. Vertrauens-Badges: Gridinsoft und Trustpilot

### 11.1 Gridinsoft

- **Wer:** Betreiber.
- **Was:** Optional, nur prüfen (Entscheidung vom 27.11.2026): Gridinsoft ist ein Anbieter, der Websites auf Sicherheit und Ruf prüft (gridinsoft.com). Du schaust nach, wie die Domain eingestuft ist. Ein Badge (ein kleines Prüfsiegel zum Einbinden auf der Seite) binden wir nur ein, wenn Gridinsoft eines anbietet. Ob es ein offizielles Badge gibt, ist in der Anbieter-Doku **nicht belegt**. Gibt es keins, ist der Schritt mit der Prüfung erledigt.
- **Wozu:** Vertrauenssignal im Footer oder Vertrauensbereich der Web-App.
- **Wo eintragen:** GitHub-Variable `TRUST_GRIDINSOFT_URL` (Weg: Schritt 1.3), nur wenn es wirklich ein offizielles Badge gibt. Sonst nicht anlegen oder leer lassen, dann erscheint nichts.
- **Woher:** Prüfwerkzeug ohne Anmeldung: <https://gridinsoft.com/website-reputation-checker>, dort nacheinander `app.linefm.de` und `linefm.de` eingeben, die Prüfung starten und das Ergebnis jeweils als Bildschirmfoto sichern. Sieht das Ergebnis falsch aus, geht eine kostenlose Prüfanfrage über <https://portal.gridinsoft.com/register> (Konto nötig). Ein Konto-Profil zum Anlegen oder ein Badge für Website-Inhaber haben wir auf der Seite nicht gefunden. Nachfragen: auf der Seite "For Business" > "Integration & Licensing" (<https://gridinsoft.com/our-partners#contact-us>). Quelle: <https://gridinsoft.com> (abgerufen 26.11.2026). Das Anmeldeportal haben wir nicht eingesehen (nicht geprüft). Zeige nur ein Ergebnis, das echt und gut ist.
- **Prüfschritt:** Die Prüfseite zeigt für die Domain eine saubere Einstufung. Ist `TRUST_GRIDINSOFT_URL` gesetzt, öffnet der Link in der Web-App genau diese Seite.
- **Wenn es nicht klappt:** Du findest kein Badge zum Einbinden: Variable leer lassen, dann zeigt die Web-App nichts. Die Seite ist falsch eingestuft: kostenlose Prüfanfrage über <https://portal.gridinsoft.com/register>. Kein Badge zu sehen, obwohl die Variable gesetzt ist: Die Web-Version ist nicht neu gebaut: Der Entwickler muss neu bauen. Ein schlechtes Ergebnis zeigst du nicht.
- [ ] erledigt

### 11.2 Trustpilot

- **Wer:** Betreiber legt das Konto an, Entwickler bindet das Badge ein.
- **Was:** Kostenloses Unternehmenskonto bei Trustpilot (Bewertungsportal) anlegen, das Profil für die Domain beanspruchen und **nur das kostenlose Widget** (ein kleiner Bewertungskasten, bei Trustpilot "TrustBox" genannt) oder einen Link zum Profil einbinden (Entscheidung vom 27.11.2026). Kein bezahlter Tarif.
- **Wozu:** Öffentliche Bewertungen als Vertrauenssignal.
- **Wo eintragen:** GitHub-Variable `TRUST_TRUSTPILOT_URL` (Weg: Schritt 1.3): die Adresse der Profilseite, meist `https://de.trustpilot.com/review/<Domain>`. Das Format ist nicht in der Doku belegt: Öffne dein Profil im Browser und kopiere die Adresse aus der Adresszeile.
- **Woher:** Ablauf: (1) Unternehmenskonto mit Firmen-E-Mail anlegen, (2) Domain `linefm.de` angeben und das Profil beanspruchen (Trustpilot verlangt einen Nachweis, dass die Domain dir gehört, folge den Hinweisen am Bildschirm), (3) die Profil-Adresse kopieren, (4) wenn du ein Widget willst, den erzeugten Code an den Entwickler schicken, er baut ihn ein. Das Unternehmenskonto legst du an: <https://business.trustpilot.com/signup>. Es ist ein anderes Konto als ein normales Bewerterprofil. Widgets (TrustBox): <https://business.trustpilot.com/features/trustbox-widgets>, dort Typ wählen, einstellen, Code erzeugen. Regeln für Logo und Badge: <https://corporate.trustpilot.com/legal/for-businesses/legal-brand-guidelines> (abgerufen 26.11.2026). Ohne passenden Tarif darf der TrustScore (die Sternebewertung) nicht auf der eigenen Seite gezeigt werden, und manche Widgets gibt es nur in bezahlten Tarifen. Wähle deshalb nur ein Widget, das im Gratis-Konto frei verfügbar ist, sonst zeige nur einen Link zum Profil. Nicht geprüft: die Schritte zum Beanspruchen und die Domainbestätigung (die Trustpilot-Hilfe war nicht abrufbar), und welche Widgets im Gratis-Tarif frei sind. Nur Dinge zeigen, die echt sind.
- **Prüfschritt:** Das Profil ist im Business-Bereich sichtbar. Der Link oder das Widget in der Web-App öffnet das Profil.
- **Wenn es nicht klappt:** Trustpilot bietet für das kostenlose Konto kein passendes Widget an oder verweigert die Sterne: Das ist eine Tarifsache, und wir buchen keinen bezahlten Tarif. Setze nur einen Textlink zum Profil. Existiert noch kein Profil mit Bewertungen, zeigst du nichts (Variable leer).
- [ ] erledigt

---

## 12. Signierte Releases und Sicherheits-Scanner

### 12.1 Automatische Signatur (nichts zu tun)

- **Wer:** Entwickler (nichts für dich zu tun).
- **Was:** Jedes Release (veröffentlichte Version) bekommt automatisch eine GitHub-Attestierung (Build-Provenance, ein Herkunftsnachweis: Die Datei stammt aus diesem Repository) und eine digitale Signatur mit cosign über Sigstore, ohne eigenen Schlüssel ("keyless"). Die Signatur liegt als `*.sigstore.json` neben jeder Datei.
- **Wozu:** Nutzer können prüfen, dass eine Datei unverändert ist und aus diesem Repository stammt.
- **Wo eintragen:** nichts. Es läuft ohne Zutun.
- **Woher:** entfällt.
- **Prüfschritt:** Öffne im Repository rechts "Releases", dann ein Release und darin "Assets" (die Dateiliste): Dort hängen `*.sigstore.json`-Dateien. Die Prüfbefehle stehen in [RELEASE-VERIFIZIEREN.md](RELEASE-VERIFIZIEREN.md).
- **Wenn es nicht klappt:** Keine `.sigstore.json` am Release: Im Lauf "Release" den Job "Pruefsummen, Attestierung und Signatur" öffnen und die rote Zeile an den Entwickler schicken.
- [ ] geprüft

### 12.2 GPG-Signatur (optional)

- **Wer:** Entwickler, Repo-Eigentümer legt das Secret an.
- **Was:** Zusätzlich eine GPG-Signatur der Prüfsummen. GPG ist ein verbreitetes Signaturverfahren mit zwei Schlüsseln: einem privaten (geheim, signiert) und einem öffentlichen (damit prüft jeder die Signatur).
- **Wozu:** Wer GPG nutzt, prüft `SHA256SUMS.txt` gegen einen öffentlichen Schlüssel.
- **Wo eintragen:** GitHub-Secrets (Weg: Schritt 1.3), nur der Repo-Eigentümer kann sie anlegen: `GPG_PRIVATE_KEY` (der private Schlüssel als Text, die erste Zeile nennt „PGP PRIVATE KEY BLOCK“) und `GPG_PASSPHRASE` (das Passwort des Schlüssels).
- **Woher:** Der **[Entwickler]** erzeugt den Schlüssel mit dir (ihr legt die Passphrase gemeinsam fest, sie kommt in den Passwortmanager): `gpg --full-generate-key` (ed25519 oder RSA 4096). Export des privaten Schlüssels: `gpg --armor --export-secret-keys <ID>`. Den öffentlichen Schlüssel veröffentlichen, zum Beispiel auf keys.openpgp.org, und in der Doku verlinken. Den privaten Schlüssel sicher sichern.
- **Prüfschritt:** Die Zusammenfassung des Release-Laufs nennt "GPG-Signatur (SHA256SUMS.txt.asc): aktiv" und den Fingerabdruck, und die Datei `SHA256SUMS.txt.asc` hängt am Release.
- **Wenn es nicht klappt:** Zusammenfassung meldet "GPG: übersprungen": Eines der beiden Secrets fehlt. Meldung "bad passphrase": `GPG_PASSPHRASE` passt nicht zum Schlüssel.
- [ ] erledigt

### 12.3 Scorecard-Token und Code Scanning (optional)

- **Wer:** Repo-Eigentümer.
- **Was:** Zwei optionale Einstellungen. `SCORECARD_TOKEN` ist ein Zugangscode (Fine-grained Token), der nur lesen darf. Der Ablauf `scorecard.yml` (OpenSSF Scorecard, ein automatischer Sicherheits-Check des Repositories mit Badge in der README) nutzt ihn. Die Variable `CODE_SCANNING_ENABLED` auf `true` lädt die Ergebnisse von CodeQL (einer automatischen Code-Sicherheitsprüfung) auch in einem privaten Repo hoch.
- **Wozu:** Ohne Token fallen einzelne Scorecard-Checks (zum Beispiel Branch-Protection) niedriger aus. In einem öffentlichen Repo läuft Code Scanning ohnehin.
- **Wo eintragen:** Secret `SCORECARD_TOKEN` und Variable `CODE_SCANNING_ENABLED` (Weg zum Anlegen: Schritt 1.3). Die Variable bekommt den Wert `true`, sinnvoll nur bei privatem Repo mit GitHub Code Security.
- **Woher:** Das Token erzeugt **Tim Hauke als Repository-Eigentümer** (ein Collaborator kann es laut GitHub-Doku voraussichtlich nicht, Folgerung, nicht wörtlich belegt):
  1. GitHub: Profilbild oben rechts > "Settings" > ganz unten links "Developer settings" > "Personal access tokens" > "Fine-grained tokens" > "Generate new token".
  2. Name zum Beispiel "OpenSSF Scorecard Action - VectoDE/linefm-radio-app".
  3. Ablauf (Expiration) höchstens ein Jahr, dazu einen Kalendereintrag zur Erneuerung anlegen.
  4. "Repository access": nur dieses Repository wählen.
  5. Berechtigung "Administration" auf "Read-only" stellen. "Metadata: Read-only" kommt automatisch.
  6. "Generate token", den Wert sofort kopieren (er wird nur einmal gezeigt) und als Secret `SCORECARD_TOKEN` anlegen.
  Quellen: <https://github.com/ossf/scorecard-action/blob/main/docs/authentication/fine-grained-auth-token.md>, <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens> (abgerufen 26.11.2026). Bei Repository Rulesets (Regelwerke für geschützte Branches) braucht Scorecard laut Doku keinen Token, ob dieses Repo Rulesets nutzt, haben wir nicht geprüft. Code Scanning in privaten Repos braucht GitHub Code Security.
- **Prüfschritt:** Der Scorecard-Lauf ist grün, das Badge in der README zeigt einen Wert.

- **Wenn es nicht klappt:** Lauf rot mit "Bad credentials": Token abgelaufen. Tokens laufen spätestens nach einem Jahr ab, GitHub warnt vorher per E-Mail. Neuen Token erzeugen (Weg siehe oben) und das Secret überschreiben. Taucht das Repository bei "Repository access" nicht auf, bist du nicht der Eigentümer: Das Token muss Tim Hauke anlegen.

#### Token für Sicherheitsfunde (nicht vorgesehen)

- **Entscheidung des Betreibers (22.11.2026):** Es gibt kein `SECURITY_ALERTS_TOKEN`. Nichts einzurichten.
- **Folge:** `security-alerts.yml` gleicht regulär nur Code Scanning ab. Dependabot- und Secret-Scanning-Alerts prüft der Betreiber im Reiter "Security" des Repositories (siehe SECURITY.md). Dependabot-Alerts sind Warnungen vor Bibliotheken mit bekannten Lücken, Secret-Scanning-Alerts melden ein Geheimnis, das im Code gelandet ist.

### 12.4 PageSpeed-Schlüssel (optional)

- **Wer:** Betreiber trägt selbst ein, Entwickler nennt nur den Namen.
- **Was:** Ein Google-API-Schlüssel für die PageSpeed-Messung der Web-Version.
- **Wozu:** Mit Schlüssel misst Google die Ladezeit von außen. Ohne Schlüssel misst der Ablauf "Pages" auf dem GitHub-Rechner, das reicht für den Betrieb.
- **Wo eintragen:** Secret `PAGESPEED_API_KEY` (Weg: Schritt 1.3).
- **Woher:** Du brauchst ein Google-Konto (Firmenkonto, Schritt 10.3). Anleitung von Google: <https://developers.google.com/speed/docs/insights/v5/get-started>, dort "Get a Key".
  1. Im Google-Cloud-Projekt die "PageSpeed Insights API" aktivieren: <https://console.cloud.google.com/apis/library> (APIs & Services > Library), die API suchen, "Enable". Gibt es noch kein Projekt, legst du über die Projektauswahl oben ein neues an (Menüname nicht geprüft).
  2. <https://console.cloud.google.com/apis/credentials> > "Create credentials" > "API key".
  3. Die Console verlangt eine Einschränkung: den Schlüsselnamen anklicken > Bereich "API restrictions" > "Restrict key" > "PageSpeed Insights API" wählen > "Save".
  4. Der Schlüssel erscheint im Dialog "API key created". Sofort in den Passwortmanager kopieren.
  5. Als Secret `PAGESPEED_API_KEY` in GitHub anlegen.
  Quelle: <https://docs.cloud.google.com/docs/authentication/api-keys> (abgerufen 26.11.2026). Nicht geprüft: Kontingente und deutsche Menünamen.
- **Prüfschritt:** Der nächste Lauf "Pages" ist grün und seine Zusammenfassung nennt PageSpeed als Messquelle.
- **Wenn es nicht klappt:** In der Liste bei "API restrictions" fehlt die PageSpeed Insights API: Sie ist im Projekt noch nicht aktiviert, zuerst aktivieren. Meldung "API key not valid": Schlüssel neu aus der Console kopieren, ohne Leerzeichen. Meldung "API not enabled": die API im Projekt aktivieren. (Die beiden Meldungen stammen aus der Praxis, die Google-Doku nennt keine Fehlercodes: nicht geprüft.)
- [ ] erledigt

### 12.5 NVD-Schlüssel (optional)

- **Wer:** Betreiber trägt selbst ein, Entwickler nennt nur den Namen.
- **Was:** Ein kostenloser Schlüssel der US-Schwachstellendatenbank NVD.
- **Wozu:** Der Ablauf "DAST" (ein wöchentlicher automatischer Sicherheitstest) prüft damit die verwendeten Bibliotheken auf bekannte Lücken (OWASP dependency-check). Ohne Schlüssel wird dieser Teil übersprungen.
- **Wo eintragen:** Secret `NVD_API_KEY` (Weg: Schritt 1.3).
- **Woher:**
  1. <https://nvd.nist.gov/developers/request-an-api-key> öffnen.
  2. Organisation, E-Mail-Adresse und Art der Organisation angeben, Nutzungsbedingungen annehmen, absenden.
  3. NVD schickt dir eine E-Mail mit einem Link. Der Link gilt 7 Tage und lässt sich nur einmal nutzen. Öffne ihn im Browser.
  4. Den angezeigten Schlüssel sofort in den Passwortmanager legen.
  5. Als Secret `NVD_API_KEY` in GitHub anlegen.
  Die NVD-Seite blockiert automatische Abrufe (HTTP 403), den Wortlaut dort konnten wir nicht selbst lesen. Die Angaben stammen aus Suchauszügen der NVD-Seiten (nicht geprüft).
- **Prüfschritt:** Im Repository Reiter "Actions" > links "DAST" > rechts "Run workflow" > grüner Knopf "Run workflow". Der Job für dependency-check läuft durch statt übersprungen zu werden.
- **Wenn es nicht klappt:** Der Link in der E-Mail gilt sieben Tage und nur einmal. Ist er abgelaufen oder hast du den Schlüssel nicht gespeichert, beantrage einen neuen (ein verlorener Schlüssel lässt sich nicht abrufen). Beantragst du mit derselben E-Mail neu, wird der alte Schlüssel ungültig, sobald du den neuen Link öffnest. Lauf rot mit HTTP 403: Schlüssel falsch eingefügt.
- [ ] erledigt

### 12.6 SonarCloud, Snyk und Best-Practices-Badge

- **Wer:** Repo-Eigentümer legt die Konten für SonarCloud und Snyk an, die Abläufe liegen im Repository. Für dich als Betreiber ist hier nichts zu tun.
- **SonarCloud und Snyk** (zwei Online-Dienste, die den Code automatisch auf Fehler und Sicherheitslücken prüfen): Entscheidung vom 27.11.2026 (sie ersetzt die vom 21.11.2026): Beide sind wieder dabei, jeweils im kostenlosen Tarif. Die Abläufe liegen jetzt im Repository (`.github/workflows/sonar.yml` und `snyk.yml`, dazu `sonar-project.properties`). Sie laufen bei jedem Änderungsvorschlag, bei jeder Änderung auf `main` und einmal pro Woche. Solange das jeweilige Secret fehlt, überspringt der Ablauf die Prüfung und schreibt nur den Hinweis "skipped" in die Zusammenfassung. Das ist kein Fehler und kein Warnsignal. Änderungsvorschläge aus Forks bekommen nie Secrets und werden deshalb immer übersprungen. Die Abläufe selbst sind mit actionlint und zizmor geprüft, **gegen die echten Dienste wurden sie noch nicht gelaufen** (die Konten gibt es noch nicht).
  - **Was der Repo-Eigentümer einmalig tut, SonarCloud:** Konto unter <https://sonarcloud.io> mit dem GitHub-Konto anlegen, das Repository importieren, "Automatic Analysis" in den Projekteinstellungen ausschalten (sonst meldet der Ablauf einen Konflikt), unter "My Account > Security" ein Token erzeugen und als Secret `SONAR_TOKEN` ablegen. Organisation (`vectode`) und Projektschlüssel (`VectoDE_linefm-radio-app`) in `sonar-project.properties` sind Annahmen nach dem Standardschema von SonarCloud: Stimmen sie nicht mit dem angelegten Projekt überein, schlägt der Lauf fehl, dann dort korrigieren. Der Gratis-Tarif gilt laut Anbieter für öffentliche Repositories (nicht live geprüft). SonarCloud kennt kein Dart, das prüft weiterhin `flutter analyze`.
  - **Snyk:** Konto unter <https://snyk.io> mit dem GitHub-Konto anlegen, unter "Account settings" den Auth-Token (API-Token) kopieren und als Secret `SNYK_TOKEN` ablegen. "Snyk Code" muss in den Einstellungen der Snyk-Organisation einmal eingeschaltet werden, sonst scheitert `snyk code test`. Die Grenzen des Gratis-Tarifs (Anzahl Tests pro Monat, private Repositories) sind nicht live geprüft. Ob Snyk die Abhängigkeiten dieses Dart-Projekts über `pubspec.lock` sauber liest, ist noch ungetestet.
  - Ein Fund in einem der beiden Abläufe macht ihn rot, genau wie bei Semgrep. Funde von Snyk erscheinen zusätzlich unter Security > Code scanning.
  - Semgrep, CodeQL, Trivy, OSV, gitleaks und zizmor laufen ohne Konto weiter.
- **OpenSSF Best Practices (bestpractices.dev):** Das Badge auf bestpractices.dev ist ein Prüfsiegel für gute Entwicklungspraxis. Schon die unterste Stufe verlangt eine freie Lizenz (FLOSS, freie und quelloffene Software): Das Kriterium `floss_license` lautet "The software produced by the project MUST be released as FLOSS" (<https://www.bestpractices.dev/en/criteria/0>, abgerufen 27.11.2026). LINEFM Radio ist proprietär (nicht frei lizenziert), das Badge ist deshalb nicht erreichbar. Kein Konto nötig.
- **Prüfschritt:** Im Repository im Reiter "Actions" (links die Liste der Abläufe) sind "Semgrep", "CodeQL" und "Supply Chain" grün. Sobald die Secrets `SONAR_TOKEN` und `SNYK_TOKEN` gesetzt sind, laufen "SonarCloud" und "Snyk" wirklich und sind grün. Vorher stehen sie ebenfalls grün da, mit dem Vermerk "skipped" in der Zusammenfassung des Laufs.
- **Wenn es nicht klappt:** Einer der drei ist rot: Das erledigt der Entwickler.

---

## 13. Datenschutzangaben je Store

Die Angaben müssen zur Datenschutzerklärung passen. Im Zweifel anwaltlich prüfen lassen.

### 13.1 Google Play: Datensicherheit

- **Wer:** Betreiber trägt die Antworten ein, Entwickler liefert sie.
- **Was:** Das Formular "Datensicherheit" (Data safety) in der Play Console beantworten: Welche Daten sammelt die App, welche gibt sie weiter? "Telemetrie" heißt hier die Statistik und die Absturzberichte aus Abschnitt 9.
- **Wozu:** Google zeigt die Antworten auf der Store-Seite. Falsche Angaben können zur Ablehnung führen.
- **Wo eintragen:** Play Console (<https://play.google.com/console>) > deine App öffnen > "Monitor and improve" > "Policy and programs" > "App content" > "Data safety" > "Start". Menünamen ändern sich, im Zweifel in der Suche "App content" eingeben.
- **Woher:** Die Antworten hängen an deiner Konfiguration:
  - Keine Telemetrie genutzt: Die App selbst erhebt keine Daten (Cast siehe nächster Punkt, er gilt immer). Favoriten, Verlauf und Einstellungen bleiben auf dem Gerät.
  - **Cast immer mit bedenken:** Cast ist die Übertragung der App auf Chromecast-Geräte (Fernseher, Lautsprecher). Das Cast-SDK (Googles Programmbibliothek dafür) der Google Play-Dienste sendet laut Google Nutzungsdaten. Die App startet es erst beim Tippen auf den Cast-Knopf, doch das Plugin kann es auf Android schon beim Beenden der App initialisieren (siehe [ENTWICKLUNG.md](ENTWICKLUNG.md), Abschnitt Google Cast). Ob Google Übertragungen an das Cast-SDK als "geteilt" wertet, lässt sich aus der Google-Doku nicht ableiten (nicht geprüft, Übertragungen an Dienstleister zählen laut Google nicht als Teilen). Gib die Daten vorsichtig an: "App-Aktivität" und "Geräte- oder andere IDs" mit Zweck "App-Funktionen", auch ohne eigene Telemetrie, und stimme das mit dem Entwickler und dem Anwalt ab. Die genauen Daten stehen in der aktuellen Google-Dokumentation zum Cast-SDK, vor dem Ausfüllen nachlesen.
  - Umami, Sentry (auch in der Variante GlitchTip) oder Firebase aktiv: Nutzungsdaten (App-Aktivität) und Absturzdaten angeben, Verschlüsselung bei der Übertragung "ja", Löschung auf Anfrage nach deinem tatsächlichen Verfahren.
  - Google Analytics (nur Web): betrifft die Web-Version, nicht die App.
- **Prüfschritt:** Die Antworten stimmen mit Abschnitt 7 und 11 der Datenschutzerklärung überein. Löschung und Speicherdauer wie in Schritt 17.13. **Antwortvorschlag** (Details in [STORE-DATENSCHUTZANGABEN.md](STORE-DATENSCHUTZANGABEN.md), Abschnitt 3, abgeleitet aus [VERARBEITUNGSVERZEICHNIS.md](VERARBEITUNGSVERZEICHNIS.md)): Ohne Telemetrie (Fall A aus Schritt 1.6) lautet die Antwort "Keine Daten erhoben oder weitergegeben". Mit Telemetrie (Fall B):

  | Frage | Antwort | Offen |
  |---|---|---|
  | Daten erhoben oder geteilt? | Ja | |
  | Bei der Übertragung verschlüsselt? | Ja (alles läuft über HTTPS) | Cast-Gerät im lokalen Netz prüfen **[Entwickler]** |
  | Löschung beantragbar? | Nein vorgeschlagen (kein Konto, keine Kennung) | **[Anwalt]** |
  | App-Aktivität, App-Interaktionen | erhoben, nicht geteilt, optional, Zweck Analyse | |
  | App-Informationen, Absturzprotokolle | erhoben, nicht geteilt, optional, Zweck Analyse | |
  | App-Informationen, Diagnose | Nein | |
  | Geräte- oder andere IDs | Nein im Standard-Build, Ja bei aktivem Firebase | |
  | Weitergabe | Nein (Dienstleister im Auftrag) | **[Anwalt]** |
  | Werbe-ID, Werbung | Nein | |
  | Google Cast (Android) | nicht belegt | **[Entwickler, Anwalt]**: Der Entwickler liefert vor Abgabe die Antwort aus dem Datenschutzbericht der Cast-Bibliothek, bis dahin gib "App-Aktivität" und "Geräte- oder andere IDs" an |

  Die Spalte "Offen" nennt, wer die Antwort noch klären muss. Optionale Erhebung (nach Einwilligung) als optional kennzeichnen, aber nur, wenn alle Nutzer ablehnen können, ohne die Kernfunktion zu verlieren. Verschlüsselung bei der Übertragung nur mit "ja", wenn wirklich alle übertragenen Daten verschlüsselt sind. Löschung "ja" auch bei automatischer Löschung innerhalb von 90 Tagen. Das gilt nur, wenn du in Schritt 17.13 wirklich eine automatische Löschung einstellst, sonst bleibt es bei "Nein" in der Antworttabelle. Ablauf im Formular: "Start" klicken, den Bereich "Data collection and security" öffnen, die Datentypen aus der Tabelle anwählen, je Typ Zweck und Umgang angeben, die Vorschau prüfen und "Submit" klicken (Quelle: <https://support.google.com/googleplay/android-developer/answer/10787469>, abgerufen 26.11.2026). Änderungen erscheinen bis zu 7 Tage später im Store. Bei Zweifel Daten, die nur auf dem Gerät bleiben, nicht angeben. Für das, was Sentry, Firebase und das Cast-SDK erheben, stehst du ein wie für eigenen Code.
- Store-Regeln: [G-12](STORE-RICHTLINIEN.md#g-12), [G-13](STORE-RICHTLINIEN.md#g-13), [G-45](STORE-RICHTLINIEN.md#g-45), [G-46](STORE-RICHTLINIEN.md#g-46)
- **Wenn es nicht klappt:** Google lehnt wegen widersprüchlicher Angaben ab: Antworten mit der Datenschutzerklärung abgleichen und den Entwickler fragen, welche Daten die konfigurierten Dienste wirklich senden. Das Formular lässt sich nicht abschicken: Alle Pflichtfragen beantworten, nur Formulare ohne offene Probleme gehen raus. Änderungen erscheinen nicht: bis zu 7 Tage warten, bei aktivem Managed Publishing (du gibst Änderungen erst selbst zur Veröffentlichung frei) dort prüfen, ob eine Änderung noch auf Freigabe wartet.
- [ ] erledigt

### 13.2 Microsoft Store

- **Wer:** Betreiber trägt ein, Entwickler liefert die Antworten.
- **Was:** Im Einreichungsformular des Microsoft Store (Partner Center) die Datenschutz-URL (Adresse der Datenschutzerklärung) und die Altersfreigabe angeben.
- **Wozu:** Pflichtfelder im Partner Center.
- **Wo eintragen:** Partner Center (<https://partner.microsoft.com/dashboard>), deine App > Einreichung > Eigenschaften und Altersfreigabe. Im Abschnitt "Privacy policy" gibst du zuerst an, ob die App personenbezogene Daten abruft, sammelt oder überträgt (ehrlich beantworten, Telemetrie und Cast bedenken). Einen eigenen Datenfragebogen wie bei Google fanden wir in der Microsoft-Doku nicht (Stand 26.11.2026, "nicht gefunden" heißt nicht "gibt es nicht").
- **Woher:** Als Datenschutz-URL trägst du `https://app.linefm.de/datenschutz/` ein.
- **Prüfschritt:** Die Einreichung hat keine offenen Pflichtfelder.
- **Wenn es nicht klappt:** Pflichtfeld unklar: Die Hilfe-Links neben dem Feld lesen, im Zweifel den Entwickler fragen.
- [ ] erledigt

### 13.3 Flathub und Snap Store

- **Wer:** Entwickler (Metainfo), Betreiber klickt im Snap-Dashboard (die Verwaltungsseite des Snap Stores, Schritt 8.2).
- **Was:** Flathub und Snap Store sind die App-Läden für Linux. Flathub braucht die Altersangabe (OARS, ein Fragebogen-Format für Altersfreigaben) in der Metainfo (der Beschreibungsdatei der App). Für den Snap Store prüfen, ob ein Datenschutzlink im Eintrag verlangt wird.
- **Wozu:** Pflichtangaben der Linux-Stores.
- **Wo eintragen:** Metainfo `linux/de.linefm.app.metainfo.xml`, Snap-Eintrag im Dashboard.
- **Woher:** Wie in Schritt 8.1. Einen Datenfragebogen wie bei Google fanden wir dort nicht (Stand 26.11.2026). Ob der Snap-Store ein Datenschutz-Feld hat, ist nicht belegt (siehe 8.2).
- **Prüfschritt:** Die Metainfo besteht die Prüfung des Flathub-Builds. Dieser Build läuft erst bei der Einreichung (Schritt 8.1). Vorab prüft der Entwickler die Datei lokal mit `appstreamcli validate`. Das Ergebnis der Einreichung trägst du in Schritt 8.1 ein.
- Store-Regeln: [D-04](STORE-RICHTLINIEN.md#d-04), [F-10](STORE-RICHTLINIEN.md#f-10), [S-08](STORE-RICHTLINIEN.md#s-08)
- **Wenn es nicht klappt:** Flathub-Build scheitert an der Metainfo: Die Fehlermeldung an den Entwickler schicken, er korrigiert die Datei.
- [ ] erledigt

### 13.4 Apple App-Privacy (später)

- **Wer:** Betreiber in der späteren Apple-Runde, Entwickler liefert Antworten.
- **Was:** "App-Datenschutz" (Privacy Nutrition Label) in App Store Connect (Apples Verwaltungsseite für Apps): eine Datenschutz-Übersicht, die im Store angezeigt wird.
- **Wozu:** Apple verlangt es vor der Einreichung.
- **Wo eintragen:** App Store Connect > App-Datenschutz. Erst mit Schritt 15.
- **Woher:** Gleiche Fakten wie bei Google. Apples Fragebogen im Zweifel vor Ort lesen.
- **Prüfschritt:** Der Status ist "Veröffentlicht".
- Store-Regeln: [A-12](STORE-RICHTLINIEN.md#a-12), [A-13](STORE-RICHTLINIEN.md#a-13), [A-14](STORE-RICHTLINIEN.md#a-14), [A-15](STORE-RICHTLINIEN.md#a-15)
- **Wenn es nicht klappt:** Später mit Schritt 15 klären.
- [ ] erledigt (Apple ist offen)

---

## 14. Bilder und Screenshots

### 14.1 Screenshots für die Stores

- **Wer:** Entwickler liefert die Bilder als Dateien (Download-Link oder Mail), Betreiber lädt sie in die Konsolen hoch.
- **Was:** Screenshots für Telefon, Tablet und Desktop. Empfohlen: Stationen, Player, Verlauf, Favoriten, Wecker, dunkel und hell.
- **Wozu:** Pflicht in den Stores.
- **Wo eintragen:** In den Konsolen der Stores. Maße (die Bilder lädst du in der jeweiligen Konsole beim Store-Eintrag hoch, Abschnitte 6 bis 8):
  - Google Play: 2 bis 8 Telefon-Screenshots, 16:9 bis 9:16, Kanten 320 bis 3840 px. Feature-Grafik 1024 x 500. Für Tablets je 7 und 10 Zoll empfohlen.
  - Microsoft Store: mindestens 1, empfohlen 4 oder mehr, 1366 x 768 oder größer.
  - Flathub: mindestens 1, über URL erreichbar.
  - **Alle Bilder und wer sie liefert:**

    | Asset | Store | Maße und Format | Wer |
    |---|---|---|---|
    | App-Icon | Google Play | 512 x 512, 32-Bit-PNG mit Alpha (Transparenz), höchstens 1024 KB | Entwickler aus dem Logo, du gibst frei |
    | Feature-Grafik (Titelbild der Store-Seite) | Google Play | 1024 x 500, JPEG oder 24-Bit-PNG ohne Alpha (Transparenz), mit Alternativtext (Bildbeschreibung, Schritt 14.2) | Entwickler, du gibst frei |
    | Telefon-Screenshots | Google Play | 2 bis 8, 320 bis 3840 px | Entwickler |
    | Store-Logo | Microsoft | 300 x 300 (Maß aus Schritt 7.5, in der Microsoft-Doku nicht geprüft) | Entwickler aus dem Logo |
    | Screenshots | Microsoft | mindestens 1, ab 1366 x 768 | Entwickler |
    | Screenshots, Icon | Flathub | über URL erreichbar, Icon in der Metainfo | Entwickler |
    | Icon, Screenshots | Snap Store | Maße nicht geprüft | Entwickler |
    | Vorschaubild für soziale Netzwerke | Web | Schritt 14.3 | Entwickler, du gibst frei |

    Dein Beitrag: das Original-Logo von LineFM Studios als Vektordatei (SVG) oder PNG ab 1024 x 1024 an den Entwickler geben und alle Entwürfe freigeben.
- **Woher:** Der Entwickler erzeugt sie auf echten Geräten oder Emulatoren (Programme, die ein Telefon am Rechner nachbilden). Du gibst sie frei: Antworte dem Entwickler per Mail je Bild oder gesammelt mit "freigegeben" und Datum, oder nenne, was geändert werden soll. Sie zeigen die echte App ohne Fantasiedaten und ohne fremde Cover in Großansicht.
- **Prüfschritt:** Alle Pflichtgrößen sind hochgeladen.
- Store-Regeln: [G-06](STORE-RICHTLINIEN.md#g-06), [A-03](STORE-RICHTLINIEN.md#a-03), [F-10](STORE-RICHTLINIEN.md#f-10)
- **Wenn es nicht klappt:** Store lehnt ein Bild ab: Maße und Dateiformat (PNG oder JPEG) mit der Liste oben vergleichen.
- [ ] erledigt

### 14.2 Alt-Texte

- **Wer:** Betreiber schreibt die Texte und schickt sie per Mail an den Entwickler, der sie in die Web-Seite einträgt. In den Konsolen trägt sie der Betreiber selbst ein.
- **Was:** Alt-Texte: kurze Bildbeschreibungen, die Screenreader (Vorlese-Programme für blinde Menschen) statt des Bildes vorlesen. Zu allen Bildern.
- **Wozu:** Barrierefreiheit.
- **Wo eintragen:** Bei den Bildern in den Konsolen (dort, wo das Formular ein Feld für Beschreibung oder Alternativtext anbietet) und auf der Web-Seite. Ein Text pro Bild.
- **Woher:** Du schreibst sie kurz und sachlich, ein Satz je Bild. Schick sie dem Entwickler per Mail mit dem Bildnamen, falls sie auf die Web-Seite sollen. Bei zweisprachigen Store-Einträgen schreibst du sie auf Deutsch und Englisch.
- **Prüfschritt:** Kein Bild ohne Beschreibung.
- **Wenn es nicht klappt:** Unsicher, was hineingehört: Ein Satz, der beschreibt, was man sieht, zum Beispiel "Player mit dem Sender LINEFM und laufendem Titel" oder "Senderliste mit Logos und Suchfeld". Kein "Bild von" und keine Werbesprache.
- [ ] erledigt

### 14.3 Vorschaubild für soziale Netzwerke

- **Wer:** Betreiber gibt frei, Entwickler liefert das Bild.
- **Was:** Das Bild freigeben, das erscheint, wenn jemand einen Link auf `app.linefm.de` teilt (Open-Graph-Bild: das Vorschaubild, das Messenger und soziale Netzwerke neben dem Link zeigen).
- **Wozu:** Es ist das Erste, was viele von der Web-App sehen.
- **Wo eintragen:** Freigabe schriftlich an den Entwickler, zum Beispiel per Mail "Vorschaubild freigegeben" mit Datum. Das Bild liegt im Repository unter `web/icons/og-image.png` und im Netz unter `https://app.linefm.de/icons/og-image.png`.
- **Woher:** Der Entwickler zeigt dir das Bild.
- **Prüfschritt:** Link auf `https://app.linefm.de/` in einen Messenger einfügen: Die Vorschau zeigt das freigegebene Bild.
- **Wenn es nicht klappt:** Alte Vorschau erscheint: Messenger speichern Vorschauen zwischen. Ein paar Stunden warten oder mit einem anderen Dienst testen.
- [ ] erledigt

---

## 15. Apple (später, Apple-Runde)

**Später (Apple-Runde):** Dieser ganze Abschnitt ist bewusst nicht Teil der ersten Veröffentlichung. Du musst ihn jetzt nicht abarbeiten, die Haken bleiben offen. Die Rollen stehen in jedem Schritt unter "Wer".

iOS, macOS, CarPlay (die App im Auto-Display von Apple) und AirPlay (Übertragung auf Apple-Lautsprecher und -Fernseher) sind im Code vorbereitet. Apple (iOS und Mac App Store) kommt **nicht in die erste Veröffentlichung**, sondern später in einer gemeinsamen Runde für iOS und Mac. Für diese Runde gelten alle Schritte dieses Abschnitts plus die Apple-Teile aus 13.4 (App-Datenschutz), 17.5 (DSA-Händlerstatus), 18.2 und 18.3 (Konto, Vereinbarungen, Steuern), 19.3 (Zertifikate), 20.1 (Support-URL) und dem Fristenkalender 20.5. Regeln: [STORE-RICHTLINIEN.md, Apple](STORE-RICHTLINIEN.md#apple-app-store).

### 15.0 Vorbedingungen der Apple-Runde (später)

- **Wer:** Betreiber.
- **Was:** Vor dem Start der Apple-Runde: die D-U-N-S-Nummer (eine kostenlose Firmen-Kennnummer, die Apple verlangt) liegt vor (18.1), Website und E-Mail auf der eigenen Domain (Apple verlangt beides für Organisationen), `support@linefm.de` und `/support/` erreichbar (20.1), Altersfragebogen 13+ beantwortet, Screenshots für iPhone, iPad und Mac (Abschnitt 14), Prüfnotizen mit Hinweis auf die laut.fm-Vereinbarung (17.7), Mac-Sandbox-Export über den Speichern-Dialog umgesetzt, Wecker mit AlarmKit ab iOS 26 und Hinweis auf den Benachrichtigungs-Rückfall in App- und Store-Text.
- **Wozu:** Ohne diese Punkte lehnt Apple ab oder die Anmeldung hängt.
- **Wo eintragen:** App Store Connect, Entwicklerportal.
- **Woher:** die genannten Schritte.
- **Prüfschritt:** Alle Unterpunkte abgehakt, erst dann `APPLE_PUBLISHING_ENABLED` setzen (15.6).
- Store-Regeln: [A-01](STORE-RICHTLINIEN.md#a-01), [A-17](STORE-RICHTLINIEN.md#a-17), [A-20](STORE-RICHTLINIEN.md#a-20), [A-22](STORE-RICHTLINIEN.md#a-22), [A-23](STORE-RICHTLINIEN.md#a-23), [A-34](STORE-RICHTLINIEN.md#a-34). In den Datenschutz-Labels keine Werbedaten angeben.
- **Wenn es nicht klappt:** Ein Punkt der Liste fehlt: Die Apple-Runde bleibt aus, `APPLE_PUBLISHING_ENABLED` wird nicht gesetzt. Die Pipeline `store-apple.yml` läuft dann nicht. Das ist gewollt und kein Fehler. Welcher Punkt fehlt, zeigt der Verweis in der Klammer, dort nachlesen.
- [ ] erledigt (Apple-Runde, später)

### 15.1 Konto und Team-ID

- **Wer:** Betreiber.
- **Was:** Apple Developer Program beitreten (99 US-Dollar pro Jahr, für eine Firma wird eine D-U-N-S-Nummer verlangt). Team-ID (eine 10-stellige Kennung deines Apple-Teams) notieren.
- **Wozu:** Grundlage für alles Weitere.
- **Wo eintragen:** Secret `APPLE_TEAM_ID`. Außerdem steht der Name als `{{APPLE_TEAM_ID}}` in `packaging/ios/ExportOptions-*.plist.template` und in `web/.well-known/apple-app-site-association`. Das Skript und der Web-Postbuild setzen ihn aus dem Secret ein.
- **Woher:** <https://developer.apple.com/programs/enroll/>. Die Team-ID steht nach der Anmeldung unter <https://developer.apple.com/account> > "Membership details" (Mitgliedschaftsdetails), 10 Zeichen. Quelle: <https://developer.apple.com/help/glossary/team-id> (abgerufen 26.11.2026). Verzögerungen entstehen durch fehlende Zwei-Faktor-Anmeldung, Aliase statt echtem Namen, eine Firmen-E-Mail außerhalb der eigenen Domain, eine nicht öffentliche oder nicht passende Website und Handelsnamen statt des exakten Rechtsträgernamens. Die Freigabedauer nennt Apple nicht (nicht geprüft).
- **Prüfschritt:** Die ID ist 10 Zeichen lang und im Secret hinterlegt.
- Store-Regeln: [A-24](STORE-RICHTLINIEN.md#a-24), [A-26](STORE-RICHTLINIEN.md#a-26)
- **Wenn es nicht klappt:** Apple verlangt eine D-U-N-S-Nummer: Sie ist kostenlos (Schritt 18.1). Leer unter "Membership details": An den Apple Developer Support wenden. Die Freigabe bleibt aus: Zwei-Faktor, echter Name, Firmen-E-Mail auf eigener Domain, öffentliche Website und exakter Firmenname prüfen.
- [ ] erledigt

### 15.2 App-ID und App Store Connect

- **Wer:** Betreiber, Entwickler begleitet.
- **Was:** Bundle-ID `de.linefm.app` (der eindeutige Name der App bei Apple) unter Zertifikate, IDs & Profile registrieren (Background Modes Audio erlaubt Musik im Hintergrund, später CarPlay). App in App Store Connect anlegen (Name "LINEFM Radio", Sprache Deutsch).
- **Wozu:** Ohne App-Eintrag kein Upload.
- **Wo eintragen:** <https://developer.apple.com/account/resources> > "Identifiers" > Plus > "App IDs" > Continue > Typ "App" > Beschreibung, **Explicit** App ID, Bundle-ID `de.linefm.app`, Capabilities wählen > Continue > Register (<https://developer.apple.com/help/account/identifiers/register-an-app-id/>, abgerufen 26.11.2026). Das dürfen nur Account Holder oder Admin. Eine Capability, die du im Portal anhakst, wird erst genutzt, wenn der Entwickler sie im Xcode-Target hinzufügt (Background Modes Audio). In App Store Connect die App anlegen: Den Menüpfad "Neue App" und die Pflichtfelder haben wir nicht geprüft.
- **Woher:** eigene Eingabe.
- **Prüfschritt:** Die App erscheint in App Store Connect.
- **Wenn es nicht klappt:** Bundle-ID schon vergeben: Mit dem Entwickler klären, sie gehört dann zu einem anderen Team. Das Capability-Kästchen ist grau oder fehlt: Prüfen, ob du Account Holder oder Admin bist und ob die Funktion für die Plattform verfügbar ist. Ein Upload braucht eine App mit expliziter App-ID.
- [ ] erledigt

### 15.3 API-Schlüssel

- **Wer:** Betreiber (Account Holder) erzeugt den Schlüssel und trägt die Secrets selbst ein, Entwickler nennt die Namen.
- **Was:** API-Schlüssel für App Store Connect erzeugen. Zuerst muss der Account Holder unter "Users and Access" > "Integrations" auf "Request Access" klicken und den Bedingungen zustimmen, Apple prüft die Anfrage. Danach "Users and Access" > "Integrations" > "App Store Connect API" > "Team Keys" > "Generate API Key" (oder Plus), Name vergeben, unter "Access" eine Rolle wählen, "Generate". Einen **Team Key**, keinen Individual Key. Quelle: <https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/> (abgerufen 26.11.2026). Welche Rolle der Upload braucht, steht dort nicht (nicht geprüft, im Zweifel Entwickler fragen).
- **Wozu:** Mit diesem Zugangsschlüssel darf die Pipeline Apps hochladen, ohne dass sie dein Apple-Passwort kennt.
- **Wo eintragen:** Secrets `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8` (Inhalt der `.p8`-Datei, einer Textdatei mit dem geheimen Schlüssel, als Text, nicht Base64). Weg zum Anlegen: Schritt 1.3.
- **Woher:** App Store Connect. Die Key-ID steht in der Schlüsseltabelle, die Issuer-ID oben auf der Integrations-Seite (aus allgemeiner Apple-Kenntnis, auf der gelesenen Seite nicht genannt, nicht geprüft). Name und Rolle lassen sich nach dem Erzeugen nicht ändern, dann widerrufen und neu erzeugen. Team-Schlüssel gelten für alle Apps.
- **Prüfschritt:** Alle drei stehen in der Secret-Liste.
- **Wenn es nicht klappt:** Kein Knopf "Generate API Key": Der Account Holder hat den API-Zugang noch nicht angefordert, oder du bist nicht Admin. Die `.p8`-Datei lässt sich nur einmal laden. Verloren: Schlüssel widerrufen und neu erzeugen.
- [ ] erledigt

### 15.4 Zertifikate und Profile

- **Wer:** Entwickler mit Mac, Betreiber gibt Zugang frei.
- **Was:** Voraussetzung: ein Mac (für Schlüsselbund und Zertifikatsanforderung). Hast du keinen, macht der Entwickler diesen Schritt auf seinem Rechner. "Apple Distribution" (iOS und Mac) und "Mac Installer Distribution" (nur Mac App Store) als `.p12` exportieren. Je ein App-Store-Profil für `de.linefm.app` und `de.linefm.app.widget` (iOS) sowie `de.linefm.app` (macOS). Für das signierte DMG außerhalb des Stores zusätzlich ein "Developer ID Application"-Zertifikat. Siehe [D-10](STORE-RICHTLINIEN.md#d-10).
- **Wozu:** Apple signiert und prüft jede App. Ein Zertifikat ist ein digitaler Ausweis, mit dem Apple erkennt, dass die App von dir stammt. Ein Profil (Provisioning Profile) verknüpft App, Zertifikat und Konto. Eine `.p12`-Datei packt Zertifikat und privaten Schlüssel zusammen.
- **Wo eintragen:** Secrets `APPLE_DISTRIBUTION_CERT_P12_BASE64`, `APPLE_DISTRIBUTION_CERT_PASSWORD`, `APPLE_MAC_INSTALLER_CERT_P12_BASE64`, `APPLE_MAC_INSTALLER_CERT_PASSWORD`, `APPLE_IOS_PROVISIONING_PROFILES_BASE64` (je Profil eine Zeile Base64), `APPLE_MACOS_PROVISIONING_PROFILE_BASE64`, `APPLE_DEVELOPER_ID_CERT_P12_BASE64`, `APPLE_DEVELOPER_ID_CERT_PASSWORD`.
- **Woher:** Apple-Entwicklerportal und Schlüsselbund (macOS). Ablauf laut Apple: In Keychain Access eine Zertifikatsanforderung (CSR) erzeugen ("Zertifikatsassistent" > "Zertifikat einer Zertifizierungsstelle anfordern"), im Portal unter "Certificates, Identifiers & Profiles" Plus, Typ wählen, CSR hochladen, laden und installieren (<https://developer.apple.com/help/account/certificates/certificates-overview/>). Profile: "Profiles" > Plus > unter Distribution "App Store Connect" (iOS) bzw. "Mac App Store Connect" (macOS) > Continue > App-ID > Zertifikat > Name > Generate > Download (<https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/>, abgerufen 26.11.2026). Nur Account Holder oder Admin. Je Typ ist pro Team nur ein Distributionszertifikat erlaubt. Nicht geprüft: der `.p12`-Export aus dem Schlüsselbund, die Gültigkeitsdauer, die App-ID `de.linefm.app.widget`, und ob für ein DMG ein "Developer ID Installer" nötig ist. Die Pipeline `store-apple.yml` nutzt kein fastlane, Details in [secrets.md](secrets.md).
- **Prüfschritt:** Alle Secrets stehen in der Liste.
- **Wenn es nicht klappt:** Lauf rot mit "No signing certificate": Das falsche Zertifikat ist exportiert oder das Passwort stimmt nicht. Export im Schlüsselbund wiederholen. Das Portal meldet, es gebe schon ein Zertifikat dieses Typs: das vorhandene samt privatem Schlüssel auf dem Rechner exportieren, auf dem es angelegt wurde. Ohne den privaten Schlüssel muss das Zertifikat widerrufen und neu erstellt werden. Läuft ein Distributionszertifikat ab oder wird es widerrufen, lassen sich keine neuen Builds hochladen.
- [ ] erledigt

### 15.5 Namen der Provisioning-Profile für den Export

- **Wer:** Entwickler.
- **Was:** Die Platzhalter `{{PROVISIONING_PROFILE_APPSTORE_NAME}}` und `{{PROVISIONING_PROFILE_ADHOC_NAME}}` in `packaging/ios/ExportOptions-appstore.plist.template` bzw. `ExportOptions-adhoc.plist.template`.
- **Wozu:** Xcode braucht den Profilnamen beim Export.
- **Wo eintragen:** Die füllt der Entwickler beim Apple-Start mit `sed`, siehe [packaging/ios/README.md](../packaging/ios/README.md). Du lieferst nur den Profilnamen.
- **Woher:** Developer-Portal (die Pipeline nutzt kein fastlane, die Profile kommen aus Schritt 15.4).
- **Prüfschritt:** Der Export läuft ohne Fehler "No profile found".
- **Wenn es nicht klappt:** "No profile found": Der Profilname ist falsch geschrieben. Ihn exakt aus dem Entwicklerportal kopieren.
- [ ] erledigt

### 15.6 Schalter, CarPlay, Links, Review

- **Wer:** Betreiber gibt frei, Entwickler stellt um.
- **Was:** Variable `APPLE_PUBLISHING_ENABLED` erst auf `true` setzen, wenn alles vorliegt. CarPlay-Audio-Berechtigung beantragen (Formular im Entwicklerportal, "CarPlay App Entitlement Request", Kategorie Audio). AASA-Datei prüfen (sie sagt Apple, dass Links auf `app.linefm.de` direkt in der iOS-App geöffnet werden dürfen, Universal Links).
- **Wozu:** Solange der Schalter nicht `true` ist, laufen `store-apple.yml` und die Signaturschritte in `build.yml` nicht. Apple prüft CarPlay von Hand, das dauert Wochen. Ohne Freigabe zeigt die App kein CarPlay.
- **Wo eintragen:** Variable `APPLE_PUBLISHING_ENABLED`. Die AASA-Vorlage liegt in `web/.well-known/apple-app-site-association`, die Fähigkeit "Associated Domains" (`applinks:app.linefm.de`) steht in `Runner.entitlements`.
- **Woher:** Apple-Entwicklerportal.
- **Prüfschritt:** `https://app.linefm.de/.well-known/apple-app-site-association` ist ohne Dateiendung, mit `application/json` und ohne Weiterleitung erreichbar.
- macOS ohne Apple-Konto (Entscheidung vom 27.11.2026: So wird jetzt ausgeliefert): Das DMG (die Installationsdatei für den Mac) auf GitHub Releases ist weder signiert noch von Apple notarisiert (Notarisierung ist Apples Prüfstempel für Programme außerhalb des Stores). Beim ersten Start blockiert Gatekeeper (der macOS-Schutz vor unbekannter Software) die App. Nutzer öffnen sie so: App in "Programme" ziehen, einmal starten und die Warnung schließen, dann "Systemeinstellungen" > "Datenschutz & Sicherheit" > bei "Sicherheit" auf "Trotzdem öffnen" klicken und mit Passwort oder Touch ID bestätigen (ab macOS 15 geht Rechtsklick > "Öffnen" nicht mehr). Die ausführliche Anleitung liegt dem DMG bei ([packaging/macos/LIES-MICH-ZUERST.txt](../packaging/macos/LIES-MICH-ZUERST.txt)). Lege sie zusätzlich auf die Download-Seite. Signierung und Notarisierung kommen mit der Apple-Runde.
- Store-Regeln: [A-07](STORE-RICHTLINIEN.md#a-07), [A-21](STORE-RICHTLINIEN.md#a-21), [A-29](STORE-RICHTLINIEN.md#a-29), [A-33](STORE-RICHTLINIEN.md#a-33)
- Review-Risiko: Apple lehnt reine Webseiten-Hüllen ab (Richtlinien 4.2 und 4.3). Die App bringt Favoriten, Verlauf, Sleeptimer, Wecker, Sperrbildschirm-Steuerung und CarPlay als Mehrwert mit.
- **Wenn es nicht klappt:** Datei wird mit Weiterleitung oder falschem Typ ausgeliefert: Die Hosting-Konfiguration prüfen (hosting-uebersicht.md).
- [ ] erledigt

---

## 16. Abnahme

### 16.1 Prüfschritt über alles

- **Wer:** Betreiber, Entwickler hilft bei roten Punkten.
- **Was:** Die [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md) komplett abarbeiten. Der Release-Build mit `--strict` (Strengmodus: der Build bricht ab, sobald ein Pflicht-Platzhalter offen ist) muss durchlaufen. Den Build stößt der Entwickler an, das Ergebnis siehst du im Reiter "Actions" des Repositories (Schritt 1.5).
- **Wozu:** Ohne offene Platzhalter und mit bestätigten Verträgen darfst du veröffentlichen.
- **Wo eintragen:** In Abschnitt D der Freigabe-Checkliste (nicht zu verwechseln mit Anhang D dieser Anleitung) trägst du Datum und Namen ein. Danach schreibst du Tim Hauke "Freigabe erteilt" mit Datum. Erst diese Nachricht gilt als Freigabe.
- **Woher:** entfällt.
- **Prüfschritt:** Alle Punkte oben abgehakt oder bewusst als "offen" begründet.
- **Wenn es nicht klappt:** Release-Build bricht mit `--strict` ab: Die Meldung nennt den offenen Platzhalter, zurück zu Schritt 3.1.
- [ ] erledigt

### 16.2 Automatische Gegenprüfung dieser Liste

- **Wer:** Entwickler (läuft automatisch).
Das ist ein automatischer Test, du musst nichts tun. Der Test `test/tool/einrichtung_vollstaendig_test.dart` prüft bei jedem Lauf, dass jeder Platzhalter und jedes Secret und jede Variable aus dem Repo in dieser Datei in Backticks genannt ist. Fehlt ein Name, schlägt der Test fehl. Wer einen neuen Platzhalter oder ein neues Secret anlegt, ergänzt die Anhänge A und B in derselben Änderung.

### 16.3 Wenn etwas hakt

- **Wer:** Betreiber.
- Frag im Repository nach, entweder im Reiter für Tickets auf der Startseite des Repositorys (Knopf für ein neues Ticket) oder unter "Discussions" (<https://github.com/VectoDE/linefm-radio-app/discussions>, Knopf "New discussion"). Das Repository ist öffentlich, schreib dort deshalb keine vertraulichen Angaben. Beschreibe, welchen Schritt du gerade machst und was du siehst.
- Bei Fehlermeldungen von Stores: Meldung kopieren, Screenshot anhängen, keine Passwörter.
- Zeitaufwand der Prüfungen einplanen: Google Play einige Tage, CarPlay-Antrag Wochen, Flathub je nach Betreuern.

### 16.4 Probe-Release prüfen

- **Wer:** Entwickler führt die Befehle aus, Betreiber lädt die Datei herunter (Anleitung: `RELEASE-VERIFIZIEREN.md`).
- **Was:** Eine fertige Vorabversion herunterladen und prüfen, dass sie echt und vollständig ist.
- **Wozu:** So siehst du vor dem Start, dass Signaturen und Prüfsummen funktionieren.
- **Wo eintragen:** nichts. Öffne <https://github.com/VectoDE/linefm-radio-app/releases>. Nimm die oberste Version mit der Markierung "Pre-release" (Vorabversion) und klicke ihren Titel an.
- **Woher:** entfällt.
- **Prüfschritt:**
  1. Weiter unten "Assets" aufklappen. Dort liegen Dateien für Android (`.apk`), Windows (`.exe`), Linux und macOS, dazu `SHA256SUMS.txt` und je Datei eine `.sigstore.json`.
  2. Eine Datei herunterladen und die Prüfsumme vergleichen (eine Prüfsumme ist ein digitaler Fingerabdruck der Datei, er ändert sich bei jeder Veränderung). Windows: Startmenü öffnen, "PowerShell" tippen, Enter. Dort `Get-FileHash "$HOME\Downloads\dateiname"` ausführen ("dateiname" durch den echten Namen mit Endung ersetzen). Den langen Wert unter "Hash" mit der Zeile für diese Datei in `SHA256SUMS.txt` vergleichen. Groß- und Kleinschreibung spielt keine Rolle.
  3. Optional, wenn die GitHub-Kommandozeile (`gh`) eingerichtet ist, sonst macht das der Entwickler: Die Herkunft prüfst du mit `gh attestation verify dateiname --repo VectoDE/linefm-radio-app`. Alle Befehle stehen in [RELEASE-VERIFIZIEREN.md](RELEASE-VERIFIZIEREN.md).
  4. Die App installieren und starten, wie in [BAUEN-UND-STARTEN.md](BAUEN-UND-STARTEN.md) beschrieben.
- **Wenn es nicht klappt:** Prüfsumme weicht ab: Die Datei nicht öffnen, neu herunterladen und erneut vergleichen. Weicht sie weiter ab, sofort den Entwickler informieren. Eine Plattform fehlt unter "Assets": Lauf "Release" dieser Version öffnen und die Zusammenfassung an den Entwickler schicken.
- [ ] erledigt

### 16.5 Sprachumschaltung prüfen

- **Wer:** Betreiber.
- **Was:** Die App gibt es auf Deutsch und Englisch. Prüfen, dass die Umschaltung klappt.
- **Wozu:** Ein Teil der Hörer nutzt die App auf Englisch. Die Store-Texte gibt es ebenfalls in beiden Sprachen.
- **Wo eintragen:** nichts. In der App: "Einstellungen" öffnen, Abschnitt "Sprache". Zur Wahl stehen "Systemsprache", "Deutsch" und "English".
- **Woher:** entfällt.
- **Prüfschritt:** "English" wählen: Alle Texte wechseln sofort auf Englisch, ohne Neustart. "Systemsprache" folgt der Sprache des Geräts. Ist das Gerät weder auf Deutsch noch auf Englisch gestellt, erscheint Englisch.
- **Wenn es nicht klappt:** Ein Text bleibt in der falschen Sprache: Bildschirmfoto machen, notieren, wo der Text steht, und an den Entwickler schicken.
- [ ] erledigt

### 16.6 Gerätetests vor der Store-Freigabe

- **Wer:** Entwickler führt die Tests aus, Betreiber stellt Geräte und bestätigt die Berichte (eine Mail "Bericht gelesen, in Ordnung" genügt).
Diese Prüfungen gehen nur mit echten Geräten. Du musst sie nicht selbst machen, aber vor der Freigabe muss für jede ein Ergebnis vorliegen. Die Tests führt der Entwickler durch, Geräte stellt ihr gemeinsam (dein Android-Telefon, Chromecast, Auto). Du bestätigst die Berichte. Kurz erklärt: NVDA, TalkBack und VoiceOver sind Screenreader (Vorlese-Programme für blinde Menschen) für Windows, Android bzw. iPhone. Android Auto zeigt Apps auf dem Auto-Display. Chromecast überträgt Ton auf Fernseher oder Lautsprecher. Autoplay heißt: Die Wiedergabe startet von selbst. Das Tray ist das Symbol im Infobereich der Taskleiste. "Systemschrift 200 %" stellst du in den Geräteeinstellungen unter Anzeige bzw. Schriftgröße ein.

| Prüfung | Gerät | Woran man sieht, dass es klappt |
|---|---|---|
| Bedienung nur mit Tastatur und mit dem Screenreader NVDA | Windows-PC, Chrome, Firefox; Safari am Mac | Jeder Knopf ist erreichbar und wird vorgelesen |
| TalkBack | Android-Telefon | Sender, Play und Pause werden vorgelesen |
| VoiceOver | iPhone (erst mit Apple) | wie TalkBack |
| Systemschrift 200 % | Telefon | Nichts wird abgeschnitten oder überlappt |
| Wisch-Gesten | Telefon | Senderwechsel per Wischen klappt |
| Wecker mit Android-Berechtigung | Android-Telefon | Wecker startet das Radio zur eingestellten Zeit, auch im Ruhemodus |
| Autoplay | echte Browser | Der Start klappt nach einem Klick, ohne Fehlermeldung |
| Android Auto | Auto oder Desktop Head Unit | Senderliste und Wiedergabe im Auto |
| Chromecast | Android-Telefon und Chromecast | Start, Titelwechsel, Senderwechsel, Lautstärke |
| Widget | Android-Telefon | Widget zeigt Sender und reagiert auf Tippen |
| Linux-Tastenkürzel, Tray und Mini-Fenster | Linux- und Windows-PC | Medientasten steuern die App, Tray-Menü und Mini-Fenster öffnen |

- **Prüfschritt:** Für jede Zeile liegt ein kurzer Bericht des Entwicklers vor (Gerät, Datum, Ergebnis).
- **Wenn es nicht klappt:** Jede Abweichung mit Gerät, Systemversion und Bildschirmfoto an den Entwickler.
- [ ] erledigt

---

## 17. Recht und Datenschutz im Betrieb

Vorprüfung, keine Rechtsberatung. Jeden Punkt lässt du von einem Anwalt bestätigen. Die Kürzel wie [D-04](STORE-RICHTLINIEN.md#d-04) in diesem Teil verweisen auf die Liste der Store-Regeln. Du musst sie nicht lesen, sie sind für Nachfragen von Anwalt oder Entwickler da. Die Store-Regeln zum Datenschutz: [D-04](STORE-RICHTLINIEN.md#d-04), [G-12](STORE-RICHTLINIEN.md#g-12), [G-13](STORE-RICHTLINIEN.md#g-13), [A-09](STORE-RICHTLINIEN.md#a-09), [A-15](STORE-RICHTLINIEN.md#a-15), [M-05](STORE-RICHTLINIEN.md#m-05), [W-03](STORE-RICHTLINIEN.md#w-03).

### 17.1 Impressum nach § 5 DDG

- **Wer:** Betreiber liefert die Werte, Entwickler trägt sie ein.
- **Was:** Das Impressum (die Pflichtseite mit deinen Firmendaten) vollständig machen, auf der Web-App unter `/impressum/` (deutsch und englisch) und in der App. Es enthält: Name, Rechtsform (zum Beispiel GmbH), ladungsfähige Anschrift (eine Hausanschrift, an der man dir Post zustellen kann, kein Postfach), vertretungsberechtigte Person, E-Mail, einen zweiten schnellen Kontaktweg (Telefon), Register und USt-IdNr., falls vorhanden, sowie die verantwortliche Person für Inhalte nach § 18 MStV (Medienstaatsvertrag).
- **Wozu:** Pflicht für jede Website und App, die geschäftlich betrieben wird (das Gesetz nennt das "geschäftsmäßiges Telemedium"). Google, Apple und Microsoft verlangen dieselben Angaben zusätzlich in ihrer Verwaltungsoberfläche, der Store-Konsole (Schritt 17.5).
- **Wo eintragen:** Du lieferst die Werte wie in Schritt 3.1 beschrieben (Liste in Anhang B), der Entwickler trägt sie ein. Verwende in allen Store-Konsolen dieselbe Anschrift, Buchstabe für Buchstabe.
- **Woher:** Handelsregister bzw. Gewerbeanmeldung, eigene Unterlagen.
- **Prüfschritt:** Die Seite `/impressum/` zeigt keine Stellen mit doppelten geschweiften Klammern wie `{{BETREIBER_NAME}}` (das sind noch nicht ausgefüllte Platzhalter). Die Anschrift im Impressum und im D-U-N-S-Eintrag (deine Firmenkennnummer, Schritt 18.1) stimmt überein. Die Gleichheit in Play Console, App Store Connect und Partner Center prüfst du erst in Schritt 16.1 (Abnahme), wenn die Konten stehen.
- **Wenn es nicht klappt:** Du kennst eine Angabe nicht (zum Beispiel die USt-IdNr.): Was es für LineFM Studios nicht gibt, trägst du wie in Schritt 3.1 als "Nicht zutreffend." ein (nie leer lassen). Alles andere findest du im Handelsregisterauszug oder fragst du den Steuerberater. Das Impressum zeigt noch Platzhalter in doppelten Klammern: Eine Angabe fehlt in der Werte-Datei `legal_values.json` (Schritt 3.1), sag es dem Entwickler. Ob alles rechtlich passt, bestätigt der Anwalt.
- [ ] erledigt

### 17.2 Datenschutzerklärung und Einwilligung (DSGVO, TDDDG)

- **Wer:** Betreiber mit Anwalt, Entwickler pflegt die Texte.
- **Was:** Die Datenschutzerklärung nennt jeden Empfänger: laut.fm, Apple iTunes-Suche (Cover), `cdn.linefm.de`, `radiogruppe.de`, Google Cast, Hoster, sowie **Sentry, Firebase und Umami**. Wenn Telemetrie genutzt wird (Schritt 1.6), laufen die Dienste in den Store-Builds nur nach Einwilligung und sind in allen Store-Formularen als optional angegeben. Im Web kommt GA4/GTM hinzu (Schritt 10.2).
- **Wozu:** Ohne Einwilligung der Nutzer darf die App auf dem Gerät nichts auslesen oder speichern, was nicht zwingend nötig ist (§ 25 TDDDG, das Gesetz zum Datenschutz auf Endgeräten). Die Store-Formulare müssen zur Erklärung passen, sonst droht Ablehnung oder Sperre.
- **Wo eintragen:** Du sagst dem Entwickler, welche Dienste aktiv sind. Er trägt sie in die Werte-Datei `legal_values.json` bzw. die Variable `LEGAL_VALUES_JSON` ein und lässt den Generator (sein Programm für die Rechtstexte) mit den genutzten Diensten laufen, zum Beispiel `--providers=umami,sentry`, plus Firebase, falls aktiv. Die Store-Formulare füllst du nach Abschnitt 13 aus.
- **Woher:** Deine Entscheidung, welche Dienste laufen (Schritt 9.1), und die Auftragsverarbeitungsverträge (AVV) aus Schritt 17.3.
- **Prüfschritt:** Das macht der Entwickler mit dir gemeinsam. Ohne Einwilligung zeigt der Netzwerkmitschnitt (Browser-Entwicklertools, Taste F12, Reiter "Netzwerk") keine Anfrage an Sentry, Firebase, Umami oder Google. Widerruf in den Einstellungen stoppt die Übertragung sofort.
- **Externe Links:** Die App lädt Inhalte von und verlinkt auf Dritte: `music.youtube.com` und `open.spotify.com` (Song suchen), `radiogruppe.de`, `cdn.linefm.de`, `api.laut.fm`, die Streams und die iTunes-Suche. Prüfe mit dem Anwalt, dass die Datenschutzerklärung jeden davon nennt und bei Links sagt, dass beim Öffnen die Regeln des Zielanbieters gelten. Die vollständige Liste liefert der Entwickler aus dem Code.
- Store-Regeln: [D-04](STORE-RICHTLINIEN.md#d-04), [G-04](STORE-RICHTLINIEN.md#g-04), [G-12](STORE-RICHTLINIEN.md#g-12), [A-09](STORE-RICHTLINIEN.md#a-09), [A-15](STORE-RICHTLINIEN.md#a-15), [M-05](STORE-RICHTLINIEN.md#m-05)
- **Wenn es nicht klappt:** Der Netzwerkmitschnitt zeigt Anfragen vor der Einwilligung: Sofort dem Entwickler melden, das wäre ein Datenschutzfehler. Eine Zeile der Datenschutzerklärung passt nicht zu dem, was die App tut: Der Entwickler lässt den Generator neu laufen, danach stimmst du das Ergebnis mit dem Anwalt ab.
- [ ] erledigt

### 17.3 AVV je Auftragsverarbeiter

- **Wer:** Betreiber.
- **Was:** Für jeden Dienst, der personenbezogene Daten (alles, was sich einer Person zuordnen lässt, zum Beispiel IP-Adressen) in deinem Auftrag verarbeitet, einen Auftragsverarbeitungsvertrag (AVV) nach Art. 28 DSGVO abschließen und ablegen. Darin sagt der Dienstleister zu, die Daten nur nach deinen Vorgaben zu verwenden.
- **Wozu:** Ohne unterschriebenen Vertrag darf ein Dienst nicht eingeschaltet werden. Die Freigabe-Checkliste sperrt die Telemetrie (Statistik und Absturzberichte) so lange.
- **Wo eintragen:** Ablage im Passwortmanager oder Vertragsordner. In der Spalte "DPF prüfen" siehst du, bei welchen Anbietern du nachsehen musst, ob sie im Datenschutzabkommen EU-USA (Data Privacy Framework, kurz DPF) gelistet sind. Liste:

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
| CDN-Anbieter von `cdn.linefm.de` | Logos | beim CDN-Anbieter | je nach Anbieter |

- **Woher:** Die Anbieter. Die genauen Menüpfade haben wir nicht live geprüft. Liste der DPF-Teilnehmer: <https://www.dataprivacyframework.gov/list>.
- **Prüfschritt:** Für jede Zeile mit aktivem Dienst liegt ein Vertrag mit Datum vor, der DPF-Status ist mit Abrufdatum notiert.
- **Wenn es nicht klappt:** Ein Anbieter bietet keinen Vertrag zum Anklicken: Beim Anbieter nach dem "Data Processing Addendum" fragen (das englische Wort für den AVV). Ein US-Anbieter fehlt in der DPF-Liste: Das heißt nicht automatisch, dass etwas verboten ist, kläre es mit dem Anwalt. Solange ein Vertrag fehlt, bleibt der Dienst ausgeschaltet.
- [ ] erledigt

### 17.4 Barrierefreiheit (BFSG)

- **Wer:** Betreiber entscheidet, Entwickler setzt um.
- **Was:** Entscheidung des Inhabers: Es gibt eine **freiwillige** Erklärung zur Barrierefreiheit als Seite `/barrierefreiheit/` (de und en) in der Web-App, Inhalt aus [BARRIEREFREIHEIT.md](BARRIEREFREIHEIT.md) (Schritt 3.2). Unabhängig davon klärst du mit dem Anwalt, ob das BFSG (Barrierefreiheitsstärkungsgesetz) Pflichten auslöst. Kleinstunternehmen mit Dienstleistungen sind ausgenommen (nach dem Gesetz: weniger als 10 Beschäftigte und höchstens 2 Millionen Euro Jahresumsatz oder Bilanzsumme). Ob das auf LineFM Studios zutrifft, entscheidet der Anwalt.
- **Wozu:** Seit 28.06.2025 gelten die Anforderungen für bestimmte Dienstleistungen im elektronischen Geschäftsverkehr. Ob eine kostenlose Radio-App darunter fällt, ist eine Rechtsfrage.
- **Wo eintragen:** Kontakt und Antwortfrist für Barrieren lieferst du (Anhang B), der Entwickler trägt sie in `docs/BARRIEREFREIHEIT.md` ein. Die Seite `/barrierefreiheit/` baut der Entwickler und verlinkt sie im Fuß der Web-App und in der App unter "Über".
- **Woher:** Anwalt. Gesetzestext: <https://www.gesetze-im-internet.de/bfsg/> (nicht live abgerufen).
- **Prüfschritt:** `https://app.linefm.de/barrierefreiheit/` und `/en/barrierefreiheit/` antworten mit 200 (der Statuscode für "Seite gefunden", der Entwickler prüft das) und zeigen keine Platzhalter in doppelten Klammern. Die BFSG-Einschätzung des Anwalts liegt schriftlich vor und bestätigt die freiwillige Erklärung.
- Store-Regeln: [W-06](STORE-RICHTLINIEN.md#w-06)
- **Wenn es nicht klappt:** Der Anwalt sieht Pflichten nach dem BFSG: Die freiwillige Erklärung reicht dann nicht, mit dem Entwickler einen Plan und eine Frist abstimmen. Die Seite `/barrierefreiheit/` antwortet nicht mit 200: Die Web-Version wurde noch nicht neu gebaut, bitte den Entwickler darum.
- [ ] erledigt

### 17.5 Händlerstatus nach DSA bei Apple und Google

- **Wer:** Betreiber (Konto), Anwalt liefert den Text der Nutzungsbedingungen, Entwickler baut die Seite.
- **Was:** In App Store Connect (Apple) und in der Play Console (Google) angeben, ob LineFM Studios als Händler (englisch Trader) im Sinne des Digital Services Act (DSA, EU-Gesetz über digitale Dienste) auftritt, und die Kontaktdaten bestätigen. Grob gesagt ist Händler, wer gewerblich handelt, nicht nur zum privaten Spaß.
- **Wozu:** Apple verlangt die Angabe für jedes Konto, auch ohne EU-Vertrieb, und fragt spätestens bei der nächsten Einreichung danach. Als Händler zeigt Apple in der EU Anschrift, Telefon und E-Mail auf der Produktseite. Wer kein Händler ist, bei dem weist Apple EU-Kunden darauf hin, dass Verbraucherrechte nicht gelten. Google fragt dasselbe in der Play Console ab.
- **Wo eintragen:** App Store Connect > "Business" > Reiter "Agreements" > Bereich "Compliance" > "Digital Services Act" > "Complete Compliance Requirements" (Rolle Account Holder oder Admin). Je App: Apps > App wählen > "App Compliance" > "Digital Services Act" > "Edit". Play Console > "Manage account" > "Account details" > "About you" (Status Trader oder Non-trader erklären), danach je App unter "Monitor and improve" > "Policy and programs" > "App content" bestätigen. Als Trader braucht jede App einen Link zu Nutzungsbedingungen.
- **Woher:** Für Firmen nimmt Apple die Anschrift aus dem D-U-N-S-Eintrag (Schritt 18.1), dazu Telefon und E-Mail (per Code bestätigt) und einen Nachweis zu Name und Anschrift. Quelle Apple: <https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/> (abgerufen 26.11.2026). Zu Google: <https://support.google.com/googleplay/android-developer/answer/17594752> (abgerufen 26.11.2026).
- **Fristen bei Google:** Bestehende Konten müssen bis **1. Februar 2027** erklären, neue Konten sofort. Ab 1. März 2027 zeigt Google öffentlich Kontaktdaten, die D-U-N-S-Nummer und den Link zu den Nutzungsbedingungen, im EWR und in Großbritannien zusätzlich den Händlernamen ("Offered by").
- **Wichtig:** Falsche Angaben können zur Kontosperre und weltweiten Entfernung der App führen. Die Erklärung ersetzt die Identitätsprüfung nicht. Als Händler verlangt Apple zusätzlich Zahlungskontodaten (Bankverbindung), falls noch keine hinterlegt sind.
- **Entscheidung:** Ob du Händler bist, entscheidest du mit dem Anwalt. Google nennt als Hinweise Gewinnabsicht (auch durch Werbung), Umfang, Geschäftsaufbau und Rechtsform. Nutzungsbedingungen für die App gibt es bisher nicht: Als Händler brauchst du eine Seite dafür, der Anwalt liefert den Text.
- **Prüfschritt:** Bei Apple ist der letzte Schritt "Review and Confirm" abgeschlossen, bei Google steht die Erklärung unter "App content" (eine eigene Bestätigungsanzeige beschreibt Google nicht). Die angezeigten Daten stimmen mit dem Impressum überein.
- **Microsoft:** Fragt das Partner Center nach dem Händlerstatus, dieselben Angaben wie bei Google und Apple.
- **Apple je App:** Nach der Bestätigung lässt sich der Status je App einstellen. Das gehört in die Apple-Runde (Abschnitt 15), die später kommt.
- Store-Regeln: [G-26](STORE-RICHTLINIEN.md#g-26), [A-25](STORE-RICHTLINIEN.md#a-25), [A-43](STORE-RICHTLINIEN.md#a-43), [M-25](STORE-RICHTLINIEN.md#m-25). Apple erst in der späteren Apple-Runde.
- **Wenn es nicht klappt:** Der Bestätigungscode kommt nicht an: In der Eingabemaske die manuelle Prüfung anfordern. Die Anschrift stimmt nicht: den D-U-N-S-Eintrag prüfen, Apple ändert die Anschrift nur über den Support. Bei einem Postfach als Anschrift zusätzlich einen Nachweis (zum Beispiel Rechnung) hochladen. Apple kann den Händlerstatus nicht für dich festlegen. Die Statusnamen in App Store Connect haben wir nicht geprüft.
- [ ] erledigt

### 17.6 Markenrechte LINEFM

- **Wer:** Betreiber.
- **Was:** Prüfen, ob die Marke LINEFM eingetragen ist und wem sie gehört. Falls nicht: Anmeldung beim DPMA (Deutsches Patent- und Markenamt) oder beim EUIPO (Markenamt der EU) erwägen.
- **Wozu:** Stores reagieren auf Markenbeschwerden. Mit eingetragener Marke kannst du Nachahmer melden und eigene Einreichungen belegen.
- **Wo eintragen:** Ergebnis in Abschnitt A1 der [Freigabe-Checkliste](FREIGABE-CHECKLISTE.md).
- **Woher:** Recherche im DPMAregister (<https://register.dpma.de>, das deutsche Markenregister) und in TMview (Suche in vielen Markenregistern), Anwalt. Gebühren nicht live abgerufen.
- **Prüfschritt:** Registernummer oder bewusste Entscheidung gegen eine Anmeldung ist notiert.
- **Wenn es nicht klappt:** Die Recherche findet eine ähnliche Marke eines anderen Inhabers: Nicht selbst bewerten, mit dem Anwalt klären. Die Gebühren für eine Anmeldung haben wir nicht abgerufen (nicht geprüft).
- [ ] erledigt

### 17.7 laut.fm-Vereinbarung

- **Wer:** Betreiber.
- **Was:** Die Vereinbarung mit laut.fm hast du bereits und behältst sie selbst, sie kommt nicht ins Repository (Entscheidung des Inhabers). Die Bestätigung aus Schritt 2.1 holst du ein. Bei der Einreichung der App nennst du sie, wenn ein Store nach den Rechten an den Inhalten fragt.
- **Wozu:** Google und Apple fragen bei Streaming-Apps nach dem Recht, die Inhalte zu verbreiten. Ohne Beleg droht die Ablehnung wegen geistigen Eigentums.
- **Wo eintragen:** Play Console: Hinweis im Feld für Prüfer (Schritt 6.13), Partner Center: Schritt 7.7; bei einer Beschwerde wegen geistigen Eigentums lädst du den Nachweis über die Seite "Richtlinienstatus" hoch. App Store Connect (spätere Apple-Runde): Frage "Content Rights" in den App-Informationen beantworten, Hinweis in den Review-Notizen, Nachweis bei Bedarf als Anhang. Partner Center: Hinweise für die Zertifizierung. Snap und Flathub: auf Nachfrage.
- **Woher:** deine Unterlagen.
- **Prüfschritt:** Abschnitt A5 der Freigabe-Checkliste abgehakt, Vereinbarung griffbereit.
- Store-Regeln: [D-03](STORE-RICHTLINIEN.md#d-03), [G-03](STORE-RICHTLINIEN.md#g-03), [G-32](STORE-RICHTLINIEN.md#g-32), [A-10](STORE-RICHTLINIEN.md#a-10), [M-14](STORE-RICHTLINIEN.md#m-14), [S-04](STORE-RICHTLINIEN.md#s-04)
- **Wenn es nicht klappt:** Ein Store fragt nach Rechten: Schick ihm die Bestätigung von laut.fm aus Schritt 2.1 und formuliere keine eigene Erklärung dazu. Die Plattform lehnt wegen geistigen Eigentums ab: Nachweis über den Einspruchsweg des Stores hochladen (Schritt 20.6).
- [ ] erledigt

### 17.8 Radio3FM und FobFM

- **Wer:** Betreiber legt die Freigaben selbst ab (nicht ins Repository).
- **Was:** Schriftliche Freigabe beider Sender (Schritt 2.2) als Datei ablegen, damit du sie Prüfern zeigen kannst.
- **Wozu:** Gleicher Grund wie 17.7.
- **Wo eintragen:** Abschnitt A1 der Freigabe-Checkliste, Ablage bei dir (Betreiber).
- **Woher:** Ansprechpartner bei den Sendern (Sender-Betreiber).
- **Prüfschritt:** Zwei Freigaben mit Datum liegen vor. Ohne sie nimmt der Entwickler die Sender aus der App.
- Store-Regeln: [D-03](STORE-RICHTLINIEN.md#d-03), [G-02](STORE-RICHTLINIEN.md#g-02), [M-28](STORE-RICHTLINIEN.md#m-28). Ohne schriftliche Erlaubnis für Namen, Logos und Streams keine Andeutung einer Verbindung.
- **Wenn es nicht klappt:** Eine Freigabe fehlt: Lass den Entwickler den Sender aus der App nehmen und liefere nicht auf Verdacht aus. Die Freigaben legst du als Datei mit Datum bei dir ab.
- [ ] erledigt

### 17.9 Lizenzen und Seite /lizenz/

- **Wer:** Entwickler.
- **Was:** Die Seite `/lizenz/` (de und en) in der Web-App nennt die Lizenz der App und alle Fremdlizenzen (libmpv und FFmpeg, zwei Abspiel-Bausteine in der App, und die Pakete aus [LIZENZEN-DRITTE.md](LIZENZEN-DRITTE.md)). Ihre URL steht in der Flathub-Metainfo und kann in den Store-Einträgen stehen.
- **Wozu:** LGPL und GPL verlangen Lizenztext und Hinweis auf den Quellcode der Bibliotheken. Flathub prüft die Lizenz-URL.
- **Wo eintragen:** nichts von Hand, die Seite kommt mit dem Web-Build. Du gibst den Wortlaut zur App-Lizenz frei (Schritt 2.5).
- **Woher:** Repo.
- **Prüfschritt:** `https://app.linefm.de/lizenz/` und `/en/lizenz/` antworten mit 200. In der App öffnet "Lizenzen" die Liste.
- Store-Regeln: [F-07](STORE-RICHTLINIEN.md#f-07), [W-04](STORE-RICHTLINIEN.md#w-04)
- **Wenn es nicht klappt:** Die Seite `/lizenz/` antwortet nicht mit 200: Die Web-Version wurde noch nicht neu gebaut, bitte den Entwickler darum. Eine Lizenz fehlt in der Liste: Den Entwickler fragen, er ergänzt [LIZENZEN-DRITTE.md](LIZENZEN-DRITTE.md).
- [ ] erledigt

### 17.10 Jugendschutz (JMStV)

- **Wer:** Betreiber entscheidet, Entwickler setzt um.
- **Was:** Die App richtet sich an Nutzer ab 13 Jahren (Entscheidung des Inhabers), in allen Stores mit Altersfreigabe 13+. Grund: gelegentlich derbe Sprache in den Streams. Der Anwalt entscheidet, ob nach dem Jugendmedienschutz-Staatsvertrag (JMStV) ein Jugendschutzbeauftragter zu bestellen ist (§ 7 JMStV; eine benannte Person, die zu Jugendschutz berät) oder ob LineFM Studios stattdessen einer Selbstkontrolle wie der FSM beitritt.
- **Wozu:** Für geschäftsmäßige Telemedien mit möglicherweise entwicklungsbeeinträchtigenden Inhalten kann ein Jugendschutzbeauftragter Pflicht sein.
- **Wo eintragen:** Ergebnis in Abschnitt A4 der Freigabe-Checkliste. Ist ein Beauftragter nötig, kommen Name und Kontakt ins Impressum (der Entwickler legt dafür einen Platzhalter an).
- **Woher:** Anwalt. Gesetzestext nicht live abgerufen.
- **Prüfschritt:** Schriftliche Einschätzung liegt vor.
- Store-Regeln: [D-06](STORE-RICHTLINIEN.md#d-06), [D-07](STORE-RICHTLINIEN.md#d-07), [G-19](STORE-RICHTLINIEN.md#g-19), [G-20](STORE-RICHTLINIEN.md#g-20), [A-17](STORE-RICHTLINIEN.md#a-17), [M-18](STORE-RICHTLINIEN.md#m-18), [F-10](STORE-RICHTLINIEN.md#f-10)
- **Wenn es nicht klappt:** Der Anwalt rät zu einem Jugendschutzbeauftragten: Name und Kontakt ins Impressum, den Entwickler einen Platzhalter anlegen lassen. Eine Altersfreigabe ab 13 wird in einem Store höher eingestuft: Antworten im Fragebogen prüfen. Stimmen sie, akzeptierst du die höhere Einstufung oder lässt den Inhalt anpassen (zum Beispiel Sender mit derben Streams entfernen), die Einstufung wird nie gegen die Antworten geändert. Die Entscheidung trifft der Betreiber mit dem Anwalt.
- [ ] erledigt

### 17.11 Verzeichnis der Verarbeitungstätigkeiten (Art. 30 DSGVO)

- **Wer:** Betreiber, Entwickler liefert das Muster.
- **Was:** Das ausgefüllte Muster [VERARBEITUNGSVERZEICHNIS.md](VERARBEITUNGSVERZEICHNIS.md) übernehmen, prüfen und als dein eigenes Verzeichnis pflegen. Es listet jeden Datenfluss: wofür die Daten genutzt werden (Zweck), auf welcher Rechtsgrundlage, wer sie bekommt, ob sie in Länder außerhalb der EU gehen (Drittlandübermittlung) und wie lange sie gespeichert werden.
- **Wozu:** Das Verzeichnis ist Pflicht. Die Ausnahme für kleine Unternehmen (Art. 30 Abs. 5 DSGVO) greift nicht, wenn Telemetrie genutzt wird, weil du Daten dann nicht nur gelegentlich verarbeitest. Ohne Telemetrie prüft der Anwalt, ob die Ausnahme greift. Die Datenschutz-Aufsichtsbehörde kann es anfordern. Es ist die Grundlage für Datenschutzerklärung und Store-Formulare.
- **Wo eintragen:** In deine Unterlagen. Das Muster im Repo bleibt Vorlage, die gepflegte Fassung liegt bei dir.
- **Woher:** Muster im Repo, deine Konfiguration, die AVV aus Schritt 17.3.
- **Prüfschritt:** Jede aktive Zeile ist geprüft und datiert, die Speicherdauern stimmen mit der Datenschutzerklärung überein.
- Store-Regeln: [D-05](STORE-RICHTLINIEN.md#d-05), [D-08](STORE-RICHTLINIEN.md#d-08)
- **Wenn es nicht klappt:** Eine Zeile passt nicht zur Wirklichkeit: Mit dem Entwickler abgleichen, bevor du sie freigibst. Die Aufsichtsbehörde fordert das Verzeichnis an: Gepflegte Fassung, nicht das Muster, vorlegen.
- [ ] erledigt

### 17.12 Datenpanne: Meldeweg (Art. 33 und 34 DSGVO)

- **Wer:** Betreiber liefert die Meldewege, Entwickler trägt sie in `betrieb/INCIDENT.md` ein.
- **Was:** Festlegen, wer bei einer Datenpanne entscheidet und meldet. Eine Datenpanne liegt vor, wenn Unbefugte an Daten kommen oder Daten verloren gehen. Beispiele: offenes Umami- oder Sentry-Konto (auch GlitchTip), geleakter Firebase-Zugang, kompromittierter Server, Meldung eines Auftragsverarbeiters.
- **Wozu:** Meldung an die Datenschutz-Aufsichtsbehörde (die Landesbehörde für Datenschutz) binnen 72 Stunden ab Kenntnis, wenn ein Risiko für Betroffene besteht (Art. 33). Bei hohem Risiko auch Benachrichtigung der Betroffenen (Art. 34). Jede Panne wird dokumentiert, auch ohne Meldung.
- **Wo eintragen:** Meldewege in [betrieb/INCIDENT.md](betrieb/INCIDENT.md) (Schritt 19.7). Meldung über das Online-Formular der zuständigen Landesdatenschutzbehörde (dieselbe wie `{{AUFSICHTSBEHOERDE_DATENSCHUTZ}}`).
- **Woher:** Ablauf: 1. Vorfall eindämmen (Zugang sperren, Schlüssel tauschen). 2. Verantwortlicher bei LineFM Studios entscheidet mit dem Anwalt über die Meldepflicht. 3. Meldung binnen 72 Stunden. 4. Dokumentation im Vorfallsbericht. Die AVV verpflichten die Anbieter, dir Pannen unverzüglich zu melden.
- **Prüfschritt:** Namen, Vertretung und Behördenformular sind in INCIDENT.md eingetragen.
- **Wenn es nicht klappt:** Du weißt nicht, ob es eine meldepflichtige Panne ist: Die Frist von 72 Stunden läuft ab dem Moment, in dem du davon erfährst. Ruf sofort den Anwalt an und entscheide mit ihm. Dokumentieren musst du in jedem Fall.
- [ ] erledigt

### 17.13 Speicherdauern

- **Wer:** Betreiber legt die Dauern fest. Hoster bzw. nginx/Traefik stellt der Entwickler ein, die Dienste (Umami, Sentry, GA4) stellt der Betreiber im jeweiligen Konto ein.
- **Was:** Für jeden Datenfluss eine Speicherdauer festlegen, im Dienst einstellen und gleichlautend in Datenschutzerklärung, Verarbeitungsverzeichnis und Store-Formularen angeben.

| Daten | Vorschlag | Wo einstellen | Platzhalter |
|---|---|---|---|
| Server-Logs der Web-App (Protokolle der Zugriffe) | 7 Tage, IP gekürzt (der letzte Teil der IP-Adresse wird abgeschnitten) | Hoster bzw. nginx/Traefik | `{{LOG_AUFBEWAHRUNG}}` |
| Umami, Sentry/GlitchTip, Firebase | 90 Tage | Einstellungen des jeweiligen Dienstes | `{{TELEMETRIE_AUFBEWAHRUNG}}` |
| GA4 (nur Web) | 2 Monate | GA4 > Verwaltung > Datenaufbewahrung | `{{GA4_AUFBEWAHRUNG}}` |
| Support-E-Mails | bis zur Erledigung, danach gesetzliche Aufbewahrung, falls sie greift | Postfach | in der Datenschutzerklärung prüfen |
| Listen der Test-Nutzer bei Google | bis Testende | Play Console | entfällt |

- **Wozu:** Google fragt im Formular "Datensicherheit", ob und wie Daten gelöscht werden. Abweichende Angaben sind ein Ablehnungsgrund.
- **Wo eintragen:** Siehe Tabelle, Werte in `legal_values.json` bzw. `LEGAL_VALUES_JSON`.
- **Woher:** Die Vorschläge sind Erfahrungswerte, keine Rechtsauskunft. Mit dem Anwalt abstimmen.
- **Prüfschritt:** Einstellung im Dienst, Datenschutzerklärung und Store-Formular nennen dieselbe Dauer.
- Store-Regeln: [G-12](STORE-RICHTLINIEN.md#g-12), [G-31](STORE-RICHTLINIEN.md#g-31), [A-31](STORE-RICHTLINIEN.md#a-31)
- **Wenn es nicht klappt:** Der Dienst lässt die gewünschte Dauer nicht zu: Die Dauer in Erklärung und Formular an das anpassen, was der Dienst tatsächlich einstellt, nie umgekehrt.
- [ ] erledigt

---

## 18. Konten, Kosten und Steuern

Alle Konten laufen auf LineFM Studios als Organisation. Gebühren abgerufen am 26.11.2026 auf den genannten offiziellen Seiten. Steuerliches ist nur eine Vorprüfung. Was davon für dich gilt, klärst du mit deinem Steuerberater.

### 18.1 D-U-N-S-Nummer

- **Wer:** Betreiber.
- **Was:** Eine D-U-N-S-Nummer für LineFM Studios beantragen oder die vorhandene nachschlagen. Das ist eine neunstellige Firmenkennnummer der Auskunftei Dun & Bradstreet. Halte Firmenname und Anschrift genau so bereit, wie sie im Handelsregister stehen.
- **Wozu:** Pflicht für das Google-Organisationskonto und das Apple-Organisationskonto, bei Microsoft der schnellere Weg. Google verlangt, dass rechtlicher Name und Anschrift im Zahlungsprofil exakt mit dem Dun-&-Bradstreet-Profil übereinstimmen. Impressum und Handelsregister sollten dazu passen.
- **Wo eintragen:** Antrag direkt bei Dun & Bradstreet (kostenlos, <https://www.dnb.com/duns/get-a-duns.html> laut Google und Apple, "International" wählen, die deutsche Seite haben wir nicht geprüft). Vorher nachschlagen, ob schon eine Nummer existiert: <https://my.dnb.com/lookup>. Die Nummer selbst trägst du bei der Kontoanlage in Google Play bzw. im Apple-Anmeldeformular ein. Vor Drittanbietern, die Geld verlangen, warnt Google. Nur ein Expressdienst von D&B kostet. Apple bietet eine eigene Suche im Anmeldeablauf.
- **Woher:** kostenlos, laut Google bis zu etwa 30 Tage Bearbeitung (Android-FAQ: 28 Tage; Apple nennt 5 Werktage bei D&B plus bis zu 2 Werktage Abgleich) (<https://support.google.com/googleplay/android-developer/answer/13628312>, abgerufen 26.11.2026).
- **Prüfschritt:** Die neunstellige Nummer ist im Passwortmanager notiert, der Eintrag zeigt die richtige Anschrift.
- **Wenn es nicht klappt:** Name oder Anschrift weichen ab, Banner "Your organization name or address is no longer verified": Im Banner "View details" > "How to fix" > "Review details" (nur Kontoinhaber), im Zahlungscenter "Review updates" > "Confirm". Apple meldet "Your organization is not listed as a legal entity": Unter dem exakten Namen des Rechtsträgers eintragen (kein Marken- oder Handelsname), sonst D&B über <https://support.dnb.com/?CUST=APPLEDEV> mit Handelsregisterauszug anschreiben. Dauert es länger als zwei Wochen: D&B per E-Mail kontaktieren. Profil steht auf "out of business": D&B kontaktieren. Neue Nummer vergeben: Google Play Support bitten, das Konto umzustellen.
- [ ] erledigt

### 18.2 Kontenübersicht

- **Wer:** Betreiber (Haken je Konto erst am Ende von Phase 8).

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

- **Postfächer:** Lege sie früh bei deinem Mail-Anbieter an (dort, wo `linefm.de` Mails empfängt): `support@linefm.de` für den Support, eine Funktionsadresse für die Konten (zum Beispiel `apps@linefm.de`), ein gemeinsames Postfach für Alarme und bei Microsoft eine Adresse auf der Firmendomain. Wie das geht, hängt vom Mail-Anbieter ab (nicht geprüft).
- **Was:** Lege jedes Konto an, das du brauchst, mit einer Funktionsadresse (zum Beispiel `apps@linefm.de` für Konten, `support@linefm.de` nur für den Support, nie die private Adresse). Schalte die Zwei-Faktor-Anmeldung ein (Anmeldung mit Passwort plus Code vom Handy) und lege die Notfall-Codes (Ersatz-Codes für den Fall, dass das Handy fehlt) im Passwortmanager ab. Mindestens zwei Personen brauchen je Konto Admin-Recht.
- **Wozu:** Verlässt eine Person das Team, bleibt das Konto erreichbar. Fällt ein Konto weg, lässt sich die App bei Google und Apple nicht einfach in ein anderes Konto übernehmen, dafür musst du eine Übertragung (Transfer) beantragen.
- **Wo eintragen:** Passwortmanager, Spalte "Konto, Inhaber, Zweitadmin, Notfall-Codes, Verlängerung". Die drei Rollen trägst du einmal hier ein und verweist in den Konten darauf: Konto-Inhaber (Firma): ____________________; Betreiber von DNS und CDN: ____________________; zweite Person mit Admin-Recht: ____________________ (die Felder stehen auch in Schritt 1.6).
- **Woher:** siehe Tabelle.
- **Prüfschritt:** Für jede Zeile sind Inhaber, Zweitadmin und Ablaufdatum der Mitgliedschaft (Apple, Domain) notiert.
- Store-Regeln zu Konten: [D-02](STORE-RICHTLINIEN.md#d-02), [G-25](STORE-RICHTLINIEN.md#g-25), [A-24](STORE-RICHTLINIEN.md#a-24), [M-20](STORE-RICHTLINIEN.md#m-20), [S-07](STORE-RICHTLINIEN.md#s-07), [F-12](STORE-RICHTLINIEN.md#f-12).
- **Wenn es nicht klappt:** Ein Konto hat nur einen Admin: Zweite Person mit Admin-Recht einladen, bevor die erste ausfällt. Notfall-Codes verloren: Sofort beim Anbieter neue erzeugen. Ein Konto wurde mit einer privaten Adresse angelegt: Beim Anbieter auf die Funktionsadresse umstellen, soweit er das erlaubt (Google und Apple oft nicht, dann Transfer beantragen).
- [ ] erledigt

### 18.3 Vereinbarungen, Zahlungs- und Steuerangaben in den Konsolen

- **Wer:** Betreiber.
- **Was:** Die Vereinbarungen jeder Console annehmen. Das Zahlungsprofil (Bankverbindung, mit der die Stores Geld auszahlen oder abbuchen) und Steuerformulare sind bei einer kostenlosen App ohne Käufe nach Angaben der Stores nicht nötig. Ausnahme: Als DSA-Händler verlangt Apple Zahlungskontodaten (Schritt 17.5, spätere Apple-Runde).
- **Wozu:** Ohne angenommene Vereinbarung stoppen die Uploads. Apple legt neue Fassungen regelmäßig vor.
- **Wo eintragen:** Zahlungsprofil in der Play Console: "Manage account" > "Play apps settings" > "Monetization settings" > "Payments profile" (nur der Kontoinhaber). Einen Vereinbarungsbereich unter "Settings" nennt die Google-Doku nicht (nicht geprüft). Der Developer-Distribution-Vertrag wird bei der Registrierung angenommen. App Store Connect > Geschäftliches (Vertrag für kostenlose Apps). Partner Center > Konto-Einstellungen.
- **Woher:** Quellen in den Store-Punkten. Fragt eine Console beim Anlegen dennoch Steuerangaben ab (zum Beispiel das US-Steuerformular W-8BEN-E für ausländische Firmen), fülle es mit dem Steuerberater aus.
- **Prüfschritt:** Keine Console zeigt einen roten Hinweis zu Vereinbarungen.
- Store-Regeln: [G-28](STORE-RICHTLINIEN.md#g-28), [A-27](STORE-RICHTLINIEN.md#a-27), [M-21](STORE-RICHTLINIEN.md#m-21), [S-07](STORE-RICHTLINIEN.md#s-07)
- **Wenn es nicht klappt:** Die Zahlungsmethode zeigt "Verifications pending": "Verify" klicken und die Einzahlungsprüfung abschließen oder offizielle Bankunterlagen hochladen (bis zu fünf Tage). Ob Google bei einer kostenlosen App ohne Käufe ein Zahlungsprofil und Steuerangaben verlangt, ist auf den gelesenen Seiten nicht ausdrücklich belegt (nicht geprüft).
- [ ] erledigt

### 18.4 Steuerliche Vorprüfung

- **Wer:** Betreiber mit Steuerberater.
- **Was:** Kosten der Konten (Google, Apple, Domain, Server) als Betriebsausgaben erfassen. Rechnungen von Google (Irland), Apple (Irland bzw. Luxemburg) und Cloudflare (USA) können unter das Reverse-Charge-Verfahren fallen (du schuldest dann die Umsatzsteuer, nicht der Rechnungsaussteller).
- **Wozu:** Saubere Buchhaltung. Die App erzielt keinen Umsatz, solange sie kostenlos ist und keine Werbung zeigt.
- **Wo eintragen:** Buchhaltung.
- **Woher:** Rechnungen aus den Konsolen. **Das ist keine Steuerberatung, bitte mit dem Steuerberater klären.**
- **Prüfschritt:** Der Steuerberater hat die Einordnung bestätigt.
- **Wenn es nicht klappt:** Eine Rechnung ist unklar eingeordnet: Dem Steuerberater vorlegen, nicht selbst entscheiden. Das ist keine Steuerberatung.
- [ ] erledigt

---

## 19. Technik und Betrieb

Das Betriebshandbuch mit Deploy, Rollback und Wiederherstellung ist [betrieb/RUNBOOK.md](betrieb/RUNBOOK.md), der Störungsablauf [betrieb/INCIDENT.md](betrieb/INCIDENT.md), die Bedrohungen [betrieb/BEDROHUNGSMODELL.md](betrieb/BEDROHUNGSMODELL.md).

### 19.1 Domains und DNS

- **Wer:** Betreiber.
- **Was:** Die Domain `linefm.de` mit den Subdomains `app.linefm.de` (Web-App) und `cdn.linefm.de` (Logos) dauerhaft absichern: automatische Verlängerung beim Registrar an, Registrar-Sperre (Transfer Lock) an (das ist eine Funktion des Registrars. DENIC beschreibt zusätzlich den .de **Registry Lock** als stärkeren Schutz, <https://www.denic.de/en/products/de-registry-lock/>, Preis über den Provider), DNSSEC an, wenn der DNS-Anbieter es kann.
- **Wozu:** Läuft die Domain aus, fallen Web-App, App-Links (Web-Adressen, die direkt die App öffnen, abgesichert durch die Dateien `assetlinks.json` und `apple-app-site-association`), die Flathub-Bestätigung und die Datenschutz-URL in allen Stores gleichzeitig aus. Die Stores können die App dann sperren.
- **Wo eintragen:** Beim Registrar und beim DNS-Anbieter. DNSSEC schaltest du beim Registrar ein, nicht bei DENIC. Nutzt du externes DNS (zum Beispiel Cloudflare), trägt der Registrar die DS-Daten ein, die der DNS-Anbieter anzeigt (<https://www.denic.de/en/faq/faqs-about-dnssec/>, abgerufen 26.11.2026). Die Menüs hängen vom Registrar ab, nicht geprüft.
- **Woher:** Registrar-Konto (Schritt 18.2).
- **Prüfschritt:** Das Ablaufdatum der Domain steht im Fristenkalender (Abschnitt 20.5). Ob DNSSEC aktiv ist, prüft der Entwickler (Befehl `dig +dnssec linefm.de` zeigt `ad`) oder du im Browser mit dem Verisign DNSSEC Analyzer (nicht geprüft).
- **Wenn es nicht klappt:** Dein Registrar bietet DNSSEC oder die Sperre nicht an: Support fragen, ob er DNSSEC für .de unterstützt. DNSSEC nur einschalten, wenn DNS-Anbieter und Registrar beide die Daten richtig tragen, falsche Daten machen die Domain für Nutzer mit DNSSEC-Prüfung unerreichbar. Zieht die Domain zu einem anderen Anbieter um, setzt DENIC sie kurz in einen Übergangszustand (TRANSIT) und löscht dabei den DNSSEC-Eintrag (DS-Eintrag). Die Domain ist dann vorübergehend nicht mehr signiert. DNSSEC schützt nicht vor Phishing oder Domain-Entführung. Die Schalter beim Registrar haben wir nicht geprüft.
- [ ] erledigt

### 19.2 Web-Hosting und TLS

- **Wer:** Entwickler prüft, Betreiber bekommt die Rückmeldung.
- **Was:** Hosting aus Abschnitt 5, Zertifikat aus Schritt 4.2. Verlängerung prüfen: Das Zertifikat (der digitale Ausweis der Web-Adresse, Grundlage des Schlosses im Browser) wird automatisch erneuert: Let's Encrypt nach 60 Tagen, Cloudflare ebenfalls.
- **Wozu:** Abgelaufenes Zertifikat heißt: Web-App nicht erreichbar, App-Links ungültig.
- **Wo eintragen:** nichts zusätzlich.
- **Woher:** [betrieb/RUNBOOK.md](betrieb/RUNBOOK.md), Abschnitt "Zertifikate und Domain".
- **Prüfschritt:** Quartalsweise führt der Entwickler den `openssl`-Befehl aus dem Betriebshandbuch (Runbook) aus und meldet dir das Ablaufdatum. Der Uptime-Monitor (Schritt 19.6) meldet Ausfälle.
- **Wenn es nicht klappt:** Das Zertifikat läuft in weniger als 14 Tagen ab, obwohl die Erneuerung automatisch laufen sollte: Beim Hoster prüfen, ob der Erneuerungsjob läuft, sonst von Hand erneuern (Schritt 4.2).
- [ ] eingerichtet
- [ ] regelmäßig erledigt (quartalsweise, Liste in Schritt 20.7)

### 19.3 Signierschlüssel und ihre Sicherung

- **Wer:** Betreiber sichert, Entwickler hilft.
- **Was:** Ein Signierschlüssel ist wie ein Siegel: Nur damit lassen sich Updates der App herausgeben. Geht er verloren, hängen Updates fest. Lege deshalb für jeden Schlüssel eine verschlüsselte Sicherung an zwei getrennten Orten an (Passwortmanager plus Offline-Kopie, zum Beispiel verschlüsselter USB-Stick im Tresor).

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
| Updater-Schlüssel, noch nicht angelegt, siehe Text darunter (Ed25519 ist die Schlüsselart; Secret `UPDATER_ED25519_PRIVATE_KEY`, geplant in der Umgebung `release`) | signiert die Update-Hinweise der direkten Downloads (Installer, die du direkt von der GitHub-Releases-Seite lädst statt aus einem Store: Windows-Setup, macOS-DMG) | Nutzer der direkten Downloads bekommen keine Updates mehr bzw. müssen neu installieren | kein Ablauf |
| GPG-Schlüssel (optional) | `SHA256SUMS.txt.asc` | neuen Schlüssel veröffentlichen | laut Schlüssel |
| SSH-Schlüssel für das Ausrollen | Web-Deploy | neu erzeugen, auf dem Server tauschen | kein Ablauf |

- **Wozu:** Ein verlorener Schlüssel kann Updates für Wochen blockieren.
- **Wo eintragen:** Passwortmanager und Offline-Kopie. In GitHub nur als Secret (Anhang A).
  - **Updater-Schlüssel, Stand heute:** Stand 26.11.2026 liest **keiner** der Abläufe unter `.github/workflows/` das Secret `UPDATER_ED25519_PRIVATE_KEY`, und es gibt keine Umgebung `release` in den Abläufen. Lege den Schlüssel deshalb erst an, wenn der Entwickler den Update-Ablauf liefert.
  - **Wo er dann hinkommt:** als Secret in eine geschützte Umgebung `release` (GitHub > Settings > Environments > `release` > Environment secrets, mit "Required reviewers"). Die Umgebung legt der Repo-Eigentümer an.
  - **Wer was macht:** Die Schlüsselerzeugung ist ein Entwicklerschritt (Befehl, Sicherung, Einbau des öffentlichen Schlüssels in die App). Du bewahrst nur die Sicherung auf. LineFM Studios ist Eigentümer und verwahrt den privaten Schlüssel (Passwortmanager plus Offline-Kopie).
  - **Wo er gilt:** Der Updater ist nach Entscheidung des Inhabers nur in den direkten Downloads aktiv und in allen Store-Builds per Build-Schalter entfernt, eine automatische Prüfung erzwingt das.
  - **Wechsel:** Nur bei Verdacht auf Missbrauch. Dann erzeugt der Entwickler einen neuen Schlüssel, liefert eine App-Version aus, die übergangsweise beide öffentlichen Schlüssel annimmt, und löscht danach den alten. Ohne Verdacht ist kein regelmäßiger Wechsel vorgesehen.
- **Woher:** Die jeweiligen Schritte (6.3, 7.3, 7.4, 8.2, 12.2, 15.3, 15.4, 5.2).
- Store-Regeln: [D-01](STORE-RICHTLINIEN.md#d-01), [A-04](STORE-RICHTLINIEN.md#a-04), [M-02](STORE-RICHTLINIEN.md#m-02), [S-05](STORE-RICHTLINIEN.md#s-05), [F-11](STORE-RICHTLINIEN.md#f-11)
- **Prüfschritt:** Einmal im Jahr spielst du mit dem Entwickler eine Sicherung testweise zurück. Er vergleicht den Fingerabdruck des Schlüssels (eine Prüfsumme, per `keytool -list -v` bzw. `openssl pkcs12 -info`) mit dem Original.
- **Wenn es nicht klappt:** Die Sicherung lässt sich nicht zurückspielen: Sofort eine neue anlegen und prüfen. Ein Schlüssel ist verloren: Schritt 6.3 (Upload-Schlüssel zurücksetzen) bzw. [betrieb/INCIDENT.md](betrieb/INCIDENT.md).
- [ ] eingerichtet
- [ ] regelmäßig erledigt (einmal im Jahr, Liste in Schritt 20.7)

### 19.4 Secrets-Abgleich

- **Wer:** Betreiber, Entwickler gleicht ab.
- **Was:** Alle Secrets und Variablen aus Anhang A eintragen, soweit du den jeweiligen Kanal nutzt. Anhang A ist vollständig: Jeder Name, den ein Workflow unter `.github/workflows/` liest, steht dort, das prüft der Test aus Schritt 16.2. Details je Wert: [secrets.md](secrets.md).
- **Wozu:** Fehlende Werte lassen Schritte still ausfallen.
- **Wo eintragen:** Schritt 1.3. Die Werte für `deploy-web.yml` sind normale Repo-Secrets (Schritt 1.3, 5.2). Die Umgebung `production` dient nur der Freigabe vor dem Ausrollen.
- **Woher:** Anhang A, Spalte "Bezugsquelle".
- **Prüfschritt:** Ein Release-Lauf (Actions > "Release") nennt in seiner Zusammenfassung keinen fehlenden Namen.
- **Wenn es nicht klappt:** Ein Release-Lauf nennt einen fehlenden Namen: In Anhang A den Namen suchen, Bezugsquelle nachlesen, Secret in Schritt 1.3 anlegen. Der Test aus Schritt 16.2 meldet einen unbekannten Namen: Das ist ein Fehler im Repo, den Entwickler fragen.
- [ ] erledigt

### 19.5 Release-Ablauf

- **Wer:** Entwickler startet und prüft, Betreiber gibt in den Konsolen frei.
- **Was:** Ein Release (eine fertige Version der App) entsteht automatisch bei jeder Änderung auf `main` (Ablauf "Release", Versionsnummer wie in der Einleitung beschrieben).
  - `release.yml` baut alle Plattformen, signiert (Sigstore, Attestierung, optional GPG) und hängt die Dateien an das GitHub-Release.
  - Ab Version 1.0.0 laden `store-google.yml` (Spur "internal"), `store-microsoft.yml` (Entwurf), `store-snap.yml` (Kanal "edge") und `store-apple.yml` (wenn `APPLE_PUBLISHING_ENABLED` gesetzt ist) die App in die Stores hoch.
  - `deploy-web.yml` rollt das Web nach deiner Freigabe aus.
  - Flathub bekommt ein Update per Änderungsvorschlag, den `flathub-prep.yml` vorbereitet.
- **Wozu:** Die automatischen Abläufe laden nur hoch. **Die Veröffentlichung in den Stores gibst du selbst frei**: Play Console (Test and release > Production > neue Version aus der Spur "internal" hochstufen, gestaffelter Rollout), Partner Center (die Einreichung im Entwurf prüfen und abschicken), Snap (Kanal "edge" auf "candidate" und "stable" hochstufen, im Snap-Dashboard oder per `snapcraft release`, über den Entwickler), App Store Connect (zur Prüfung einreichen). Die genauen Schaltflächen je Store haben wir nicht live geprüft (nicht geprüft, Anmeldung nötig). Gehe in jeder Console den Weg an einem Testlauf einmal durch, bevor es ernst wird.
- **Wo eintragen:** nichts. Ablauf: [stores-pipelines.md](stores-pipelines.md), Prüfung: [RELEASE-VERIFIZIEREN.md](RELEASE-VERIFIZIEREN.md).
- **Woher:** entfällt.
- **Prüfschritt:** Vor jeder Freigabe die Freigabe-Checkliste, Abschnitt E, durchgehen. Gestaffelten Rollout bei Google mit 10 bis 20 Prozent beginnen und die Absturzrate beobachten.
- Store-Regeln zu Updates: [D-01](STORE-RICHTLINIEN.md#d-01), [G-23](STORE-RICHTLINIEN.md#g-23), [G-34](STORE-RICHTLINIEN.md#g-34), [A-32](STORE-RICHTLINIEN.md#a-32)
- **Wenn es nicht klappt:** Ein Lauf bricht ab: In Actions den roten Schritt öffnen und an den Entwickler schicken. Nach dem Release fehlt eine Plattform: Prüfen, ob das zugehörige Secret gesetzt ist (Anhang C). Die Veröffentlichung hängt nur an dir: Ohne deine Freigabe geht nichts live.
- [ ] erledigt

### 19.6 Überwachung

- **Wer:** Betreiber (Alarm-Postfach, Benachrichtigungen), Entwickler liefert Hinweise.
- **Was:** Der Ablauf `uptime.yml` (ein Uptime-Monitor: er prüft regelmäßig, ob die Seiten erreichbar sind) testet alle 30 Minuten Web-App und laut.fm-Schnittstelle und öffnet bei Ausfall ein Ticket mit dem Label `uptime`. Schalte die Benachrichtigung ein: im Repository oben "Watch" > "Custom" > den Haken für Tickets setzen (die Oberfläche beschriftet ihn englisch). Danach unter <https://github.com/settings/notifications> bei "Watching" sowohl "Email" als auch "On GitHub" einschalten, sonst siehst du nichts im Posteingang bzw. bekommst keine Mail (<https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/setting-up-notifications/configuring-notifications>, abgerufen 26.11.2026).
- **Wozu:** Ohne Benachrichtigung merkt niemand das Ticket. GitHub startet geplante Läufe nicht minutengenau, das ist ein Hinweis, keine Garantie.
- **Wo eintragen:** Die Variable `WEB_BASE_URL` (Schritt 5.2) aktiviert den Monitor. Zusätzlich brauchst du einen externen Monitor, weil `uptime.yml` mit GitHub zusammen ausfallen kann.
  - **Empfehlung: UptimeRobot Free.** 50 Monitore, Prüfung alle 5 Minuten, laut Anbieter auch für kommerzielle Projekte (<https://uptimerobot.com/pricing/>, abgerufen 26.11.2026). Das Konto legt LineFM Studios an, mit dem gemeinsamen Alarm-Postfach. Better Stack Free (10 Monitore, E-Mail-Alarm) passt nicht, weil es laut Preisseite nur für private Projekte gilt (<https://betterstack.com/pricing>, abgerufen 26.11.2026).
  - **Wichtig:** Im Gratis-Tarif gibt es laut UptimeRobot-Hilfe nur **einen** E-Mail-Kanal pro Konto (<https://help.uptimerobot.com/en/articles/11360953-personal-notification-channels>, abgerufen 26.11.2026). Nimm als Konto-Adresse deshalb ein gemeinsam gelesenes Postfach oder einen Verteiler (eine Adresse, die an mehrere Personen weiterleitet), den du bei deinem Mail-Anbieter anlegst, zum Beispiel `betrieb@linefm.de`. Mindestens zwei Personen sollten ihn empfangen. Eine zweite Einzeladresse bräuchte einen kostenpflichtigen "Notify-only"-Platz.
  - **Monitore:** `https://app.linefm.de/`, `https://app.linefm.de/datenschutz/`, `https://cdn.linefm.de/images/icons/main.png`, `https://api.laut.fm/`. Alarm per E-Mail an den gemeinsamen Verteiler (der Kanal geht laut Hilfeartikel an die Registrierungsadresse). SMS oder Anruf kosten Guthaben. Ob und welche der fünf Integrationen (zum Beispiel Slack) im Gratis-Tarif frei sind, zeigt die Seite nicht (nicht geprüft).
  - Nach dem Anlegen mit einem Testalarm prüfen.
- **Woher:** entfällt.
- **Prüfschritt:** Unter Actions läuft der Ablauf "Uptime" grün. Im externen Monitor einen Monitor kurz pausieren bzw. auf eine falsche URL stellen: die Alarm-Mail kommt an. Absturzberichte in Sentry, Firebase Crashlytics und Play Console (Android Vitals) einmal pro Woche ansehen.
- **Wenn es nicht klappt:** Der Testalarm kommt nicht an: Spam-Ordner prüfen und prüfen, ob der Monitor dem Alarmkontakt zugewiesen ist. Die Klickpfade im UptimeRobot-Dashboard haben wir nicht geprüft (Anmeldung nötig), sie stehen im Hilfebereich <https://help.uptimerobot.com/en/>. Keine Mail von GitHub bei einem Uptime-Ticket: "Email" und "On GitHub" unter Notifications einschalten und den Watch-Haken für Tickets prüfen.
- [ ] eingerichtet
- [ ] regelmäßig erledigt (wöchentlich, Liste in Schritt 20.7)

### 19.7 Notfallplan

- **Wer:** Betreiber liefert die Meldewege, Entwickler trägt sie in die Datei ein.
- **Was:** [betrieb/INCIDENT.md](betrieb/INCIDENT.md) lesen und die Meldewege eintragen: wer wird bei Ausfall benachrichtigt, wer entscheidet über Rollback, wer spricht mit Stores und Nutzern. Fälle, die vorbereitet sein müssen: Web-App nicht erreichbar, Stream bei laut.fm ausgefallen, Schlüssel in falsche Hände geraten (sofort widerrufen, Secret tauschen, neues Release), Store sperrt die App (Begründung lesen, Einspruch über die Console), Konto-Zugang verloren.
- **Wozu:** Im Ernstfall fehlt sonst die Zeit zum Nachdenken.
- **Wo eintragen:** `docs/betrieb/INCIDENT.md`, Abschnitt "Meldewege" (der Entwickler trägt Namen ein, wenn du sie lieferst).
- **Woher:** Deine Organisation.
- **Prüfschritt:** Einmal im Jahr eine Übung nach dem Abschnitt "Übungen".
- **Wenn es nicht klappt:** Im Ernstfall fehlt ein Name: Sieh zuerst die Reihenfolge im Abschnitt "Meldewege" an und ruf dann die erste erreichbare Person an. Trage den Namen danach nach.
- [ ] erledigt

### 19.8 Abhängigkeiten aktuell halten

- **Wer:** Entwickler, Betreiber bekommt die Zusammenfassung.
- **Was:** Dependabot (ein GitHub-Werkzeug, das veraltete Bausteine meldet) öffnet jeden Montag Änderungsvorschläge für die GitHub-Abläufe und die Dart-Pakete der App (`.github/dependabot.yml`, 7 Tage Wartezeit nach Erscheinen). Sicherheitsmeldungen erscheinen im Reiter "Security".
- **Wozu:** Veraltete Pakete heißen Sicherheitslücken und irgendwann Ablehnung in den Stores (Ziel-API, Xcode-Version, Seitengröße 16 KB bei Android).
- **Wo eintragen:** nichts. Wer die Vorschläge prüft und zusammenführt, regelt der Wartungsvertrag (Schritt 2.5, dort als Teil der Vereinbarung mit dem Entwickler).
- **Woher:** entfällt.
- **Prüfschritt:** Monatlich: keine offenen Dependabot-Vorschläge älter als 30 Tage, keine offene kritische Sicherheitsmeldung.
- **Wenn es nicht klappt:** Ein Dependabot-Vorschlag bricht die Prüfung: Den Entwickler fragen, nicht selbst zusammenführen (mergen). Eine kritische Sicherheitsmeldung ist offen: Den Entwickler am selben Tag informieren.
- [ ] eingerichtet
- [ ] regelmäßig erledigt (monatlich, Liste in Schritt 20.7)

### 19.9 Aufgaben am Tag des Live-Gangs

- **Wer:** Entwickler und Betreiber gemeinsam.
- **Was:**
  1. **Flathub-Domainbestätigung:** Die Datei `https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` mit dem Inhalt, den Flathub nach der Aufnahme im Entwicklerportal anzeigt, auf der Hauptdomain ablegen (Schritt 8.1). Weiterleitungen folgt Flathub, HTTPS ist Pflicht. Typ `text/plain`.
  2. **Brotli auf dem Server:** Für nginx das Modul `ngx_brotli` aktivieren bzw. bei Plesk und Traefik die Kompression laut [hosting-uebersicht.md](hosting-uebersicht.md) einschalten. Cloudflare macht es selbst.
  3. **Telemetrie-Adressen in der Sicherheitsrichtlinie:** Nach dem Setzen von `UMAMI_URL`, `SENTRY_DSN` oder Firebase die Web-App neu bauen und die Server-Header neu ausrollen, sonst blockiert die CSP die Anfragen (Schritt 9.2). Läuft Umami oder GlitchTip auf eigenem Server, dort die Server-Logs auf die in der Datenschutzerklärung genannte Dauer begrenzen und IP-Adressen kürzen bzw. nicht speichern.
  4. Search Console und Sitemap (Schritt 10.1) und Vertrauens-Badges (Abschnitt 11) sind schon in Phase 9 erledigt. Hier nur nachsehen, ob die Sitemap weiter gelesen wird.
- **Wozu:** Diese Punkte gehen erst, wenn die Domain live ist.
- **Wo eintragen:** siehe je Punkt.
- **Woher:** Flathub-Portal, Hoster.
- **Prüfschritt:** Der Entwickler führt die Befehle aus. `curl -sI https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` zeigt 200 (Datei gefunden). `curl -sI -H "Accept-Encoding: br" https://app.linefm.de/main.dart.js | grep -i content-encoding` zeigt `br`. Nach Einwilligung erscheint ein Ereignis in Umami.
- Store-Regeln: [F-04](STORE-RICHTLINIEN.md#f-04), [W-01](STORE-RICHTLINIEN.md#w-01), [W-03](STORE-RICHTLINIEN.md#w-03)
- **Wenn es nicht klappt:** Eine der drei Prüfungen schlägt fehl: Hoster fragen (Brotli), Flathub-Datei prüfen (Schritt 8.1), Einwilligung testen (Schritt 10.2). Erst melden, wenn die Domain wirklich live ist.
- [ ] erledigt

---

## 20. Support und Pflege

### 20.1 Support-Kontakt und Support-URL

- **Wer:** Betreiber legt das Postfach an, Entwickler stellt die Support-Seite bereit.
- **Was:** Die Adresse `support@linefm.de` anlegen (macht LineFM Studios) und die Seite `/support/` der Web-App (de: `https://app.linefm.de/support/`, en: `https://app.linefm.de/en/support/`) als Support-URL nutzen. Beides in jedes Support-Feld jedes Stores eintragen.
- **Wozu:** Google verlangt eine Kontakt-E-Mail, Apple eine Support-URL, Microsoft Support-Kontaktdaten. Fehlende oder tote Kontakte sind ein häufiger Ablehnungsgrund.
- **Wo eintragen:** Play Console > Store-Präsenz > Kontaktdaten. App Store Connect > App-Informationen > Support-URL. Partner Center > Store-Eintrag. Flathub-Metainfo (`<url type="contact">` und `<url type="support">`, der Entwickler trägt sie ein). Snap: Dashboard und Snap-Metadaten (Kontakt, Website).
- **Woher:** Entscheidung des Inhabers. Antwortzeit festlegen (Empfehlung: zwei Werktage). Apple-Felder trägst du erst in der späteren Apple-Runde ein.
- **Prüfschritt:** Zuerst (Phase 3): Testmail an die Adresse kommt an. Danach, sobald die Web-App steht (Phase 4): die URL öffnet im Browser die Support-Seite (der Entwickler prüft Status 200).
- Store-Regeln: [G-29](STORE-RICHTLINIEN.md#g-29), [A-28](STORE-RICHTLINIEN.md#a-28), [M-22](STORE-RICHTLINIEN.md#m-22), [S-08](STORE-RICHTLINIEN.md#s-08), [F-13](STORE-RICHTLINIEN.md#f-13), [W-05](STORE-RICHTLINIEN.md#w-05)
- **Wenn es nicht klappt:** Die Testmail kommt nicht an: Postfach und Spam prüfen, beim Anbieter die Weiterleitung kontrollieren. Die URL `/support/` antwortet nicht mit 200: Web-Version nicht neu gebaut. Ein Store lehnt die Support-Adresse ab: Sie muss erreichbar sein und auf eine echte Person oder ein Team zeigen.
- [ ] erledigt

### 20.2 Bewertungen beantworten

- **Wer:** Betreiber.
- **Was:** Bewertungen in Google Play, App Store und Microsoft Store wöchentlich lesen und sachlich beantworten. Fehlerberichte daraus als Ticket im Repo anlegen.
- **Wozu:** Antworten verbessern die Bewertung und zeigen den Stores, dass die App gepflegt ist.
- **Wo eintragen:** Play Console > Bewertungen, App Store Connect > Bewertungen, Partner Center > Rezensionen.
- **Woher:** entfällt. Keine Bewertungen kaufen oder gegen Vorteile tauschen, das verbieten alle Stores.
- **Prüfschritt:** Keine Bewertung mit Fehlerbeschreibung bleibt länger als eine Woche unbeantwortet.
- **Wenn es nicht klappt:** Du weißt nicht, wie du auf eine harte Bewertung antworten sollst: Sachlich bleiben, Lösung anbieten, keine Vorwürfe. Eine Bewertung verstößt gegen die Regeln des Stores: Dort melden, nicht selbst löschen lassen wollen.
- [ ] eingerichtet
- [ ] regelmäßig erledigt (wöchentlich, Liste in Schritt 20.7)

### 20.3 Meldung von Sicherheitslücken

- **Wer:** Betreiber schaltet die Benachrichtigungen in seinem GitHub-Konto ein (Klickweg unten), Entwickler erneuert `security.txt` rechtzeitig vor dem Ablaufdatum und prüft es.
- **Was:** Meldungen kommen über das GitHub-Formular aus `SECURITY.md` und `web/.well-known/security.txt` (Schritt 3.3). Benachrichtigung für "Security alerts" einschalten.
- **Wozu:** Wer eine Lücke findet, braucht einen vertraulichen Weg. Die Datei `security.txt` sagt Sicherheitsforschern, wie sie dich erreichen. Sie hat ein Ablaufdatum (`Expires: 2027-05-19`) und muss vorher erneuert werden.
- **Wo eintragen:** Am Repository oben "Watch" > "Custom" > "Security alerts" anhaken. Dann in den Benachrichtigungs-Einstellungen (Posteingang-Symbol > "Manage notifications" > "Notification settings") bei Dependabot-Alerts mindestens "Email" oder "On GitHub" wählen (<https://docs.github.com/en/code-security/dependabot/dependabot-alerts/configuring-notifications-for-dependabot-alerts>, abgerufen 26.11.2026). Die Erneuerung von `security.txt` macht der Entwickler, du bekommst Bescheid, wenn sie erfolgt ist.
- **Woher:** entfällt.
- **Prüfschritt:** `https://app.linefm.de/.well-known/security.txt` zeigt ein `Expires` in der Zukunft (im Browser öffnen, die Zeile `Expires:` lesen). Du bekommst bei einem Test-Alarm oder der nächsten Meldung eine Mail von GitHub.
- **Wenn es nicht klappt:** Du bekommst keine Meldung: Am Repository unter "Watch" > "Custom" den Punkt "Security alerts" einschalten und in den Einstellungen bei den Dependabot-Alerts "Email" oder "On GitHub" aktivieren. GitHub meldet nur für neu auftretende Schwachstellen, nicht rückwirkend. Wer Benachrichtigungen zu Secret-Scanning- und Code-Scanning-Funden bekommt, ist nicht geprüft.
- [ ] erledigt

### 20.4 Monatliche Prüfung der Store-Richtlinien

- **Wer:** Entwickler, Betreiber bei Handlungsbedarf.
- **Was:** Ein geplanter Ablauf (Workflow) prüft monatlich alle in [STORE-RICHTLINIEN.md](STORE-RICHTLINIEN.md) verlinkten Richtlinienseiten auf Erreichbarkeit und Änderungen und öffnet bei Änderung ein Ticket. Das Ticket trägt das Label `store-policy`. **Zuständig:** Der Entwickler liest es binnen fünf Werktagen, fasst die Änderung zusammen und weist es dir zu, wenn du in einer Console handeln musst. Nennt der Store eine kürzere Frist, gilt sie.
- **Wozu:** Stores ändern ihre Regeln ohne Vorwarnung, oft mit kurzen Fristen.
- **Wo eintragen:** Benachrichtigung für Tickets (Schritt 19.6) reicht.
- **Woher:** entfällt.
- **Prüfschritt:** Jeden Monat ein grüner Lauf oder ein bearbeitetes Ticket.
- **Wenn es nicht klappt:** Das Ticket nennt eine Frist, die bald abläuft: Den Entwickler am selben Tag informieren und die Frist in den Fristenkalender (Schritt 20.5) eintragen. Der Lauf ist rot, weil eine Seite nicht erreichbar ist: Das ist meist ein Umzug der Seite, der Entwickler pflegt die Adresse.
- [ ] eingerichtet
- [ ] regelmäßig erledigt (monatlich, Liste in Schritt 20.7)

### 20.5 Fristenkalender

- **Wer:** Betreiber führt den Kalender, Entwickler liefert die technischen Termine.

Trag diese Termine mit Erinnerung vier Wochen vorher in einen gemeinsamen Kalender ein. Zeilen mit "Entwickler" erledigt der Entwickler, du behältst nur den Termin im Blick.

| Wann | Was | Wer | Quelle |
|---|---|---|---|
| 01.02.2027 | Google Play: Händlerstatus (DSA) und 16-KB-Seiten müssen erfüllt sein, sonst keine Updates | LineFM Studios und Entwickler | Schritte 17.5, 6.11 |
| jährlich, Stichtag bisher 31. August | Google Play: neue Apps und Updates müssen die aktuelle Ziel-API haben. Seit 31.08.2026 Android 16 (API 36), eine Verlängerung auf Antrag war bis 01.11.2026 möglich | Entwickler | <https://developer.android.com/google/play/requirements/target-sdk>, abgerufen 26.11.2026; [G-11](STORE-RICHTLINIEN.md#g-11), [G-34](STORE-RICHTLINIEN.md#g-34) |
| jährlich, meist Frühjahr (ab der Apple-Runde) | Apple: Uploads nur mit aktuellem Xcode. Seit 28.04.2026 Xcode 26 mit iOS-26-SDK | Entwickler | <https://developer.apple.com/news/upcoming-requirements/>, abgerufen 26.11.2026; [A-18](STORE-RICHTLINIEN.md#a-18), [A-32](STORE-RICHTLINIEN.md#a-32) |
| jährlich zum Beitrittsdatum (ab der Apple-Runde) | Apple-Mitgliedschaft verlängern (99 US-Dollar), sonst verschwinden die Apps aus dem Store | LineFM Studios | <https://developer.apple.com/programs/enroll/>; [A-26](STORE-RICHTLINIEN.md#a-26) |
| jährlich (ab der Apple-Runde) | Apple-Distribution-Zertifikat und Profile erneuern | Entwickler | Entwicklerportal |
| laut Datum | Developer-ID-Zertifikat, Windows-Zertifikat, Azure-Client-Secret, Snap-Anmeldedaten erneuern | LineFM Studios und Entwickler | Schritt 19.3 |
| jährlich laut Registrar | Domain `linefm.de` verlängern | LineFM Studios | Registrar |
| jährlich und bei Aufforderung | Play-Erklärungen erneut bestätigen: Datensicherheit, Vordergrunddienst, Vollbild-Intent, Zielgruppe | LineFM Studios | [G-34](STORE-RICHTLINIEN.md#g-34) |
| bei Aufforderung (ab der Apple-Runde) | neue Apple-Vereinbarungen annehmen, sonst stoppen die Uploads | LineFM Studios | [A-27](STORE-RICHTLINIEN.md#a-27) |
| spätestens 19.05.2027, dann halbjährlich | `security.txt` erneuern | Entwickler | Schritt 20.3 |
| monatlich | Store-Richtlinien-Prüfung, Dependabot, Sicherheitsmeldungen | Entwickler | Schritte 19.8, 20.4 |
| quartalsweise | TLS-Ablauf, laut.fm-Schnittstelle, Wiederherstellungsübung | Entwickler (du bekommst die Rückmeldung) | [betrieb/RUNBOOK.md](betrieb/RUNBOOK.md) |
| jährlich | DPF-Status der US-Anbieter, AVV noch gültig, Datenschutzerklärung und Store-Formulare abgleichen, Altersfragebögen (Apple fragt bei neuen Systemen nach) | LineFM Studios | Schritte 17.2, 17.3 |
| jährlich | Wiederherstellung einer Schlüsselsicherung testen, Notfallübung | beide | Schritte 19.3, 19.7 |

- **Wenn es nicht klappt:** Eine Frist ist schon abgelaufen: Sofort die zuständige Console öffnen, Folgen laut Store prüfen und den Entwickler informieren.
- [ ] Kalender angelegt

### 20.6 Ablehnungen und Sperren

- **Wer:** Betreiber, Entwickler hilft.
- **Was:** Lehnt ein Store ab oder sperrt die App: Begründung lesen, Ursache beheben, neu einreichen. Hältst du die Ablehnung für falsch, Einspruch einlegen: Play Console über "Richtlinienstatus", Apple über das App Review Board, die Einspruchsstelle von Apple (spätere Apple-Runde), Microsoft über den Einspruchsweg der Zertifizierung, Snap und Flathub im jeweiligen Forum bzw. in der Einreichung.
- **Wozu:** Wiederholte Verstöße können bei Google zur Kontosperre führen. Schnelle, sachliche Antworten verkürzen die Prüfung.
- **Wo eintragen:** in der jeweiligen Console. Ticket im Repo mit Meldung und Screenshot, ohne Passwörter.
- **Woher:** Der Entwickler hilft bei der Ursache.
- **Prüfschritt:** Jede Ablehnung hat ein Ticket mit Ergebnis.
- Store-Regeln: [G-33](STORE-RICHTLINIEN.md#g-33), [A-30](STORE-RICHTLINIEN.md#a-30), [M-23](STORE-RICHTLINIEN.md#m-23)
- **Wenn es nicht klappt:** Du verstehst die Begründung nicht: Wortlaut an den Entwickler schicken. Der Store ändert seine Meinung auch nach einem Einspruch nicht: Ursache beheben und neu einreichen, bevor weitere Verstöße zählen. Bei Sperre des Kontos sofort den Anwalt und den Entwickler einbinden.
- [ ] verstanden

### 20.7 Regelmäßige Aufgaben im Überblick

- **Wer:** Betreiber.
- **Was:** Diese Aufgaben wiederholen sich. Das einmalige Einrichten steht in den Schritten oben ("eingerichtet"), das regelmäßige Erledigen trägst du hier ein.
- **Wozu:** Ein einziger Haken würde sonst nach dem ersten Mal "fertig" melden.
- **Wo eintragen:** Fristenkalender (Schritt 20.5).

  | Aufgabe | Rhythmus | Schritt | Wer |
  |---|---|---|---|
  | Zertifikat und Domain-Ablauf prüfen | quartalsweise | 19.2, 19.1 | Entwickler prüft, du bekommst die Rückmeldung |
  | Sicherungen der Signierschlüssel testweise zurückspielen | einmal im Jahr | 19.3 | du mit Entwickler |
  | Uptime-Alarme und Absturzberichte ansehen | wöchentlich | 19.6 | du |
  | Offene Abhängigkeits-Vorschläge und Sicherheitsmeldungen ansehen | monatlich | 19.8 | Entwickler, du bekommst die Zusammenfassung |
  | Bewertungen in den Stores beantworten | wöchentlich | 20.2 | du |
  | Store-Richtlinien-Ticket lesen | monatlich | 20.4 | Entwickler, bei Handlungsbedarf du |
  | Fristen und Ablaufdaten (Apple-Mitgliedschaft, Domain, Zertifikate, Händlerstatus) | laufend | 20.5 | du |
  | Notfallübung | einmal im Jahr | 19.7 | du mit Entwickler |

- **Woher:** entfällt.
- **Prüfschritt:** Jede Zeile hat einen Termin im Kalender.
- **Wenn es nicht klappt:** Ein Termin wurde verpasst: Sofort nachholen, Datum notieren und den Rhythmus im Kalender anpassen.
- [ ] eingerichtet


---

## Anhang A: Alle Secrets und Variablen

Das ist eine Nachschlageliste. Du füllst sie nicht auf einmal aus, die Schritte oben sagen dir, wann du welchen Wert brauchst. Eingetragen wird in GitHub (Schritt 1.3). Art: S = Secret (geheimer Wert), V = Variable (nicht geheimer Wert). Ohne den Wert fehlt die Funktion, die in der Spalte "Ziel" steht. Trag nur die Werte ein, die zu den Kanälen gehören, die du nutzt. Ausführliche Herkunft: [secrets.md](secrets.md).

| Name | Art | Ziel | Bezugsquelle | Schritt |
|---|---|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | S | Google Play | vom Entwickler erzeugte `upload-keystore.jks` als Base64 | 6.3 |
| `ANDROID_KEYSTORE_PASSWORD` | S | Google Play | beim Erzeugen vergeben | 6.3 |
| `ANDROID_KEY_ALIAS` | S | Google Play | beim Erzeugen vergeben | 6.3 |
| `ANDROID_KEY_PASSWORD` | S | Google Play | beim Erzeugen vergeben | 6.3 |
| `PLAY_SERVICE_ACCOUNT_JSON` | S | Google Play | Google Cloud Console, Dienstkonto | 6.4 |
| `BUILD_NUMBER_OFFSET` | V | Google Play | Zahl, nur bei Bedarf, Standard 100 | 6.4 |
| `ANDROID_CERT_SHA256` | V | App-Links Android | Play Console "Protected with Play" > "Manage Play app signing", plus Upload-Schlüssel | 6.9 |
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
| `SONAR_TOKEN` | S | SonarCloud (Repo-Eigentümer, Ablauf `sonar.yml`) | SonarCloud-Konto | 12.6 |
| `SNYK_TOKEN` | S | Snyk (Repo-Eigentümer, Ablauf `snyk.yml`) | Snyk-Konto | 12.6 |
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
| `SENTRY_DSN` | V | Telemetrie | Sentry (oder GlitchTip), Projekt | 9.2 |
| `SENTRY_ENVIRONMENT` | V | Telemetrie | zum Beispiel `production` | 9.2 |
| `FIREBASE_CONFIG_JSON` | S | Telemetrie (optional) | Firebase, Web-App-Konfiguration | 9.2 |
| `GSC_VERIFICATION` | V | Search Console | Search Console, "HTML-Tag" | 10.1 |
| `GTM_ID` | V | GTM (Web) | tagmanager.google.com, Container | 10.2 |
| `PAGESPEED_API_KEY` | S | Qualitätsprüfung der Web-Seite (pages.yml), optional. Ohne den Schlüssel läuft Lighthouse auf dem Runner. | console.cloud.google.com, API key restricted to PageSpeed Insights API | 12.4 |
| `FEATURES_JSON` | V | Funktionsschalter (`showListenerCount`), Standard alles aus, siehe [Konfiguration](KONFIGURATION.md) | z. B. `{"showListenerCount": true}` | 9.4 |
| `GA4_MEASUREMENT_ID` | V | GA4 (Web) | analytics.google.com, Datenstreams | 10.2 |
| `TRUST_GRIDINSOFT_URL` | V | Vertrauens-Badge | Profil bei Gridinsoft | 11.1 |
| `TRUST_TRUSTPILOT_URL` | V | Vertrauens-Badge | Profil bei Trustpilot | 11.2 |
| `GPG_PRIVATE_KEY` | S | Signierte Releases (optional) | `gpg --armor --export-secret-keys <ID>` | 12.2 |
| `NVD_API_KEY` | S | OWASP dependency-check im Workflow `dast.yml` (optional, ohne Schlüssel wird der Job übersprungen) | kostenloser Schlüssel von nvd.nist.gov/developers/request-an-api-key | 12.5 |
| `UPDATER_ED25519_PRIVATE_KEY` (noch nicht anlegen, Schritt 19.3) | S (Umgebung `release`) | Updater der direkten Downloads (Windows-Setup, macOS-DMG), nie in Store-Builds | selbst erzeugter Ed25519-Schlüssel, Befehl liefert der Entwickler | 19.3 |
| `GPG_PASSPHRASE` | S | Signierte Releases (optional) | beim Erzeugen vergeben | 12.2 |
| `SCORECARD_TOKEN` | S | OpenSSF Scorecard (optional) | GitHub, Fine-grained token | 12.3 |
| `CODE_SCANNING_ENABLED` | V | CodeQL (optional) | `true` | 12.3 |

## Anhang B: Alle Platzhalter

Ein Platzhalter ist eine Stelle in den Rechtstexten, die durch deinen Wert ersetzt wird. Du lieferst die Werte, der Entwickler schreibt sie in `legal_values.json` bzw. die Variable `LEGAL_VALUES_JSON` (Schritt 3.1), sofern in der Spalte "Ort im Repo" nichts anderes steht. "Pflicht" laut `assets/legal/placeholders.json`. Nicht zutreffende Angaben als `"Nicht zutreffend."` eintragen.

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
| `{{CDN_ANBIETER}}` | ja | Datenschutz | CDN-Anbieter von `cdn.linefm.de` |
| `{{LOG_AUFBEWAHRUNG}}` | ja | Datenschutz | Speicherdauer der Server-Protokolle, zum Beispiel 7 Tage |
| `{{TELEMETRIE_AUFBEWAHRUNG}}` | nur mit Telemetrie | Datenschutz | Speicherdauer der Statistik- und Fehlerdaten |
| `{{UMAMI_BETREIBER}}` | nur mit Umami | Datenschutz | Server-Anbieter der Umami-Instanz |
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

## Anhang C: Welcher Ablauf liest was

Zum Nachschlagen. So prüfst du einen Eintrag: Ablauf unter <https://github.com/VectoDE/linefm-radio-app/actions> öffnen (Schritt 1.5). Läuft er grün und nennt die Zusammenfassung den Namen nicht als fehlend, ist der Wert angekommen.

| Ablauf (Name unter Actions) | Startet | Liest |
|---|---|---|
| Release | bei jeder Änderung auf `main` | Android-, Windows- und Apple-Signierschlüssel, `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE` |
| Build | als Teil von "Release" | `LEGAL_VALUES_JSON`, `FEATURES_JSON`, `WEB_BASE_URL`, Telemetrie-, Google- und Badge-Variablen, `ANDROID_CERT_SHA256`, `BUILD_NUMBER_OFFSET`, Signierschlüssel |
| Pages | bei Änderungen an der App auf `main` | `LEGAL_VALUES_JSON`, `FEATURES_JSON`, `GTM_ID`, `GA4_MEASUREMENT_ID`, `GSC_VERIFICATION`, `UMAMI_URL`, `UMAMI_WEBSITE_ID`, `TRUST_GRIDINSOFT_URL`, `TRUST_TRUSTPILOT_URL`, `PAGESPEED_API_KEY` |
| Store Google Play | ab 1.0.0 automatisch, sonst "Run workflow" | `PLAY_SERVICE_ACCOUNT_JSON` |
| Store Microsoft | ab 1.0.0 automatisch, sonst "Run workflow" | `MS_STORE_TENANT_ID`, `MS_STORE_SELLER_ID`, `MS_STORE_CLIENT_ID`, `MS_STORE_CLIENT_SECRET`, `MS_STORE_PRODUCT_ID`, `MS_STORE_IDENTITY_NAME`, `MS_STORE_PUBLISHER`, `MS_STORE_PUBLISHER_DISPLAY_NAME` |
| Store Snap | ab 1.0.0 automatisch, sonst "Run workflow" | `SNAPCRAFT_STORE_CREDENTIALS` |
| Store Apple | ab 1.0.0 und nur mit `APPLE_PUBLISHING_ENABLED` = `true` | alle `APPLE_*`- und `APP_STORE_CONNECT_*`-Secrets |
| Deploy Web | ab 1.0.0 automatisch, sonst "Run workflow" | `WEB_DEPLOY_TARGETS`, Cloudflare-, `DEPLOY_*`- und `PLESK_*`-Werte |
| DAST | wöchentlich, sonst "Run workflow" | `NVD_API_KEY` |
| OpenSSF Scorecard | wöchentlich und bei Änderungen auf `main` | `SCORECARD_TOKEN` |
| CodeQL | bei Änderungen | `CODE_SCANNING_ENABLED` |
| Uptime | regelmäßig | `WEB_BASE_URL` |

## Anhang D: Was nur du entscheiden oder liefern kannst

Die folgenden Punkte warten ausschließlich auf dich (LineFM Studios). Sie stehen in den Schritten oben, hier nur gesammelt. Jeder Punkt hat hier einen eigenen Haken. Sind alle gesetzt, ist alles bis zur Veröffentlichung geklärt.

| Haken | Punkt | Schritt |
|---|---|---|
| [ ] | Pflichtangaben für Impressum und Datenschutz liefern (14 Pflichtwerte) | 3.1 |
| [ ] | Verantwortliche Person nach Medienstaatsvertrag benennen, anwaltlich prüfen | 3.1, Anhang B |
| [ ] | Auftragsverarbeitungsvertrag mit dem Telemetrie-Betreiber unterschreiben | 2.4, 17.3 |
| [ ] | Nutzungsrechtevertrag zum Code | 2.5 |
| [ ] | Ein Anwaltstermin für alle offenen Rechtsfragen: Freigabe des Quellcodes (1.4), Verträge (2), Rundfunkrecht und verantwortliche Person (3.1, 3.4), Barrierefreiheitserklärung (3.2), Einwilligung, Cast und Speicherhinweis (3.4, 13.1), Speicherung der gewählten App-Sprache ohne Einwilligung, Google-Cast-Skript im Web erst nach Einwilligung, Google als Empfänger bei Firebase, GA4 (10.2), Lizenz der Windows-Abspielbibliothek (7.6) | siehe Klammern |
| [ ] | Lizenz der vorgebauten Windows-Abspielbibliothek klären, vor dem Microsoft Store | 7.6 |
| [ ] | GA4-Auftragsverarbeitung annehmen | 10.2 |
| [ ] | DNS für `app.linefm.de` | 4.1 |
| [ ] | CORS für `cdn.linefm.de` | 4.4 |
| [ ] | Play-Erklärungen zu Vordergrunddienst und Vollbild | 6.6 |
| [ ] | HSTS-Preload, nur wenn alle Subdomains HTTPS haben | 4.3 |
| [ ] | Search Console | 10.1 |
| [ ] | Vorschaubild für soziale Netzwerke freigeben | 14.3 |
| [ ] | Gridinsoft: nur prüfen, Badge nur falls angeboten. Trustpilot: kostenloses Konto, nur Gratis-Widget | 11.1, 11.2 |
| [ ] | Gerätetests auf echten Geräten | 16.6 |
| [ ] | Konten anlegen: Google Play (6.1), Microsoft (7.1), Snap und Flathub (8) | 6.1, 7.1, 8.1, 8.2, 18.2 |
| [ ] | D-U-N-S-Nummer beantragen (dauert bis zu 30 Tage) | 18.1 |
| [ ] | Hosting-Weg wählen: Cloudflare Pages, eigener Server oder Plesk | 5.1 |
| [ ] | Entscheiden, ob Statistik und Absturzberichte genutzt werden, und welcher Anbieter | 9.1 |
| [ ] | Postfächer anlegen (`support@linefm.de`, Funktionsadresse für Konten, gemeinsames Postfach für Uptime-Alarme) | 18.2, 19.6, 20.1 |
| [ ] | Store-Erklärungen abgeben (Altersfreigabe, Datensicherheit, Zielgruppe, Händlerstatus) | 6.5, 13, 17.5 |
| [ ] | Zweite Person mit Admin-Recht je Konto benennen | 18.2 |
| [ ] | Fristen für Händlerstatus bei Google (1. Februar 2027) und 16-KB-Seiten (1. Februar 2027) | 17.5, 6.11 |

### Nur der Eigentümer des Repositories (Tim Hauke)

Diese Punkte kann ein Collaborator nicht erledigen, weil GitHub sie dem Eigentümer eines persönlichen Repositories vorbehält:

| Haken | Punkt | Schritt |
|---|---|---|
| [ ] | Umgebung `production` mit Genehmigern anlegen ("Prevent self-review" aus), Umgebungs-Secrets setzen | 1.3, 5.2 |
| [ ] | Project-Felder (Priorität, Schweregrad, Größe, Iteration, Ziel-Release), Status "In Review" und "Blocked", Ansichten | im Repository, nicht Teil dieser Anleitung |
| [ ] | Discussions-Kategorien anlegen | im Repository, nicht Teil dieser Anleitung |

### Bewusst entschieden

- **Sprachwahl in der App:** Die Sprache wird in den Einstellungen gewählt und gespeichert (Prüfung in Schritt 16.5). Die Klärung, ob das ohne Einwilligung zulässig ist, steht beim Anwaltstermin (siehe Tabelle oben).
- **SonarCloud und Snyk sind wieder dabei** (Entscheidung vom 27.11.2026, ersetzt die vom 21.11.2026): kostenlose Tarife, Konten legt der Repo-Eigentümer an, siehe Schritt 12.6.
- **Test der Vorabversion:** Schritt 16.4 beschreibt, wie du eine automatisch erzeugte Vorabversion auf Echtheit und Vollständigkeit prüfst.
- **OpenSSF-Best-Practices-Badge:** strukturell nicht erreichbar (proprietäre Lizenz), siehe Schritt 12.6.

## Anhang E: Stand der Quellenprüfung (27.11.2026)

Das ist Hintergrund für den Entwickler und für Nachfragen, du musst hier nichts tun. Hier steht, welche offenen Punkte gegen die offizielle Dokumentation geprüft wurden. Alles, was nicht in der Tabelle steht, trägt im jeweiligen Schritt seinen eigenen Vermerk ("abgerufen" oder "nicht geprüft").

| Punkt | Quelle | Ergebnis |
|---|---|---|
| Best-Practices-Badge verlangt freie Lizenz | <https://www.bestpractices.dev/en/criteria/0> | bestätigt (Kriterium `floss_license`, MUST) |
| Flathub: Binärdateien und Weitergabe | <https://docs.flathub.org/docs/for-app-authors/requirements> | bestätigt, siehe Schritt 8.1; offen bleibt der Sonderfall eigene Binärdatei |
| Cloudflare Pages: Token-Berechtigung, Account-ID | <https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/> | Berechtigung bestätigt, Fundort der Account-ID weicht ab (Schritt 5.2) |
| Snap: Hochstufen zwischen Kanälen | <https://snapcraft.io/docs/channels> (leitet auf eine Anmeldeseite um) | nicht prüfbar, bleibt offen (Schritt 8.2) |
| Play Console, Partner Center, Apple | Menüs nur mit Konto sichtbar | nicht geprüft, die Hinweise "Menüname vor Ort prüfen" bleiben stehen |
| Plesk | keine offizielle Quelle gelesen | nicht geprüft |
| Search-Console-TXT-Format | <https://support.google.com/webmasters/answer/9008080> | bestätigt: `google-site-verification=<Zeichenfolge>` (Schritt 10.1) |
| BFSG Kleinstunternehmen | <https://www.gesetze-im-internet.de/bfsg/__2.html> | bestätigt: § 2 Nr. 17, unter 10 Personen und Umsatz oder Bilanzsumme höchstens 2 Mio. Euro |
| SonarCloud, Snyk | Ordner `.github` des Repositories | Abläufe `sonar.yml` und `snyk.yml` angelegt, nur statisch geprüft (actionlint, zizmor), nicht gegen die Dienste gelaufen, siehe Schritt 12.6 |

---

## Anhang F: Glossar

Das Glossar steht in einer Tabelle am Anfang der Anleitung ("Die wichtigsten Begriffe"). Anhang F enthielt früher Ergänzungen, sie sind dort eingearbeitet.
