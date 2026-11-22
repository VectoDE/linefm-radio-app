# Barrierefreiheit / Accessibility

Deutsch zuerst, English below ([jump to English](#english)).

---

## Deutsch

### Ziel

LINEFM Radio soll sich mit Tastatur, Screenreader, starker Vergrößerung und bei eingeschränktem Sehen benutzen lassen. Maßstab ist WCAG 2.2 Stufe AA, wo machbar AAA. Für die App kommt EN 301 549 dazu. Das BFSG nennen wir als Maßstab. Ob es für dieses Angebot gilt und eine Erklärung Pflicht ist, wird geprüft; eine Anwaltsprüfung steht aus.

Das ist ein Ziel. Wir behaupten nicht, dass die App WCAG AA erfüllt. Was belegt ist und was fehlt, steht unten.

### Stand

Belegt (Stand 22. November 2026):

- axe-core 4.x prüft die Web-Version über Sender, Player, Verlauf, Favoriten, Einstellungen, Wecker, Über, zwei Dialoge, zwei Auswahlfenster sowie Impressum und Datenschutz, bei 390 und 1280 px, hell und dunkel. Letzter dokumentierter Lauf (19. November): 58 Läufe, keine Verstöße. Aktuelle Läufe sieht man am Badge in der README.
- Die Farbwerte der App sind per Test belegt (`test/ui/theme/contrast_test.dart`): Text erreicht auf den Grundflächen mindestens 4,5:1.
- Namen und Rollen von Schaltflächen, Dialogen und Navigation sind in Widget-Tests geprüft (zum Beispiel `test/features/icon_action_semantics_test.dart`, `test/ui/widgets/named_dialog_test.dart`).
- Kernkomponenten haben Golden-Tests in Hell und Dunkel.
- Die animierten Ladepunkte stehen still, wenn das System „Bewegung reduzieren“ meldet.

### Bekannte Lücken

Diese Punkte sind offen. Nichts davon ist behoben.

| Bereich | Lücke | Verweis |
|---|---|---|
| Alle Plattformen | Nicht mit echten Screenreadern geprüft (TalkBack, VoiceOver, NVDA). Der Zugriffsbaum ist per Test belegt, das Vorlesen nicht. | [Freigabe-Checkliste](../docs/FREIGABE-CHECKLISTE.md), B10 |
| Desktop | Die Schaltflächen der eigenen Titelleiste (Minimieren, Maximieren, Schließen) sind per Tab nicht erreichbar. Das ist so gebaut und per Test festgehalten. Ob Fenster-Aktionen per Tastatur über das Systemmenü zuverlässig gehen, ist nicht geprüft. | Issue #87 |
| Windows-Installer | Die Oberfläche hat Screenreader-Beschriftungen im Code. Mit der UI-Automation-Schnittstelle von Windows oder mit NVDA wurde sie nicht geprüft. | Pull Request #110, Issue #88 |
| Desktop, Einstellungen | Bei Fensterbreite 880 bricht die Beschriftung „Systemsprache“ mitten im Wort um. | Issue #118 |
| Web | Zoom auf 400 Prozent ohne waagerechtes Scrollen ist nicht vollständig geprüft. | [Erklärung](../docs/BARRIEREFREIHEIT.md) |
| Web | Beim Tabben über das Seitenende hinaus landet der Fokus kurz auf unbeschrifteten Flutter-Elementen. | [Erklärung](../docs/BARRIEREFREIHEIT.md) |
| App | Ein rotes Herz-Symbol im hellen Schema hat etwa 4,2:1. Das genügt für Bedienelemente (3:1), nicht für Text. | [Erklärung](../docs/BARRIEREFREIHEIT.md) |
| Radiowecker | Die Systemdialoge des Weckers sind nicht auf Barrierefreiheit geprüft. | Gerätetest B3 |
| Livestream | Es gibt keine Untertitel und keine Transkripte für gesprochene Inhalte. Das Programm kommt von laut.fm bzw. den Sendern. | keiner |

### Wie wir prüfen

- Bei jedem Pull Request, bei jedem Push auf `main` und wöchentlich: der Workflow `a11y.yml` baut die Web-Version und lässt axe-core mit den Tags WCAG 2.0 bis 2.2 (A, AA, AAA) und Best Practices laufen. Bei jedem Verstoß, gleich welcher Stufe, und bei jeder nicht erreichbaren Ansicht schlägt der Lauf fehl. Von axe nicht entscheidbare Prüfungen stehen im Bericht und müssen von Hand beurteilt werden.
- In der normalen Testsuite: Kontrast-, Semantik- und Golden-Tests.
- Ein Windows-Integrationstest in der CI (Pull Request #114) ist offen und noch nicht auf `main`. Er prüft nach dem Merge die Titelleiste im echten Fenster, aber nicht die Barrierefreiheit insgesamt.
- Von Hand vor jedem Release: Tastaturdurchlauf, Zoom, Screenreader-Stichprobe ([Freigabe-Checkliste](../docs/FREIGABE-CHECKLISTE.md), B7 und B10). Diese Handprüfung ist noch nicht gelaufen.

Automatische Werkzeuge finden nur einen Teil der Probleme. Ein grüner axe-Lauf sagt nichts über den Screenreader-Ablauf oder die Verständlichkeit.

### Eine Barriere melden

- Öffne ein Issue mit der Vorlage [„Barriere melden“](https://github.com/VectoDE/linefm-radio-app/issues/new?template=accessibility.yml).
- Oder schreib an die Kontaktadresse des Betreibers. Die Adresse steht im Impressum, in der App und auf der Web-Seite unter `/impressum/`, und kommt aus der Betreiber-Konfiguration. Hier tragen wir sie nicht fest ein.

Nenn bitte Gerät, Betriebssystem, App-Version und Hilfstechnik (zum Beispiel NVDA mit Firefox) und was du tun wolltest.

Das Projekt betreut eine einzelne Person. Antworten kommen meist innerhalb einer Woche, ohne feste Zusage (siehe [SUPPORT.md](../SUPPORT.md)). Falls das BFSG gilt, ist die Marktüberwachungsstelle der Länder für die Barrierefreiheit von Produkten und Dienstleistungen (MLBF) in Magdeburg zuständig ([mlbf-barrierefrei.de](https://www.mlbf-barrierefrei.de)). Ob das BFSG für diese kostenlose Radio-App überhaupt gilt (Umfang der Dienstleistung, Ausnahme für Kleinstunternehmen), wird geprüft. Das ist keine Rechtsberatung.

### Mehr

- [Erklärung zur Barrierefreiheit (Entwurf)](../docs/BARRIEREFREIHEIT.md) mit dem vollständigen Stand
- [Freigabe-Checkliste](../docs/FREIGABE-CHECKLISTE.md)
- [Mitarbeiten](../CONTRIBUTING.md)

---

## English

### Goal

LINEFM Radio should work with a keyboard, a screen reader, strong magnification and low vision. The yardstick is WCAG 2.2 level AA, and AAA where feasible. For the app, EN 301 549 applies as well. We name the German BFSG as a yardstick. Whether it applies to this offer and a statement is required is being reviewed; a lawyer's review is pending.

This is a goal. We do not state that the app meets WCAG AA. What is proven and what is missing is listed below.

### Current state

Proven (as of 22 November 2026):

- axe-core 4.x checks the web version across Stations, Player, History, Favorites, Settings, Alarm, About, two dialogs, two sheets, plus the legal notice and privacy policy, at 390 and 1280 px, light and dark. Last documented run (19 November): 58 runs, no violations. The badge in the README shows current runs.
- The app's color values are covered by a test (`test/ui/theme/contrast_test.dart`): text reaches at least 4.5:1 on the base surfaces.
- Names and roles of buttons, dialogs and navigation are checked in widget tests (for example `test/features/icon_action_semantics_test.dart`, `test/ui/widgets/named_dialog_test.dart`).
- Core components have golden tests in light and dark.
- The animated loading dots stop when the system asks to reduce motion.

### Known gaps

These items are open. None of them is fixed.

| Area | Gap | Reference |
|---|---|---|
| All platforms | Not tested with real screen readers (TalkBack, VoiceOver, NVDA). The accessibility tree is covered by tests; spoken output is not. | [Release checklist](../docs/FREIGABE-CHECKLISTE.md), B10 (German) |
| Desktop | The buttons of the custom title bar (minimize, maximize, close) cannot be reached with Tab. This is by design and pinned by a test. Whether window actions work reliably from the keyboard through the system menu has not been checked. | Issue #87 |
| Windows installer | The UI has screen reader labels in code. It has not been checked with Windows UI Automation or NVDA. | Pull request #110, issue #88 |
| Desktop, Settings | At a window width of 880, the label "Systemsprache" breaks in the middle of the word. | Issue #118 |
| Web | Zoom to 400 percent without horizontal scrolling is not fully checked. | [Statement](../docs/BARRIEREFREIHEIT.md) (German) |
| Web | Tabbing past the end of the page briefly lands focus on unlabeled Flutter elements. | [Statement](../docs/BARRIEREFREIHEIT.md) (German) |
| App | A red heart icon in the light theme has about 4.2:1. That is enough for controls (3:1), not for text. | [Statement](../docs/BARRIEREFREIHEIT.md) (German) |
| Radio alarm | The system dialogs of the alarm have not been checked for accessibility. | Device test B3 |
| Live stream | There are no captions and no transcripts for spoken content. The programme comes from laut.fm and the stations. | none |

### How we test

- On every pull request, every push to `main` and weekly: the `a11y.yml` workflow builds the web version and runs axe-core with the WCAG 2.0 to 2.2 tags (A, AA, AAA) and best practices. The run fails on any violation of any level and on any view it cannot reach. Checks axe cannot decide appear in the report and need a manual verdict.
- In the regular test suite: contrast, semantics and golden tests.
- A Windows integration test in CI (pull request #114) is open and not on `main` yet. After the merge it checks the title bar in a real window, not accessibility as a whole.
- By hand before each release: keyboard walkthrough, zoom, screen reader spot check ([release checklist](../docs/FREIGABE-CHECKLISTE.md), B7 and B10, German). This manual check has not been run yet.

Automatic tools find only part of the problems. A green axe run says nothing about screen reader use or readability.

### Report a barrier

- Open an issue with the ["Accessibility barrier"](https://github.com/VectoDE/linefm-radio-app/issues/new?template=accessibility.yml) template.
- Or write to the operator's contact address. The address is in the legal notice, in the app and on the website at `/impressum/`, and comes from the operator configuration. We do not hard-code it here.

Please include your device, operating system, app version and assistive technology (for example NVDA with Firefox), and what you were trying to do.

One person maintains this project. Replies usually come within a week, with no fixed commitment (see [SUPPORT.md](../SUPPORT.md)). If the BFSG applies, the competent body is the market surveillance authority of the German states for the accessibility of products and services (Marktüberwachungsstelle der Länder für die Barrierefreiheit von Produkten und Dienstleistungen, MLBF) in Magdeburg ([mlbf-barrierefrei.de](https://www.mlbf-barrierefrei.de)). Whether the BFSG applies to this free radio app at all (scope of the service, micro-enterprise exemption) is being reviewed. This is not legal advice.

### More

- [Accessibility statement (draft, German)](../docs/BARRIEREFREIHEIT.md) with the full state
- [Release checklist (German)](../docs/FREIGABE-CHECKLISTE.md)
- [Contributing](../CONTRIBUTING.md)
