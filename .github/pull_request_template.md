## Worum geht es?

<!-- Ein, zwei Sätze: Was ändert sich und warum? -->

Refs #

## Vorher / Nachher

<!-- Was war vorher, was ist jetzt? Bei sichtbaren Änderungen Screenshots
     (hell und dunkel, schmal und breit), bei Messwerten Zahlen vorher/nachher. -->

| Vorher | Nachher |
|---|---|
|  |  |

## Breaking Change?

- [ ] Nein
- [ ] Ja: <!-- Was bricht, wer muss was tun (Konfiguration, Secrets, gespeicherte Daten, Hosting)? -->

## Was wurde geprüft?

- [ ] `dart format --set-exit-if-changed .`
- [ ] `flutter analyze --fatal-infos`
- [ ] `flutter test`
- [ ] Bei sichtbaren Änderungen: Screenshots hell und dunkel, schmal und breit
- [ ] Bei Web-Änderungen: Build mit `--wasm --no-web-resources-cdn` und Postbuild, im Browser geöffnet
- [ ] Neue Texte in Deutsch und Englisch
- [ ] Keine Zugangsdaten, Schlüssel oder personenbezogenen Daten im Diff

## Qualitäts-Checkliste (qs)

Nur ankreuzen, was dieser PR betrifft und was geprüft ist.

- [ ] Sicherheit: Workflows, Abhängigkeiten, Eingaben, Rechte geprüft (actionlint, zizmor, gitleaks)
- [ ] Barrierefreiheit: Tastatur, Screenreader-Label, Kontrast; a11y-Workflow ohne serious/critical
- [ ] Datenschutz und Recht: neue Datenflüsse in der Datenschutzerklärung, Platzhalter-Regeln
- [ ] Performance: Bundle-Größe, Caching-Header, keine neuen Fremd-Requests
- [ ] SEO/GEO: Title, Description, strukturierte Daten, Sitemap
- [ ] Design und UX: Abstände, Typografie, Zustände (leer, Laden, Fehler) passen zum Rest der App; hell und dunkel, schmal und breit angesehen
- [ ] Usability: Ablauf ohne Erklärung verständlich, Fehlermeldungen sagen, was zu tun ist
- [ ] i18n: Deutsch und Englisch vollständig, Platzhalter und Plural stimmen, lange Texte brechen das Layout nicht
- [ ] Medien (Bilder, Icons, Audio): Alt-Text bzw. Semantik-Label, Lizenz geklärt und vermerkt, Dateigröße angemessen
- [ ] Tests: neue oder angepasste Tests für die Änderung, `flutter test` grün
- [ ] Texte: klingt nach Mensch, keine Floskeln
- [ ] Doku und README aktualisiert
- [ ] Release: CHANGELOG-Eintrag, Version in pubspec.yaml

## Offen oder bewusst nicht gemacht

<!-- Was fehlt noch, was wurde absichtlich weggelassen? Sonst "nichts". -->
