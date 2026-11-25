# Wettbewerbsabgleich

Sachlicher Vergleich von LINEFM Radio mit fünf real existierenden Radio-Apps und Web-Playern. Er dient der Planung. In Store-Texten, auf der Website und in der README kommt kein Vergleich vor (Regel in [STORE-TEXTE.md](STORE-TEXTE.md)).

Abrufdatum aller Quellen: **21.11.2026**. Grundlage sind die Store-Einträge im deutschen Apple App Store, abgefragt über die offizielle iTunes Search API, und die öffentliche Seite der bisherigen Web-App. Zahlen wie Bewertungen und Versionen ändern sich täglich.

## Was geprüft wurde und was nicht

- Geprüft: die App-Store-Einträge in Deutschland (Beschreibung, Preis, Bewertung, Version) und die Seite app.linecast.de.
- **Nicht geprüft:** die Google-Play-Einträge. Die Seiten laden ihre Inhalte per Skript und waren für den Abruf nicht lesbar. Aussagen zu Android stehen hier nicht.
- **Nicht geprüft:** tatsächliches Verhalten der Apps. Wir haben keine der Apps installiert oder bedient. Die Funktionsangaben stammen aus den Beschreibungen der Anbieter und sind Eigenaussagen.
- Die Auswertung der Antworten der Schnittstelle lief über ein Hilfsmittel, das Texte zusammenfasst. Zahlen und Namen sind übernommen, bei einer Entscheidung auf Grundlage dieser Tabelle bitte am Original gegenlesen (Links in der Quellenliste).

## Vergleich

Angaben zu den Mitbewerbern stehen so in deren Store-Beschreibung. "nicht genannt" heißt: Die Beschreibung erwähnt es nicht. Es heißt nicht, dass die App es nicht kann.

| | LINEFM Radio (Stand Code) | radio.de | TuneIn Radio | laut.fm (App der LAUT AG) | Simple Radio | app.linecast.de (bisherige Web-App) |
|---|---|---|---|---|---|---|
| Anbieter | LineFM Studios (Betreiber), Entwicklung VectoDE | radio.de GmbH | TuneIn | LAUT AG | Streema, Inc. | RadioGruppe Deutschland, "Made by Tim Hauke" |
| Umfang | 6 Sender (4 LINEFM, 2 Partner) | über 60.000 Sender, über 2,2 Mio. Podcasts | über 100.000 Sender aus 197 Ländern, Sport, Nachrichten, Podcasts | über 10.000 Sender, Millionen Songs, eigene Sendungen gestalten und live moderieren | rund 90.000 Sender | Sender der RadioGruppe |
| Preis | kostenlos, ohne Werbung, ohne Konto (Ziel laut Store-Text) | kostenlos, Prime (einmalig 39,99 EUR) gegen Video- und Banner-Werbung | kostenlos, optionales Premium-Abo | kostenlos | kostenlos mit In-App-Käufen, laut Beschreibung ohne Werbung | kostenlos, Werbung nicht belegt |
| Sleeptimer | ja (15/30/45/60 Min.) | genannt | nicht genannt | genannt | nicht genannt | ja (15/30/45/60 Min.) |
| Wecker | ja (Android, Desktop). Auf iOS nur als Hinweis (Entscheidung 36) | nicht genannt | nicht genannt | nicht genannt | nicht genannt | nicht belegt |
| Favoriten | ja (Songs und Sender, Export und Import) | nicht genannt | nicht genannt | genannt | genannt | ja (Songs und Sender) |
| Verlauf | ja (zuletzt gespielte Titel) | nicht genannt | nicht genannt | nicht genannt | nicht genannt | ja |
| Auto | Android Auto (CarPlay in Arbeit, Apple noch nicht veröffentlicht) | CarPlay genannt | nicht genannt | CarPlay genannt | nicht genannt | nein (Web) |
| Streaming zu Geräten | Chromecast (Android), AirPlay im Code (auf iOS ungetestet) | AirPlay und Chromecast genannt | nicht genannt | nicht genannt | nicht genannt | nein |
| Uhr | nicht vorhanden | nicht genannt | nicht genannt | nicht genannt | Apple Watch genannt | nein |
| Weitere Merkmale | Homescreen-Widget (Android), Tray und Mini-Fenster (Desktop), Deutsch und Englisch | Offline-Downloads für Podcasts | Live-Sport | Ortssuche, Moderation vom Handy | schlichte Oberfläche | Lauftext, Lautstärke merken |
| Plattformen | Android, Web, Windows, Linux, macOS, iOS (Veröffentlichung Android, Web, Desktop zuerst) | iOS (Android nicht geprüft) | iOS (Android nicht geprüft) | iOS (Android nicht geprüft) | iOS (Android nicht geprüft) | Web |
| Bewertung im deutschen App Store | noch nicht veröffentlicht | 4,6 bei 373.635 Bewertungen | 4,67 bei 100.985 Bewertungen | 4,19 bei 37 Bewertungen | 4,62 bei 15.926 Bewertungen | nicht anwendbar |
| Letzte Version im App Store | | 5.11.19 vom 17.11.2026 | 42.9.0 vom 16.11.2026 | 2.0.7 vom 13.11.2025 | 12.2.1 vom 30.10.2026 | |

