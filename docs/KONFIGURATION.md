# Konfiguration

Alle Einstellungen, die beim Bauen der App festgelegt werden, liegen im Ordner [`config/`](../config/). Jedes Thema hat eine eigene Datei.

## Grundregel

- Im Repository liegt jede Datei nur als vollständiges Beispiel: `<thema>.example.json`. Alle Schlüssel sind da, die Werte sind leer bzw. aus.
- Wer etwas nutzen will, kopiert die Beispieldatei, entfernt `.example` aus dem Namen und füllt die Werte aus. Beispiel: `features.example.json` kopieren, als `features.json` speichern.
- Echte Dateien (ohne `example`) kommen nie ins Repository, `.gitignore` schließt sie aus.
- Fehlt eine echte Datei, gilt der sichere Standard: Die Funktion ist aus.
- Einzige Ausnahme ist die Senderliste `stations.json`. Sie liegt gefüllt im Repository, damit die App ohne weitere Dateien funktioniert. Anleitung: [Sender verwalten](SENDER-VERWALTEN.md).

## Die Dateien

| Datei | Wofür | Liest die App? |
|---|---|---|
| `stations.json` | Senderliste | ja |
| `app.example.json` → `app.json` | Umgebung, Version, Web-Adresse, Telemetrie, Firebase, Google Tag, Vertrauenssiegel, `STATIONS_URL` (feste Adresse zum Nachladen der Senderliste, nur https) | ja |
| `features.example.json` → `features.json` | Schalter. `showListenerCount`: Hörerzahl im Player zeigen (`true`/`false`, Standard `false`) | ja |
| `operator.example.json` → `operator.json` | Betreiberangaben fürs Impressum (Issue #98) | noch nicht, nur Schema |
| `telemetry.example.json` → `telemetry.json` | Telemetrie getrennt von `app.json` | noch nicht, nur Schema; heute stehen die Werte in `app.json` |
| `updater.example.json` → `updater.json` | Update-Hinweis: `enabled` (`true`/`false`), `channel` (`stable` oder `beta`) | noch nicht, nur Schema |

Ein Feld `hinweis` darf in jeder Datei stehen und wird ignoriert.

Alle Werte landen in der fertigen App und sind dort lesbar. Trage also nur öffentliche Kennungen ein, keine Passwörter oder geheimen Schlüssel.

## Lokal bauen

1. Beispieldatei kopieren und umbenennen, z. B. `config/features.example.json` → `config/features.json`.
2. Werte eintragen, z. B. `"showListenerCount": true`.
3. Prüfen: `dart run tool/check_config.dart`. Jede Datei bekommt `OK` oder eine Meldung mit dem Fehler.
4. Bauen mit `tool/bauen.ps1` (Windows) bzw. `tool/bauen.sh`, siehe [Bauen und Starten](BAUEN-UND-STARTEN.md). Die Skripte nehmen `config/app.json` und `config/features.json` automatisch mit, wenn es sie gibt.

## Bauen in GitHub Actions

In der CI gibt es keine echten Dateien. Die Werte kommen aus den Repository-Einstellungen (Settings → Secrets and variables → Actions) und werden beim Bauen in `config/app.json` geschrieben (`.github/actions/write-config`):

- Werte für `app.json`: Variablen und Secrets wie in [Einrichtung](EINRICHTUNG.md) beschrieben.
- Schalter: Variable `FEATURES_JSON` mit dem Inhalt einer `features.json`, z. B. `{"showListenerCount": true}`. Ohne Variable gelten die Werte aus `features.example.json`, also alles aus. Unbekannte Schlüssel oder andere Werte als `true`/`false` brechen den Build mit einer Meldung ab.

## Prüfung in der CI

Jeder Pull Request führt `dart run tool/check_config.dart` aus. Geprüft wird:

- Jede Beispieldatei enthält alle Schlüssel ihres Schemas, keine unbekannten, mit dem richtigen Typ und ohne echte Werte.
- `app.example.json` enthält jeden Wert, den der App-Code liest.
- Die Senderliste besteht die strenge Prüfung.
- Unbekannte Dateien im Ordner sind ein Fehler, damit ein Tippfehler im Dateinamen auffällt.

## Ein neues Thema ergänzen

Neue Datei `config/<thema>.example.json` anlegen, das Schema in `tool/check_config.dart` (`_schemas`) eintragen und hier in der Tabelle ergänzen.
