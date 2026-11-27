# Lizenzen von Bausteinen Dritter (libmpv, FFmpeg und weitere)

LINEFM Radio steht selbst unter "Alle Rechte vorbehalten". Die App enthält aber fremde Bausteine mit eigenen Lizenzen. Diese Seite sagt, welche das auf Linux und Windows sind und was der Betreiber tun muss. Sie ist eine technische Vorprüfung und ersetzt keine Rechtsberatung.

## Warum das ein Thema ist

Windows und Linux spielen Audio über `just_audio_media_kit` und `media_kit`. Das nutzt **libmpv**, und libmpv nutzt **FFmpeg** zum Dekodieren. Beide sind freie Software mit Copyleft-Regeln:

- LGPL (zum Beispiel FFmpeg im Standard-Build, libplacebo): Die Bibliothek darf in proprietärer Software stecken, wenn sie austauschbar bleibt (dynamisch gelinkt), der Lizenztext beiliegt und die Quelle der Bibliothek genannt wird.
- GPL (mpv und FFmpeg, sobald GPL-Teile eingeschaltet sind): Wird ein Programm mit einer GPL-Bibliothek zusammen ausgeliefert und gilt als ein Werk, müsste das ganze Programm unter der GPL stehen. Für eine proprietäre App wäre das ein Problem.

Ob eine dynamisch geladene GPL-Bibliothek die App zu einem "Werk unter der GPL" macht, ist juristisch umstritten. Der sichere Weg ist, nur LGPL-Builds auszuliefern.

## Stand je Plattform

| Plattform | Quelle von libmpv und FFmpeg | Lizenz laut Stand der Prüfung | Offen |
|---|---|---|---|
| Linux (Flatpak) | im Manifest `packaging/flathub/de.linefm.app.yml` gebaut: mpv 0.42.0, FFmpeg 8.0, libass, libplacebo | **LGPL**: mpv mit `-Dgpl=false` (LGPL 2.1 oder neuer), FFmpeg ohne `--enable-gpl` und ohne `--enable-version3` (LGPL 2.1 oder neuer), libass ISC, libplacebo LGPL 2.1 oder neuer. Geprüft im Manifest am 27.11.2026 | Bau und Wiedergabe mit diesen Optionen auf Linux noch nicht getestet |
| Linux (Snap) | im Snap selbst gebaut (`packaging/snap/snapcraft.yaml`, Parts `ffmpeg`, `libplacebo`, `mpv`): mpv 0.42.0, FFmpeg 8.0, libplacebo v7.387.0, gleiche Quellen und Prüfsummen wie im Flatpak; libass aus Ubuntu (`libass9`). Die GPL-Pakete `libmpv2` und `libmpv-dev` aus Ubuntu werden nicht mehr verwendet | **LGPL**: mpv mit `-Dgpl=false` (LGPL 2.1 oder neuer), FFmpeg mit `--disable-gpl --disable-nonfree --enable-version3` (LGPL 3 oder neuer), libass ISC. Nachweis nur in CI: `store-snap.yml` entpackt den fertigen Snap und prüft mit `tool/check_native_lgpl.py` die eingebettete Bau-Konfiguration; der Job schlägt bei jedem GPL-Anteil fehl | Snap-Bau ist noch nie gelaufen (kein Linux-Build, kein Store-Konto). Erst der erste grüne Lauf bestätigt Bau, Wiedergabe und LGPL-Prüfung |
| Linux (Tarball) | System-libmpv des Nutzers | liegt beim Nutzer, wir liefern sie nicht mit | in der Anleitung als Voraussetzung nennen |
| Windows | vorgebaute `libmpv-2.dll` des Projekts media-kit (Audio-Build vom 24.09.2023, Archiv `mpv-dev-x86_64-20230924-git-652a1dd.7z`), geladen vom Paket `media_kit_libs_windows_audio` 1.0.9 | **LGPL**: mpv mit `-Dgpl=false` gebaut (LGPL 2.1 oder neuer), FFmpeg mit `--disable-gpl --disable-nonfree --enable-version3` (LGPL 3 oder neuer). Zusammen gilt damit praktisch die LGPL 3. Belege siehe Abschnitt "Windows: Prüfung der libmpv" | Lizenztexte und Quellenhinweis im Installer beilegen; anwaltlich bestätigen lassen |
| Android, iOS, macOS, Web | nutzen die Plattform-Player (ExoPlayer, AVPlayer, HTML-Audio) | nicht betroffen | keine |

## Windows: Prüfung der libmpv

