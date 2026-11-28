import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/player_controller.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/platform/deep_links.dart';

import 'app_host.dart';
import 'player_controller_helpers.dart';

void main() {
  test('secondsBucket: grobe Klassen', () {
    expect(secondsBucket(0), '<10');
    expect(secondsBucket(59), '10-59');
    expect(secondsBucket(3600), '3600+');
  });

  group('Telemetrie an einer Stelle', () {
    test('Start und Stop melden je genau ein play/stop', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      await c.controller.startStation(stationsCatalog[1]);
      await flush();
      await c.controller.togglePlayback();
      await flush();
      expect(c.sink.events, <String>[
        'play {station: linefmrap}',
        'stop {station: linefmrap, seconds_bucket: <10}',
      ]);
      expect(c.active, stationsCatalog[1]);
    });

    test('Senderwechsel waehrend der Wiedergabe: stop alt, play neu', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      await c.controller.startStation(stationsCatalog[0]);
      await flush();
      await c.controller.startStation(stationsCatalog[2]);
      await flush();
      expect(c.sink.names, <String>['play', 'stop', 'play']);
      expect(c.sink.events.last, 'play {station: linefmgaming}');
    });

    test('Neuverbindung zaehlt nicht doppelt', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      await c.controller.startStation(stationsCatalog[0]);
      await flush();
      c.playback
        ..emit(c.playback.state.copyWith(status: PlayerStatus.reconnecting))
        ..emit(c.playback.state.copyWith(status: PlayerStatus.playing));
      await flush();
      expect(c.sink.names, <String>['play']);
    });

    test('Fehler meldet error_stream, kein stop', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      c.controller; // Controller anlegen (abonniert den Zustand).
      c.playback
        ..emit(
          PlayerUiState(
            status: PlayerStatus.connecting,
            station: stationsCatalog[3],
          ),
        )
        ..emit(c.playback.state.copyWith(status: PlayerStatus.error));
      await flush();
      expect(c.sink.events, <String>[
        'play {station: linefmlofi}',
        'error_stream {station: linefmlofi}',
      ]);
    });

    test('vom System gestarteter Sender: Auswahl folgt', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      c.controller;
      await c.playback.playStation(stationsCatalog[4]);
      await flush();
      expect(c.active, stationsCatalog[4]);
      expect(c.sink.events, <String>['play {station: radio3fm}']);
    });
  });

  group('Steuerung', () {
    test('Shuffle spielt eine andere Station', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      final before = c.active;
      await c.controller.shuffleStation();
      expect(c.active, isNot(before));
      expect(c.playback.plays, <String>['play:${c.active.slug}']);
    });

    test('Lautstaerke wird nur mit "Lautstaerke merken" gespeichert', () async {
      final on = Ctx();
      addTearDown(on.dispose);
      await on.controller.setVolume(0.4);
      expect(on.prefs.readVolume(), 0.4);

      final off = Ctx(settings: const AppSettings(rememberVolume: false));
      addTearDown(off.dispose);
      await off.controller.setVolume(0.4);
      expect(off.prefs.readVolume(), isNull);
      expect(off.playback.state.volume, 0.4);
    });

    test('Titel geht an Benachrichtigung und Widget', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      c.controller;
      await flush();
      expect(c.playback.calls, contains("now:linefm:I Was Lovin' You"));
      expect(c.widget.updates, contains("linefm:I Was Lovin' You:false"));
    });

    test('gewaehlte Station und Wiedergabe steuern den Live-Motor', () async {
      final c = Ctx();
      addTearDown(c.dispose);
      final repo = c.container.read(nowPlayingRepositoryProvider);
      c.container.read(playerStateProvider);
      await flush();
      await c.controller.startStation(stationsCatalog[1]);
      await flush();
      expect((repo as TestRepository).calls, contains('active:linefmrap'));
      expect(repo.calls, contains('playing:true'));
    });
  });

  group('Start', () {
    test(
      'Autoplay spielt die letzte Station, Lautstaerke kommt zurueck',
      () async {
        final c = Ctx(lastStation: 'linefmlofi', volume: 0.6);
        addTearDown(c.dispose);
        await c.controller.startup(web: false);
        expect(
          c.playback.calls,
          containsAllInOrder(<String>['volume:0.6', 'play:linefmlofi']),
        );
      },
    );

    test('Autoplay waits until the app is in the foreground', () async {
      final c = Ctx(lastStation: 'linefmlofi');
      addTearDown(c.dispose);
      final foreground = Completer<void>();
      final started = c.controller.startup(
        web: false,
        untilForeground: foreground.future,
      );
      await flush();
      expect(c.playback.plays, isEmpty);
      foreground.complete();
      await started;
      expect(c.playback.calls, contains('play:linefmlofi'));
    });

    test('Autoplay aus: nichts startet', () async {
      final c = Ctx(settings: const AppSettings(autoplay: false));
      addTearDown(c.dispose);
      await c.controller.startup(web: false);
      expect(c.playback.plays, isEmpty);
    });

    test('?station= waehlt den Sender', () async {
      final c = Ctx(settings: const AppSettings(autoplay: false));
      addTearDown(c.dispose);
      await c.controller.startup(
        launchUri: Uri.parse('https://app.linefm.de/?station=fobfm'),
        web: true,
      );
      expect(c.active.slug, 'fobfm');
    });

    test('Deep Link startet den Sender', () async {
      final c = Ctx(settings: const AppSettings(autoplay: false));
      addTearDown(c.dispose);
      await c.controller.startup(web: false);
      DeepLinks.dispatch(Uri.parse('linefm://play?station=linefmgaming'));
      await flush();
      await flush();
      expect(c.playback.calls, contains('play:linefmgaming'));
    });

    testWidgets('Web: Autoplay erst nach der ersten Nutzeraktion', (
      tester,
    ) async {
      final c = Ctx();
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      expect(c.controller.autoplayPending, isTrue);
      expect(c.playback.plays, isEmpty);

      c.controller.onUserInteraction();
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.playback.plays, <String>['play:linefm']);
    });

    testWidgets('Web: eigener Start in der ersten Aktion verhindert Autoplay', (
      tester,
    ) async {
      final c = Ctx();
      addTearDown(c.dispose);
      await c.controller.startup(web: true);
      c.controller.onUserInteraction();
      await c.controller.startStation(stationsCatalog[2]);
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.playback.plays, <String>['play:linefmgaming']);
    });
  });
}
