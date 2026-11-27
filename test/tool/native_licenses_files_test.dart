import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/ui/theme/native_licenses.dart';

/// The LGPL/GPL texts and the libmpv/FFmpeg source notice must ship with the
/// Windows build, the installer and the in-app licenses page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('license texts exist and are the GNU originals', () {
    final lgpl = File('assets/licenses/LGPL-3.0.txt').readAsStringSync();
    final gpl = File('assets/licenses/GPL-3.0.txt').readAsStringSync();
    expect(lgpl, contains('GNU LESSER GENERAL PUBLIC LICENSE'));
    expect(lgpl, contains('Version 3, 29 June 2007'));
    expect(gpl, contains('GNU GENERAL PUBLIC LICENSE'));
    expect(gpl, contains('Version 3, 29 June 2007'));
  });

  test('source notice names build, flags and source addresses', () {
    final notice = File('assets/licenses/NATIVE-LIBRARIES.txt')
        .readAsStringSync();
    for (final s in <String>[
      'libmpv-win32-audio-build',
      'mpv-dev-x86_64-20230924-git-652a1dd.7z',
      '-Dgpl=false',
      '--disable-gpl',
      'https://github.com/mpv-player/mpv',
      'https://ffmpeg.org',
    ]) {
      expect(notice, contains(s));
    }
  });

  test('assets are bundled and installed', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/licenses/'),
    );
    final cmake = File('windows/CMakeLists.txt').readAsStringSync();
    final installer = File('installer/windows/build.ps1').readAsStringSync();
    for (final name in <String>[
      'LGPL-3.0.txt',
      'GPL-3.0.txt',
      'NATIVE-LIBRARIES.txt',
    ]) {
      expect(cmake, contains('assets/licenses/$name'));
      expect(installer, contains('licenses/$name='));
    }
  });

  test('licenses page lists the full texts on Windows', () async {
    registerNativeLicenses(platform: TargetPlatform.windows, web: false);
    final texts = <String>[];
    await for (final entry in LicenseRegistry.licenses) {
      if (entry.packages.contains('libmpv')) {
        texts.add(entry.paragraphs.map((p) => p.text).join('\n'));
      }
    }
    final all = texts.join('\n');
    expect(all, contains('GNU LESSER GENERAL PUBLIC LICENSE'));
    expect(all, contains('GNU GENERAL PUBLIC LICENSE'));
    expect(all, contains('libmpv-win32-audio-build'));
  });
}
