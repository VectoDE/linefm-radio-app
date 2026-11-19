# LINEFM Radio

Die App zum Live-Hören der LINEFM-Sender: LineFM +MAIN, +RAP, +GAMING, +LOFI sowie Radio3FM und FobFM. Ein Angebot von RadioGruppe Deutschland. Gebaut mit Flutter (ein Framework von Google) für Android, iOS, Windows, macOS, Linux und das Web.

<!--
Badges: Es stehen hier bewusst keine. Sie kommen erst, wenn sie echt sind:
- CI-Status: nach dem Merge der Workflows (.github/workflows/ci.yml), aktuell offen in PR #34.
- OpenSSF Scorecard: nach dem ersten Lauf von scorecard.yml, bei privatem Repo nicht aussagekräftig.
- OpenSSF Best Practices: erst nach Eintrag auf bestpractices.dev. Die FLOSS-Lizenz-Anforderung ist bei "Alle Rechte vorbehalten" nicht erfüllbar.
-->

**Stand:** in Entwicklung, Version 1.0.0. Noch in keinem Store veröffentlicht. Die Web-Version ist für `https://app.linefm.de` vorgesehen.

## Wer liest was?

| Ich bin ... | Ich will ... | Weiter bei |
|---|---|---|
| Hörerin oder Hörer | wissen, was die App kann | [Für Hörer](#für-hörer) |
| Betreiber (jaybelife) | Konten einrichten und freigeben | [Für Betreiber](#für-betreiber) |
| Entwickler | bauen, testen, erweitern | [Für Entwickler](#für-entwickler) |

## Für Hörer

Alle Sender in einer App, kostenlos und ohne Konto.

- **Live hören** mit Sendername, aktuellem Titel und Cover. Die Wiedergabe läuft im Hintergrund weiter, auch bei gesperrtem Bildschirm, und lässt sich mit Medientasten und Kopfhörern steuern.
- **Song merken:** Favoriten sammeln, teilen und exportieren. Sender lassen sich ebenfalls als Favorit markieren.
- **Verlauf** der zuletzt gespielten Titel.
- **Schlafen und Wecken:** Sleeptimer (15, 30, 45 oder 60 Minuten) und Radiowecker mit Sender.
- **Unterwegs:** Homescreen-Widget (Android), Android Auto, Chromecast. AirPlay und CarPlay sind vorbereitet, aber noch nicht veröffentlicht.
- **Am Computer:** Tray-Symbol (Symbol im Infobereich der Taskleiste), Mini-Fenster, das im Vordergrund bleibt, Tastenkürzel.
- **Deutsch und Englisch**, hell und dunkel, für Handy, Tablet und Desktop.
- **Links:** `https://app.linefm.de/?station=<sender>` und `linefm://play?station=<sender>` öffnen direkt den Sender.

Datenschutz: Favoriten, Verlauf und Einstellungen bleiben auf deinem Gerät. Statistik und Absturzberichte sind nur aktiv, wenn der Betreiber sie einschaltet, und dann nur nach deiner Einwilligung. Impressum und Datenschutzerklärung stehen in der App und unter `/impressum/` und `/datenschutz/` auf der Web-Seite.

Fehler melden und Ideen: im Bereich Issues oder Discussions dieses Repositories.

## Für Betreiber

Du musst keinen Code anfassen. Was du tun musst, steht in zwei Listen:

1. **[Einrichtung](docs/EINRICHTUNG.md):** Konten und Zugangsdaten für Google Play, Microsoft Store, Flathub, Snap Store, Web-Hosting, Statistik, später Apple. Alles als Checkboxen, Schritt für Schritt.
2. **[Freigabe-Checkliste](docs/FREIGABE-CHECKLISTE.md):** Was du vor dem Start schriftlich bestätigst (Marke, Name, Icon, Rechtstexte, laut.fm, Übergabe) und welche Gerätetests laufen.

Hosting der Web-Version: [Überblick](docs/hosting-uebersicht.md) mit Anleitungen für [nginx](docs/hosting-nginx.md), [Traefik](docs/hosting-traefik.md), [Cloudflare Pages](docs/hosting-cloudflare.md) und [Plesk](docs/hosting-plesk.md). Statistik und Absturzberichte: [Telemetrie](docs/telemetry.md).

Verteilung: Google Play, Microsoft Store, Flathub, Snap Store und GitHub Releases (Installer, APK, unsigniertes macOS-DMG mit [Öffnen-Anleitung](packaging/macos/LIES-MICH-ZUERST.txt)). Apple App Store und Mac App Store sind bewusst zurückgestellt, der Code ist dafür vorbereitet. Übersicht der Pakete: [packaging/README.md](packaging/README.md).

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

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [docs/EINRICHTUNG.md](docs/EINRICHTUNG.md) | Konten und Secrets für den Betreiber |
| [docs/FREIGABE-CHECKLISTE.md](docs/FREIGABE-CHECKLISTE.md) | Freigaben, Rechtsprüfung, Gerätetests, Store-Texte |
| [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) | Bauen, Testen, Architektur |
| [docs/hosting-uebersicht.md](docs/hosting-uebersicht.md) | Web-Hosting, Cache, Header |
| [docs/STORE-TEXTE.md](docs/STORE-TEXTE.md) | Texte für Play, Microsoft Store, Snap, Flathub, Tester-Einladung |
| [docs/BARRIEREFREIHEIT.md](docs/BARRIEREFREIHEIT.md) | Erklärung zur Barrierefreiheit (Entwurf) |
| [docs/LIZENZEN-DRITTE.md](docs/LIZENZEN-DRITTE.md) | Lizenzen von libmpv, FFmpeg und weiteren Bausteinen |
| [SECURITY.md](SECURITY.md) | Sicherheitslücke melden |
| [CHANGELOG.md](CHANGELOG.md) | Änderungen je Version |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Mitarbeiten |
| [docs/telemetry.md](docs/telemetry.md) | Statistik, Absturzberichte, Selbsthosting |
| [packaging/README.md](packaging/README.md) | Installer, Store-Pakete, Signierung |

## Credits

Entwickelt von [Tim Hauke (VectoDE)](https://github.com/VectoDE) für jaybelife. LINEFM und diese App gehören jaybelife.

Made by .jaybelife with ♥. Ein Angebot von RadioGruppe Deutschland. Die Sender werden über laut.fm ausgespielt. Schriften: Poppins und Syncopate (Lizenztexte in der App).

## Rechte

**Alle Rechte vorbehalten.** Der Quellcode ist einsehbar (sobald das Repository öffentlich ist), aber nicht unter einer Open-Source-Lizenz veröffentlicht. Nutzung, Kopie, Änderung und Weitergabe brauchen die schriftliche Erlaubnis des Rechteinhabers.

LINEFM, die Logos, das App-Icon und die Sendernamen sind Marken und Eigentum des Betreibers beziehungsweise der jeweiligen Inhaber (u. a. LINEFM, Radio3FM, FobFM, RadioGruppe Deutschland, laut.fm) und von dieser Rechtevergabe ausgenommen. Android, Google Play, Android Auto und Chromecast sind Marken von Google, Apple, iOS, CarPlay und AirPlay von Apple, Windows und Microsoft Store von Microsoft. Diese Namen werden nur zur Beschreibung der Kompatibilität genannt.

## English

LINEFM Radio is a Flutter app for listening to the LINEFM radio stations live (Android, iOS, Windows, macOS, Linux, web). It is under development and not yet published in any store. Operators start with [docs/EINRICHTUNG.md](docs/EINRICHTUNG.md) and [docs/FREIGABE-CHECKLISTE.md](docs/FREIGABE-CHECKLISTE.md), developers with [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) (all in German). Developed by Tim Hauke (VectoDE) for jaybelife. LINEFM and this app belong to jaybelife. All rights reserved, no open-source license.
