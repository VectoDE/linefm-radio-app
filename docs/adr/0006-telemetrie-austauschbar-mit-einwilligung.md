# ADR 0006: Telemetrie austauschbar und nur mit Einwilligung

Status: angenommen
Quelle: Entscheidung 24 und 26 des Inhabers (18.11.2026)

## Kontext

Der Betreiber will wissen, wie die App genutzt wird und wo sie abstürzt. Statistik und Absturzberichte sind nach DSGVO und TDDDG einwilligungspflichtig. Welcher Anbieter passt, war offen, und der Betreiber wollte sich nicht auf einen festlegen.

## Entscheidung

Die App unterstützt mehrere Anbieter hinter einer Schnittstelle: Umami (Statistik), GlitchTip oder Sentry (Absturzberichte), optional Firebase. Aktiv ist nur, was beim Build konfiguriert ist. Ohne Konfiguration sendet die App nichts und zeigt keinen Dialog. Mit Konfiguration startet kein Dienst vor der Einwilligung, und ein Widerruf stoppt ihn sofort. Die Web-Version kann zusätzlich Google Analytics 4 über den Tag Manager laden, mit eigener Einwilligung. Firebase ist im Standard-Build nicht enthalten.

## Folgen

- Der Betreiber kann den Anbieter wechseln, ohne die App umzubauen. Docker Compose für Umami und GlitchTip liegt unter `deploy/telemetry/`.
- Datenschutzerklärung, Einwilligungstext, Content-Security-Policy und Store-Angaben müssen zu den aktivierten Anbietern passen ([telemetry.md](../telemetry.md), [STORE-DATENSCHUTZANGABEN.md](../STORE-DATENSCHUTZANGABEN.md)). Nach jeder Änderung neu bauen und die Header neu ausrollen.
- Die Daten sind pseudonym, nicht anonym (IP-Adresse beim Empfänger). Das ist so dokumentiert.
- Die Einordnung der Dienste als Auftragsverarbeitung und die Datenschutzerklärung muss der Betreiber rechtlich prüfen lassen.

## Verworfene Alternativen

Ein fester Anbieter: einfacher, bindet aber den Betreiber. Keine Telemetrie: kein Wissen über Abstürze. Beides verworfen.
