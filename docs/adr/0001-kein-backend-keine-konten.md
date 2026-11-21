# ADR 0001: Kein Backend, keine Konten

Status: angenommen
Quelle: Entscheidung des Inhabers, Runde 1 bis 3 (18.11.2026)

## Kontext

Die App soll LINEFM-Sender hören lassen und die Funktionen der Web-App app.linecast.de abbilden. Betreiber ist jaybelife, entwickelt wird unentgeltlich von einer Einzelperson. Die Titel- und Senderdaten liefert laut.fm öffentlich, ohne Anmeldung.

## Entscheidung

LINEFM Radio hat kein eigenes Backend, keine Datenbank und keine Nutzerkonten. Favoriten, Verlauf und Einstellungen liegen lokal auf dem Gerät. Die Web-Version besteht aus statischen Dateien. Die App ruft direkt laut.fm, die Cover-Suche von Apple und die Logo-Server ab.

## Folgen

- Es gibt nichts zu sichern oder wiederherzustellen. Der Betrieb besteht aus dem Ausliefern statischer Dateien ([Betriebshandbuch](../betrieb/RUNBOOK.md)).
- Ganze Angriffsklassen entfallen (Konten, Sitzungen, Datenbank). Siehe [Bedrohungsmodell](../betrieb/BEDROHUNGSMODELL.md).
- Der Datenschutz wird einfacher: Die App speichert selbst keine Nutzerdaten auf Servern des Betreibers.
- Favoriten wandern nicht zwischen Geräten. Dafür gibt es Export und Import als Datei.
- Wir hängen an der Verfügbarkeit und den Bedingungen von laut.fm und Apple. Ein Ausfall dort lässt sich nicht abfangen.
- Telemetrie ist die einzige Ausnahme und nur mit Einwilligung ([ADR 0006](0006-telemetrie-austauschbar-mit-einwilligung.md)).

## Verworfene Alternativen

Eigenes Backend mit Konten und Sync: mehr Aufwand, Betriebskosten, Datenschutz- und Sicherheitspflichten, ohne dass Hörer es verlangt hätten. Verworfen.
