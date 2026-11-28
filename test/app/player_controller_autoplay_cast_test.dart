import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';

import 'player_controller_helpers.dart';

void main() {
  group('Web-Autoplay-Sperre', () {
    test(
      'Start ohne Nutzeraktion: nur Auswahl, Knopf "Radio starten"',
      () async {
        var active = false;
        final c = Ctx(
          settings: const AppSettings(autoplay: false),
          activation: () => active,
        );
        addTearDown(c.dispose);
        await c.controller.startStation(stationsCatalog[3]);
        expect(c.active, stationsCatalog[3]);
        expect(c.playback.plays, isEmpty);
        expect(c.container.read(autoplayBlockedProvider), isTrue);

        active = true;
        await c.controller.startStation(stationsCatalog[3]);
        await flush();
        expect(c.playback.plays, <String>['play:${stationsCatalog[3].slug}']);
        expect(c.container.read(autoplayBlockedProvider), isFalse);
      },
    );

    test('Web-Autoplay ohne Nutzeraktion zeigt den Knopf', () async {
      final c = Ctx(activation: () => false);
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      expect(c.controller.autoplayPending, isTrue);
      expect(c.container.read(autoplayBlockedProvider), isTrue);
    });

    testWidgets('Wiedergabe von anderer Stelle blendet den Knopf aus', (
      tester,
    ) async {
      final c = Ctx(activation: () => false);
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      c.playback.emit(const PlayerUiState(status: PlayerStatus.playing));
      await tester.pump();
      expect(c.container.read(autoplayBlockedProvider), isFalse);
    });

    test('Nativ (Standard): kein Knopf', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      await c.controller.startup(web: false);
      expect(c.container.read(autoplayBlockedProvider), isFalse);
    });
  });

  group('Cast', () {
    test('Stop im Player beendet die Wiedergabe am Cast-Geraet', () async {
      final cast = Cast(playing: true);
      final c = Ctx(settings: const AppSettings(autoplay: false), cast: cast);
      addTearDown(c.dispose);
      await c.controller.togglePlayback();
      expect(cast.stops, 1);
      expect(c.playback.plays, isEmpty);
    });

    test('ohne laufenden Cast-Sender startet Play lokal', () async {
      final cast = Cast(playing: false);
      final c = Ctx(settings: const AppSettings(autoplay: false), cast: cast);
      addTearDown(c.dispose);
      await c.controller.togglePlayback();
      expect(cast.stops, 0);
      expect(c.playback.plays, hasLength(1));
    });

    test('Anzeige: Cast-Sender gilt als "spielt"', () {
      final station = stationsCatalog[1];
      const local = PlayerUiState(volume: 0.5);
      final cast = CastState(
        available: true,
        connectedDevice: const CastDevice(id: 'tv', name: 'TV'),
        station: station,
      );
      final merged = mergeCastPlayback(local, cast);
      expect(merged.isPlaying, isTrue);
      expect(merged.station, station);
      expect(merged.volume, 0.5);
      expect(mergeCastPlayback(local, const CastState()), local);
    });
  });
}
