import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Native Bibliotheken der Desktop-Wiedergabe (Windows, Linux) auf der
/// Lizenzseite. `just_audio_media_kit`/`media_kit` spielen dort ueber
/// libmpv, das FFmpeg, libass und libplacebo nutzt. Die Dart-Pakete meldet
/// Flutter selbst, diese nativen Teile nicht.
///
/// Angaben nach `docs/LIZENZEN-DRITTE.md` (Stand 27.11.2026): Windows,
/// Flatpak und Snap liefern LGPL-Builds (mpv mit `-Dgpl=false`, FFmpeg ohne
/// `--enable-gpl`). Die vollstaendigen Texte der LGPL 3 und GPL 3 sowie der
/// Quellenhinweis liegen unter [nativeLicenseAssets] und erscheinen ebenfalls
/// auf der Lizenzseite.
/// Die Bibliotheken liegen als eigene Dateien (.so/.dll) bei und lassen sich
/// austauschen.
void registerNativeLicenses({TargetPlatform? platform, bool web = kIsWeb}) {
  final target = platform ?? defaultTargetPlatform;
  if (web ||
      (target != TargetPlatform.windows && target != TargetPlatform.linux)) {
    return;
  }
  if (_registered && platform == null) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final lib in nativeLibraries) {
      yield LicenseEntryWithLineBreaks(<String>[lib.name], lib.notice);
    }
    const packages = <String>['libmpv', 'FFmpeg'];
    for (final asset in nativeLicenseAssets) {
      yield LicenseEntryWithLineBreaks(
        packages,
        await rootBundle.loadString(asset),
      );
    }
  });
}

bool _registered = false;

/// License texts and source notice shipped for libmpv/FFmpeg. Also installed
/// as files next to the Windows executable and in the installer.
const List<String> nativeLicenseAssets = <String>[
  'assets/licenses/NATIVE-LIBRARIES.txt',
  'assets/licenses/LGPL-3.0.txt',
  'assets/licenses/GPL-3.0.txt',
];

/// Eintrag fuer eine native Bibliothek.
@immutable
class NativeLibrary {
  const NativeLibrary(this.name, this.license, this.source, [this.note = '']);

  final String name;
  final String license;
  final String source;
  final String note;

  String get notice =>
      '$name\n\n'
      'Lizenz / License: $license\n'
      'Quellcode / Source: $source\n'
      '${note.isEmpty ? '' : '\n$note\n'}'
      '\nDie Bibliothek liegt als eigene Datei bei und kann ersetzt werden. '
      'The library ships as a separate file and can be replaced.';
}

const List<NativeLibrary> nativeLibraries = <NativeLibrary>[
  NativeLibrary(
    'libmpv',
    'LGPL-2.1-or-later (Build mit / built with -Dgpl=false); '
        'Windows-DLL mit FFmpeg: LGPL-3.0-or-later',
    'https://github.com/mpv-player/mpv',
    'Windows: Audio-Build von media-kit, Release 2023-09-24 '
        '(https://github.com/media-kit/libmpv-win32-audio-build).',
  ),
  NativeLibrary(
    'FFmpeg',
    'Windows, Snap: LGPL-3.0-or-later (--enable-version3); Flatpak: '
        'LGPL-2.1-or-later (Build ohne --enable-gpl / built without '
        '--enable-gpl)',
    'https://ffmpeg.org',
  ),
  NativeLibrary('libass', 'ISC', 'https://github.com/libass/libass'),
  NativeLibrary(
    'libplacebo',
    'LGPL-2.1-or-later',
    'https://code.videolan.org/videolan/libplacebo',
  ),
];
