# ADR 0008: Senderliste als Konfigurationsdatei mit Nachladen

Status: angenommen
Quelle: Anforderung und Entscheidung des Inhabers vom 21.11.2026 (Issue #91), ersetzt [ADR 0003](0003-senderliste-fest-im-code.md)

## Kontext

Sender sollen sich ohne Programmierkenntnisse hinzufügen, entfernen, umbenennen und umsortieren lassen. Bisher stand die Liste fest im Code (ADR 0003), jede Änderung war ein App-Update mit Store-Prüfung.

## Entscheidung

- Die Senderliste steht in einer einzigen Datei, `config/stations.json`. Sie ist die einzige echte Datei in `config/`, die im Repository liegt, und wird mit jeder App ausgeliefert. Damit läuft die App ohne weitere Dateien.
- Beim Start holt die App nach dem ersten Bild die aktuelle Fassung von einer festen eigenen Adresse (`STATIONS_URL`, zur Bauzeit gesetzt). Ist sie nicht erreichbar oder ungültig, gilt die zuletzt gültige bzw. die mitgelieferte Liste.
- Schutz gegen eine manipulierte Datei: nur https, Host fest, keine Weiterleitungen, höchstens 64 KB, nur JSON, strenges Schema mit Fehler bei unbekannten Feldern, Kürzel nur `[a-z0-9_-]`, Logo-Hosts fest im Code (nicht in der Datei), Stream-Adressen werden aus dem Kürzel abgeleitet und sind nicht eintragbar. Leere Listen werden nie übernommen.
- Gespeichert werden nur Kürzel. Ein entfernter Sender verschwindet aus der Anzeige; Favoriten bleiben gespeichert, ein Wecker weckt mit dem ersten Sender, ein Link zeigt einen Hinweis.
- Native Teile (Android-Widget, Android Auto, CarPlay) führen keine eigene Kopie der Liste.
- Weitere Konfigurationsteile (`features`, `operator`, `telemetry`, `updater`) liegen im selben Ordner, je als `*.example.json`, und werden vom selben Werkzeug (`tool/check_config.dart`) geprüft. Siehe [Konfiguration](../KONFIGURATION.md).

## Folgen

- Senderänderungen wirken ohne neue App-Version, sobald die Datei unter `STATIONS_URL` aktualisiert ist.
- Neue Angriffsfläche: eine manipulierte Datei unter der eigenen Adresse. Sie kann nur Sender aus laut.fm und Logos der erlaubten Hosts eintragen.
- Neue Sender ohne mitgeliefertes Logo zeigen in Android Auto, Widget und CarPlay das LINEFM-Logo, bis eine App-Version das Logo mitbringt.

## Verworfene Alternativen

- Nur mitgelieferte Datei ohne Nachladen: einfacher, aber jede Änderung bleibt ein App-Update. Vom Inhaber verworfen.
- Senderliste nur vom Server: ohne Netz beim ersten Start keine Sender. Verworfen.
