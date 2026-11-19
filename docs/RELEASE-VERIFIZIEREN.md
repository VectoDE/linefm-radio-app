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
(Get-FileHash .\linefm-radio-1.2.3-windows-x64.zip -Algorithm SHA256).Hash
# mit der Zeile in SHA256SUMS.txt vergleichen (Gross-/Kleinschreibung egal)
```

Die Prüfsummen zeigen, dass die Datei beim Download nicht beschädigt wurde. Sie beweisen allein nicht die Herkunft, denn wer das Release ändern kann, kann auch `SHA256SUMS.txt` ändern. Dafür gibt es Schritt 2.

## 2. Herkunft (Attestierung, wenn vorhanden)

Der Release-Workflow lässt für `SHA256SUMS.txt` eine Build-Provenance und eine SBOM-Attestierung über Sigstore erzeugen. GitHub erlaubt das nur in öffentlichen Repositories (oder mit Enterprise Cloud). Steht in der Zusammenfassung „Build-Provenance: success“, prüfst du so:

```sh
gh attestation verify linefm-radio-1.2.3-android.apk -R VectoDE/linefm-radio-app
```

Ohne Attestierung (privates Repository) bleibt nur Schritt 1 plus die Plattform-Signaturen aus Schritt 4.

## 3. Stückliste (SBOM)

`linefm-radio-<version>-sbom.spdx.json` listet die Abhängigkeiten im SPDX-Format (erzeugt mit Anchore Syft aus dem Quelltext). Sie lässt sich mit üblichen Werkzeugen auf bekannte Schwachstellen prüfen, zum Beispiel:

```sh
osv-scanner --sbom linefm-radio-1.2.3-sbom.spdx.json
```

## 4. Signaturen der Plattformen

Diese Signaturen gibt es nur, wenn beim Build die passenden Secrets gesetzt waren (siehe [secrets.md](secrets.md)).

| Datei | Prüfung |
|---|---|
| Android `*.apk` | `apksigner verify --print-certs linefm-radio-1.2.3-android.apk` (Android SDK Build-Tools). Der SHA-256-Fingerprint muss zu dem in `/.well-known/assetlinks.json` der Web-Version passen, sobald diese live ist. |
| Android `*.aab` | `jarsigner -verify linefm-radio-1.2.3-android.aab` (der Upload-Schlüssel; Google signiert für die Auslieferung neu). |
| Windows (`*.exe` im ZIP) | `signtool verify /pa /v linefm_radio.exe` oder Eigenschaften > Digitale Signaturen. |
| macOS `*.dmg` | `spctl -a -vv -t install linefm-radio-1.2.3-macos.dmg` und `xcrun stapler validate linefm-radio-1.2.3-macos.dmg` (signiert und notarisiert). |

## Was wir nicht versprechen

- **Bit-gleiche Builds:** Die Build-Workflows setzen `SOURCE_DATE_EPOCH` auf die Zeit des Commits. Das macht Zeitstempel dort gleich, wo die Werkzeuge den Wert auswerten. Ob zwei Builds desselben Commits bit-gleich sind, haben wir nicht geprüft. Flutter, Gradle, Xcode und die Packer schreiben teils eigene Zeitstempel und Pfade. Verlass dich deshalb auf Schritt 1 und 2, nicht auf einen eigenen Nachbau.
- **Signierte Release-Dateien als Ganzes:** Es gibt keine eigene GPG- oder Sigstore-Signatur je Datei. Die Herkunft belegt die Attestierung aus Schritt 2, sofern vorhanden.

Fehler oder Zweifel an einer Datei bitte vertraulich melden, wie in [SECURITY.md](../SECURITY.md) beschrieben.
