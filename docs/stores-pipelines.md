# Store- und Deploy-Pipelines

Alle Abläufe laden die Dateien aus dem GitHub-Release (gebaut, geprüft und attestiert von `release.yml`) und haben dieselben Regeln: Auslöser ist das Release oder ein manueller Start mit Tag, jeder Schritt ist über Secrets abgesichert, und ohne Secrets wird sauber übersprungen. Die Liste aller Secrets steht in [secrets.md](secrets.md).

| Workflow | Ziel | Auslöser | Läuft nur, wenn |
|---|---|---|---|
| `store-google.yml` | Google Play, Spur `internal` oder `alpha` (geschlossener Test) | jeder Release-Tag, manuell | `PLAY_SERVICE_ACCOUNT_JSON` gesetzt und AAB signiert |
| `store-microsoft.yml` | Microsoft Store (MSIX mit Store-Identität, `msstore`) | Endversionen, manuell | `MS_STORE_*` gesetzt |
| `store-snap.yml` | Snap Store, Kanal `edge` | jeder Release-Tag, manuell | `SNAPCRAFT_STORE_CREDENTIALS` gesetzt |
| `flathub-prep.yml` | Artefakt mit gefülltem Flatpak-Manifest und Einreichungsvorlage | Endversionen, manuell | immer (keine Secrets nötig). Reicht **nichts** bei Flathub ein |
| `store-apple.yml` | TestFlight (iOS), Mac App Store | Endversionen, manuell | `APPLE_PUBLISHING_ENABLED=true` und alle Apple-Secrets |
| `deploy-web.yml` | Cloudflare Pages, SSH (nginx/Traefik), Plesk | Endversionen, manuell | Ziel in `WEB_DEPLOY_TARGETS` bzw. Eingabe `targets`, Secrets vollständig, Umgebung `production` freigegeben |

`release.yml` ruft diese Workflows nach dem Anlegen des Releases auf. Vorabversionen (alpha, beta, rc) gehen in keinen Store und nicht ins Web; das passiert erst ab `1.0.0`.

## Manuell starten

Actions > Workflow wählen > "Run workflow", Tag eintragen (ein Release mit diesem Tag muss existieren). Mit der GitHub-CLI: `gh workflow run store-google.yml -f tag=vX.Y.Z -f track=internal`.

## Reihenfolge für die Erstveröffentlichung

1. Release-Tag setzen (nur mit Freigabe des Inhabers). `release.yml` baut, signiert, veröffentlicht.
2. **Google Play:** Neue Apps müssen mit Status `draft` starten (Standard der Pipeline). In der Play Console den Entwurf prüfen und zur Überprüfung senden. Privates Konto: erst 14 Tage geschlossener Test mit mindestens 12 Testern (Spur `alpha`).
3. **Microsoft Store:** Die Einreichung bleibt Entwurf im Partner Center (`commit=false`). Prüfen, dann dort abschicken oder den Workflow mit `commit=true` neu starten.
4. **Snap:** Auf `edge` testen, dann in der Snap-Store-Weboberfläche oder per Workflow mit Kanal `candidate`/`stable` anheben.
5. **Flathub:** Artefakt `flathub-manifest-<version>` herunterladen und die Hinweise in [packaging/flathub/README.md](../packaging/flathub/README.md) befolgen. Voraussetzung: Repository öffentlich.
6. **Web:** Umgebung `production` mit Genehmigern anlegen, Secrets eintragen, `WEB_DEPLOY_TARGETS` setzen.

## Bekannte Grenzen (offen)

- **Alles ungetestet gegen echte Konten.** Es gibt noch kein Play-, Partner-Center-, Snap-, Cloudflare- oder Apple-Konto und keinen Zielserver. `actionlint`, `zizmor` und `yamllint` sind sauber, der erste echte Lauf je Ziel ist ein Test und sollte beobachtet werden.
- **Snap:** `snapcraft` baut aus dem Quelltext mit dem Flutter-Plugin. `config/app.json` (Telemetrie, Web-URL) fließt dabei nicht ein, und die Flutter-Version ist nicht auf 3.50.0 festgelegt. Ein Snap aus dieser Pipeline läuft mit Standardwerten. Eine Änderung an `packaging/snap/snapcraft.yaml` (Paket P26) wäre nötig. Zusätzlich ist ungeklärt, ob Tray und MPRIS unter strikter Absicherung laufen.
- **Apple:** Der Ablauf nutzt `flutter build`, `xcodebuild`, `productbuild` und `altool` ohne fastlane (dadurch kein Ruby und kein `Gemfile.lock` nötig). Signiert wird manuell mit hinterlegten Zertifikaten und Profilen. Die Profile für App und Widget müssen zu den Bundle-IDs `de.linefm.app` und `de.linefm.app.widget` passen. Für das Mac-App-Store-Paket ergänzt die Pipeline die Team-Kennung in den Entitlements.
- **Microsoft Store:** Die Reihenfolge von `msstore publish` mit `--inputFile` ohne Projektordner ist anhand der Dokumentation (Stand Oktober 2026) umgesetzt und nicht erprobt.
- **Private Repositories:** Artefakt-Attestierungen sind in `release.yml` nur mit GitHub Enterprise Cloud möglich. Das betrifft diese Pipelines nicht, sie laden nur die Release-Dateien.
- **Actions-Kontingent:** macOS-Minuten zählen im privaten Repo zehnfach. Deshalb prüft ein billiger Ubuntu-Job zuerst die Secrets, und die macOS-Jobs starten gar nicht erst ohne `APPLE_PUBLISHING_ENABLED`.
