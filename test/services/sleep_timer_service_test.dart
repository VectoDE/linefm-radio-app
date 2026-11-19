import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';

/// Merkt jede Lautstaerke und jeden Stop.
class _Playback extends NoopPlaybackService {
  final List<double> volumes = <double>[];
  int stops = 0;

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
    await super.setVolume(volume);
  }

  @override
  Future<void> stopPlayback() async {
    stops++;
    await super.stopPlayback();
  }
}

void main() {
  final t0 = DateTime(2026, 11, 18, 22);
  late FakeClock clock;
  late _Playback playback;
  late StreamController<Track?> tracks;
  late DefaultSleepTimerService service;

  setUp(() async {
    clock = FakeClock(t0);
    playback = _Playback();
    await playback.playStation(stationsCatalog.first);
    await playback.setVolume(0.8);
    playback.volumes.clear();
    tracks = StreamController<Track?>.broadcast();
    service = DefaultSleepTimerService(
      clock: clock,
      playback: playback,
      tracks: tracks.stream,
      tick: const Duration(days: 1), // Timer im Test nie von selbst
    );
  });

  tearDown(() async {
    await service.dispose();
    await tracks.close();
  });

  Track track({required String title, DateTime? endsAt}) =>
      Track(artist: 'A', title: title, endsAt: endsAt);

  test(
    'Minuten: stoppt nach Ablauf und stellt die Lautstaerke wieder her',
    () async {
      final seen = <SleepTimerState>[];
      final sub = service.states.listen(seen.add);
      await service.start(const SleepTimerMinutes(15));
      expect(service.state.endsAt, t0.add(const Duration(minutes: 15)));

      clock.advance(const Duration(minutes: 14));
      await service.tick();
      expect(playback.stops, 0);
      expect(playback.volumes, isEmpty, reason: 'noch kein Ausblenden');

      clock.advance(const Duration(minutes: 1));
      await service.tick();
      expect(playback.stops, 1);
      expect(playback.state.status, PlayerStatus.idle);
      expect(playback.state.volume, 0.8, reason: 'wiederhergestellt');
      expect(SleepTimerLogic.isExpired(service.state, clock.now()), isTrue);
      await sub.cancel();
      expect(seen, isNotEmpty);
    },
  );

  test('blendet in den letzten 20 s linear aus', () async {
    await service.start(const SleepTimerMinutes(15));
    clock.setTo(t0.add(const Duration(minutes: 15, seconds: -10)));
    await service.tick();
    expect(playback.volumes.single, closeTo(0.4, 1e-9));

    clock.setTo(t0.add(const Duration(minutes: 15, seconds: -5)));
    await service.tick();
    expect(playback.volumes.last, closeTo(0.2, 1e-9));
  });

  test(
    'Abbruch waehrend des Ausblendens stellt die Lautstaerke wieder her',
    () async {
      await service.start(const SleepTimerMinutes(15));
      clock.setTo(t0.add(const Duration(minutes: 15, seconds: -10)));
      await service.tick();
      await service.cancel();
      expect(playback.state.volume, 0.8);
      expect(service.state.isActive, isFalse);
      expect(playback.stops, 0);
    },
  );

  test('Aus beendet den laufenden Timer', () async {
    await service.start(const SleepTimerMinutes(15));
    await service.start(const SleepTimerOff());
    expect(service.state.isActive, isFalse);
    clock.advance(const Duration(hours: 1));
    await service.tick();
    expect(playback.stops, 0);
  });

  group('Ende des Songs', () {
    test('ohne bekanntes Songende (Live) nicht moeglich', () async {
      expect(sleepTimerEndOfSongAvailable(track(title: 'x'), t0), isFalse);
      expect(sleepTimerEndOfSongAvailable(null, t0), isFalse);
      await service.start(
        const SleepTimerEndOfSong(),
        currentTrack: track(title: 'x'),
      );
      expect(service.state.isActive, isFalse);
    });

    test('Songende in der Vergangenheit ist nicht moeglich', () async {
      final past = track(
        title: 'x',
        endsAt: t0.subtract(const Duration(seconds: 1)),
      );
      expect(sleepTimerEndOfSongAvailable(past, t0), isFalse);
    });

    test('stoppt zum Songende', () async {
      final song = track(
        title: 's',
        endsAt: t0.add(const Duration(minutes: 2)),
      );
      expect(sleepTimerEndOfSongAvailable(song, t0), isTrue);
      await service.start(const SleepTimerEndOfSong(), currentTrack: song);
      expect(service.state.endsAt, song.endsAt);
      clock.advance(const Duration(minutes: 2));
      await service.tick();
      expect(playback.stops, 1);
    });

    test(
      'Titelwechsel beendet sofort, auch vor dem berechneten Ende',
      () async {
        final song = track(
          title: 's',
          endsAt: t0.add(const Duration(minutes: 2)),
        );
        await service.start(const SleepTimerEndOfSong(), currentTrack: song);
        clock.advance(const Duration(minutes: 1, seconds: 50));
        tracks.add(track(title: 'naechster'));
        await Future<void>.delayed(Duration.zero);
        expect(playback.stops, 1);
      },
    );

    test(
      'gleicher Song mit korrigiertem Ende verschiebt die Endzeit',
      () async {
        final song = track(
          title: 's',
          endsAt: t0.add(const Duration(minutes: 2)),
        );
        await service.start(const SleepTimerEndOfSong(), currentTrack: song);
        final later = t0.add(const Duration(minutes: 3));
        tracks.add(song.copyWith(endsAt: later));
        await Future<void>.delayed(Duration.zero);
        expect(service.state.endsAt, later);
        expect(playback.stops, 0);
      },
    );
  });

  test(
    '7: nach Ablauf stoppt ein spaeterer Titelwechsel nicht erneut',
    () async {
      final song = track(
        title: 's',
        endsAt: t0.add(const Duration(minutes: 2)),
      );
      await service.start(const SleepTimerEndOfSong(), currentTrack: song);
      clock.advance(const Duration(minutes: 2));
      await service.tick();
      expect(playback.stops, 1);
      // Nutzer startet das Radio neu, danach wechselt der Titel.
      await playback.playStation(stationsCatalog.first);
      tracks.add(track(title: 'naechster'));
      await Future<void>.delayed(Duration.zero);
      expect(playback.stops, 1, reason: 'Timer ist abgelaufen, nichts mehr');
      expect(playback.state.status, PlayerStatus.playing);
    },
  );

  test('Ablauf ohne laufende Wiedergabe stoppt nichts', () async {
    await playback.stopPlayback();
    final before = playback.stops;
    await service.start(const SleepTimerMinutes(15));
    clock.advance(const Duration(minutes: 15));
    await service.tick();
    expect(playback.stops, before);
  });
}
