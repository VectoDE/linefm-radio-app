import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/cast/chrome_cast_service.dart';

import 'cast_helpers.dart';

void main() {
  final station = stationsCatalog.first;
  final other = stationsCatalog[1];

  group('ChromeCastService', () {
    late FakeCastBackend backend;
    late ChromeCastService service;

    setUp(() {
      backend = FakeCastBackend();
      service = ChromeCastService(backend: backend, resolveStreamUrl: url);
    });

    tearDown(() => service.dispose());

    test('Zustand: verfügbar, Geräte folgen der Suche', () async {
      expect(service.state.available, isTrue);
      expect(service.state.devices, isEmpty);
      backend.setDevices(<CastDevice>[tv, speaker]);
      expect(service.state.devices, hasLength(2));
      expect(service.state.isCasting, isFalse);
    });

    test('states liefert zuerst den aktuellen Zustand', () async {
      backend.setDevices(<CastDevice>[tv]);
      final first = await service.states.first;
      expect(first.devices, <CastDevice>[tv]);
    });

    test('connect baut die Sitzung auf, disconnect beendet sie', () async {
      backend.setDevices(<CastDevice>[tv]);
      await service.connect(tv);
      expect(service.state.connectedDevice, tv);
      expect(service.state.isCasting, isTrue);
      await service.disconnect();
      expect(backend.endCalls, 1);
      expect(service.state.isCasting, isFalse);
    });

    test('connecting wird sichtbar, ist aber noch kein Casting', () async {
      backend.setLink(const CastLinkState(CastLink.connecting, tv));
      expect(service.state.connecting, isTrue);
      expect(service.state.isCasting, isFalse);
    });

    test('Fehlstart der Sitzung ändert den Zustand nicht', () async {
      backend.startResult = false;
      await service.connect(tv);
      expect(service.state.isCasting, isFalse);
    });

    test('cast lädt MP3-Live-Stream mit Titel, Künstler und Cover', () async {
      await service.connect(tv);
      await service.cast(station, a);
      expect(backend.loads, hasLength(1));
      final media = backend.loads.single;
      expect(
        media.streamUrl,
        Uri.parse('https://stream.laut.fm/${station.slug}'),
      );
      expect(media.title, 'Song A');
      expect(media.artist, 'Artist A');
      expect(media.stationName, station.displayName);
      expect(media.imageUrl, Uri.parse('https://cdn.example/a.jpg'));
    });

    test('ohne Titel: Sender als Titel, Senderlogo als Cover', () async {
      await service.connect(tv);
      await service.cast(station, null);
      final media = backend.loads.single;
      expect(media.title, station.displayName);
      expect(media.artist, 'LINEFM');
      expect(media.imageUrl.toString(), station.logoUrl);
    });

    test('ohne Sitzung wird nichts geladen', () async {
      await service.cast(station, a);
      expect(backend.loads, isEmpty);
    });

    test(
      'updateTrack zieht Metadaten nach, gleicher Titel nicht doppelt',
      () async {
        await service.connect(tv);
        await service.cast(station, a);
        await service.updateTrack(station, b);
        await service.updateTrack(station, b);
        expect(backend.loads.map((m) => m.title), <String>['Song A', 'Song B']);
      },
    );

    test(
      'updateTrack für einen nie übergebenen Sender wird ignoriert',
      () async {
        await service.connect(tv);
        await service.cast(station, a);
        await service.updateTrack(other, b);
        expect(backend.loads, hasLength(1));
      },
    );

    test('schnelle Wechsel: Zwischenstände werden übersprungen', () async {
      await service.connect(tv);
      final gate = backend.loadGate = Completer<void>();
      final first = service.cast(station, a);
      await settle();
      unawaited(
        service.updateTrack(station, const Track(artist: 'X', title: 'x1')),
      );
      unawaited(service.updateTrack(station, b));
      gate.complete();
      await first;
      await settle();
      expect(backend.loads.map((m) => m.title), <String>['Song A', 'Song B']);
    });

    test(
      'Sitzungsende verwirft offene Wünsche und das geladene Medium',
      () async {
        await service.connect(tv);
        await service.cast(station, a);
        await service.disconnect();
        await service.updateTrack(station, b);
        expect(backend.loads, hasLength(1));
        // Neue Sitzung lädt erneut, auch denselben Titel.
        await service.connect(tv);
        await service.cast(station, a);
        expect(backend.loads, hasLength(2));
      },
    );

    test('setVolume geht nur bei Sitzung an das Gerät', () async {
      await service.setVolume(0.4);
      expect(backend.volumes, isEmpty);
      await service.connect(tv);
      await service.setVolume(0.4);
      await service.setVolume(3);
      expect(backend.volumes, <double>[0.4, 1.0]);
    });

    test('Suche reicht activeScan durch', () async {
      await service.startDiscovery();
      await service.startDiscovery(activeScan: true);
      expect(backend.scans, <bool>[false, true]);
    });

    test('Ladefehler beendet den Dienst nicht', () async {
      final failing = ChromeCastService(
        backend: backend,
        resolveStreamUrl: (_) => throw StateError('offline'),
      );
      addTearDown(failing.dispose);
      await service.connect(tv);
      await failing.cast(station, a);
      expect(backend.loads, isEmpty);
    });

    test('cast meldet den Sender im Zustand, stopMedia stoppt ihn', () async {
      await service.connect(tv);
      expect(service.state.isPlayingMedia, isFalse);
      await service.cast(station, a);
      expect(service.state.station, station);
      expect(service.state.isPlayingMedia, isTrue);

      await service.stopMedia();
      expect(backend.stopMediaCalls, 1);
      expect(service.state.isPlayingMedia, isFalse);
      expect(service.state.isCasting, isTrue, reason: 'Sitzung bleibt');

      // Titelwechsel nach dem Stopp lädt nichts neu.
      await service.updateTrack(station, b);
      expect(backend.loads, hasLength(1));
    });

    test('stopMedia während des Ladens verwirft den Auftrag', () async {
      await service.connect(tv);
      final gate = Completer<Uri>();
      final slow = ChromeCastService(
        backend: backend,
        resolveStreamUrl: (_) => gate.future,
      );
      addTearDown(slow.dispose);
      final pending = slow.cast(station, a);
      await slow.stopMedia();
      gate.complete(Uri.parse('https://stream.laut.fm/linefm'));
      await pending;
      expect(backend.loads, isEmpty);
      expect(slow.state.isPlayingMedia, isFalse);
    });

    test('Sitzungsende vergisst den Sender', () async {
      await service.connect(tv);
      await service.cast(station, a);
      await service.disconnect();
      expect(service.state.station, isNull);
      expect(service.state.isPlayingMedia, isFalse);
    });
  });
}
