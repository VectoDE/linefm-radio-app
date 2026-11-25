# Mitarbeiten

LINEFM Radio ist ein Projekt von Tim Hauke (VectoDE) für jaybelife. Das Repository ist öffentlich einsehbar, der Quellcode steht aber unter "Alle Rechte vorbehalten" (siehe [LICENSE](LICENSE)): Lesen ja, Nutzungsrechte nein. Kopieren, Ändern oder Weitergeben braucht die schriftliche Erlaubnis des Rechteinhabers. Beiträge von außen sind nur nach Absprache möglich. Schreib vorher ein Issue, bevor du Zeit in einen Pull Request steckst.

## Vor dem ersten Beitrag

- Lies [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md): Aufbau, Bauen, Tests.
- Mit einem Beitrag stimmst du zu, dass der Rechteinhaber ihn im Projekt nutzen darf. Eine schriftliche Absprache dazu kommt vor dem ersten Merge.
- Sicherheitslücken nicht als Issue melden, sondern nach [SECURITY.md](SECURITY.md).

## Arbeitsweise

1. Für jede Änderung gibt es ein Issue mit einer Aufgabenliste (Checkboxen). Aufgaben werden erst abgehakt, wenn sie erledigt und geprüft sind.
2. Branch pro Änderung, kurzer Name, zum Beispiel `fix-wecker-zeitzone`.
3. Kleine, prüfbare Commits im Stil von Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).
4. Pull Request gegen `main`, mit `Refs #<Issue>` im Text. Issues werden nicht automatisch geschlossen.

## Vor jedem Pull Request

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

Alle drei müssen grün sein. Bei Web-Änderungen zusätzlich `flutter build web --release --wasm --no-web-resources-cdn` und `dart run tool/web_postbuild.dart build/web`, danach die Seite im Browser öffnen.

## Regeln für den Code

- Bestehende Konventionen übernehmen. Import immer `package:material_ui/material_ui.dart`.
- Keine neuen Abhängigkeiten ohne Begründung im Pull Request.
- Keine Zugangsdaten, Schlüssel oder personenbezogenen Daten in Code, Commits oder Issues. Konfiguration liegt in `config/app.json` (nicht im Repo).
- Texte für Menschen (App, Doku, Stores) gehen durch eine Sprachprüfung: klingen wie von einem Menschen geschrieben, echte Umlaute, Fachwörter erklärt.
- Neue sichtbare Texte kommen in beide Sprachen (Deutsch und Englisch).
- Barrierefreiheit: Neue Bedienelemente brauchen einen Namen für Screenreader und müssen per Tastatur bedienbar sein. Stand und bekannte Lücken: [.github/ACCESSIBILITY.md](.github/ACCESSIBILITY.md).

## Fragen

Im Bereich Discussions dieses Repositories.
