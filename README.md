# LINEFM Radio

Die App zum Live-Hören der LINEFM-Sender: LineFM +MAIN, +RAP, +GAMING, +LOFI sowie Radio3FM und FobFM. Ein Angebot von RadioGruppe Deutschland. Gebaut mit Flutter (ein Framework von Google) für Android, iOS, Windows, macOS, Linux und das Web.

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/VectoDE/linefm-radio-app/badge)](https://scorecard.dev/viewer/?uri=github.com/VectoDE/linefm-radio-app)
[![CI](https://github.com/VectoDE/linefm-radio-app/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/ci.yml)
[![Barrierefreiheit](https://github.com/VectoDE/linefm-radio-app/actions/workflows/a11y.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/a11y.yml)
[![Lieferkette](https://github.com/VectoDE/linefm-radio-app/actions/workflows/supply-chain.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/supply-chain.yml)
[![CodeQL](https://github.com/VectoDE/linefm-radio-app/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/codeql.yml)
[![Semgrep](https://github.com/VectoDE/linefm-radio-app/actions/workflows/semgrep.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/semgrep.yml)
[![Lizenz: proprietär](https://img.shields.io/badge/Lizenz-propriet%C3%A4r-lightgrey)](LICENSE)


**Stand:** in Entwicklung, Version 1.0.0. Noch in keinem Store veröffentlicht. Die Web-Version ist für `https://app.linefm.de` vorgesehen.

## Wer liest was?

| Ich bin ... | Ich will ... | Weiter bei |
|---|---|---|
| Hörerin oder Hörer | wissen, was die App kann | [Für Hörer](#für-hörer) |
| Mensch mit Screenreader, Tastatur oder Vergrößerung | wissen, was geht und was nicht | [Barrierefreiheit](#barrierefreiheit) |
| Entscheider | Stand, Kosten, Risiken auf einen Blick | [Für Entscheider](#für-entscheider) |
| Betreiber (jaybelife) | Konten einrichten und freigeben | [Für Betreiber](#für-betreiber) |
| Neu im Code | zum ersten Mal bauen | [Erste Schritte](#erste-schritte) |
| Betreiber oder Tester | die App selbst bauen lassen, herunterladen, öffnen und nutzen | [Bauen und Starten](docs/BAUEN-UND-STARTEN.md) |
| Entwickler | bauen, testen, erweitern | [Für Entwickler](#für-entwickler) |
| Unsicher, wohin mit der Frage | Hilfe finden | [SUPPORT.md](SUPPORT.md) |

## Für Hörer

Alle Sender in einer App, kostenlos und ohne Konto.

- **Live hören** mit Sendername, aktuellem Titel und Cover. Die Wiedergabe läuft im Hintergrund weiter, auch bei gesperrtem Bildschirm, und lässt sich mit Medientasten und Kopfhörern steuern.
- **Song merken:** Favoriten sammeln, teilen und exportieren. Sender lassen sich ebenfalls als Favorit markieren.
- **Verlauf** der zuletzt gespielten Titel.
- **Schlafen und Wecken:** Sleeptimer (15, 30, 45 oder 60 Minuten) und Radiowecker mit Sender.
- **Unterwegs:** Homescreen-Widget (Android), Android Auto, Chromecast. AirPlay und CarPlay sind vorbereitet, aber noch nicht veröffentlicht.
- **Am Computer:** Tray-Symbol (Symbol im Infobereich der Taskleiste), Mini-Fenster, das im Vordergrund bleibt, Tastenkürzel.
- **Deutsch und Englisch** (Systemsprache oder in den Einstellungen festgelegt), hell und dunkel, für Handy, Tablet und Desktop. Warum nur zwei Sprachen: [Sprachen](#sprachen).
- **Links:** `https://app.linefm.de/?station=<sender>` und `linefm://play?station=<sender>` öffnen direkt den Sender.

Datenschutz: Favoriten, Verlauf und Einstellungen bleiben auf deinem Gerät. Statistik und Absturzberichte sind nur aktiv, wenn der Betreiber sie einschaltet, und dann nur nach deiner Einwilligung. In der Web-Version kann der Betreiber zusätzlich eine Reichweitenmessung mit Google Analytics einrichten; auch die läuft nur, wenn du gesondert zustimmst. Impressum und Datenschutzerklärung stehen in der App und unter `/impressum/` und `/datenschutz/` auf der Web-Seite.

Fehler melden und Ideen: im Bereich Issues oder Discussions dieses Repositories.

## Barrierefreiheit

Die App lässt sich mit Tastatur bedienen, alle Bereiche sind für Screenreader ausgezeichnet, hell und dunkel erreichen die Texte mindestens 4,5:1 Kontrast. Jeder Pull Request lässt axe-core über die Web-Version laufen (Workflow `a11y.yml`); bei einem schweren Fund schlägt der Lauf fehl. Mit echten Screenreadern (TalkBack, VoiceOver, NVDA) ist die App noch nicht geprüft. Was geht, was fehlt und wie du uns erreichst: [Erklärung zur Barrierefreiheit](docs/BARRIEREFREIHEIT.md).

## Für Entscheider

- **Stand:** Version 1.0.0 fertig gebaut, noch in keinem Store. Was vor dem Start fehlt, sind Konten, Zugangsdaten und schriftliche Freigaben des Betreibers, keine Programmierarbeit: [Freigabe-Checkliste](docs/FREIGABE-CHECKLISTE.md).
- **Laufende Kosten:** kein eigenes Backend, keine Nutzerkonten. Es fallen nur Store-Gebühren (Google Play einmalig, Apple jährlich, falls später gewünscht) und das Web-Hosting an. Die Sender kommen über die öffentliche laut.fm-API.
- **Daten:** Ohne aktivierte Statistik schickt die App von sich aus nur Anfragen an laut.fm (API und Streams), an Apple (iTunes-Cover-Suche, abschaltbar), an cdn.linefm.de (Sender-Icons) und an radiogruppe.de (Logo). Statistik und Absturzberichte nur nach Einwilligung, siehe [Telemetrie](docs/telemetry.md). Im Web optional Google Analytics, nur nach eigener Einwilligung (siehe [Einrichtung](docs/EINRICHTUNG.md)).
- **Prüfbarkeit:** Jedes Release hat Prüfsummen, eine SBOM, eine Herkunfts-Attestierung von GitHub und eine cosign-Signatur je Datei, auf Wunsch zusätzlich eine GPG-Signatur: [Release-Dateien prüfen](docs/RELEASE-VERIFIZIEREN.md).
- **Risiken:** Abhängigkeit von laut.fm als einziger Datenquelle; Marken- und Rechtsfragen (Name, Logo, Rechtstexte) klärt der Betreiber mit einem Anwalt, bevor etwas veröffentlicht wird.

## Für Betreiber

Du musst keinen Code anfassen. Was du tun musst, steht in zwei Listen:

1. **[Einrichtung](docs/EINRICHTUNG.md):** Konten und Zugangsdaten für Google Play, Microsoft Store, Flathub, Snap Store, Web-Hosting, Statistik, später Apple. Alles als Checkboxen, Schritt für Schritt.
2. **[Freigabe-Checkliste](docs/FREIGABE-CHECKLISTE.md):** Was du vor dem Start schriftlich bestätigst (Marke, Name, Icon, Rechtstexte, laut.fm, Übergabe) und welche Gerätetests laufen.

Welches Secret wohin gehört, steht gesammelt in [docs/secrets.md](docs/secrets.md). Wie die Store-Abläufe zusammenhängen und in welcher Reihenfolge du sie zum ersten Mal startest: [docs/stores-pipelines.md](docs/stores-pipelines.md).

Hosting der Web-Version: [Überblick](docs/hosting-uebersicht.md) mit Anleitungen für [nginx](docs/hosting-nginx.md), [Traefik](docs/hosting-traefik.md), [Cloudflare Pages](docs/hosting-cloudflare.md) und [Plesk](docs/hosting-plesk.md). Statistik und Absturzberichte: [Telemetrie](docs/telemetry.md).

Verteilung: Google Play, Microsoft Store, Flathub, Snap Store und GitHub Releases (Installer, APK, unsigniertes macOS-DMG mit [Öffnen-Anleitung](packaging/macos/LIES-MICH-ZUERST.txt)). Apple App Store und Mac App Store sind bewusst zurückgestellt, der Code ist dafür vorbereitet. Übersicht der Pakete: [packaging/README.md](packaging/README.md).

## Erste Schritte

Du brauchst [Flutter 3.50](https://docs.flutter.dev/get-started/install) und Git. Für Android zusätzlich Android Studio, für Windows Visual Studio mit C++ und Rust.

1. Repository klonen und im Ordner `flutter pub get` ausführen.
2. `config/app.example.json` nach `config/app.json` kopieren. Die Vorlage reicht zum Starten, Statistik bleibt aus.
3. `flutter run -d chrome --dart-define-from-file=config/app.json` startet die Web-Version im Browser.
4. Vor einem Pull Request: `dart format .`, `flutter analyze --fatal-infos` und `flutter test` müssen ohne Fehler durchlaufen.

Hängt etwas, steht die Lösung oft in [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md), sonst frag in den Discussions ([SUPPORT.md](SUPPORT.md)). Wie wir miteinander umgehen: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Für Entwickler

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
```

- Flutter 3.50 (Dart 3.14), UI mit `material_ui`, State mit Riverpod. Windows-Build braucht Rust und kurze Pfade.
- Konfiguration über `--dart-define-from-file=config/app.json` (Vorlage `config/app.example.json`).
- Aufbau, Tests und Goldens, Deep Links, Entscheidung zum laut.fm-WebSocket: **[Entwicklung](docs/ENTWICKLUNG.md)**.
- Datenquelle: öffentliche [laut.fm-API](https://docs.api.laut.fm/api-spec.yaml). Es gibt kein eigenes Backend und keine Konten.
- Ordner: `lib/` (App), `test/`, `android/ ios/ macos/ windows/ linux/ web/` (Plattformen), `deploy/` (Web-Server-Konfiguration), `packaging/` (Installer und Store-Pakete), `tool/` (Generatoren).

## Sprachen

Die App gibt es auf Deutsch und Englisch. Das weicht bewusst vom Hausstandard mit 31 Sprachen ab, der Inhaber hat das am 19.11.2026 so entschieden. Die Gründe:

- Wer LINEFM hört, spricht fast immer Deutsch. Die Sender moderieren auf Deutsch, Titel und Sendungsnamen kommen aus laut.fm und bleiben unübersetzt. Englisch deckt alle anderen Geräte-Sprachen ab: Ist das Gerät auf eine andere Sprache gestellt, zeigt die App Englisch. In den Einstellungen lässt sich die Sprache festlegen (Systemsprache, Deutsch oder English); die Wahl gilt sofort und wird mit den übrigen Einstellungen gespeichert. Rangfolge: Wahl in dieser Sitzung, dann `?lang=de|en` der Web-Adresse, dann gespeicherte Wahl, dann die Systemsprache. „Speicher löschen“ stellt wieder die Systemsprache ein.
- Jede weitere Sprache brauchte geprüfte Übersetzungen der Rechtstexte (Impressum, Datenschutz) und der Store-Texte. Maschinell übersetzte Rechtstexte wollen wir nicht veröffentlichen.
- Die Struktur ist erweiterbar. Texte stehen in ARB-Dateien unter `lib/l10n/` (Vorlage `app_de.arb`), Rechtstexte unter `assets/legal/<sprache>/`. Für eine neue Sprache kommen `app_<code>.arb` und die übersetzten Rechtstexte dazu, Flutter erzeugt die Zugriffsklassen beim Bauen. Dazu werden `resolveAppLocale` in `lib/app/app.dart` und `AppLanguage` in `lib/domain/app_settings.dart` um die Sprache ergänzt, dazu ein Eintrag in der Sprachwahl der Einstellungen.

## OpenSSF und Prüfsiegel

| Siegel | Stand |
|---|---|
| OpenSSF Scorecard | läuft wöchentlich und bei jedem Push auf `main` (`scorecard.yml`), Ergebnis im Badge oben |
| OpenSSF Best Practices (bestpractices.dev) | **strukturell nicht erreichbar.** Schon die Stufe „passing“ verlangt eine FLOSS-Lizenz (Kriterium `floss_license`). LINEFM Radio ist proprietär, das bleibt so |
| Signierte Releases mit Herkunftsnachweis | GitHub-Attestierung (SLSA Build Provenance) und cosign keyless je Release-Datei, siehe [Release-Dateien prüfen](docs/RELEASE-VERIFIZIEREN.md) |

Einige Scorecard-Prüfungen können hier nicht voll punkten, und das schreiben wir offen hin:

- **Code-Review:** Das Projekt hat einen einzigen Entwickler. Pull Requests laufen durch die Pflicht-Checks, eine zweite Person, die freigibt, gibt es nicht.
- **Maintained:** Scorecard wertet Repositories unter 90 Tagen Alter ab. Das Repository ist im November 2026 entstanden.
- **CII-Best-Practices:** hängt am Badge von bestpractices.dev, siehe oben.
- **Fuzzing:** Scorecard erkennt OSS-Fuzz, ClusterFuzzLite und Fuzz- bzw. Property-Tests in Go, Haskell, JavaScript/TypeScript, Erlang und C#/F#. Für Dart gibt es weder eine passende Fuzzing-Engine noch eine Erkennung. ClusterFuzzLite unterstützt Dart nicht, ein Ersatz-Fuzzer nur für die Hilfsskripte in Python würde die Wertung heben, ohne die App sicherer zu machen. Begründung in Issue #59.
- **Branch-Protection** und **CI-Tests** steigen mit der Zeit: Seit dem 19.11.2026 schützt das Ruleset `main-schutz` den Branch `main`, jede Änderung läuft als Pull Request durch die Pflicht-Checks. Scorecard bewertet aber auch die älteren Commits.

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [docs/EINRICHTUNG.md](docs/EINRICHTUNG.md) | Konten und Secrets für den Betreiber |
| [docs/FREIGABE-CHECKLISTE.md](docs/FREIGABE-CHECKLISTE.md) | Freigaben, Rechtsprüfung, Gerätetests, Store-Texte |
| [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) | Bauen, Testen, Architektur |
| [docs/hosting-uebersicht.md](docs/hosting-uebersicht.md) | Web-Hosting, Cache, Header |
| [docs/STORE-TEXTE.md](docs/STORE-TEXTE.md) | Texte für Play, Microsoft Store, Snap, Flathub, Tester-Einladung |
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

Entwickelt von [Tim Hauke (VectoDE)](https://github.com/VectoDE) für jaybelife. LINEFM und diese App gehören jaybelife.

Made by .jaybelife with ♥. Ein Angebot von RadioGruppe Deutschland. Die Sender werden über laut.fm ausgespielt. Schriften: Poppins und Syncopate (Lizenztexte in der App).

## Rechte

**Alle Rechte vorbehalten, keine Open-Source-Lizenz.** Das Repository ist seit dem 19.11.2026 öffentlich. Du darfst den Quellcode lesen und auf GitHub ansehen. Nutzungsrechte gibt dir das nicht: Nutzung, Kopie, Änderung und Weitergabe brauchen die schriftliche Erlaubnis des Rechteinhabers. Der verbindliche Text steht in [LICENSE](LICENSE).

LINEFM, die Logos, das App-Icon und die Sendernamen sind Marken und Eigentum des Betreibers beziehungsweise der jeweiligen Inhaber (u. a. LINEFM, Radio3FM, FobFM, RadioGruppe Deutschland, laut.fm) und von dieser Rechtevergabe ausgenommen. Android, Google Play, Android Auto und Chromecast sind Marken von Google, Apple, iOS, CarPlay und AirPlay von Apple, Windows und Microsoft Store von Microsoft. Diese Namen werden nur zur Beschreibung der Kompatibilität genannt.

## English

LINEFM Radio is a Flutter app for listening to the LINEFM radio stations live (Android, iOS, Windows, macOS, Linux, web). It is under development and not yet published in any store. Operators start with [docs/EINRICHTUNG.md](docs/EINRICHTUNG.md) and [docs/FREIGABE-CHECKLISTE.md](docs/FREIGABE-CHECKLISTE.md), developers with [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) (all in German). Developed by Tim Hauke (VectoDE) for jaybelife. LINEFM and this app belong to jaybelife. All rights reserved, no open-source license.
