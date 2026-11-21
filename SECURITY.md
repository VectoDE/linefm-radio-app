# Sicherheitsrichtlinie

Hier steht, wie du eine Sicherheitslücke in LINEFM Radio meldest und was danach passiert.

## Lücke melden

Bitte **nicht** öffentlich als Issue oder in den Discussions melden. Nutze das vertrauliche Meldeformular von GitHub:

**<https://github.com/VectoDE/linefm-radio-app/security/advisories/new>**

(Reiter Security > "Report a vulnerability". Du brauchst ein GitHub-Konto. Die Meldung sehen nur die Betreuer des Repositorys. Dieselbe Angabe steht in [web/.well-known/security.txt](web/.well-known/security.txt). Eine E-Mail-Adresse veröffentlichen wir bewusst nicht.)

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

| Prüfung | Werkzeug | Wo | Wann |
|---|---|---|---|
| Bekannte Schwachstellen in Dart- und npm-Paketen | OSV-Scanner auf `pubspec.lock` und `tool/a11y/package-lock.json` | `supply-chain.yml` | Push auf `main`, jeder Pull Request, wöchentlich |
| Secrets in der Git-Historie | gitleaks (CLI, Version und SHA-256 fest im Workflow) | `supply-chain.yml` | Push auf `main`, jeder Pull Request, wöchentlich |
| Schwachstellen, Secrets und Fehlkonfiguration (Dateisystem, Dockerfile) sowie das Basisimage des Web-Containers | Trivy (CLI, Version und SHA-256 fest), Ergebnisse in Code Scanning, HIGH/CRITICAL brechen ab | `supply-chain.yml` | Push auf `main`, jeder Pull Request, wöchentlich |
| Sicherheit der Workflows | zizmor (Ergebnisse in Code Scanning) und actionlint | `supply-chain.yml` | Push auf `main`, jeder Pull Request, wöchentlich |
| Updates für Actions, Pub, Gradle, Docker, Compose und npm | Dependabot | `.github/dependabot.yml` | wöchentlich, mit 7 Tagen Wartezeit |
| Statische Analyse | CodeQL (Workflows bei jedem PR, Kotlin wöchentlich, Swift von Hand) | `codeql.yml` | Push auf `main`, jeder Pull Request, wöchentlich |
| Statische Analyse für Kotlin, Swift, JavaScript, Python, Bash, Dockerfile, Compose und Workflows | Semgrep Community Edition (ohne Konto, Image per Digest), Ergebnisse in Code Scanning | `semgrep.yml` | Push auf `main`, jeder Pull Request, wöchentlich |
| Dart-Code | `flutter analyze --fatal-infos` (CodeQL und Semgrep kennen Dart nicht) | `ci.yml` | Push auf `main`, jeder Pull Request |
| Robustheit der Parser (laut.fm, iTunes, Cover-Cache) | zufallsbasierte Tests mit festem Seed, siehe unten | `ci.yml` (`test/data/fuzz/`) | Push auf `main`, jeder Pull Request |
| Code-Qualität, zusätzliche Prüfungen | SonarQube Cloud und Snyk: vorbereitet, laufen erst mit Token ([docs/EINRICHTUNG.md](docs/EINRICHTUNG.md), 12.4 und 12.5) | `sonar.yml`, `snyk.yml` | sobald eingerichtet |
| Repo-Hygiene | OpenSSF Scorecard | `scorecard.yml` | Push auf `main`, wöchentlich |

Zum Fuzzing: Die Parser für die Antworten von laut.fm und der iTunes-Suche und das Laden des Cover-Caches bekommen in jedem Testlauf Tausende zufällig erzeugte, auch kaputte Eingaben (eigener Generator, fester Seed, keine zusätzliche Abhängigkeit). Sie dürfen dabei nie abstürzen; erlaubt ist nur der vorgesehene Fehlertyp `LautApiException`. Die Tests haben zwei echte Fehler gefunden, beide sind behoben: Zahlen wie `1e999` (in JSON gültig, in Dart unendlich) und Zeitstempel außerhalb des gültigen Bereichs im gespeicherten Cache. OpenSSF Scorecard wertet das nicht als Fuzzing. Erkannt werden dort nur OSS-Fuzz, ClusterFuzzLite und Fuzzing in einigen anderen Sprachen (Go, Haskell, JavaScript mit fast-check, Erlang, F#), Dart nicht.

Ein Eintrag bei bestpractices.dev ist nicht möglich: Das Badge verlangt eine Open-Source-Lizenz, LINEFM Radio ist proprietär.

Signierte Releases: Jede Release-Datei trägt eine GitHub-Attestierung und eine cosign-Signatur (`*.sigstore.json`), optional `SHA256SUMS.txt.asc` (GPG). Prüfen: [docs/RELEASE-VERIFIZIEREN.md](docs/RELEASE-VERIFIZIEREN.md).

## In English

Please report security vulnerabilities privately through GitHub's form: <https://github.com/VectoDE/linefm-radio-app/security/advisories/new>. Do not open a public issue. We aim to acknowledge a report within 7 days and to give a first assessment within 14 days. We follow coordinated disclosure: the fix and the advisory are published together with you, usually within 90 days. The project is maintained by one person, so these are targets, not guarantees.
