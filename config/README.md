# config/

Einstellungen zum Bauen der App, je Thema eine YAML-Datei mit Kommentar über jedem Schlüssel. Im Repository liegen nur Beispiele (`*.example.yaml`) und die Senderliste (`stations.yaml`). Zum Nutzen eine Beispieldatei kopieren, `.example` aus dem Namen entfernen und ausfüllen. Echte Dateien bleiben lokal (`.gitignore`); fehlt eine, ist die Funktion aus.

Anleitung: [docs/KONFIGURATION.md](../docs/KONFIGURATION.md), Senderliste: [docs/SENDER-VERWALTEN.md](../docs/SENDER-VERWALTEN.md). Prüfen: `dart run tool/check_config.dart`.
