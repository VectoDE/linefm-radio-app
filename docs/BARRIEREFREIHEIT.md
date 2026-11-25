# Erklärung zur Barrierefreiheit (Entwurf)

Kurzfassung auf Deutsch und Englisch mit bekannten Lücken und Meldeweg: [ACCESSIBILITY.md](../.github/ACCESSIBILITY.md).

**Status:** Entwurf, freiwillig. Ob für LINEFM Radio eine Erklärung nach dem Barrierefreiheitsstärkungsgesetz (BFSG) Pflicht ist, ist nicht geklärt (siehe [FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md), Abschnitt A4). Dieser Text ist eine Vorprüfung und ersetzt keine Rechtsberatung. Vor der Veröffentlichung mit einem Anwalt oder der zuständigen Stelle abstimmen.

Stand der Prüfung: 19. November 2026. Geprüft wurde die Web-Version (Chromium, Wasm-Build) automatisch mit axe-core 4.14.0 (WCAG 2.0 bis 2.2, Stufen A bis AAA, und Best Practices) und von Hand mit Tastatur und Zugriffsbaum. axe lief über Sender, Player, Verlauf, Favoriten, Einstellungen, Wecker, Über, die Dialoge „Speicher löschen“ und „Uhrzeit eingeben“ und die Auswahlfenster „Sleeptimer“ und „Favoriten exportieren“ bei 390 und 1280 px, jeweils hell und dunkel, dazu über Impressum und Datenschutz auf Deutsch und Englisch: 58 Läufe, keine Verstöße. 54 Prüfungen konnte axe nicht selbst entscheiden („incomplete“): Kontrast von Text auf Bildern (Cover, Logos) und der fehlende Sprunglink in Dialogen; die Farbwerte dazu sind per Test belegt (`test/ui/theme/contrast_test.dart`). Dabei gefunden und behoben: Der Dialog „Speicher löschen“ hatte keinen zugänglichen Namen, die untere Navigationsleiste im Handy-Layout ließ sich per Screenreader nicht auslösen, die Auswahlfenster hießen nur „Dialog“, und das Ziffernblatt des Uhrzeit-Dialogs hatte unbeschriftete Regler (im Web gibt es deshalb nur die Texteingabe). Gerätetests mit TalkBack, VoiceOver und NVDA sind **noch nicht** gelaufen.

## Unser Ziel

LINEFM Radio soll sich ohne Maus, mit Screenreader, mit starker Vergrößerung und bei eingeschränktem Sehen benutzen lassen. Maßstab ist WCAG 2.2, Stufe AA, und, wo es machbar ist, AAA. Für Apps zusätzlich EN 301 549.

## Was heute funktioniert

- Alle Funktionen sind mit der Tastatur erreichbar, die Reihenfolge folgt dem Bildschirm. Im Handy-Layout: Kopfbereich, Inhalt, Hinweise, Player, Navigation unten. Im breiten Layout: Navigation links, Kopfbereich, Inhalt, Hinweise, Player rechts. Tab und Umschalt+Tab bleiben in keinem Bereich hängen; zur Ausnahme am Seitenende siehe „Bekannte Einschränkungen“.
- Die Bereiche sind als Landmarks ausgezeichnet (Hauptinhalt, Navigation, Player, Kopfbereich, Hinweise).
- Textfarben der App erreichen in der Berechnung aus den Farbwerten mindestens 4,5:1, die Hauptschrift liegt bei 15:1 bis 18:1 (hell und dunkel). Eine Ausnahme ist der Wert für ein rotes Herz-Symbol auf erhöhter Fläche im hellen Schema mit etwa 4,2:1; das ist ein Bedienelement und erfüllt 3:1, aber nicht 4,5:1 für Text.
- Heller und dunkler Modus, auch nach Systemeinstellung.
- Die Web-Version wurde bei 320, 390 und 1280 px Breite angesehen, hell und dunkel (Screenshots in der Qualitätsrunde). Eine vollständige Prüfung auf waagerechtes Scrollen bei 400 Prozent Zoom steht noch aus.
- Der Ladezustand der Startseite ist als Status für Screenreader gekennzeichnet. Namen und Rollen der Bedienelemente in der App sind im Zugriffsbaum vorhanden, wurden aber noch nicht mit einem echten Screenreader durchgehört.
- Die animierten Ladepunkte der Startseite stehen still, wenn das System "Bewegung reduzieren" meldet.
- Deutsch und Englisch, die Sprache der Seite ist ausgezeichnet.

