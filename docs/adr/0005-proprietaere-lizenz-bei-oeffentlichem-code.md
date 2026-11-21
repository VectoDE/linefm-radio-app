# ADR 0005: Proprietäre Lizenz bei öffentlichem Code

Status: angenommen
Quelle: Entscheidung 42 und 43 des Inhabers (18.11.2026)

## Kontext

Das Repository ist öffentlich, damit Hörer und Prüfer nachsehen können, was die App tut, und damit kostenlose Repository-Dienste (Scorecard, Code-Scanning) laufen. Marken, Logos und Icon gehören dem Betreiber.

## Entscheidung

Der Quellcode ist sichtbar, aber nicht frei lizenziert: alle Rechte vorbehalten (`LICENSE`). Marken, Namen und Logos sind ausdrücklich ausgenommen und gehören den jeweiligen Betreibern. Es gibt keine Open-Source-Lizenz.

## Folgen

- Nutzung, Veränderung und Weitergabe des Codes durch Dritte sind nicht erlaubt.
- Das OpenSSF-Best-Practices-Badge verlangt eine freie Lizenz. Es ist deshalb strukturell nicht erreichbar und wird ehrlich als nicht erfüllt geführt ([SECURITY.md](../../SECURITY.md)).
- Flathub und andere Kanäle prüfen die Lizenz. Eine nicht freie Lizenz kann dort ein Hindernis sein. Das ist beim Einreichen zu klären.
- Die Lizenzen der Abhängigkeiten gelten unabhängig davon ([LIZENZEN-DRITTE.md](../LIZENZEN-DRITTE.md)).

## Verworfene Alternativen

Open-Source-Lizenz (zum Beispiel GPL oder MIT): gäbe das Badge, erlaubte aber jedem die Wiederverwendung. Der Inhaber hat dagegen entschieden. Privates Repository: schließt kostenlose Prüfdienste und Transparenz aus. Beides verworfen.