Stand 27.11.2026. Keine Rechtsberatung, das Ergebnis lässt der Anwalt bestätigen.

**Woher die Datei kommt.** Das Paket `media_kit_libs_windows_audio` (Version 1.0.9 laut `pubspec.lock`, selbst MIT-lizenziert) lädt beim Windows-Build ein fertiges Archiv herunter und prüft dessen MD5-Summe. Aus `windows/CMakeLists.txt` des Pakets:

- Archiv: `mpv-dev-x86_64-20230924-git-652a1dd.7z`
- Adresse: <https://github.com/media-kit/libmpv-win32-audio-build/releases/download/2023-09-24/mpv-dev-x86_64-20230924-git-652a1dd.7z>
- MD5 des Archivs: `cd738e16e2a19626d7cfa48801524f8c`
- Release-Seite: <https://github.com/media-kit/libmpv-win32-audio-build/releases/tag/2023-09-24>, gebaut aus mpv-Commit [652a1dd](https://github.com/mpv-player/mpv/commit/652a1dd90711839acdccc08004056d25514ef2d8) (mpv v0.36.0-403)

Das Build-Repository `media-kit/libmpv-win32-audio-build` (abgeleitet von `zhongfly/mpv-winbuild`) hat selbst keine Lizenzangabe. Seine Paketdateien im Hauptzweig sind nicht verlässlich, weil sie sich nach dem Build geändert haben. Deshalb zählt die Datei selbst.

**Was in der DLL steht.** Die Bau-Konfiguration ist in jeder mpv- und FFmpeg-Bibliothek als Text eingebettet. Ausgelesen aus der beim lokalen Windows-Build entstandenen `build/windows/x64/libmpv/libmpv-2.dll` (14,8 MB, MD5 `4eda7466f01800ef8a35ea6587a2fa96`):

- mpv: `Configuration: -Dgpl=false -Db_lto=true -Db_ndebug=true -Dlibmpv=true ... -Dlua=disabled -Djavascript=enabled -Dlibarchive=enabled -Dlcms2=enabled -Dopenal=enabled -Dgl=disabled ...`, Version `mpv v0.36.0-403-g652a1dd907`
- FFmpeg: `--disable-gpl --disable-nonfree --enable-version3 --enable-static --disable-shared ...`
- FFmpeg meldet für alle Teilbibliotheken: `libavcodec license: LGPL version 3 or later` (ebenso libavfilter, libavformat, libavutil, libswresample, libswscale)

So lässt sich das nachprüfen (Python, ohne Zusatzwerkzeuge):

```sh
python -I -c "import re,sys; b=open(sys.argv[1],'rb').read(); [print(m.group().decode()[:200]) for m in re.finditer(rb'(Configuration: -D[ -~]{20,}|lib[a-z]+ license: [ -~]+|--disable-gpl[ -~]{0,60})', b)]" build/windows/x64/libmpv/libmpv-2.dll
```

