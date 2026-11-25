import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/favorites/favorite_stations_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/platform/deep_links.dart';

/// Entfernte Sender (Issue #91): Favoriten, Wecker und Deep Links auf einen
/// Sender, der nicht mehr in der Liste steht, fuehren zu keinem Fehler.
void main() {
  late List<Station> original;

  setUp(() {
    original = List.of(stationsCatalog);
    // "fobfm" aus der Liste nehmen, als haette der Betreiber ihn entfernt.
    setStationsForTest(<Station>[
      for (final s in stationsCatalog)
        if (s.slug != 'fobfm') s,
    ]);
    DeepLinks.resetForTest();
  });

  tearDown(() => setStationsForTest(original));

  test('Favorit bleibt gespeichert, wird aber nicht angezeigt', () {
    final slugs = FavoriteStationsLogic.decode('["linefm","fobfm"]');
    expect(slugs, containsAll(<String>['linefm', 'fobfm']));
    expect(FavoriteStationsLogic.stations(slugs).map((s) => s.slug), <String>[
      'linefm',
    ]);
    expect(FavoriteStationsLogic.encode(slugs), '["linefm","fobfm"]');
  });

  test('kaputte Eintraege im Speicher fallen weg', () {
    expect(FavoriteStationsLogic.decode('["../x", 3, "linefm"]'), <String>{
      'linefm',
    });
    expect(FavoriteStationsLogic.decode('kein json'), isEmpty);
  });

  test('Wecker auf entfernten Sender weckt mit dem ersten Sender', () {
    expect(alarmStationFor('fobfm').slug, stationsCatalog.first.slug);
    expect(alarmStationFor('linefmrap').slug, 'linefmrap');
  });

  test('Deep Link auf entfernten Sender: Hinweis statt Wiedergabe', () async {
    final played = <Uri>[];
    final unavailable = <String>[];
    final a = DeepLinks.stream.listen(played.add);
    final b = DeepLinks.unavailable.listen(unavailable.add);
    DeepLinks.dispatch(Uri.parse('linefm://play?station=fobfm'));
    DeepLinks.dispatch(Uri.parse('linefm://play?station=..%2Fetc'));
    await Future<void>.delayed(Duration.zero);
    expect(played, isEmpty);
    expect(unavailable, <String>['fobfm']);
    await a.cancel();
    await b.cancel();
  });

  test('Platzhalter fuer gespeicherte Songs eines entfernten Senders', () {
    final s = unknownStation('fobfm');
    expect(s.displayName, 'fobfm');
    expect(stationBySlug('fobfm'), isNull);
  });
}
