import 'dart:async';

import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/platform/carplay_bridge.dart';
import 'package:linefm_radio/services/audio/browse_tree.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';

class _FakeHost implements CarPlayHost {
  List<Station> favorites = <Station>[];
  Station? recent;
  final List<Station> played = <Station>[];
  final StreamController<void> changes = StreamController<void>.broadcast();
  final StreamController<CarPlayNowPlaying> now =
      StreamController<CarPlayNowPlaying>.broadcast();

  @override
  List<AutoMenuFolder> menu() =>
      BrowseTree.menu(favorites: favorites, recent: recent);

  @override
  Stream<void> get menuChanges => changes.stream;

  @override
  Stream<CarPlayNowPlaying> get nowPlaying => now.stream;

  @override
  Future<void> play(Station station) async => played.add(station);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(CarPlayBridge.channelName);
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> sent;
  late _FakeHost host;
  late MethodChannelCarPlayBridge bridge;

  /// Simuliert einen Aufruf der nativen Seite (Swift) an Dart.
  Future<Object?> callFromNative(String method, [Object? args]) async {
    final completer = Completer<Object?>();
    await messenger.handlePlatformMessage(
      CarPlayBridge.channelName,
      codec.encodeMethodCall(MethodCall(method, args)),
      (ByteData? reply) {
        if (reply == null) {
          completer.complete(#notImplemented);
          return;
        }
        completer.complete(codec.decodeEnvelope(reply));
      },
    );
    return completer.future;
  }

  setUp(() {
    sent = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      sent.add(call);
      return null;
    });
    host = _FakeHost();
    bridge = MethodChannelCarPlayBridge(host: host);
  });

  tearDown(() async {
    await bridge.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('setMenu (Dart -> nativ)', () {
    test('init schickt die drei Ordner in fester Reihenfolge', () async {
      host
        ..favorites = <Station>[stationBySlug('linefmrap')!]
        ..recent = stationBySlug('fobfm');
      await bridge.init();

      expect(sent.single.method, 'setMenu');
      final args = sent.single.arguments as Map<Object?, Object?>;
      final folders = (args['folders']! as List<Object?>)
          .cast<Map<Object?, Object?>>();
      expect(folders.map((f) => f['id']), <String>[
        BrowseTree.favoriteStationsId,
        BrowseTree.stationsId,
        BrowseTree.recentId,
      ]);
      final favorites = (folders[0]['stations']! as List<Object?>)
          .cast<Map<Object?, Object?>>();
      expect(favorites.single['slug'], 'linefmrap');
      expect(favorites.single.keys, containsAll(<String>['id', 'title']));
      expect((folders[1]['stations']! as List<Object?>).length, 6);
      final recent = (folders[2]['stations']! as List<Object?>)
          .cast<Map<Object?, Object?>>();
      expect(recent.single['slug'], 'fobfm');
    });

    test('Aenderung von Favoriten/Verlauf schickt neues Menue', () async {
      await bridge.init();
      sent.clear();
      host.favorites = <Station>[stationsCatalog.first];
      host.changes.add(null);
      await pumpEventQueue();
      expect(sent.single.method, 'setMenu');
    });

    test('Payload entspricht AutoMenuFolder.toJson', () {
      final folders = BrowseTree.menu();
      expect(MethodChannelCarPlayBridge.menuPayload(folders), <String, Object>{
        'folders': <Map<String, Object>>[for (final f in folders) f.toJson()],
      });
    });
  });

  group('nowPlaying (Dart -> nativ)', () {
    test(
      'sendet Station, Titel, Kuenstler und Status; Duplikate nicht',
      () async {
        await bridge.init();
        sent.clear();
        const value = CarPlayNowPlaying(
          slug: 'linefm',
          station: 'LineFM +MAIN',
          title: 'Song',
          artist: 'Band',
          playing: true,
        );
        host.now
          ..add(value)
          ..add(value);
        await pumpEventQueue();
        expect(sent.single.method, 'nowPlaying');
        expect(sent.single.arguments, <String, Object?>{
          'slug': 'linefm',
          'station': 'LineFM +MAIN',
          'title': 'Song',
          'artist': 'Band',
          'playing': true,
        });
      },
    );

    test('updateNowPlaying behaelt den Wiedergabestatus der Station', () async {
      await bridge.init();
      final station = stationBySlug('linefm')!;
      host.now.add(
        const CarPlayNowPlaying(
          slug: 'linefm',
          station: 'LineFM +MAIN',
          playing: true,
        ),
      );
      await pumpEventQueue();
      sent.clear();
      await bridge.updateNowPlaying(
        station,
        const Track(artist: 'A', title: 'T'),
      );
      final args = sent.single.arguments as Map<Object?, Object?>;
      expect(args['title'], 'T');
      expect(args['artist'], 'A');
      expect(args['playing'], true);
    });
  });

  group('nativ -> Dart', () {
    setUp(() => bridge.init());

    test('getMenu liefert dasselbe Menue wie setMenu', () async {
      final reply = await callFromNative('getMenu');
      expect(reply, MethodChannelCarPlayBridge.menuPayload(host.menu()));
    });

    test('play startet den Sender und meldet true', () async {
      final reply = await callFromNative('play', <String, Object?>{
        'slug': 'linefmlofi',
      });
      await pumpEventQueue();
      expect(reply, true);
      expect(host.played.single.slug, 'linefmlofi');
    });

    test('play mit unbekanntem oder fehlendem Slug meldet false', () async {
      expect(
        await callFromNative('play', <String, Object?>{'slug': 'gibtsnicht'}),
        false,
      );
      expect(await callFromNative('play'), false);
      expect(host.played, isEmpty);
    });

    test('unbekannte Methode = nicht implementiert', () async {
      expect(await callFromNative('foo'), #notImplemented);
    });
  });

  test('ohne native Seite (MissingPluginException) kein Fehler', () async {
    messenger.setMockMethodCallHandler(channel, null);
    await bridge.init();
    await bridge.updateNowPlaying(stationsCatalog.first, null);
  });

  group('AudioHandlerCarPlayHost.nowPlayingFrom', () {
    final station = stationBySlug('linefmrap')!;

    test('mit Titel', () {
      final item = BrowseTree.stationItem(
        station,
        track: const Track(artist: 'Band', title: 'Song'),
      );
      expect(
        AudioHandlerCarPlayHost.nowPlayingFrom(item, playing: true),
        CarPlayNowPlaying(
          slug: station.slug,
          station: station.displayName,
          title: 'Song',
          artist: 'Band',
          playing: true,
        ),
      );
    });

    test('ohne Titel nur Station', () {
      final item = BrowseTree.stationItem(station);
      final value = AudioHandlerCarPlayHost.nowPlayingFrom(
        item,
        playing: false,
      );
      expect(value.slug, station.slug);
      expect(value.title, isNull);
      expect(value.artist, isNull);
    });

    test('kein oder fremdes MediaItem = leer', () {
      expect(
        AudioHandlerCarPlayHost.nowPlayingFrom(null, playing: false),
        const CarPlayNowPlaying(),
      );
      expect(
        AudioHandlerCarPlayHost.nowPlayingFrom(
          const MediaItem(id: 'x', title: 'x'),
          playing: true,
        ),
        const CarPlayNowPlaying(playing: true),
      );
    });
  });

  test('initCarPlay ausserhalb von iOS ist ein No-Op', () async {
    final noop = await initCarPlay(NoopPlaybackService());
    expect(noop, isA<NoopCarPlayBridge>());
  });
}
