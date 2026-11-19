# iOS: ExportOptions

Zwei Vorlagen, beide mit Platzhaltern:

| Datei | Zweck | `method` |
|---|---|---|
| `ExportOptions-appstore.plist.template` | App Store Connect / TestFlight | `app-store-connect` |
| `ExportOptions-adhoc.plist.template` | Testgeraete (Ad Hoc) | `release-testing` |

`app-store-connect` und `release-testing` sind die Namen ab Xcode 15.3. Die alten Werte `app-store` und `ad-hoc` funktionieren noch, sind aber veraltet.

Platzhalter:

| Platzhalter | Quelle |
|---|---|
| `{{APPLE_TEAM_ID}}` | Apple Developer Account, Mitgliedschaft (10 Zeichen), Secret `APPLE_TEAM_ID` |
| `{{PROVISIONING_PROFILE_APPSTORE_NAME}}` | Name des App-Store-Profils fuer `de.linefm.app` (bei fastlane match: `match AppStore de.linefm.app`) |
| `{{PROVISIONING_PROFILE_ADHOC_NAME}}` | Name des Ad-Hoc-Profils (`match AdHoc de.linefm.app`) |

Einsatz:

```bash
sed -e "s/{{APPLE_TEAM_ID}}/$APPLE_TEAM_ID/" \
    -e "s/{{PROVISIONING_PROFILE_APPSTORE_NAME}}/$PROFILE_NAME/" \
    packaging/ios/ExportOptions-appstore.plist.template > "$RUNNER_TEMP/ExportOptions.plist"
flutter build ipa --release --export-options-plist="$RUNNER_TEMP/ExportOptions.plist"
```

Die erzeugte Datei nicht committen. Die Apple-Pipeline (fastlane `match`/`gym`, Gate `APPLE_PUBLISHING_ENABLED`) liegt in P27. Das Ziel `destination: export` schreibt die IPA nur lokal, hochgeladen wird per `pilot`/`deliver`.
