# ADR 0004: Zwei Sprachen, Deutsch und Englisch

Status: angenommen
Quelle: Entscheidung 15 des Inhabers (18.11.2026), bestätigt am 19.11.2026 (Issue #63)

## Kontext

Der Hausstandard des Betreibers sieht 31 Sprachen vor. Die Hörer von LINEFM sind überwiegend deutschsprachig.

## Entscheidung

Die App hat zwei Sprachen: Deutsch und Englisch. Sie folgt der Systemsprache und fällt auf Englisch zurück. Deutsch ist die Vorlage (`lib/l10n/app_de.arb`). Die Struktur lässt weitere Sprachen als zusätzliche ARB-Dateien ohne Umbau zu. Die Ausnahme vom Hausstandard steht mit dieser Begründung in der README.

## Folgen

- Jeder Text muss in beiden Sprachen vorliegen. `flutter gen-l10n` und Tests in der CI prüfen das.
- Rechtstexte und Store-Texte gibt es ebenfalls nur auf Deutsch und Englisch.
- Weitere Sprachen kosten Übersetzung, Prüfung auf Textlänge und Pflege der Store-Einträge. Technisch sind sie kein Problem.

## Verworfene Alternativen

31 Sprachen sofort: hoher Übersetzungs- und Prüfaufwand ohne belegten Bedarf. Verworfen.
