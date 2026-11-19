# Packaging

Konfigurationen fuer die Verteilung ausserhalb von `flutter build`. Gebaut werden die Artefakte von `.github/workflows/build.yml` (P25), veroeffentlicht von den Store-Pipelines (P27). Hier liegt nur, was dafuer pro Plattform gebraucht wird.

| Ordner | Inhalt | Verteilung |
|---|---|---|
| `windows/` | Inno-Setup-Skript, MSIX-/Store-Anleitung | GitHub Releases, Microsoft Store |
| `flathub/` | Flatpak-Manifest, Hinweise zu Flathub-Regeln | Flathub |
| `snap/` | `snapcraft.yaml` (strict, core24) | Snap Store |
| `macos/` | `create_dmg.sh`, Oeffnen-Anleitung, DMG-Hintergrund | GitHub Releases (unsigniertes DMG) |
| `android/` | Signierung und `versionCode` | Google Play, APK/AAB im Release |
| `ios/` | `ExportOptions`-Vorlagen (App Store, Ad Hoc) | App Store Connect, Testgeraete |

Mac App Store: nicht Teil dieses Ordners. Vorbereitet sind Entitlements und Bundle-ID in `macos/` (P17) und die Pipeline `store-apple.yml` (P27, hinter `APPLE_PUBLISHING_ENABLED`). Das unsignierte DMG hier ist die GitHub-Variante.

Alles Ungetestete ist in den jeweiligen Dateien markiert (Flatpak und Snap brauchen Linux, DMG braucht macOS, Inno Setup braucht Windows mit Inno Setup 6).
