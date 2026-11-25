# Konfiguration

Alle Einstellungen, die beim Bauen der App festgelegt werden, liegen im Ordner [`config/`](../config/). Jedes Thema hat eine eigene Datei im Format YAML. Über jedem Schlüssel steht ein Kommentar: was er bedeutet, ob er Pflicht oder optional ist, welche Werte bzw. welches Format erlaubt sind, der Standardwert und ein Beispiel.

## Grundregel

- Im Repository liegt jede Datei nur als vollständiges Beispiel: `<thema>.example.yaml`. Alle Schlüssel sind da, jeweils mit dem Standardwert (leer bzw. aus).
- Wer etwas nutzen will, kopiert die Beispieldatei, entfernt `.example` aus dem Namen und füllt die Werte aus. Beispiel: `features.example.yaml` kopieren und als `features.yaml` speichern.
- Echte Dateien (ohne `example`) kommen nie ins Repository, `.gitignore` schließt sie aus.
- Fehlt eine echte Datei, gilt der sichere Standard: Die Funktion ist aus.
- Einzige Ausnahme ist die Senderliste `stations.yaml`. Sie liegt gefüllt im Repository, damit die App ohne weitere Dateien funktioniert. Anleitung: [Sender verwalten](SENDER-VERWALTEN.md).

## YAML in drei Regeln

1. Jede Zeile hat die Form `schluessel: wert`. Was hinter `#` steht, ist ein Kommentar.
2. Eingerückt wird mit zwei Leerzeichen, nie mit Tabs.
3. Text mit `#` oder `:` gehört in Anführungszeichen, z. B. `farbe: "#4B4B7D"`. `true` und `false` stehen ohne Anführungszeichen.

## Die Dateien

| Datei | Wofür | Liest die App? |
|---|---|---|
| `stations.yaml` | Senderliste | ja |
| `app.example.yaml` → `app.yaml` | Umgebung, Web-Adresse, Telemetrie, Firebase, Google Tag, Vertrauenssiegel, `STATIONS_URL` (feste https-Adresse zum Nachladen der Senderliste) | ja |
| `features.example.yaml` → `features.yaml` | Schalter. `showListenerCount`: Hörerzahl im Player zeigen (`true`/`false`, Standard `false`) | ja |
| `operator.example.yaml` → `operator.yaml` | Betreiberangaben fürs Impressum | noch nicht, nur Schema |
| `telemetry.example.yaml` → `telemetry.yaml` | Telemetrie getrennt von `app.yaml` | noch nicht, nur Schema; heute stehen die Werte in `app.yaml` |
| `updater.example.yaml` → `updater.yaml` | Update-Hinweis: `enabled` (`true`/`false`), `channel` (`stable` oder `beta`) | noch nicht, nur Schema |

Alle Werte landen in der fertigen App und sind dort lesbar. Trage also nur öffentliche Kennungen ein, keine Passwörter oder geheimen Schlüssel.

## Lokal bauen

1. Beispieldatei kopieren und umbenennen, z. B. `config/features.example.yaml` → `config/features.yaml`.
2. Werte eintragen, z. B. `showListenerCount: true`.
3. Prüfen: `dart run tool/check_config.dart`. Jede Datei bekommt `OK` oder eine Meldung mit Zeile und Fehler.
4. Bauen mit `tool/bauen.ps1` (Windows) bzw. `tool/bauen.sh`, siehe [Bauen und Starten](BAUEN-UND-STARTEN.md). Die Skripte prüfen `app.yaml` und `features.yaml` und erzeugen daraus die Bauwerte `config/app.json`.

Ohne Skript: `dart run tool/check_config.dart --defines config/app.json`, danach `flutter build <ziel> --dart-define-from-file=config/app.json`. `config/app.json` ist eine erzeugte Datei, nicht von Hand bearbeiten.

## Bauen in GitHub Actions

In der CI gibt es keine echten Dateien. Die Werte kommen aus den Repository-Einstellungen (Settings → Secrets and variables → Actions). `.github/actions/write-config` nimmt die Standardwerte aus `app.example.yaml` und `features.example.yaml`, setzt die Variablen ein und schreibt `config/app.json`:

- Werte für `app.yaml`: Variablen und Secrets wie in [Einrichtung](EINRICHTUNG.md) beschrieben.
- Schalter: Variable `FEATURES_JSON` mit den Schaltern als JSON, z. B. `{"showListenerCount": true}`. Ohne Variable gilt `features.example.yaml`, also alles aus. Unbekannte Schlüssel oder andere Werte als `true`/`false` brechen den Build mit einer Meldung ab.

## Prüfung in der CI

Jeder Pull Request führt `dart run tool/check_config.dart` aus. Geprüft wird:

- Über jedem Schlüssel steht ein Kommentar.
- Jede Beispieldatei enthält alle Schlüssel ihres Schemas, keine unbekannten, mit dem richtigen Typ und genau dem Standardwert.
- Formate: https-Adressen, Version (SemVer), `GTM-…`, `G-…`, Auswahlwerte, E-Mail, PLZ, Telefon.
- `app.example.yaml` enthält jeden Wert, den der App-Code liest.
- Die Senderliste besteht die strenge Prüfung der App (Kürzel `^[a-z0-9_-]{1,64}$`, Farbe `#RRGGBB`, Logos nur von erlaubten Hosts).
- Unbekannte Dateien im Ordner sind ein Fehler, damit ein Tippfehler im Dateinamen auffällt.

## Ein neues Thema ergänzen

Neue Datei `config/<thema>.example.yaml` mit Kommentar über jedem Schlüssel anlegen, das Schema in `tool/check_config.dart` (`_schemas`) eintragen und hier in der Tabelle ergänzen.
