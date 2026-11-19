# Sicherheitsrichtlinie

Hier steht, wie du eine Sicherheitslücke in LINEFM Radio meldest und was danach passiert.

## Lücke melden

Bitte **nicht** öffentlich als Issue oder in den Discussions melden. Schreib an:

**{{SECURITY_KONTAKT}}**

(E-Mail-Adresse oder Formular-Link. Der Betreiber trägt hier den Kontakt ein, bevor das Repository öffentlich wird. Dieselbe Angabe steht in [web/.well-known/security.txt](web/.well-known/security.txt). Ist das Repository öffentlich, kann zusätzlich die GitHub-Funktion "Report a vulnerability" unter dem Reiter Security aktiviert werden.)

Hilfreich sind:

- betroffene Version oder Plattform (Android, Windows, Web usw.)
- Schritte zum Nachstellen oder ein kleines Beispiel
- was du für die Auswirkung hältst
- ob und wann du die Lücke veröffentlichen willst

Bitte keine Daten Dritter abgreifen, keine Last-Tests gegen app.linefm.de oder die Dienste von laut.fm, Apple und Google und keine Social-Engineering-Versuche gegen Personen.

## Was du von uns erwarten kannst

Das Projekt wird von einer Einzelperson betreut. Die Fristen sind deshalb Zielwerte, keine Zusagen:

| Schritt | Ziel |
|---|---|
| Eingang bestätigen | innerhalb von 7 Tagen |
| erste Einschätzung | innerhalb von 14 Tagen |
| Fehlerbehebung | je nach Schwere, kritische Lücken zuerst |
| Veröffentlichung der Korrektur | gemeinsam mit dir abgestimmt, üblich sind bis zu 90 Tage |

Wir nennen dich auf Wunsch im Changelog. Ein Kopfgeld gibt es nicht.

## Unterstützte Versionen

| Version | Unterstützt |
|---|---|
| 1.0.x (noch nicht veröffentlicht) | ja, sobald veröffentlicht |
| ältere Vorabstände | nein |

## Was zum Umfang gehört

- die App (Android, iOS, macOS, Windows, Linux) und die Web-Version unter app.linefm.de
- die Konfigurationen in `deploy/` (nginx, Traefik, Plesk, Cloudflare, Telemetrie)
- die Build- und Release-Abläufe in `.github/workflows/`

Nicht dazu gehören Lücken in Diensten Dritter (laut.fm, Apple iTunes Search, Google Cast, Hosting-Anbieter). Bitte melde sie dem jeweiligen Betreiber.

## Bekannte, bewusst akzeptierte Punkte

- Die Content-Security-Policy erlaubt `style-src 'unsafe-inline'`, weil die Flutter-Engine Inline-Stile setzt. Begründung und Gegenmaßnahmen: [docs/hosting-uebersicht.md](docs/hosting-uebersicht.md), Abschnitt Security-Header.
- Telemetrie-Schlüssel (Umami-Website-ID, Sentry-DSN) stehen im Binary. Das sind öffentliche Kennungen, keine Geheimnisse (siehe [docs/telemetry.md](docs/telemetry.md)).

## So wird die Sicherheit geprüft

Abhängigkeitsprüfung (Dependabot, OSV), statische Analyse (CodeQL), Secret-Scan und OpenSSF Scorecard laufen in den Workflows unter `.github/workflows/`. Ein Eintrag bei bestpractices.dev besteht noch nicht.
