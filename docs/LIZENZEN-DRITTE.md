# Lizenzen von Bausteinen Dritter (libmpv, FFmpeg und weitere)

LINEFM Radio steht selbst unter "Alle Rechte vorbehalten". Die App enthält aber fremde Bausteine mit eigenen Lizenzen. Diese Seite sagt, welche das auf Linux und Windows sind und was der Betreiber tun muss. Sie ist eine technische Vorprüfung und ersetzt keine Rechtsberatung.

## Warum das ein Thema ist

Windows und Linux spielen Audio über `just_audio_media_kit` und `media_kit`. Das nutzt **libmpv**, und libmpv nutzt **FFmpeg** zum Dekodieren. Beide sind freie Software mit Copyleft-Regeln:

- **LGPL** (zum Beispiel FFmpeg im Standard-Build, libplacebo): Die Bibliothek darf in proprietärer Software stecken, wenn sie austauschbar bleibt (dynamisch gelinkt), der Lizenztext beiliegt und die Quelle der Bibliothek genannt wird.
- **GPL** (mpv und FFmpeg, sobald GPL-Teile eingeschaltet sind): Wird ein Programm mit einer GPL-Bibliothek zusammen ausgeliefert und gilt als ein Werk, müsste das ganze Programm unter der GPL stehen. Für eine proprietäre App wäre das ein Problem.

Ob eine dynamisch geladene GPL-Bibliothek die App zu einem "Werk unter der GPL" macht, ist juristisch umstritten. Der sichere Weg ist, nur LGPL-Builds auszuliefern.

## Stand je Plattform

| Plattform | Quelle von libmpv und FFmpeg | Lizenz laut Stand der Prüfung | Offen |
|---|---|---|---|
| Linux (Flatpak) | im Manifest `packaging/flathub/de.linefm.app.yml` gebaut: mpv 0.42.0, FFmpeg 8.0, libass, libplacebo | FFmpeg ohne `--enable-gpl`: LGPL 2.1 oder neuer. libass: ISC. libplacebo: LGPL 2.1 oder neuer. **mpv: standardmäßig GPL 2 oder neuer** | mpv mit `-Dgpl=false` bauen (siehe unten), im Manifest vorgesehen, **nicht getestet** |
| Linux (Snap) | Ubuntu-Pakete `libmpv2` und `libmpv-dev` | Debian und Ubuntu bauen mpv und libmpv in der Regel mit GPL-Teilen. Genaue Lizenz laut Paket-Metadaten nachlesen | prüfen, `apt-cache show libmpv2` und `/usr/share/doc/libmpv2/copyright` im Snap |
| Linux (Tarball) | System-libmpv des Nutzers | liegt beim Nutzer, wir liefern sie nicht mit | in der Anleitung als Voraussetzung nennen |
| Windows | vorgebaute `libmpv-2.dll` des Projekts media-kit (Audio-Build vom 24.09.2023), geladen vom Paket `media_kit_libs_windows_audio` | **aus dem Paket nicht ersichtlich.** mpv ist standardmäßig GPL, ein LGPL-Build ist möglich | Lizenz des Builds beim Upstream nachlesen (media-kit/libmpv-win32-audio-build), Ergebnis hier eintragen |
| Android, iOS, macOS, Web | nutzen die Plattform-Player (ExoPlayer, AVPlayer, HTML-Audio) | nicht betroffen | keine |

## Was zu tun ist

- [ ] **Flatpak:** `-Dgpl=false` bei mpv setzen und prüfen, dass Wiedergabe von laut.fm-Streams (MP3/AAC/Ogg) weiter läuft. Das Manifest enthält die Option bereits mit Kommentar. Der Bau auf Linux fehlt noch.
- [ ] **Windows:** Lizenz der mitgelieferten `libmpv-2.dll` klären. Ist sie GPL, gibt es drei Wege: LGPL-Build von libmpv verwenden, die App unter einer GPL-kompatiblen Lizenz anbieten (widerspricht "Alle Rechte vorbehalten") oder Windows auf einen anderen Player umstellen. Bis zur Klärung Windows nicht im Store veröffentlichen.
- [ ] **Snap:** Lizenz der Ubuntu-Pakete prüfen. Ist libmpv2 GPL, gilt dasselbe wie bei Windows.
- [ ] **Lizenztexte beilegen:** Für jede ausgelieferte LGPL- oder GPL-Bibliothek den Lizenztext und einen Hinweis auf die Quelle ins Paket legen (Flatpak: `/app/share/licenses/`, Windows-Installer: Ordner `licenses`, Tarball: Ordner `licenses`). Der Hinweis nennt Name, Version, Lizenz und die Adresse des Quellcodes (zum Beispiel `https://github.com/mpv-player/mpv`, `https://ffmpeg.org`).
- [ ] **Austauschbarkeit:** Die Bibliotheken bleiben als eigene Dateien (`.so`, `.dll`) liegen und werden nicht in die ausführbare Datei gelinkt. So kann ein Nutzer sie ersetzen. In der Dokumentation kurz erwähnen.
- [ ] **In der App:** Der Bildschirm mit den Lizenzen (Einstellungen > Über) listet die Dart-Pakete automatisch. Für native Bibliotheken fehlt dort der Eintrag. Wunsch an die Entwicklung: libmpv, FFmpeg, libass, libplacebo mit Lizenz und Quelle als zusätzliche Einträge aufnehmen.

## Weitere Bausteine

- **Google Cast SDK** (Android, über `flutter_chrome_cast`): Das SDK gehört zu den Google Play-Diensten und hat eigene Nutzungsbedingungen. Es sendet nach Angabe von Google Nutzungsdaten, siehe Datenschutzerklärung, Abschnitt 7.
- **Schriften:** Poppins steht unter der Open Font License, Syncopate unter Apache 2.0. Beide Lizenztexte liegen in der App (`assets/fonts/`).
- **Ersatzschriften der Web-Version** (Noto-Familien wie Noto Color Emoji, Noto Sans, Noto Sans Symbols, Noto Sans SC/TC/HK/JP/KR sowie Roboto): SIL Open Font License 1.1. Quelle ist Google Fonts (`fonts.gstatic.com`), die Dateien liegen aber auf unserem eigenen Server unter `assets/fonts/fallback/`. Der Browser lädt sie nur, wenn ein Text Zeichen enthält, die Poppins und Syncopate nicht haben. Welche Dateien es sind und welche SHA-256-Prüfsummen sie haben, steht in `tool/font_fallback.lock.json`. Die OFL erlaubt Weitergabe und Selbsthosting, solange die Schriften nicht einzeln verkauft werden und der Lizenztext beiliegt. Das Werkzeug legt den OFL-Text mit Urheberangaben als `assets/fonts/fallback/OFL.txt` daneben.
- **Flutter und Dart-Pakete:** überwiegend BSD, MIT und Apache 2.0. Die vollständige Liste erzeugt Flutter beim Build (Datei `assets/NOTICES` im Web).

Diese Liste ist ein Stand vom 19.11.2026. Bei jedem Update von `media_kit_libs_*`, mpv oder FFmpeg neu prüfen.
