# LINEFM Radio

[Deutsch](README.md) | English

The app for listening live to the LINEFM stations: LineFM +MAIN, +RAP, +GAMING, +LOFI, plus Radio3FM and FobFM. LineFM is an offering of RadioGruppe Deutschland on behalf of the LINEFM Gruppe. LineFM Studios belongs to Julian Gebauer. Built with Flutter (a Google framework) for Android, iOS, Windows, macOS, Linux and the web.

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/VectoDE/linefm-radio-app/badge)](https://scorecard.dev/viewer/?uri=github.com/VectoDE/linefm-radio-app)
[![CI](https://github.com/VectoDE/linefm-radio-app/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/ci.yml)
[![Accessibility](https://github.com/VectoDE/linefm-radio-app/actions/workflows/a11y.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/a11y.yml)
[![Supply chain](https://github.com/VectoDE/linefm-radio-app/actions/workflows/supply-chain.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/supply-chain.yml)
[![CodeQL](https://github.com/VectoDE/linefm-radio-app/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/codeql.yml)
[![Semgrep](https://github.com/VectoDE/linefm-radio-app/actions/workflows/semgrep.yml/badge.svg?branch=main)](https://github.com/VectoDE/linefm-radio-app/actions/workflows/semgrep.yml)
[![License: proprietary](https://img.shields.io/badge/License-proprietary-lightgrey)](LICENSE)

**Status:** under development. Every merge to `main` produces a signed pre-release under [Releases](https://github.com/VectoDE/linefm-radio-app/releases), starting with `0.1.0-alpha.N` (flow: [Build and run, A4](docs/BAUEN-UND-STARTEN.md#a4-der-weg-über-ein-release), German). Not published in any store yet. The web version is planned for `https://app.linefm.de`.

Most detailed documents are still German. Pages marked (German) have no English version yet. English entry pages: [docs/en](docs/en/README.md).

## Who reads what?

| I am ... | I want to ... | Go to |
|---|---|---|
| A listener | know what the app can do | [For listeners](#for-listeners) |
| Someone using a screen reader, keyboard or magnification | know what works and what does not | [Accessibility](#accessibility) |
| A decision maker | see state, costs and risks at a glance | [For decision makers](#for-decision-makers) |
| The operator (LineFM Studios) | set up and approve accounts | [For operators](#for-operators) |
| New to the code | build for the first time | [Getting started](#getting-started) |
| Operator or tester | have the app built, download, open and use it | [Build and run](docs/BAUEN-UND-STARTEN.md) (German) |
| A developer | build, test, extend | [For developers](#for-developers) |
| Unsure where to ask | find help | [SUPPORT.md](SUPPORT.md) |

## For listeners

All stations in one app, free and without an account.

- Listen live with station name, current title and cover. Playback continues in the background, also with the screen locked, and responds to media keys and headphones.
- Remember a song: collect, share and export favorites. Stations can be marked as favorites too.
- History of recently played titles.
- Sleep and wake: sleep timer (15, 30, 45 or 60 minutes) and a radio alarm with a station.
- On the move: home screen widget (Android), Android Auto, Chromecast. AirPlay and CarPlay are prepared but not released yet.
- On the computer: tray icon (the icon in the taskbar's notification area), a mini window that stays in front, keyboard shortcuts.
- German and English (system language or set in the settings), light and dark, for phone, tablet and desktop. Why only two languages: [Languages](#languages).
- Links: `https://app.linefm.de/?station=<station>` and `linefm://play?station=<station>` open a station directly.

Privacy: favorites, history and settings stay on your device. Statistics and crash reports are active only if the operator turns them on, and then only with your consent. On the web, the operator can also set up reach measurement with Google Analytics; that runs only if you agree separately. The legal notice and privacy policy are in the app and at `/impressum/` and `/datenschutz/` on the website.

Report bugs and share ideas in the tickets area or in Discussions of this repository.

## Accessibility

The app works with a keyboard, all areas are marked up for screen readers, and text reaches at least 4.5:1 contrast in light and dark. Every proposed change runs axe-core against the web version (workflow `a11y.yml`); a serious finding fails the run. The app has not yet been tested with real screen readers (TalkBack, VoiceOver, NVDA). What works, what is missing and how to reach us: [ACCESSIBILITY.md](.github/ACCESSIBILITY.md) (German and English) and the detailed [accessibility statement](docs/BARRIEREFREIHEIT.md) (German).

## For decision makers

- State: pre-releases appear automatically under Releases on every merge, not in any store yet. What is missing before launch is accounts, credentials and written approvals from the operator, not programming work: [Release checklist](docs/FREIGABE-CHECKLISTE.md) (German).
- Running costs: no backend of our own, no user accounts. Only store fees (Google Play once, Apple yearly if wanted later) and web hosting. The stations come through the public laut.fm API.
- Data: with statistics off, the app itself only sends requests to laut.fm (API and streams), to Apple (iTunes artwork search, can be turned off) and to cdn.linefm.de (station icons). The RadioGruppe logo is bundled in the app. Statistics and crash reports only after consent, see [Telemetry](docs/telemetry.md) (German). On the web, Google Analytics is optional and only with separate consent (see [Setup](docs/EINRICHTUNG.md), German).
- Verifiability: every release has checksums, an SBOM, a GitHub provenance attestation and a cosign signature per file, plus a GPG signature on request: [Verify release files](docs/RELEASE-VERIFIZIEREN.md) (German).
- Risks: dependence on laut.fm as the only data source; trademark and legal questions (name, logo, legal texts) are settled by the operator with a lawyer before anything is published.

## For operators

You do not need to touch code. What you need to do is in two lists (both German):

1. [Setup](docs/EINRICHTUNG.md): accounts and credentials for Google Play, Microsoft Store, Flathub, Snap Store, web hosting, statistics, Apple later. Everything as checkboxes, step by step.
2. [Release checklist](docs/FREIGABE-CHECKLISTE.md): what you confirm in writing before launch (brand, name, icon, legal texts, laut.fm, handover) and which device tests run.

Which secret goes where is collected in [docs/secrets.md](docs/secrets.md). How the store flows fit together and in which order you start them for the first time: [docs/stores-pipelines.md](docs/stores-pipelines.md).

Hosting the web version: [overview](docs/hosting-uebersicht.md) with guides for [nginx](docs/hosting-nginx.md), [Traefik](docs/hosting-traefik.md), [Cloudflare Pages](docs/hosting-cloudflare.md) and [Plesk](docs/hosting-plesk.md). Statistics and crash reports: [Telemetry](docs/telemetry.md). All German.

Distribution: Google Play, Microsoft Store, Flathub, Snap Store and GitHub Releases (installer, APK, unsigned macOS DMG with an [opening guide](packaging/macos/LIES-MICH-ZUERST.txt)). The Apple App Store and Mac App Store are postponed on purpose; the code is prepared for them. Overview of the packages: [packaging/README.md](packaging/README.md).

## Getting started

You need [Flutter 3.50](https://docs.flutter.dev/get-started/install) and Git. For Android also Android Studio, for Windows Visual Studio with C++ and Rust.

1. Clone the repository and run `flutter pub get` in the folder.
2. Optional: copy `config/app.example.yaml` to `config/app.yaml`, fill it in, and generate the build values with `dart run tool/check_config.dart --defines config/app.json`. Without this step the app starts with defaults and statistics stay off. See [Configuration](docs/KONFIGURATION.md) (German).
3. `flutter run -d chrome --dart-define-from-file=config/app.json` starts the web version in the browser.
4. Before a proposed change: `dart format .`, `flutter analyze --fatal-infos` and `flutter test` must pass without errors.

If something is stuck, the answer is often in [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) (German); otherwise ask in Discussions ([SUPPORT.md](SUPPORT.md)). How we treat each other: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## For developers

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
```

- Flutter 3.50 (Dart 3.14), UI with `material_ui`, state with Riverpod. The Windows build needs Rust and short paths.
- Configuration through `--dart-define-from-file=config/app.json` (generated from `config/app.yaml`, see [Configuration](docs/KONFIGURATION.md), German).
- Structure, tests and goldens, deep links, the decision on the laut.fm WebSocket: **[Development](docs/ENTWICKLUNG.md)** (German). Short English overview: [Architecture](docs/en/architecture.md).
- Data source: the public [laut.fm API](https://docs.api.laut.fm/api-spec.yaml). There is no backend of our own and there are no accounts.
- Folders: `lib/` (app), `test/`, `android/ ios/ macos/ windows/ linux/ web/` (platforms), `deploy/` (web server configuration), `packaging/` (installers and store packages), `tool/` (generators).
- Linux packages (.deb, .rpm, AppImage) are described in [packaging/linux/README.md](packaging/linux/README.md).

## Languages

The app comes in German and English. This deliberately deviates from the house standard of 31 languages; the owner decided so on 19 November 2026. The reasons:

- Whoever listens to LINEFM almost always speaks German. The stations broadcast in German, and titles and show names come from laut.fm and stay untranslated. English covers all other device languages: if the device is set to another language, the app shows English. The language can be set in the settings (system language, German or English); the choice applies at once and is saved at once, even if the storage notice is not confirmed yet (all other settings still wait for the confirmation). Order of precedence: choice in this session, then `?lang=de|en` in the web address, then the saved choice, then the system language. "Clear storage" resets to the system language.
- Every further language would need reviewed translations of the legal texts (legal notice, privacy policy) and the store texts. We do not want to publish machine-translated legal texts.
- The structure is extensible. Texts live in ARB files under `lib/l10n/` (template `app_de.arb`), legal texts under `assets/legal/<language>/`. A new language needs `app_<code>.arb` and the translated legal texts; Flutter generates the access classes during the build. Also extend `resolveAppLocale` in `lib/app/app.dart` and `AppLanguage` in `lib/domain/app_settings.dart`, and add an entry to the language choice in the settings.

## OpenSSF and seals

| Seal | State |
|---|---|
| OpenSSF Scorecard | runs weekly and on every push to `main` (`scorecard.yml`), result in the badge above |
| OpenSSF Best Practices (bestpractices.dev) | **structurally not reachable.** Even the "passing" level requires a FLOSS license (criterion `floss_license`). LINEFM Radio is proprietary and stays so |
| Signed releases with provenance | GitHub attestation (SLSA build provenance) and keyless cosign per release file, see [Verify release files](docs/RELEASE-VERIFIZIEREN.md) (German) |

Some Scorecard checks cannot score fully here, and we say so openly:

- Code review: the project has a single developer. Proposed changes pass the required checks; there is no second person who approves.
- Maintained: Scorecard marks down repositories younger than 90 days. The repository was created in November 2026.
- CII best practices: depends on the bestpractices.dev badge, see above.
- Fuzzing: Scorecard recognizes OSS-Fuzz, ClusterFuzzLite and fuzz or property tests in Go, Haskell, JavaScript/TypeScript, Erlang and C#/F#. For Dart there is neither a suitable fuzzing engine nor detection. ClusterFuzzLite does not support Dart; a stand-in fuzzer only for the Python helper scripts would raise the score without making the app safer. The reasoning is in the repository.
- Branch protection and CI tests rise over time: since 19 November 2026 the ruleset `main-schutz` protects `main`, and every change runs through the required checks as a proposed change. Scorecard also rates the older commits, though.

## Standards and compliance

As of 22 November 2026. Status: **met** = the check runs in CI and was green, **partly met** = part is proven and the rest is listed as open, **target** = aimed for, not proven yet. Nothing is marked met without proof. This is neither legal advice nor a certification. Most evidence files are in German.

| Area | Standard or practice | Status | Evidence and open points |
|---|---|---|---|
| Accessibility | WCAG 2.2 AA | partly met | axe-core on every proposed change with no violations ([a11y.yml](.github/workflows/a11y.yml)). Screen reader testing and 400 % zoom are missing, see [ACCESSIBILITY.md](.github/ACCESSIBILITY.md) |
| Accessibility | EN 301 549 | target | Yardstick, no proof ([ACCESSIBILITY.md](.github/ACCESSIBILITY.md)) |
| Accessibility | BFSG | target | Whether the BFSG applies to this app and a statement is mandatory is being reviewed; draft in [docs/BARRIEREFREIHEIT.md](docs/BARRIEREFREIHEIT.md). If it applies, the MLBF in Magdeburg is the competent body ([mlbf-barrierefrei.de](https://www.mlbf-barrierefrei.de)) |
| Security | OpenSSF Scorecard | partly met | Runs weekly and on every push to `main` ([scorecard.yml](.github/workflows/scorecard.yml)); some checks cannot score fully, see [OpenSSF and seals](#openssf-and-seals) |
| Security | Signed releases (cosign, Sigstore) | target | The flow is in [release.yml](.github/workflows/release.yml), but no release exists yet; verification guide: [docs/RELEASE-VERIFIZIEREN.md](docs/RELEASE-VERIFIZIEREN.md) |
| Security | Provenance (GitHub attestation, SLSA build provenance) | target | As above: provable only with the first release. We do not claim a SLSA level |
| Security | SBOM (SPDX, CycloneDX) | target | Produced in the release flow ([release.yml](.github/workflows/release.yml)), no release yet |
| Security | CodeQL | partly met | GitHub Actions workflows on every proposed change, Kotlin and Java weekly; CodeQL does not support Dart ([codeql.yml](.github/workflows/codeql.yml)) |
| Security | Semgrep CE | partly met | Runs on every proposed change; Dart is not covered, `flutter analyze` covers it ([semgrep.yml](.github/workflows/semgrep.yml)) |
| Security | Trivy, OSV, gitleaks | met | Dependencies, configuration and git history, on every proposed change ([supply-chain.yml](.github/workflows/supply-chain.yml)) |
| Security | zizmor (workflow audit) | met | On every proposed change ([supply-chain.yml](.github/workflows/supply-chain.yml), rules in [zizmor.yml](.github/zizmor.yml)) |
| Privacy | GDPR | partly met | Favorites, history and settings stay on the device ([ADR 0001](docs/adr/0001-kein-backend-keine-konten.md)). The privacy policy is a draft with open placeholders; review by a lawyer is pending |
| Privacy | TDDDG, consent | partly met | Statistics and reach measurement start only after consent, withdrawal stops them ([docs/telemetry.md](docs/telemetry.md), tests `test/features/consent_storage_test.dart`, `google_consent_test.dart`). Legal review is pending. Flow: [Consent data flow](docs/en/consent-data-flow.md) |
| Legal | DDG (legal notice) | target | Draft text exists, the operator details are not filled in yet; the release build fails until then |
| Legal | MStV | target | The responsible person is planned as a required field but still open; a lawyer decides whether it applies |
| Quality | Tests and required checks | met | Test suite, format and analysis on every proposed change ([ci.yml](.github/workflows/ci.yml)); `main` is protected by a ruleset |
| Quality | Coverage | partly met | Measured in CI, no fixed threshold yet; target 100 % in `lib/` |
| Quality | Golden tests | partly met | Core components and some views in light and dark; all screens and widths are still open in the tracker |
| Quality | Load tests | target | None yet; planned against our own endpoints |

## Documentation

| Document | Content |
|---|---|
| [docs/en/README.md](docs/en/README.md) | English documentation entry, by audience |
| [docs/en/architecture.md](docs/en/architecture.md) | Layers, external services, platforms |
| [docs/en/release-flow.md](docs/en/release-flow.md) | From change to download |
| [docs/en/consent-data-flow.md](docs/en/consent-data-flow.md) | Consent for statistics and crash reports |
| [docs/en/glossary.md](docs/en/glossary.md) | Terms |
| [docs/EINRICHTUNG.md](docs/EINRICHTUNG.md) | Accounts and secrets for the operator (German) |
| [docs/FREIGABE-CHECKLISTE.md](docs/FREIGABE-CHECKLISTE.md) | Approvals, legal review, device tests, store texts (German) |
| [docs/ENTWICKLUNG.md](docs/ENTWICKLUNG.md) | Build, test, architecture (German) |
| [docs/hosting-uebersicht.md](docs/hosting-uebersicht.md) | Web hosting, cache, headers (German) |
| [docs/STORE-POLICIES.md](docs/STORE-POLICIES.md) | Store policies as a checklist per store, with sources and status |
| [.github/ACCESSIBILITY.md](.github/ACCESSIBILITY.md) | Accessibility: goal, state, known gaps, report a barrier (de/en) |
| [docs/RELEASE-VERIFIZIEREN.md](docs/RELEASE-VERIFIZIEREN.md) | Verify downloads: checksums, SBOM, signatures (German) |
| [docs/LIZENZEN-DRITTE.md](docs/LIZENZEN-DRITTE.md) | Licenses of libmpv, FFmpeg and other components (German) |
| [SECURITY.md](SECURITY.md) | Report a vulnerability |
| [CHANGELOG.md](CHANGELOG.md) | Changes per version |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributing |
| [SUPPORT.md](SUPPORT.md) | Where to get help |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Code of conduct |
| [packaging/README.md](packaging/README.md) | Installers, store packages, signing |

The full inventory, with gaps, is in [docs/en/inventory.md](docs/en/inventory.md).

## Credits

Developed by [Tim Hauke](https://github.com/VectoDE) for LineFM Studios. LINEFM and this app belong to LineFM Studios.

Made by [Tim Hauke](https://github.com/VectoDE) with ♥. LineFM is an offering of RadioGruppe Deutschland on behalf of the LINEFM Gruppe. LineFM Studios belongs to Julian Gebauer. The stations are broadcast through laut.fm. Fonts: Poppins and Syncopate (license texts in the app).

## Rights

**All rights reserved, no open-source license.** The repository has been public since 19 November 2026. You may read the source code and view it on GitHub. That gives you no right of use: use, copying, modification and distribution need the written permission of the rights holder. The binding text is in [LICENSE](LICENSE) (German).

LINEFM, the logos, the app icon and the station names are trademarks and property of the operator or the respective owners (among others LINEFM, Radio3FM, FobFM, RadioGruppe Deutschland, laut.fm) and are excluded from this grant of rights. Android, Google Play, Android Auto and Chromecast are trademarks of Google; Apple, iOS, CarPlay and AirPlay of Apple; Windows and Microsoft Store of Microsoft. These names are used only to describe compatibility.
