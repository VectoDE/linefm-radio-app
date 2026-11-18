import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Meldet die Lizenzen der gebuendelten Schriften bei der `LicenseRegistry`
/// an, damit sie in der Lizenzseite ("Open-Source-Lizenzen") erscheinen.
///
/// - Poppins: SIL Open Font License 1.1 (`assets/fonts/OFL.txt`)
/// - Syncopate: Apache License 2.0 (`assets/fonts/LICENSE-Syncopate-Apache2.txt`)
///
/// Die Lizenztexte werden beim Oeffnen der Lizenzseite aus dem Asset-Bundle
/// gelesen. Sind die Dateien nicht als Asset deklariert (`pubspec.yaml`
/// `assets: - assets/fonts/`), erscheint stattdessen der Kurzhinweis mit
/// Verweis auf die Lizenz-URL. Mehrfachaufrufe sind harmlos.
void registerFontLicenses({AssetBundle? bundle}) {
  if (_registered && bundle == null) return;
  _registered = true;
  final source = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const <String>['Poppins'],
      await _load(
        source,
        'assets/fonts/OFL.txt',
        'Copyright 2020 The Poppins Project Authors '
            '(https://github.com/itfoundry/Poppins)\n\n'
            'This Font Software is licensed under the SIL Open Font License, '
            'Version 1.1. https://openfontlicense.org',
      ),
    );
    yield LicenseEntryWithLineBreaks(
      const <String>['Syncopate'],
      await _load(
        source,
        'assets/fonts/LICENSE-Syncopate-Apache2.txt',
        'Syncopate (Google Fonts).\n\n'
            'Licensed under the Apache License, Version 2.0. '
            'https://www.apache.org/licenses/LICENSE-2.0',
      ),
    );
  });
}

bool _registered = false;

Future<String> _load(AssetBundle bundle, String path, String fallback) async {
  try {
    return await bundle.loadString(path);
  } on Object {
    return fallback;
  }
}
