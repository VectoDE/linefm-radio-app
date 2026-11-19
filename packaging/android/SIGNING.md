# Android: Signierung und Versionierung

## Signierung (`key.properties`)

`android/app/build.gradle.kts` signiert den Release-Build nur, wenn `android/key.properties` existiert. Ohne die Datei entsteht ein unsigniertes Release (so baut die CI ohne Secrets). `key.properties` und `*.jks` sind in `.gitignore` und duerfen nie committet werden.

### Upload-Schluessel erzeugen (einmalig, jaybelife)

```bash
keytool -genkeypair -v -storetype PKCS12 -keystore upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

Das Passwort sicher ablegen (Passwortmanager). Geht der Upload-Schluessel verloren, kann er ueber die Play Console zurueckgesetzt werden, solange Play App Signing aktiv ist (Standard bei neuen Apps).

### Lokal bauen

`android/key.properties` anlegen (Pfad von `storeFile` ist relativ zu `android/app/`):

```properties
storeFile=upload-keystore.jks
storePassword=<Passwort>
keyAlias=upload
keyPassword=<Passwort>
```

Die `.jks` nach `android/app/upload-keystore.jks` kopieren, dann `flutter build appbundle --release`.

### CI

`build.yml` (P25) schreibt beide Dateien aus diesen GitHub-Secrets, wenn sie gesetzt sind:

| Secret | Inhalt |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Store-Passwort |
| `ANDROID_KEY_ALIAS` | z. B. `upload` |
| `ANDROID_KEY_PASSWORD` | Schluessel-Passwort |

Der Upload nach Google Play (`PLAY_SERVICE_ACCOUNT_JSON`) gehoert zu P27.

## Versionierung (`versionCode`)

`versionName` und `versionCode` kommen aus Flutter (`flutter.versionName` / `flutter.versionCode`), also aus `pubspec.yaml`:

```yaml
version: 1.0.0+1   # <versionName>+<versionCode>
```

In der CI setzen `--build-name` und `--build-number` die Werte: `versionName` ist die Release-Version ohne Suffix, `versionCode` ist `github.run_number + BUILD_NUMBER_OFFSET` (Variable, Standard 100). Der `versionCode` waechst dadurch mit jedem Lauf. Google Play verlangt pro Upload einen hoeheren Wert als der bisher veroeffentlichte und maximal 2100000000.

Die Versionsnummer vor einem Release in `pubspec.yaml` anheben (Teil vor dem `+`). Der Teil nach dem `+` zaehlt nur fuer lokale Builds ohne `--build-number`.