## Bekannte Einschränkungen

Diese Punkte sind uns bekannt und noch nicht behoben.

| Bereich | Einschränkung | Was wir tun |
|---|---|---|
| Web | Die Oberfläche wird von Flutter auf eine Zeichenfläche gerendert. Die Kontrastprüfung durch Werkzeuge ist dort nur eingeschränkt möglich, wir haben die Werte deshalb aus den Farbwerten berechnet | Handprüfung mit Screenreader steht aus |
| Alle Plattformen | Nicht geprüft mit TalkBack (Android), VoiceOver (iOS, macOS) und NVDA (Windows) | Teil der Freigabe-Checkliste, Abschnitt B10 |
| Radiowecker | Nicht auf Barrierefreiheit der Systemdialoge (Alarm, Vollbild) geprüft | Gerätetest B3 |
| Web | Beim Tabben über das Seitenende hinaus landet der Fokus kurz auf unbeschrifteten Flutter-Elementen ohne Funktion, bevor er wieder oben beginnt. Wie viele es sind, hängt von Ansicht und Browser ab | Verhalten von Flutter Web, wird beobachtet |
| Livestream | Radio hat keine Untertitel. Für Titel und Sender gibt es Text, für gesprochene Inhalte keine Transkripte | Liegt beim Programm von laut.fm bzw. den Sendern |

## Feedback und Kontakt

Wenn dir eine Stelle nicht zugänglich ist, schreib uns: {{BARRIEREFREIHEIT_KONTAKT}}. Beschreibe bitte kurz, welches Gerät und welche Hilfstechnik du nutzt. Wir antworten innerhalb von {{BARRIEREFREIHEIT_ANTWORTFRIST}}.

Bei Beschwerden zuständig: {{SCHLICHTUNGS_BZW_MARKTUEBERWACHUNGSSTELLE}}. Der Text muss vor Veröffentlichung gegen die tatsächlich zuständige Stelle geprüft werden.

Die drei Platzhalter in diesem Abschnitt trägt der Betreiber ein. Solange einer offen ist, bricht der Release-Build ab (`tool/gen_legal_html.dart --strict`).

## So prüfen wir weiter

- Automatisch bei jedem Änderungsvorschlag und jedem Push auf `main`, wirksam erst nach dem Merge von `p28-integration` (dort liegt `a11y.yml`, auf `main` ist er noch nicht): der Workflow `a11y.yml` baut die Web-Version und lässt axe-core über die oben genannten Ansichten laufen (Skript `tool/a11y/run.mjs`). Er schlägt bei jedem Verstoß fehl, gleich welcher Stufe, und wenn eine Ansicht oder ein Dialog nicht erreichbar ist. Was axe nicht entscheiden kann, steht im Bericht und in der Zusammenfassung des Laufs. Der Bericht mit Commit-Kennung und Screenshots liegt als Artefakt am Lauf. Lighthouse läuft dort nicht mit. axe findet nur einen Teil der Probleme; Screenreader-Ablauf und Verständlichkeit prüft es nicht.
- Von Hand vor jedem Release: Tastaturdurchlauf, Zoom auf 200 Prozent, Screenreader-Stichprobe (siehe [FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md), B7 und B10).
- Nach jeder Änderung an Farben, Navigation oder Formularen neu messen.

Diese Erklärung wird aktualisiert, sobald sich eine Einschränkung ändert.
