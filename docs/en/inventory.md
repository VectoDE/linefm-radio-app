# Documentation inventory

As of 28 November 2026. Basis: `README.md`, `docs/` and the documents in the repository root. The "Audience" column names who mainly reads the document: **L** listeners, **O** operator, **D** developers and admins, **A** press, partners and auditors.

## Existing

| Document | Audience | Module | Note |
|---|---|---|---|
| `README.md`, `README.en.md` | all | Entry | German and English |
| `.github/ACCESSIBILITY.md` | L, A | Users | bilingual |
| `docs/BARRIEREFREIHEIT.md` | L, A | Users | draft, German |
| `docs/EINRICHTUNG.md` | O | Operators | very long, a checkbox list per account, German |
| `docs/FREIGABE-CHECKLISTE.md` | O | Operators | approvals and device tests, German |
| `docs/KONFIGURATION.md`, `docs/SENDER-VERWALTEN.md` | O | Operators | reference for `config/`, German |
| `docs/BAUEN-UND-STARTEN.md` | O, D | Operators | building on GitHub and locally, German |
| `docs/stores-pipelines.md`, `docs/secrets.md` | O | Operators | flows and secrets, German |
| `docs/STORE-TEXTE.md`, `docs/STORE-RICHTLINIEN.md`, `docs/STORE-POLICIES.md`, `docs/STORE-DATENSCHUTZANGABEN.md` | O | Reference | policies also in English |
| `docs/ENTWICKLUNG.md` | D | Development | structure, tests, platforms, German |
| `docs/PERFORMANCE.md`, `docs/GERAETETESTS.md`, `docs/BUILD_WARNINGS.md` | D | Development | measurements and reports, German |
| `docs/hosting-*.md` | D, O | Operations | nginx, Traefik, Cloudflare, Plesk, German |
| `docs/telemetry.md` | D, A | Operations | statistics, crash reports, German |
| `docs/betrieb/` | O, D | Operations, security | runbook, incident, threat model, German |
| `docs/RELEASE-VERIFIZIEREN.md` | A, D | Security | checksums, signatures, SBOM, German |
| `docs/VERARBEITUNGSVERZEICHNIS.md`, `docs/ANWALT-UNTERLAGEN.md`, `docs/LIZENZEN-DRITTE.md` | O, A | Legal | German |
| `docs/WETTBEWERB.md` | O | Reference | German |
| `docs/adr/` | D, A | Decisions | eight entries, German |
| `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md` | all | Community | |

## New in this directory

`docs/de/` and `docs/en/` with the entry page, inventory, architecture, consent data flow, release flow and glossary.

## Gaps

| Gap | Module | Note |
|---|---|---|
| User guide with screenshots (light and dark) | Users | CI screenshots are missing |
| FAQ | Users | so far only in Discussions |
| Configuration reference with all keys in one place | Reference | spread over `config/*.example.yaml` and `KONFIGURATION.md` |
| Platform overview (features per platform) | Development | only the short table in the architecture page |
| Test strategy and CI overview | Development | workflows are not described in one place |
| Updater and live operation as one continuous operator path | Operators | parts in `stores-pipelines.md` and `betrieb/` |
| Designed graphics in the app's look (SVG) | all | Mermaid only so far |
| English versions of the operator and developer documents | all | only the entry pages and the new pages |
| Consistent English file names | all | follows with the rename |
| Link check and completeness test in CI, mirroring to the wiki and Pages | all | |
| Read-through by a lay persona | all | |
