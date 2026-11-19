import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/services/share/file_delivery_io.dart';

void main() {
  test('Download-Ordner aus Umgebung (Windows/macOS/Linux ohne XDG)', () {
    final dir = downloadDirectory(
      environment: <String, String>{
        'USERPROFILE': r'C:\Users\u',
        'HOME': '/h/u',
      },
      readFile: (_) => throw const FileSystemException('keine Datei'),
    );
    expect(dir, isNotNull);
    expect(dir!.path, endsWith('Downloads'));
    expect(dir.path, contains(Platform.isWindows ? r'C:\Users\u' : '/h/u'));
  });

  test('ohne Home-Verzeichnis kein Ordner', () {
    expect(downloadDirectory(environment: <String, String>{}), isNull);
  });

  test('freier Dateiname statt Ueberschreiben', () {
    final taken = <String>{'a.csv', 'a (1).csv'};
    expect(uniqueFileName('b.csv', taken.contains), 'b.csv');
    expect(uniqueFileName('a.csv', taken.contains), 'a (2).csv');
    expect(
      uniqueFileName('ohneendung', <String>{'ohneendung'}.contains),
      'ohneendung (1)',
    );
  });

  test(
    'schreibt UTF-8 mit BOM in den Ordner, zweite Datei bekommt Zaehler',
    () async {
      final tmp = await Directory.systemTemp.createTemp('linefm_export');
      addTearDown(() => tmp.delete(recursive: true));
      final bytes = Uint8List.fromList(<int>[
        0xEF, 0xBB, 0xBF, //
        ...utf8.encode('Titel;Künstler\r\nÜber den Wolken;Mey'),
      ]);

      final first = await saveToDownloadFolder('x.csv', bytes, into: tmp);
      final second = await saveToDownloadFolder('x.csv', bytes, into: tmp);

      expect(first, endsWith('x.csv'));
      expect(second, endsWith('x (1).csv'));
      final read = await File(first).readAsBytes();
      expect(read.sublist(0, 3), <int>[0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(read.sublist(3)), contains('Über den Wolken'));
    },
  );
}
