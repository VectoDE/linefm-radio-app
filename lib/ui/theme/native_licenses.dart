import 'package:flutter/foundation.dart';

/// Native Bibliotheken der Desktop-Wiedergabe (Windows, Linux) auf der
/// Lizenzseite. `just_audio_media_kit`/`media_kit` spielen dort ueber
/// libmpv, das FFmpeg, libass und libplacebo nutzt. Die Dart-Pakete meldet
/// Flutter selbst, diese nativen Teile nicht.
///
/// Angaben nach `docs/LIZENZEN-DRITTE.md` (Stand 19.11.2026). Welche
/// Lizenzvariante der jeweilige libmpv-Build hat (GPL oder LGPL), haengt vom
/// Build ab und ist dort als offen vermerkt; der Text sagt das ehrlich.
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
  });
}

bool _registered = false;

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
    'GPL-2.0-or-later oder LGPL-2.1-or-later, je nach Build '
        '(GPL-2.0-or-later or LGPL-2.1-or-later, depending on the build)',
    'https://github.com/mpv-player/mpv',
    'Windows: Audio-Build von media-kit '
        '(https://github.com/media-kit/libmpv-win32-audio-build).',
  ),
  NativeLibrary(
    'FFmpeg',
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
