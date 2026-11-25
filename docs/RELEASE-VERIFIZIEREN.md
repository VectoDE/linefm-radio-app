# Release-Dateien prüfen

So prüfst du, dass eine Datei aus einem GitHub-Release von LINEFM Radio unverändert ist und aus diesem Repository stammt. Welche Prüfung greift, hängt davon ab, was beim Release eingerichtet war; die Zusammenfassung des Release-Laufs (Actions > Release) sagt es für jede Version.

## 1. Prüfsummen (immer vorhanden)

Jedes Release enthält `SHA256SUMS.txt` mit der SHA-256-Summe jeder Datei.

Linux und macOS, im Ordner mit den Downloads:

```sh
sha256sum -c SHA256SUMS.txt --ignore-missing
# macOS ohne coreutils:
shasum -a 256 -c SHA256SUMS.txt --ignore-missing
```

Windows (PowerShell), je Datei:

```powershell
(Get-FileHash .\linefm-radio-X.Y.Z-windows-x64.zip -Algorithm SHA256).Hash
# mit der Zeile in SHA256SUMS.txt vergleichen (Gross-/Kleinschreibung egal)
```

Die Prüfsummen zeigen, dass die Datei beim Download nicht beschädigt wurde. Sie beweisen allein nicht die Herkunft, denn wer das Release ändern kann, kann auch `SHA256SUMS.txt` ändern. Dafür gibt es die Schritte 2 bis 4.

## 2. Herkunft (GitHub-Attestierung)

Der Release-Workflow legt für jede Datei aus `SHA256SUMS.txt` eine Build-Provenance an (`actions/attest-build-provenance`, über Sigstore). Sie belegt, welcher Workflow aus welchem Commit die Datei gebaut hat. Dazu kommt eine SBOM-Attestierung. Das Repository ist öffentlich, die Attestierung ist deshalb Pflicht: Scheitert sie, bricht das Release ab.

```sh
gh attestation verify linefm-radio-X.Y.Z-android.apk -R VectoDE/linefm-radio-app
# strenger: nur Builds aus dem Release-Workflow auf main
gh attestation verify linefm-radio-X.Y.Z-android.apk -R VectoDE/linefm-radio-app \
  --signer-workflow VectoDE/linefm-radio-app/.github/workflows/release.yml \
  --source-ref refs/heads/main
```

## 3. Signatur mit cosign (keyless, Sigstore)

Zu jeder Release-Datei und zu `SHA256SUMS.txt` liegt ein Bundle `<datei>.sigstore.json`. Signiert hat der Release-Workflow selbst, ohne festen Schlüssel: Sigstore stellt ein kurzlebiges Zertifikat auf die Identität des Workflows aus und trägt die Signatur in das öffentliche Transparenzlog Rekor ein. Der Workflow prüft jede Signatur direkt nach dem Signieren.

Prüfen mit [cosign](https://docs.sigstore.dev/cosign/system_config/installation/) ab Version 3. Der Workflow signiert mit cosign 3 im neuen Bundle-Format (Standard seit [cosign v3.0.0](https://github.com/sigstore/cosign/releases/tag/v3.0.0)). Ob ältere 2.x-Versionen diese Bundles prüfen können, ist nicht belegt.

```sh
cosign verify-blob \
  --bundle linefm-radio-X.Y.Z-android.apk.sigstore.json \
  --certificate-identity 'https://github.com/VectoDE/linefm-radio-app/.github/workflows/release.yml@refs/heads/main' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  linefm-radio-X.Y.Z-android.apk
```

Erwartete Ausgabe: `Verified OK`. Am sichersten prüfst du zuerst `SHA256SUMS.txt` mit seinem Bundle und danach die Downloads mit `sha256sum -c` (Schritt 1).

Seit #104 entsteht jedes Release beim Merge auf `main`. Die Identität ist deshalb für alle Versionen gleich. Welche Version eine Datei ist, belegen ihr Name und `SHA256SUMS.txt`; aus welchem Commit sie stammt, zeigt die Attestierung (Schritt 2).

## 4. GPG-Signatur (optional)

Hat der Betreiber einen GPG-Schlüssel hinterlegt (Secrets `GPG_PRIVATE_KEY` und `GPG_PASSPHRASE`), liegt am Release zusätzlich `SHA256SUMS.txt.asc`. Fehlt die Datei, war kein Schlüssel eingerichtet. Den Fingerabdruck nennt die Zusammenfassung des Release-Laufs.

```sh
# öffentlichen Schlüssel des Betreibers einmalig importieren (Quelle: vom Betreiber veröffentlicht)
gpg --import linefm-release-key.asc
gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt --ignore-missing
```

`Good signature` allein reicht nicht: Vergleiche den angezeigten Fingerabdruck mit dem, den der Betreiber veröffentlicht hat.

## 5. Stückliste (SBOM)

`linefm-radio-<version>-sbom.spdx.json` listet die Abhängigkeiten im SPDX-Format (erzeugt mit Anchore Syft aus dem Quelltext). Sie lässt sich mit üblichen Werkzeugen auf bekannte Schwachstellen prüfen, zum Beispiel:

```sh
osv-scanner scan source -L linefm-radio-X.Y.Z-sbom.spdx.json
```

## 6. Signaturen der Plattformen

Diese Signaturen gibt es nur, wenn beim Build die passenden Secrets gesetzt waren (siehe [secrets.md](secrets.md)).

| Datei | Prüfung |
|---|---|
| Android `*.apk` | `apksigner verify --print-certs linefm-radio-X.Y.Z-android.apk` (Android SDK Build-Tools). Die GitHub-Release-APK ist mit dem Upload-Schlüssel signiert, Play-Installationen mit dem App-Signaturschlüssel. Beide SHA-256-Fingerprints stehen in `/.well-known/assetlinks.json` der Web-Version (Variable `ANDROID_CERT_SHA256`), sobald diese live ist. |
| Android `*.aab` | `jarsigner -verify linefm-radio-X.Y.Z-android.aab` (der Upload-Schlüssel; Google signiert für die Auslieferung neu). |
| Windows (`*.exe` im ZIP und der Installer `*-windows-x64-setup.exe`) | `signtool verify /pa /v <datei>` oder Eigenschaften > Digitale Signaturen. |
| macOS `*.dmg` | `spctl -a -t open --context context:primary-signature -v linefm-radio-X.Y.Z-macos.dmg` und `xcrun stapler validate linefm-radio-X.Y.Z-macos.dmg` (signiert und notarisiert). |

## Was wir nicht versprechen

- **Bit-gleiche Builds:** Die Build-Workflows setzen `SOURCE_DATE_EPOCH` auf die Zeit des Commits. Das macht Zeitstempel dort gleich, wo die Werkzeuge den Wert auswerten. Ob zwei Builds desselben Commits bit-gleich sind, haben wir nicht geprüft. Flutter, Gradle, Xcode und die Packer schreiben teils eigene Zeitstempel und Pfade. Verlass dich deshalb auf die Schritte 1 bis 3, nicht auf einen eigenen Nachbau.
- **Langzeit-Schlüssel:** cosign arbeitet ohne festen Schlüssel. Die Signatur hängt an der Identität des Workflows im Repository. Wer Schreibrechte auf `release.yml` und Tags hat, kann gültig signieren. Deshalb schützen die Rulesets `main-schutz` (Branch) und `release-tags` (Tags) diese Stellen.

Fehler oder Zweifel an einer Datei bitte vertraulich melden, wie in [SECURITY.md](../SECURITY.md) beschrieben.