Die Spalte LINEFM Radio nennt den Code-Stand, nicht den Stand eines Stores. Die App ist in keinem Store veröffentlicht.

## Einordnung

- Die großen Anbieter (radio.de, TuneIn, Simple Radio) verkaufen Menge: Zehntausende Sender, Podcasts, Sport. LINEFM Radio konkurriert nicht um Menge, sondern bietet die LINEFM-Sender mit Funktionen zum Hören im Alltag (Sleeptimer, Wecker, Favoriten, Verlauf).
- Die laut.fm-App der LAUT AG hat im deutschen App Store nur 37 Bewertungen. Sie ist auf alle laut.fm-Sender und eigene Sendungen ausgelegt, nicht auf LINEFM. Wer gezielt LINEFM sucht, findet dort keinen eigenen Auftritt. Das ist eine Beobachtung, keine Marktanalyse.
- Die bisherige Web-App deckt Sender, Verlauf, Favoriten und Sleeptimer ab. LINEFM Radio ergänzt Hintergrundwiedergabe mit Sperrbildschirm-Steuerung, Wecker, Cast, Android Auto, Desktop-Funktionen und Deutsch und Englisch.

## Lücken und Chancen (Vorschlagsliste)

Das sind Vorschläge für Planung und Entscheidung durch LineFM Studios. Es wurden keine Tickets dafür angelegt.

| Nr. | Vorschlag | Beleg | Aufwand | Hinweis |
|---|---|---|---|---|
| 1 | **Auto und Heim auf Apple-Geräten schließen:** CarPlay und AirPlay veröffentlichen, sobald das Apple-Konto steht. | radio.de und laut.fm nennen CarPlay, radio.de nennt AirPlay. Der Code ist vorhanden, die Veröffentlichung ist zurückgestellt (Entscheidung 21). | M, wartet auf Konto und CarPlay-Entitlement | Erst nach Test auf echten Geräten werben ([FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md)). |
| 2 | **Auffindbarkeit über "LINEFM" in den Stores:** Name, Untertitel und Schlüsselwörter (siehe [STORE-TEXTE.md](STORE-TEXTE.md)) auf die Suchbegriffe der Hörer ausrichten, Screenshots mit den vier Sendern. | Die laut.fm-App hat im deutschen App Store 37 Bewertungen und führt LINEFM nicht im Namen. | S | Keine Markenrechte Dritter in Schlüsselwörtern verwenden. |
| 3 | **Uhr-Unterstützung prüfen (Apple Watch, Wear OS):** Sender starten und stoppen, Titel anzeigen. | Simple Radio nennt Apple Watch. | L | Nutzen vor dem Aufwand klären, etwa über Rückmeldungen aus dem geschlossenen Test. |
| 4 | **Sendeplan oder Moderationsinfo anzeigen,** wenn die laut.fm-Schnittstelle die Daten liefert (Endpunkt `/schedule` laut früherer Recherche, im Code nicht genutzt). | laut.fm bietet Live-Moderation als Kernfunktion. Hörer sehen heute nur den laufenden Titel. | M | Zuerst prüfen, ob die Schnittstelle zuverlässig Daten für die LINEFM-Sender liefert. |
| 5 | **Werbefrei und ohne Konto als belegte Aussage nutzen:** radio.de verkauft Werbefreiheit als Prime für 39,99 EUR. LINEFM Radio hat keine Werbung und kein Konto. | Beschreibungen von radio.de und TuneIn (Premium-Abo). | S | Nur die eigene Eigenschaft nennen, ohne Vergleich (Regel der Store-Texte). Rechtlich vor Verwendung prüfen (UWG). |

## Quellen (abgerufen am 21.11.2026)

- radio.de: <https://apps.apple.com/de/app/radio-de-radio-und-podcast/id311762416>, Prime: <https://apps.apple.com/de/app/radio-de-prime/id526364858>
- TuneIn: <https://apps.apple.com/de/app/tunein-radio-fm-musik-sport/id418987775>
- laut.fm: <https://apps.apple.com/de/app/laut-fm/id1595567340>
- Simple Radio: <https://apps.apple.com/de/app/simple-radio-fm-am-radiosender/id891132290>
- Abfrage der Daten: iTunes Search API, `https://itunes.apple.com/search?term=<Name>&entity=software&country=de` (offizielle Schnittstelle von Apple)
- Bisherige Web-App: <https://app.linecast.de/>
