# Packaging

Konfigurationen für die Verteilung außerhalb von `flutter build`. Gebaut werden die Artefakte von `.github/workflows/build.yml`, veröffentlicht von den Store-Pipelines. Hier liegt nur, was dafür pro Plattform gebraucht wird.

| Ordner | Inhalt | Verteilung |
|---|---|---|
| `windows/` | Inno-Setup-Skript, MSIX-/Store-Anleitung | GitHub Releases, Microsoft Store |
| `flathub/` | Flatpak-Manifest, Hinweise zu Flathub-Regeln | Flathub |
| `snap/` | `snapcraft.yaml` (strict, core24) | Snap Store |
| `macos/` | `create_dmg.sh`, Öffnen-Anleitung, DMG-Hintergrund | GitHub Releases (unsigniertes DMG) |
| `android/` | Signierung und `versionCode` | Google Play, APK/AAB im Release |
| `ios/` | `ExportOptions`-Vorlagen (App Store, Ad Hoc) | App Store Connect, Testgeräte |

Mac App Store: nicht Teil dieses Ordners. Vorbereitet sind Entitlements und Bundle-ID in `macos/` und die Pipeline `store-apple.yml` (hinter dem Schalter `APPLE_PUBLISHING_ENABLED`). Das unsignierte DMG hier ist die GitHub-Variante.

Alles Ungetestete ist in den jeweiligen Dateien markiert (Flatpak und Snap brauchen Linux, DMG braucht macOS, Inno Setup braucht Windows mit Inno Setup 6).
