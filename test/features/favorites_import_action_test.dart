import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/favorites/favorites_import.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/features/favorites/favorites_import_action.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

const _failed =
    'Die Datei ließ sich nicht lesen. Wähle einen Export aus LINEFM Radio '
    '(CSV oder Text).';

Favorite _fav(String slug, String artist, String title) => Favorite(
  key: FavoritesLogic.keyFor(stationSlug: slug, artist: artist, title: title),
  stationSlug: slug,
  title: title,
  artist: artist,
);

/// Q-05: Import-Ablauf um den (gut getesteten) Parser herum: Dialog-Fehler,
/// Groessenlimit, kaputtes UTF-8, Abbruch und Ergebnis-Meldung.
void main() {
  Future<FeatureHost> run(
    WidgetTester tester,
    FavoritesFilePicker picker,
  ) async {
    final host = FeatureHost();
    await tester.pumpWidget(
      host.app(
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => startFavoritesImport(context, ref, picker: picker),
            child: const Text('Import'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    return host;
  }

  XFile file(List<int> bytes) =>
      XFile.fromData(Uint8List.fromList(bytes), name: 'favoriten.csv');

  testWidgets('CSV-Export wird importiert, Meldung mit Anzahl', (tester) async {
    final csv = FavoritesExport.build(<Favorite>[
      _fav('linefm', 'Band', 'Song'),
    ], ExportFormat.csv);
    final host = await run(tester, () async => file(utf8.encode(csv)));
    expect(find.text('1 Favorit importiert.'), findsOneWidget);
    expect(host.prefs.readFavorites().single.title, 'Song');
  });

  testWidgets('Abbruch im Dialog: keine Meldung', (tester) async {
    await run(tester, () async => null);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Dialog wirft: Fehlermeldung', (tester) async {
    await run(tester, () async => throw StateError('kein Dialog'));
    expect(find.text(_failed), findsOneWidget);
  });

  testWidgets('groesser als 2 MiB: Fehlermeldung, nichts importiert', (
    tester,
  ) async {
    final host = await run(
      tester,
      () async => file(List<int>.filled(FavoritesImport.maxBytes + 1, 65)),
    );
    expect(find.text(_failed), findsOneWidget);
    expect(host.prefs.readFavorites(), isEmpty);
  });

  testWidgets('kaputtes UTF-8 und fremder Inhalt: Fehlermeldung', (
    tester,
  ) async {
    await run(tester, () async => file(<int>[0xff, 0xfe, 0x00, 0x41]));
    expect(find.text(_failed), findsOneWidget);
  });
}
