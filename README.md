# LINEFM Radio

Die App zum Live-Hören der LINEFM-Sender: LineFM +MAIN, +RAP, +GAMING, +LOFI sowie Radio3FM und FobFM. LineFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe. LineFM Studios gehört Julian Gebauer. Gebaut mit Flutter (ein Framework von Google) für Android, iOS, Windows, macOS, Linux und das Web.

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/VectoDE/linefm-radio-app/badge)](https://scorecard.dev/viewer/?uri=github.com/VectoDE/linefm-radio-app)
[![CI](https://github.com/VectoDE/linefm-radio-app/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/ci.yml)
[![Barrierefreiheit](https://github.com/VectoDE/linefm-radio-app/actions/workflows/a11y.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/a11y.yml)
[![Lieferkette](https://github.com/VectoDE/linefm-radio-app/actions/workflows/supply-chain.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/supply-chain.yml)
[![CodeQL](https://github.com/VectoDE/linefm-radio-app/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/codeql.yml)
[![Semgrep](https://github.com/VectoDE/linefm-radio-app/actions/workflows/semgrep.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/semgrep.yml)
[![Lizenz: proprietär](https://img.shields.io/badge/Lizenz-propriet%C3%A4r-lightgrey)](LICENSE)


**Stand:** in Entwicklung. Jeder Merge auf `main` erzeugt eine signierte Vorabversion unter [Releases](https://github.com/VectoDE/linefm-radio-app/releases), zuerst `0.1.0-alpha.N` (Ablauf: [Bauen und Starten, A4](docs/BAUEN-UND-STARTEN.md#a4-der-weg-über-ein-release)). Noch in keinem Store veröffentlicht. Die Web-Version ist für `https://app.linefm.de` vorgesehen.

## Wer liest was?

| Ich bin ... | Ich will ... | Weiter bei |
|---|---|---|
| Hörerin oder Hörer | wissen, was die App kann | [Für Hörer](#für-hörer) |
| Mensch mit Screenreader, Tastatur oder Vergrößerung | wissen, was geht und was nicht | [Barrierefreiheit](#barrierefreiheit) |
| Entscheider | Stand, Kosten, Risiken auf einen Blick | [Für Entscheider](#für-entscheider) |
| Betreiber (LineFM Studios) | Konten einrichten und freigeben | [Für Betreiber](#für-betreiber) |
| Neu im Code | zum ersten Mal bauen | [Erste Schritte](#erste-schritte) |
| Betreiber oder Tester | die App selbst bauen lassen, herunterladen, öffnen und nutzen | [Bauen und Starten](docs/BAUEN-UND-STARTEN.md) |
| Entwickler | bauen, testen, erweitern | [Für Entwickler](#für-entwickler) |
| Unsicher, wohin mit der Frage | Hilfe finden | [SUPPORT.md](SUPPORT.md) |

## Für Hörer

Alle Sender in einer App, kostenlos und ohne Konto.

- Live hören mit Sendername, aktuellem Titel und Cover. Die Wiedergabe läuft im Hintergrund weiter, auch bei gesperrtem Bildschirm, und lässt sich mit Medientasten und Kopfhörern steuern.
- Song merken: Favoriten sammeln, teilen und exportieren. Sender lassen sich ebenfalls als Favorit markieren.
- Verlauf der zuletzt gespielten Titel.
- Schlafen und Wecken: Sleeptimer (15, 30, 45 oder 60 Minuten) und Radiowecker mit Sender.
- Unterwegs: Homescreen-Widget (Android), Android Auto, Chromecast. AirPlay und CarPlay sind vorbereitet, aber noch nicht veröffentlicht.
- Am Computer: Tray-Symbol (Symbol im Infobereich der Taskleiste), Mini-Fenster, das im Vordergrund bleibt, Tastenkürzel.
- Deutsch und Englisch (Systemsprache oder in den Einstellungen festgelegt), hell und dunkel, für Handy, Tablet und Desktop. Warum nur zwei Sprachen: [Sprachen](#sprachen).
- Links: `https://app.linefm.de/?station=<sender>` und `linefm://play?station=<sender>` öffnen direkt den Sender.

Datenschutz: Favoriten, Verlauf und Einstellungen bleiben auf deinem Gerät. Statistik und Absturzberichte sind nur aktiv, wenn der Betreiber sie einschaltet, und dann nur nach deiner Einwilligung. In der Web-Version kann der Betreiber zusätzlich eine Reichweitenmessung mit Google Analytics einrichten; auch die läuft nur, wenn du gesondert zustimmst. Impressum und Datenschutzerklärung stehen in der App und unter `/impressum/` und `/datenschutz/` auf der Web-Seite.

Fehler melden und Ideen: im Bereich Tickets oder Discussions dieses Repositories.

## Barrierefreiheit

Die App lässt sich mit Tastatur bedienen, alle Bereiche sind für Screenreader ausgezeichnet, hell und dunkel erreichen die Texte mindestens 4,5:1 Kontrast. Jeder Änderungsvorschlag lässt axe-core über die Web-Version laufen (Workflow `a11y.yml`); bei einem schweren Fund schlägt der Lauf fehl. Mit echten Screenreadern (TalkBack, VoiceOver, NVDA) ist die App noch nicht geprüft. Was geht, was fehlt und wie du uns erreichst: [ACCESSIBILITY.md](.github/ACCESSIBILITY.md) (Deutsch und Englisch) und die ausführliche [Erklärung zur Barrierefreiheit](docs/BARRIEREFREIHEIT.md).

## Für Entscheider

- Stand: Vorabversionen erscheinen bei jedem Merge automatisch unter Releases, noch in keinem Store. Was vor dem Start fehlt, sind Konten, Zugangsdaten und schriftliche Freigaben des Betreibers, keine Programmierarbeit: [Freigabe-Checkliste](docs/FREIGABE-CHECKLISTE.md).
- Laufende Kosten: kein eigenes Backend, keine Nutzerkonten. Es fallen nur Store-Gebühren (Google Play einmalig, Apple jährlich, falls später gewünscht) und das Web-Hosting an. Die Sender kommen über die öffentliche laut.fm-API.
- Daten: Ohne aktivierte Statistik schickt die App von sich aus nur Anfragen an laut.fm (API und Streams), an Apple (iTunes-Cover-Suche, abschaltbar), an cdn.linefm.de (Sender-Icons) und an radiogruppe.de (Logo). Statistik und Absturzberichte nur nach Einwilligung, siehe [Telemetrie](docs/telemetry.md). Im Web optional Google Analytics, nur nach eigener Einwilligung (siehe [Einrichtung](docs/EINRICHTUNG.md)).
- Prüfbarkeit: Jedes Release hat Prüfsummen, eine SBOM, eine Herkunfts-Attestierung von GitHub und eine cosign-Signatur je Datei, auf Wunsch zusätzlich eine GPG-Signatur: [Release-Dateien prüfen](docs/RELEASE-VERIFIZIEREN.md).
- Risiken: Abhängigkeit von laut.fm als einziger Datenquelle; Marken- und Rechtsfragen (Name, Logo, Rechtstexte) klärt der Betreiber mit einem Anwalt, bevor etwas veröffentlicht wird.

## Für Betreiber

Du musst keinen Code anfassen. Was du tun musst, steht in zwei Listen:

1. [Einrichtung](docs/EINRICHTUNG.md): Konten und Zugangsdaten für Google Play, Microsoft Store, Flathub, Snap Store, Web-Hosting, Statistik, später Apple. Alles als Checkboxen, Schritt für Schritt.
2. [Freigabe-Checkliste](docs/FREIGABE-CHECKLISTE.md): Was du vor dem Start schriftlich bestätigst (Marke, Name, Icon, Rechtstexte, laut.fm, Übergabe) und welche Gerätetests laufen.

Welches Secret wohin gehört, steht gesammelt in [docs/secrets.md](docs/secrets.md). Wie die Store-Abläufe zusammenhängen und in welcher Reihenfolge du sie zum ersten Mal startest: [docs/stores-pipelines.md](docs/stores-pipelines.md).

Hosting der Web-Version: [Überblick](docs/hosting-uebersicht.md) mit Anleitungen für [nginx](docs/hosting-nginx.md), [Traefik](docs/hosting-traefik.md), [Cloudflare Pages](docs/hosting-cloudflare.md) und [Plesk](docs/hosting-plesk.md). Statistik und Absturzberichte: [Telemetrie](docs/telemetry.md).

Verteilung: Google Play, Microsoft Store, Flathub, Snap Store und GitHub Releases (Installer, APK, unsigniertes macOS-DMG mit [Öffnen-Anleitung](packaging/macos/LIES-MICH-ZUERST.txt)). Apple App Store und Mac App Store sind bewusst zurückgestellt, der Code ist dafür vorbereitet. Übersicht der Pakete: [packaging/README.md](packaging/README.md).

## Erste Schritte

Du brauchst [Flutter 3.50](https://docs.flutter.dev/get-started/install) und Git. Für Android zusätzlich Android Studio, für Windows Visual Studio mit C++ und Rust.

1. Repository klonen und im Ordner `flutter pub get` ausführen.
2. Optional: `config/app.example.yaml` nach `config/app.yaml` kopieren, ausfüllen und mit `dart run tool/check_config.dart --defines config/app.json` die Bauwerte erzeugen. Ohne diesen Schritt startet die App mit Standardwerten, Statistik bleibt aus. Siehe [Konfiguration](docs/KONFIGURATION.md).
3. `flutter run -d chrome --dart-define-from-file=config/app.json` startet die Web-Version im Browser.
4. Vor einem Änderungsvorschlag: `dart format .`, `flutter analyze --fatal-infos` und `flutter test` müssen ohne Fehler durchlaufen.

Hängt etwas, steht die Lösung oft in [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md), sonst frag in den Discussions ([SUPPORT.md](SUPPORT.md)). Wie wir miteinander umgehen: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Für Entwickler

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
```

- Flutter 3.50 (Dart 3.14), UI mit `material_ui`, State mit Riverpod. Windows-Build braucht Rust und kurze Pfade.
- Konfiguration über `--dart-define-from-file=config/app.json` (erzeugt aus `config/app.yaml`, siehe [Konfiguration](docs/KONFIGURATION.md)).
- Aufbau, Tests und Goldens, Deep Links, Entscheidung zum laut.fm-WebSocket: **[Entwicklung](docs/ENTWICKLUNG.md)**.
- Datenquelle: öffentliche [laut.fm-API](https://docs.api.laut.fm/api-spec.yaml). Es gibt kein eigenes Backend und keine Konten.
- Ordner: `lib/` (App), `test/`, `android/ ios/ macos/ windows/ linux/ web/` (Plattformen), `deploy/` (Web-Server-Konfiguration), `packaging/` (Installer und Store-Pakete), `tool/` (Generatoren).

## Sprachen

Die App gibt es auf Deutsch und Englisch. Das weicht bewusst vom Hausstandard mit 31 Sprachen ab, der Inhaber hat das am 19.11.2026 so entschieden. Die Gründe:

- Wer LINEFM hört, spricht fast immer Deutsch. Die Sender moderieren auf Deutsch, Titel und Sendungsnamen kommen aus laut.fm und bleiben unübersetzt. Englisch deckt alle anderen Geräte-Sprachen ab: Ist das Gerät auf eine andere Sprache gestellt, zeigt die App Englisch. In den Einstellungen lässt sich die Sprache festlegen (Systemsprache, Deutsch oder English); die Wahl gilt sofort und wird sofort dauerhaft gespeichert, auch wenn der Speicher-Hinweis noch nicht bestätigt ist (alle anderen Einstellungen folgen weiter der Bestätigung). Rangfolge: Wahl in dieser Sitzung, dann `?lang=de|en` der Web-Adresse, dann gespeicherte Wahl, dann die Systemsprache. „Speicher löschen“ stellt wieder die Systemsprache ein.
- Jede weitere Sprache brauchte geprüfte Übersetzungen der Rechtstexte (Impressum, Datenschutz) und der Store-Texte. Maschinell übersetzte Rechtstexte wollen wir nicht veröffentlichen.
- Die Struktur ist erweiterbar. Texte stehen in ARB-Dateien unter `lib/l10n/` (Vorlage `app_de.arb`), Rechtstexte unter `assets/legal/<sprache>/`. Für eine neue Sprache kommen `app_<code>.arb` und die übersetzten Rechtstexte dazu, Flutter erzeugt die Zugriffsklassen beim Bauen. Dazu werden `resolveAppLocale` in `lib/app/app.dart` und `AppLanguage` in `lib/domain/app_settings.dart` um die Sprache ergänzt, dazu ein Eintrag in der Sprachwahl der Einstellungen.

## OpenSSF und Prüfsiegel

| Siegel | Stand |
|---|---|
| OpenSSF Scorecard | läuft wöchentlich und bei jedem Push auf `main` (`scorecard.yml`), Ergebnis im Badge oben |
| OpenSSF Best Practices (bestpractices.dev) | **strukturell nicht erreichbar.** Schon die Stufe „passing“ verlangt eine FLOSS-Lizenz (Kriterium `floss_license`). LINEFM Radio ist proprietär, das bleibt so |
| Signierte Releases mit Herkunftsnachweis | GitHub-Attestierung (SLSA Build Provenance) und cosign keyless je Release-Datei, siehe [Release-Dateien prüfen](docs/RELEASE-VERIFIZIEREN.md) |

Einige Scorecard-Prüfungen können hier nicht voll punkten, und das schreiben wir offen hin:

- Code-Review: Das Projekt hat einen einzigen Entwickler. Änderungsvorschläge laufen durch die Pflicht-Checks, eine zweite Person, die freigibt, gibt es nicht.
- Maintained: Scorecard wertet Repositories unter 90 Tagen Alter ab. Das Repository ist im November 2026 entstanden.
- CII-Best-Practices: hängt am Badge von bestpractices.dev, siehe oben.
- Fuzzing: Scorecard erkennt OSS-Fuzz, ClusterFuzzLite und Fuzz- bzw. Property-Tests in Go, Haskell, JavaScript/TypeScript, Erlang und C#/F#. Für Dart gibt es weder eine passende Fuzzing-Engine noch eine Erkennung. ClusterFuzzLite unterstützt Dart nicht, ein Ersatz-Fuzzer nur für die Hilfsskripte in Python würde die Wertung heben, ohne die App sicherer zu machen. Die Begründung steht im Repository.
- Branch-Protection und CI-Tests steigen mit der Zeit: Seit dem 19.11.2026 schützt das Ruleset `main-schutz` den Branch `main`, jede Änderung läuft als Änderungsvorschlag durch die Pflicht-Checks. Scorecard bewertet aber auch die älteren Commits.

## Standards und Konformität

Stand: 22. November 2026. Status heißt: **erfüllt** = die Prüfung läuft in der CI und war grün, **teilweise** = ein Teil ist belegt, der Rest steht offen daneben, **Ziel** = angestrebt, noch nicht belegt. Nichts steht auf „erfüllt“, was wir nicht nachweisen können. Das ist keine Rechtsberatung und keine Zertifizierung.

| Bereich | Standard oder Praxis | Status | Beleg und offene Punkte |
|---|---|---|---|
| Barrierefreiheit | WCAG 2.2 AA | teilweise | axe-core bei jedem Änderungsvorschlag ohne Verstöße ([a11y.yml](.github/workflows/a11y.yml)). Screenreader-Prüfung und Zoom 400 % fehlen, siehe [ACCESSIBILITY.md](.github/ACCESSIBILITY.md) |
| Barrierefreiheit | EN 301 549 | Ziel | Maßstab, kein Nachweis ([ACCESSIBILITY.md](.github/ACCESSIBILITY.md)) |
| Barrierefreiheit | BFSG | Ziel | Ob das BFSG für diese App gilt und eine Erklärung Pflicht ist, wird geprüft; Entwurf in [docs/BARRIEREFREIHEIT.md](docs/BARRIEREFREIHEIT.md). Falls es gilt, ist die MLBF in Magdeburg zuständig ([mlbf-barrierefrei.de](https://www.mlbf-barrierefrei.de)) |
| Sicherheit | OpenSSF Scorecard | teilweise | Läuft wöchentlich und bei jedem Push auf `main` ([scorecard.yml](.github/workflows/scorecard.yml)); einige Prüfungen können nicht voll punkten, siehe [OpenSSF und Prüfsiegel](#openssf-und-prüfsiegel) |
| Sicherheit | Signierte Releases (cosign, Sigstore) | Ziel | Der Ablauf steht in [release.yml](.github/workflows/release.yml), es gibt aber noch kein Release; Prüfanleitung: [docs/RELEASE-VERIFIZIEREN.md](docs/RELEASE-VERIFIZIEREN.md) |
| Sicherheit | Herkunftsnachweis (GitHub-Attestierung, SLSA Build Provenance) | Ziel | Wie oben: erst mit dem ersten Release belegbar. Eine SLSA-Stufe behaupten wir nicht |
| Sicherheit | SBOM (SPDX, CycloneDX) | Ziel | Wird im Release-Ablauf erzeugt ([release.yml](.github/workflows/release.yml)), noch kein Release |
| Sicherheit | CodeQL | teilweise | GitHub-Actions-Workflows bei jedem Änderungsvorschlag, Kotlin und Java wöchentlich; Dart unterstützt CodeQL nicht ([codeql.yml](.github/workflows/codeql.yml)) |
| Sicherheit | Semgrep CE | teilweise | Läuft bei jedem Änderungsvorschlag; Dart ist nicht abgedeckt, dort prüft `flutter analyze` ([semgrep.yml](.github/workflows/semgrep.yml)) |
| Sicherheit | Trivy, OSV, gitleaks | erfüllt | Abhängigkeiten, Konfiguration und Git-Historie, bei jedem Änderungsvorschlag ([supply-chain.yml](.github/workflows/supply-chain.yml)) |
| Sicherheit | zizmor (Workflow-Prüfung) | erfüllt | Bei jedem Änderungsvorschlag ([supply-chain.yml](.github/workflows/supply-chain.yml), Regeln in [zizmor.yml](.github/zizmor.yml)) |
| Datenschutz | DSGVO | teilweise | Favoriten, Verlauf und Einstellungen bleiben auf dem Gerät ([ADR 0001](docs/adr/0001-kein-backend-keine-konten.md)). Die Datenschutzerklärung ist ein Entwurf mit offenen Platzhaltern; Prüfung durch einen Anwalt steht aus |
| Datenschutz | TDDDG, Einwilligung | teilweise | Statistik und Reichweitenmessung starten nur nach Einwilligung, Widerruf stoppt sie ([docs/telemetry.md](docs/telemetry.md), Tests `test/features/consent_storage_test.dart`, `google_consent_test.dart`). Rechtliche Prüfung steht aus |
| Recht | DDG (Impressum) | Ziel | Text als Entwurf vorhanden, die Betreiberangaben sind noch nicht eingetragen; der Release-Build bricht bis dahin ab |
| Recht | MStV | Ziel | Angabe der verantwortlichen Person ist als Pflichtfeld vorgesehen, aber noch offen; ob sie nötig ist, klärt ein Anwalt |
| Qualität | Tests und Pflicht-Checks | erfüllt | Testsuite, Format- und Analyseprüfung bei jedem Änderungsvorschlag ([ci.yml](.github/workflows/ci.yml)); `main` ist per Ruleset geschützt |
| Qualität | Coverage | teilweise | Wird in der CI gemessen, eine feste Schwelle gibt es noch nicht; Ziel 100 % in `lib/` |
| Qualität | Golden-Tests | teilweise | Kernkomponenten und einzelne Ansichten in Hell und Dunkel; alle Bildschirme und Breiten stehen im Tracker offen |
| Qualität | Lasttests | Ziel | Es gibt noch keine; geplant gegen eigene Endpunkte |

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [docs/EINRICHTUNG.md](docs/EINRICHTUNG.md) | Konten und Secrets für den Betreiber |
| [docs/FREIGABE-CHECKLISTE.md](docs/FREIGABE-CHECKLISTE.md) | Freigaben, Rechtsprüfung, Gerätetests, Store-Texte |
| [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) | Bauen, Testen, Architektur |
| [docs/hosting-uebersicht.md](docs/hosting-uebersicht.md) | Web-Hosting, Cache, Header |
| [docs/STORE-TEXTE.md](docs/STORE-TEXTE.md) | Texte für Play, Microsoft Store, Snap, Flathub, Tester-Einladung |
| [docs/STORE-RICHTLINIEN.md](docs/STORE-RICHTLINIEN.md) | Store-Richtlinien als Prüfliste je Store, mit Quellen und Status (englisch: [STORE-POLICIES.md](docs/STORE-POLICIES.md)) |
| [.github/ACCESSIBILITY.md](.github/ACCESSIBILITY.md) | Barrierefreiheit: Ziel, Stand, bekannte Lücken, Barriere melden (de/en) |
| [docs/BARRIEREFREIHEIT.md](docs/BARRIEREFREIHEIT.md) | Erklärung zur Barrierefreiheit (Entwurf) |
| [docs/secrets.md](docs/secrets.md) | Alle Secrets und Variablen der Abläufe |
| [docs/stores-pipelines.md](docs/stores-pipelines.md) | Store- und Deploy-Abläufe, Erstveröffentlichung |
| [docs/RELEASE-VERIFIZIEREN.md](docs/RELEASE-VERIFIZIEREN.md) | Downloads prüfen: Prüfsummen, SBOM, Signaturen |
| [docs/LIZENZEN-DRITTE.md](docs/LIZENZEN-DRITTE.md) | Lizenzen von libmpv, FFmpeg und weiteren Bausteinen |
| [SECURITY.md](SECURITY.md) | Sicherheitslücke melden |
| [CHANGELOG.md](CHANGELOG.md) | Änderungen je Version |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Mitarbeiten |
| [SUPPORT.md](SUPPORT.md) | Wo du Hilfe bekommst |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Verhaltensregeln |
| [docs/telemetry.md](docs/telemetry.md) | Statistik, Absturzberichte, Selbsthosting |
| [packaging/README.md](packaging/README.md) | Installer, Store-Pakete, Signierung |

## Credits

Entwickelt von [Tim Hauke](https://github.com/VectoDE) für LineFM Studios. LINEFM und diese App gehören LineFM Studios.

Made by [Tim Hauke](https://github.com/VectoDE) with ♥. LineFM ist ein Angebot der RadioGruppe Deutschland im Auftrag der LINEFM Gruppe. LineFM Studios gehört Julian Gebauer. Die Sender werden über laut.fm ausgespielt. Schriften: Poppins und Syncopate (Lizenztexte in der App).

## Rechte

**Alle Rechte vorbehalten, keine Open-Source-Lizenz.** Das Repository ist seit dem 19.11.2026 öffentlich. Du darfst den Quellcode lesen und auf GitHub ansehen. Nutzungsrechte gibt dir das nicht: Nutzung, Kopie, Änderung und Weitergabe brauchen die schriftliche Erlaubnis des Rechteinhabers. Der verbindliche Text steht in [LICENSE](LICENSE).

LINEFM, die Logos, das App-Icon und die Sendernamen sind Marken und Eigentum des Betreibers beziehungsweise der jeweiligen Inhaber (u. a. LINEFM, Radio3FM, FobFM, RadioGruppe Deutschland, laut.fm) und von dieser Rechtevergabe ausgenommen. Android, Google Play, Android Auto und Chromecast sind Marken von Google, Apple, iOS, CarPlay und AirPlay von Apple, Windows und Microsoft Store von Microsoft. Diese Namen werden nur zur Beschreibung der Kompatibilität genannt.

## English

LINEFM Radio is a Flutter app for listening to the LINEFM radio stations live (Android, iOS, Windows, macOS, Linux, web). It is under development and not yet published in any store. Operators start with [docs/EINRICHTUNG.md](docs/EINRICHTUNG.md) and [docs/FREIGABE-CHECKLISTE.md](docs/FREIGABE-CHECKLISTE.md), developers with [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) (all in German). Linux packages (.deb, .rpm, AppImage) are described in English in [packaging/linux/README.md](packaging/linux/README.md). Developed by [Tim Hauke](https://github.com/VectoDE) for LineFM Studios. LINEFM and this app belong to LineFM Studios. All rights reserved, no open-source license.

### Standards and compliance

As of 22 November 2026. Status: **met** = the check runs in CI and was green, **partly met** = part is proven and the rest is listed as open, **target** = aimed for, not proven yet. Nothing is marked met without proof. This is neither legal advice nor a certification. Most evidence files are in German.

| Area | Standard or practice | Status | Evidence and open points |
|---|---|---|---|
| Accessibility | WCAG 2.2 AA | partly met | axe-core on every proposed change with no violations ([a11y.yml](.github/workflows/a11y.yml)). Screen reader testing and 400 % zoom are missing, see [ACCESSIBILITY.md](.github/ACCESSIBILITY.md) |
| Accessibility | EN 301 549 | target | Yardstick, no proof ([ACCESSIBILITY.md](.github/ACCESSIBILITY.md)) |
| Accessibility | BFSG | target | Whether the BFSG applies to this app and a statement is mandatory is being reviewed; draft in [docs/BARRIEREFREIHEIT.md](docs/BARRIEREFREIHEIT.md). If it applies, the MLBF in Magdeburg is the competent body ([mlbf-barrierefrei.de](https://www.mlbf-barrierefrei.de)) |
| Security | OpenSSF Scorecard | partly met | Runs weekly and on every push to `main` ([scorecard.yml](.github/workflows/scorecard.yml)); some checks cannot score fully, see the German section "OpenSSF und Prüfsiegel" |
| Security | Signed releases (cosign, Sigstore) | target | The flow is in [release.yml](.github/workflows/release.yml), but no release exists yet; verification guide: [docs/RELEASE-VERIFIZIEREN.md](docs/RELEASE-VERIFIZIEREN.md) |
| Security | Provenance (GitHub attestation, SLSA build provenance) | target | As above: provable only with the first release. We do not claim a SLSA level |
| Security | SBOM (SPDX, CycloneDX) | target | Produced in the release flow ([release.yml](.github/workflows/release.yml)), no release yet |
| Security | CodeQL | partly met | GitHub Actions workflows on every proposed change, Kotlin and Java weekly; CodeQL does not support Dart ([codeql.yml](.github/workflows/codeql.yml)) |
| Security | Semgrep CE | partly met | Runs on every proposed change; Dart is not covered, `flutter analyze` covers it ([semgrep.yml](.github/workflows/semgrep.yml)) |
| Security | Trivy, OSV, gitleaks | met | Dependencies, configuration and git history, on every proposed change ([supply-chain.yml](.github/workflows/supply-chain.yml)) |
| Security | zizmor (workflow audit) | met | On every proposed change ([supply-chain.yml](.github/workflows/supply-chain.yml), rules in [zizmor.yml](.github/zizmor.yml)) |
| Privacy | GDPR | partly met | Favorites, history and settings stay on the device ([ADR 0001](docs/adr/0001-kein-backend-keine-konten.md)). The privacy policy is a draft with open placeholders; review by a lawyer is pending |
| Privacy | TDDDG, consent | partly met | Statistics and reach measurement start only after consent, withdrawal stops them ([docs/telemetry.md](docs/telemetry.md), tests `test/features/consent_storage_test.dart`, `google_consent_test.dart`). Legal review is pending |
| Legal | DDG (legal notice) | target | Draft text exists, the operator details are not filled in yet; the release build fails until then |
| Legal | MStV | target | The responsible person is planned as a required field but still open; a lawyer decides whether it applies |
| Quality | Tests and required checks | met | Test suite, format and analysis on every proposed change ([ci.yml](.github/workflows/ci.yml)); `main` is protected by a ruleset |
| Quality | Coverage | partly met | Measured in CI, no fixed threshold yet; target 100 % in `lib/` |
| Quality | Golden tests | partly met | Core components and some views in light and dark; all screens and widths are open im Tracker |
| Quality | Load tests | target | None yet; planned against our own endpoints |
