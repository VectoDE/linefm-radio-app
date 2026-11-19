import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';

class _FakeBackend implements HomeWidgetBackend {
  final Map<String, Object?> data = <String, Object?>{};
  final List<String> saved = <String>[];
  int covers = 0;
  int refreshes = 0;

  @override
  Future<void> save(String key, Object? value) async {
    saved.add(key);
    data[key] = value;
  }

  @override
  Future<void> saveCover(Uint8List bytes) async {
    covers++;
    data[HomeWidgetKeys.coverPath] = '/x/home_widget/linefm_cover.jpg';
  }

  @override
  Future<void> refresh() async => refreshes++;
}

void main() {
  final main = stationBySlug('linefm')!;
  final rap = stationBySlug('linefmrap')!;
  const track = Track(
    artist: 'Daft Punk',
    title: 'One More Time',
    artworkUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Music/v4/ab/600x600bb.jpg',
  );

  group('Widget-Daten', () {
    test('Werte mit Titel, Status und Texten in App-Sprache', () {
      final values = AndroidHomeWidgetSync.widgetValues(
        station: main,
        track: track,
        playing: true,
        l10n: lookupAppLocalizations(const Locale('de')),
      );
      expect(values, <String, Object?>{
        HomeWidgetKeys.stationSlug: 'linefm',
        HomeWidgetKeys.stationName: 'LineFM +MAIN',
        HomeWidgetKeys.title: 'One More Time',
        HomeWidgetKeys.artist: 'Daft Punk',
        HomeWidgetKeys.playing: true,
        HomeWidgetKeys.idleText: 'Zum Abspielen tippen',
        HomeWidgetKeys.playLabel: 'Stream starten',
        HomeWidgetKeys.stopLabel: 'Stream stoppen',
      });
    });

    test('ohne Titel: title/artist leer, Englisch als Rueckfall', () {
      final values = AndroidHomeWidgetSync.widgetValues(
        station: rap,
        track: null,
        playing: false,
        l10n: lookupAppLocalizations(const Locale('en')),
      );
      expect(values[HomeWidgetKeys.title], isNull);
      expect(values[HomeWidgetKeys.artist], isNull);
      expect(values[HomeWidgetKeys.idleText], 'Tap to play');
    });

    test('Cover: nur https, iTunes auf 300x300', () {
      expect(
        AndroidHomeWidgetSync.coverUrlFor(track).toString(),
        'https://is1-ssl.mzstatic.com/image/thumb/Music/v4/ab/300x300bb.jpg',
      );
      expect(
        AndroidHomeWidgetSync.coverUrlFor(
          const Track(artist: 'a', title: 't', artworkUrl: 'http://x/a.jpg'),
        ),
        isNull,
      );
      expect(
        AndroidHomeWidgetSync.coverUrlFor(const Track(artist: 'a', title: 't')),
        isNull,
      );
      expect(
        AndroidHomeWidgetSync.coverUrlFor(
          const Track(
            artist: 'a',
            title: 't',
            artworkUrl: 'https://cdn.linefm.de/images/icons/main.png',
          ),
        ).toString(),
        'https://cdn.linefm.de/images/icons/main.png',
      );
    });
  });

  group('AndroidHomeWidgetSync', () {
    test('schreibt nur Aenderungen und laedt das Cover einmal', () async {
      final backend = _FakeBackend();
      final fetched = <Uri>[];
      final sync = AndroidHomeWidgetSync(
        backend: backend,
        locale: () => const Locale('de'),
        fetchCover: (url) async {
          fetched.add(url);
          return Uint8List.fromList(<int>[1, 2, 3]);
        },
      );

      await sync.update(station: main, track: track, playing: false);
      expect(backend.data[HomeWidgetKeys.title], 'One More Time');
      expect(backend.covers, 1);
      expect(backend.refreshes, 1);

      backend.saved.clear();
      await sync.update(station: main, track: track, playing: false);
      expect(backend.saved, isEmpty, reason: 'unveraendert');
      expect(backend.refreshes, 1);

      await sync.update(station: main, track: track, playing: true);
      expect(backend.saved, <String>[HomeWidgetKeys.playing]);
      expect(backend.covers, 1, reason: 'gleiches Cover');
      expect(backend.refreshes, 2);
      expect(fetched, hasLength(1));
    });

    test('ohne Cover wird der Pfad geloescht (Logo-Rueckfall)', () async {
      final backend = _FakeBackend();
      final sync = AndroidHomeWidgetSync(
        backend: backend,
        locale: () => const Locale('en'),
        fetchCover: (url) async => null,
      );
      await sync.update(station: main, track: track, playing: true);
      expect(backend.data.containsKey(HomeWidgetKeys.coverPath), isTrue);
      expect(backend.data[HomeWidgetKeys.coverPath], isNull);
      expect(backend.covers, 0);
    });

    test('Fehler im Backend werden geschluckt', () async {
      final sync = AndroidHomeWidgetSync(
        backend: _ThrowingBackend(),
        fetchCover: (url) async => null,
      );
      await expectLater(
        sync.update(station: main, track: null, playing: false),
        completes,
      );
    });
  });
}

class _ThrowingBackend implements HomeWidgetBackend {
  @override
  Future<void> refresh() => throw StateError('x');

  @override
  Future<void> save(String key, Object? value) => throw StateError('x');

  @override
  Future<void> saveCover(Uint8List bytes) => throw StateError('x');
}
