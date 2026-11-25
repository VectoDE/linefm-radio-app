import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/browse_tree.dart';
import 'package:linefm_radio/services/audio/radio_player.dart';

class _SilentPlayer implements RadioPlayer {
  final StreamController<RadioSignal> _signals =
      StreamController<RadioSignal>.broadcast(sync: true);

  @override
  Stream<RadioSignal> get signals => _signals.stream;

  @override
  Future<void> load(Uri url) async {}

  @override
  Future<void> play() async {
    _signals
      ..add(RadioSignal.buffering)
      ..add(RadioSignal.playing);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() => _signals.close();
}

void main() {
  final main = stationBySlug('linefm')!;
  final lofi = stationBySlug('linefmlofi')!;
  final fob = stationBySlug('fobfm')!;

  group('BrowseTree (Auto-Menue, Issue #42)', () {
    test('Wurzel: immer drei Ordner in fester Reihenfolge', () {
      final root = BrowseTree.children(BrowseTree.rootId);
      expect(root.map((e) => e.id), <String>[
        BrowseTree.favoriteStationsId,
        BrowseTree.stationsId,
        BrowseTree.recentId,
      ]);
      expect(root.map((e) => e.title), <String>[
        'Favoriten-Sender',
        'Sender',
        'Zuletzt gehört',
      ]);
      expect(root.every((e) => e.playable == false), isTrue);
      for (final folder in root) {
        expect(
          folder.extras?[BrowseTree.contentStylePlayableHint],
          BrowseTree.contentStyleGrid,
        );
      }
    });

    test('Ordnerinhalte: Favoriten, alle Sender, zuletzt gehoert', () {
      List<String> ids(String parent) => BrowseTree.children(
        parent,
        favorites: [lofi, main],
        recent: fob,
      ).map((e) => e.id).toList();

      expect(ids(BrowseTree.favoriteStationsId), <String>[
        'linefmlofi',
        'linefm',
      ]);
      expect(ids(BrowseTree.stationsId), <String>[
        for (final s in stationsCatalog) s.slug,
      ]);
      expect(ids(BrowseTree.recentId), <String>['fobfm']);
      expect(ids('unbekannt'), isEmpty);
    });

    test('ohne Daten bleiben Favoriten und Verlauf leer', () {
      expect(BrowseTree.children(BrowseTree.favoriteStationsId), isEmpty);
      expect(BrowseTree.children(BrowseTree.recentId), isEmpty);
    });

    test('Sender sind abspielbar, live und tragen das Bild aus art()', () {
      final items = BrowseTree.children(
        BrowseTree.stationsId,
        art: BrowseTree.androidResourceArt,
      );
      for (final item in items) {
        expect(item.playable, isTrue);
        expect(item.isLive, isTrue);
        expect(item.artUri?.scheme, 'android.resource');
        expect(item.artUri?.host, 'de.linefm.app');
      }
      expect(
        items.first.artUri.toString(),
        'android.resource://de.linefm.app/drawable/auto_station_linefm',
      );
    });

    test('Android-Drawables der Senderlogos existieren im Projekt', () {
      for (final s in stationsCatalog) {
        final name = BrowseTree.androidDrawableName(s);
        expect(
          File('android/app/src/main/res/drawable-nodpi/$name.png')
              .existsSync(),
          isTrue,
          reason: name,
        );
      }
    });

    test('keep.xml schuetzt Senderlogos und Benachrichtigungs-Icon', () {
      final keep = File('android/app/src/main/res/raw/keep.xml')
          .readAsStringSync();
      expect(keep, contains('@drawable/auto_station_*'));
      expect(keep, contains('@drawable/ic_stat_linefm'));
    });

    test('Cover des Titels hat Vorrang vor dem Senderbild', () {
      final item = BrowseTree.stationItem(
        main,
        track: const Track(
          artist: 'A',
          title: 'T',
          artworkUrl: 'https://is1-ssl.mzstatic.com/x/600x600bb.jpg',
        ),
        art: BrowseTree.androidResourceArt(main),
      );
      expect(item.artUri?.host, 'is1-ssl.mzstatic.com');
      expect(item.title, 'T');
      expect(item.artist, 'A');
    });

    test('Datenstruktur fuer CarPlay (toJson)', () {
      final menu = BrowseTree.menu(favorites: [fob], recent: main);
      final json = <Map<String, Object>>[for (final f in menu) f.toJson()];
      expect(json.map((f) => f['id']), <String>[
        'favorite_stations',
        'stations',
        BrowseTree.recentId,
      ]);
      final favorites = json.first['stations']! as List<Map<String, String>>;
      expect(favorites.single, <String, String>{
        'id': 'fobfm',
        'slug': 'fobfm',
        'title': 'FobFM',
        'logoAsset': 'assets/images/stations/fobfm.png',
        'logoUrl': 'https://cdn.linefm.de/images/icons/fobfm.png',
      });
      expect(json[1]['stations'], hasLength(stationsCatalog.length));
    });

    test('Ordnernamen lokalisiert, Rueckfall Englisch', () {
      final de = LinefmAudioHandler.autoMenuTitles(const Locale('de', 'AT'));
      expect(
        <String>[de.favoriteStations, de.stations, de.recent],
        <String>['Favoriten-Sender', 'Sender', 'Zuletzt gehört'],
      );
      final fr = LinefmAudioHandler.autoMenuTitles(const Locale('fr'));
      expect(
        <String>[fr.favoriteStations, fr.stations, fr.recent],
        <String>['Favorite stations', 'Stations', 'Recently played'],
      );
    });
  });

  group('LinefmAudioHandler: Favoriten-Sender im Auto-Menue', () {
    test('gemeldete Favoriten erscheinen und loesen Neuladen aus', () async {
      final h = LinefmAudioHandler(
        player: _SilentPlayer(),
        minConnectDuration: Duration.zero,
      );
      addTearDown(h.dispose);

      final changes = <Map<String, dynamic>>[];
      final sub = h
          .subscribeToChildren(BrowseTree.favoriteStationsId)
          .listen(changes.add);
      addTearDown(sub.cancel);

      expect(await h.getChildren(BrowseTree.favoriteStationsId), isEmpty);

      h.favoriteStationSlugs = <String>{'fobfm', 'linefm'};
      await Future<void>.delayed(Duration.zero);
      final favorites = await h.getChildren(BrowseTree.favoriteStationsId);
      expect(favorites.map((e) => e.id), <String>['linefm', 'fobfm']);
      expect(changes, hasLength(1));

      // Gleiche Auswahl: kein erneutes Neuladen.
      h.favoriteStationSlugs = <String>{'linefm', 'fobfm'};
      await Future<void>.delayed(Duration.zero);
      expect(changes, hasLength(1));

      final root = await h.getChildren(AudioService.browsableRootId);
      expect(root.first.id, BrowseTree.favoriteStationsId);
    });

    test('Zuletzt gehoert folgt der Wiedergabe', () async {
      final h = LinefmAudioHandler(
        player: _SilentPlayer(),
        minConnectDuration: Duration.zero,
      );
      addTearDown(h.dispose);
      final changes = <Map<String, dynamic>>[];
      final sub = h
          .subscribeToChildren(BrowseTree.recentId)
          .listen(changes.add);
      addTearDown(sub.cancel);

      await h.playFromMediaId('linefmlofi');
      await Future<void>.delayed(Duration.zero);
      final recent = await h.getChildren(BrowseTree.recentId);
      expect(recent.single.id, lofi.slug);
      expect(changes, hasLength(1));
    });
  });
}