**Bedeutung.** Mit `-Dgpl=false` steht mpv unter der LGPL 2.1 oder neuer (siehe [mpv: Copyright](https://github.com/mpv-player/mpv/blob/master/Copyright)). FFmpeg mit `--enable-version3` und ohne `--enable-gpl` steht unter der LGPL 3 oder neuer (siehe [FFmpeg: License and Legal Considerations](https://ffmpeg.org/legal.html)). Weil FFmpeg statisch in dieselbe DLL gelinkt ist, gilt für die DLL als Ganzes die LGPL 3. Ebenfalls statisch enthalten sind unter anderem zlib, libpng, libjpeg-turbo, libarchive, lcms2, OpenAL Soft (LGPL 2 oder neuer) und mujs (ISC). Keine davon ist GPL.

**Pflichten bei LGPL 3** (Kurzfassung, Anwalt bestätigt): Lizenztext von LGPL 3 und GPL 3 beilegen, Hinweis auf die verwendete Bibliothek und Quelle (Adresse oben plus mpv- und FFmpeg-Quellcode), die DLL als eigene, austauschbare Datei ausliefern (ist so), kein Verbot von Reverse Engineering zur Fehlersuche an der Bibliothek in den Nutzungsbedingungen. Den letzten Punkt prüft der Anwalt gegen die `LICENSE` des Repos.

**Bei jedem Update** von `media_kit_libs_windows_audio` Adresse und MD5 in dessen `CMakeLists.txt` vergleichen und die eingebettete Konfiguration neu auslesen.

## Was zu tun ist

- [ ] **Flatpak:** `-Dgpl=false` ist im Manifest gesetzt, FFmpeg ohne GPL (geprüft 27.11.2026). Prüfbau in CI: `flatpak-check.yml` baut das Flatpak bei jedem Änderungsvorschlag am Manifest mit dem lokalen Linux-Bundle, prüft libmpv/FFmpeg mit `tool/check_native_lgpl.py` und die Dateien unter `/app/share/licenses/de.linefm.app/`. Offen: erster grüner Lauf und Test der Wiedergabe von laut.fm-Streams (MP3/AAC/Ogg).
- [x] **Windows:** Lizenz der mitgelieferten `libmpv-2.dll` geprüft (27.11.2026): LGPL-Build, kein GPL-Anteil eingeschaltet. Belege im Abschnitt "Windows: Prüfung der libmpv". Offen bleibt das Beilegen der Lizenztexte (Punkt unten) und die anwaltliche Bestätigung.
- [ ] **Snap:** Auf selbst gebaute LGPL-Bibliotheken umgestellt (27.11.2026), CI-Prüfung `tool/check_native_lgpl.py` im Job `store-snap.yml`. Offen: erster Snap-Bau in CI und Test der Wiedergabe. Die frühere Freigabesperre wegen der GPL-Pakete aus Ubuntu entfällt, sobald dieser Lauf grün ist.
- [x] **Lizenztexte beilegen:** LGPL 3, GPL 3 und der Quellenhinweis `NATIVE-LIBRARIES.txt` liegen in `assets/licenses/`. Sie stecken damit in jedem Build (Flutter-Assets), werden unter Windows zusätzlich nach `licenses/` neben die EXE installiert (`windows/CMakeLists.txt`) und vom Installer mitgepackt (`installer/windows/build.ps1`); im Flatpak zusätzlich unter `/app/share/licenses/de.linefm.app/`. Der Test `test/tool/native_licenses_files_test.dart` prüft das in CI. Den Wortlaut des Quellcode-Angebots in `NATIVE-LIBRARIES.txt` prüft der Anwalt.
- [ ] **Austauschbarkeit:** Die Bibliotheken bleiben als eigene Dateien (`.so`, `.dll`) liegen und werden nicht in die ausführbare Datei gelinkt. So kann ein Nutzer sie ersetzen. In der Dokumentation kurz erwähnen.
- [x] **In der App:** Auf Windows und Linux listet die Lizenzseite libmpv, FFmpeg, libass und libplacebo mit Lizenz und Quelle sowie die vollen Texte von LGPL 3, GPL 3 und den Quellenhinweis (`lib/ui/theme/native_licenses.dart`). Die Angaben gelten für Windows, Flatpak und Snap.

## Weitere Bausteine

- Google Cast SDK (Android, über `flutter_chrome_cast`): Das SDK gehört zu den Google Play-Diensten und hat eigene Nutzungsbedingungen. Es sendet nach Angabe von Google Nutzungsdaten, siehe Datenschutzerklärung, Abschnitt 7. Upstream-Punkt: Auf Android kann das Plugin das SDK beim Beenden der App initialisieren, auch ohne Cast-Nutzung (Details in [ENTWICKLUNG.md](ENTWICKLUNG.md), Abschnitt Google Cast).
- Schriften: Poppins steht unter der Open Font License, Syncopate unter Apache 2.0. Beide Lizenztexte liegen in der App (`assets/fonts/`).
- Ersatzschriften der Web-Version (Noto-Familien wie Noto Color Emoji, Noto Sans, Noto Sans Symbols, Noto Sans SC/TC/HK/JP/KR sowie Roboto): SIL Open Font License 1.1. Quelle ist Google Fonts (`fonts.gstatic.com`), die Dateien liegen aber auf unserem eigenen Server unter `assets/fonts/fallback/`. Der Browser lädt sie nur, wenn ein Text Zeichen enthält, die Poppins und Syncopate nicht haben. Welche Dateien es sind und welche SHA-256-Prüfsummen sie haben, steht in `tool/font_fallback.lock.json`. Die OFL erlaubt Weitergabe und Selbsthosting, solange die Schriften nicht einzeln verkauft werden und der Lizenztext beiliegt. Das Werkzeug legt den OFL-Text mit Urheberangaben als `assets/fonts/fallback/OFL.txt` daneben.
- Flutter und Dart-Pakete: überwiegend BSD, MIT und Apache 2.0. Die vollständige Liste erzeugt Flutter beim Build (Datei `assets/NOTICES` im Web).

Diese Liste ist ein Stand vom 19.11.2026. Bei jedem Update von `media_kit_libs_*`, mpv oder FFmpeg neu prüfen.
