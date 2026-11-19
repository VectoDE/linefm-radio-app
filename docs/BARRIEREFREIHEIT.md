# Erklärung zur Barrierefreiheit (Entwurf)

**Status:** Entwurf, freiwillig. Ob für LINEFM Radio eine Erklärung nach dem Barrierefreiheitsstärkungsgesetz (BFSG) Pflicht ist, ist nicht geklärt (siehe [FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md), Abschnitt A4). Dieser Text ist eine Vorprüfung und ersetzt keine Rechtsberatung. Vor der Veröffentlichung mit einem Anwalt oder der zuständigen Stelle abstimmen.

Stand der Prüfung: 19. November 2026. Geprüft wurde die Web-Version (Chromium, Wasm-Build) automatisch mit axe-core 4.10 und von Hand mit Tastatur und Zugriffsbaum. Gerätetests mit TalkBack, VoiceOver und NVDA sind **noch nicht** gelaufen.

## Unser Ziel

LINEFM Radio soll sich ohne Maus, mit Screenreader, mit starker Vergrößerung und bei eingeschränktem Sehen benutzen lassen. Maßstab ist WCAG 2.2, Stufe AA, und, wo es machbar ist, AAA. Für Apps zusätzlich EN 301 549.

## Was heute funktioniert

- Alle Funktionen sind mit der Tastatur erreichbar, die Reihenfolge folgt dem Bildschirm.
- Textfarben der App erreichen in der Berechnung aus den Farbwerten mindestens 4,5:1, die Hauptschrift liegt bei 15:1 bis 18:1 (hell und dunkel). Eine Ausnahme ist der Wert für ein rotes Herz-Symbol auf erhöhter Fläche im hellen Schema mit etwa 4,2:1; das ist ein Bedienelement und erfüllt 3:1, aber nicht 4,5:1 für Text.
- Heller und dunkler Modus, auch nach Systemeinstellung.
- Die Web-Version wurde bei 320, 390 und 1100 px Breite angesehen (Screenshots in der Qualitätsrunde). Eine vollständige Prüfung auf waagerechtes Scrollen bei 400 Prozent Zoom steht noch aus.
- Der Ladezustand der Startseite ist als Status für Screenreader gekennzeichnet. Namen und Rollen der Bedienelemente in der App sind im Zugriffsbaum vorhanden, wurden aber noch nicht mit einem echten Screenreader durchgehört.
- Die animierten Ladepunkte der Startseite stehen still, wenn das System "Bewegung reduzieren" meldet.
- Deutsch und Englisch, die Sprache der Seite ist ausgezeichnet.

## Bekannte Einschränkungen

Diese Punkte sind uns bekannt und noch nicht behoben.

| Bereich | Einschränkung | Was wir tun |
|---|---|---|
| Web, breite Ansicht | Verschachtelte Bedienelemente in der Senderliste (axe: `nested-interactive`), Screenreader können dadurch doppelt vorlesen | Behebung in der App geplant |
| Web, breite Ansicht | Zielgröße einzelner Schaltflächen unter 24 x 24 px (axe: `target-size`, WCAG 2.5.8) | Behebung in der App geplant |
| Web | Scrollbereiche in Liste und Verlauf sind nicht per Tastatur fokussierbar (axe: `scrollable-region-focusable`) | Behebung in der App geplant |
| Web | Die Oberfläche wird von Flutter auf eine Zeichenfläche gerendert. Die Kontrastprüfung durch Werkzeuge ist dort nur eingeschränkt möglich, wir haben die Werte deshalb aus den Farbwerten berechnet | Handprüfung mit Screenreader steht aus |
| Rechtsseiten | Platzhalter-Text in einem Grauton mit 6,5:1 erfüllt AA, aber nicht AAA | Beim Ausfüllen der Betreiberdaten prüfen |
| Alle Plattformen | Nicht geprüft mit TalkBack (Android), VoiceOver (iOS, macOS) und NVDA (Windows) | Teil der Freigabe-Checkliste, Abschnitt B10 |
| Radiowecker | Nicht auf Barrierefreiheit der Systemdialoge (Alarm, Vollbild) geprüft | Gerätetest B3 |
| Livestream | Radio hat keine Untertitel. Für Titel und Sender gibt es Text, für gesprochene Inhalte keine Transkripte | Liegt beim Programm von laut.fm bzw. den Sendern |

## Feedback und Kontakt

Wenn dir eine Stelle nicht zugänglich ist, schreib uns: {{BARRIEREFREIHEIT_KONTAKT}}. Beschreibe bitte kurz, welches Gerät und welche Hilfstechnik du nutzt. Wir antworten innerhalb von {{BARRIEREFREIHEIT_ANTWORTFRIST}}.

Bei Beschwerden zuständig: {{SCHLICHTUNGS_BZW_MARKTUEBERWACHUNGSSTELLE}}. Der Text muss vor Veröffentlichung gegen die tatsächlich zuständige Stelle geprüft werden.

Die drei Platzhalter in diesem Abschnitt trägt der Betreiber ein. Solange einer offen ist, bricht der Release-Build ab (`tool/gen_legal_html.dart --strict`).

## So prüfen wir weiter

- Automatisch bei jedem Web-Build: axe-core, Lighthouse.
- Von Hand vor jedem Release: Tastaturdurchlauf, Zoom auf 200 Prozent, Screenreader-Stichprobe (siehe [FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md), B7 und B10).
- Nach jeder Änderung an Farben, Navigation oder Formularen neu messen.

Diese Erklärung wird aktualisiert, sobald sich eine Einschränkung ändert.
