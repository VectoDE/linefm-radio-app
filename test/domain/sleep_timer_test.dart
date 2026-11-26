import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/track.dart';

import '../support/test_doubles.dart';

void main() {
  final t0 = DateTime(2026, 11, 18, 22);

  group('start', () {
    test('Minuten: Ende = jetzt + Minuten', () {
      final s = SleepTimerLogic.start(const SleepTimerMinutes(30), t0);
      expect(s.isActive, isTrue);
      expect(s.endsAt, t0.add(const Duration(minutes: 30)));
    });

    test('Aus und Minuten <= 0 ergeben inaktiv', () {
      expect(
        SleepTimerLogic.start(const SleepTimerOff(), t0).isActive,
        isFalse,
      );
      expect(
        SleepTimerLogic.start(const SleepTimerMinutes(0), t0).isActive,
        isFalse,
      );
      expect(
        SleepTimerLogic.start(const SleepTimerMinutes(-5), t0).endsAt,
        isNull,
      );
    });

    test('Ende des Songs nutzt ends_at des Titels', () {
      final end = t0.add(const Duration(minutes: 2, seconds: 10));
      final s = SleepTimerLogic.start(
        const SleepTimerEndOfSong(),
        t0,
        currentTrack: Track(artist: 'A', title: 'T', endsAt: end),
      );
      expect(s.isActive, isTrue);
      expect(s.endsAt, end);
    });

    test(
      'Ende des Songs ohne oder mit vergangenem ends_at: aktiv, Ende unbekannt',
      () {
        final none = SleepTimerLogic.start(const SleepTimerEndOfSong(), t0);
        expect(none.isActive, isTrue);
        expect(none.endsAt, isNull);
        final past = SleepTimerLogic.start(
          const SleepTimerEndOfSong(),
          t0,
          currentTrack: Track(
            artist: 'A',
            title: 'T',
            endsAt: t0.subtract(const Duration(seconds: 1)),
          ),
        );
        expect(past.isActive, isTrue);
        expect(past.endsAt, isNull);
        expect(SleepTimerLogic.remaining(past, t0), isNull);
        expect(SleepTimerLogic.isExpired(past, t0), isFalse);
      },
    );

    test('Voreinstellungen wie Web-App', () {
      expect(SleepTimerLogic.presetMinutes, <int>[15, 30, 45, 60]);
    });
  });

  group('Restzeit mit FakeClock', () {
    test('zaehlt herunter und bleibt bei null stehen', () {
      final clock = FakeClock(t0);
      final s = SleepTimerLogic.start(const SleepTimerMinutes(15), clock.now());
      expect(
        SleepTimerLogic.remaining(s, clock.now()),
        const Duration(minutes: 15),
      );
      clock.advance(const Duration(minutes: 10));
      expect(
        SleepTimerLogic.remaining(s, clock.now()),
        const Duration(minutes: 5),
      );
      expect(SleepTimerLogic.isExpired(s, clock.now()), isFalse);
      clock.advance(const Duration(minutes: 5));
      expect(SleepTimerLogic.remaining(s, clock.now()), Duration.zero);
      expect(SleepTimerLogic.isExpired(s, clock.now()), isTrue);
      clock.advance(const Duration(hours: 1));
      expect(SleepTimerLogic.remaining(s, clock.now()), Duration.zero);
      expect(SleepTimerLogic.isExpired(s, clock.now()), isTrue);
    });

    test('Abbruch: kein Timer, keine Restzeit, nie abgelaufen', () {
      final s = SleepTimerLogic.start(const SleepTimerMinutes(15), t0);
      final cancelled = SleepTimerLogic.cancel();
      expect(cancelled.isActive, isFalse);
      expect(s.isActive, isTrue);
      expect(SleepTimerLogic.remaining(cancelled, t0), isNull);
      expect(
        SleepTimerLogic.isExpired(cancelled, t0.add(const Duration(days: 1))),
        isFalse,
      );
      expect(SleepTimerLogic.fadeFactor(cancelled, t0), 1);
      expect(SleepTimerLogic.fadeStartsAt(cancelled), isNull);
    });
  });

  group('Ausblenden 20 s vor Ende', () {
    final s = SleepTimerLogic.start(const SleepTimerMinutes(15), t0);
    final end = s.endsAt!;

    test('Fade-Beginn genau 20 s vor Ende', () {
      expect(SleepTimerLogic.fadeLead, const Duration(seconds: 20));
      expect(
        SleepTimerLogic.fadeStartsAt(s),
        end.subtract(const Duration(seconds: 20)),
      );
    });

    test('vor dem Fade volle Lautstaerke, danach linear auf 0', () {
      expect(SleepTimerLogic.fadeFactor(s, t0), 1);
      expect(
        SleepTimerLogic.fadeFactor(
          s,
          end.subtract(const Duration(seconds: 20)),
        ),
        1,
      );
      expect(
        SleepTimerLogic.fadeFactor(
          s,
          end.subtract(const Duration(seconds: 10)),
        ),
        closeTo(0.5, 1e-9),
      );
      expect(
        SleepTimerLogic.fadeFactor(s, end.subtract(const Duration(seconds: 5))),
        closeTo(0.25, 1e-9),
      );
      expect(SleepTimerLogic.fadeFactor(s, end), 0);
      expect(
        SleepTimerLogic.fadeFactor(s, end.add(const Duration(seconds: 3))),
        0,
      );
    });

    test('Timer unter 20 s startet direkt im Fade', () {
      final short = SleepTimerState(
        mode: const SleepTimerMinutes(1),
        endsAt: t0.add(const Duration(seconds: 10)),
      );
      expect(SleepTimerLogic.fadeFactor(short, t0), closeTo(0.5, 1e-9));
    });
  });

  group('Wertobjekte', () {
    test('Modi und Zustand sind wertgleich', () {
      expect(const SleepTimerMinutes(15), const SleepTimerMinutes(15));
      expect(const SleepTimerMinutes(15), isNot(const SleepTimerMinutes(30)));
      expect(
        const SleepTimerMinutes(15).hashCode,
        const SleepTimerMinutes(15).hashCode,
      );
      expect(const SleepTimerOff(), const SleepTimerOff());
      expect(const SleepTimerOff().hashCode, const SleepTimerOff().hashCode);
      expect(const SleepTimerEndOfSong(), const SleepTimerEndOfSong());
      expect(
        const SleepTimerEndOfSong().hashCode,
        const SleepTimerEndOfSong().hashCode,
      );
      expect(const SleepTimerOff(), isNot(const SleepTimerEndOfSong()));
      final a = SleepTimerState(mode: const SleepTimerMinutes(15), endsAt: t0);
      final b = SleepTimerState(mode: const SleepTimerMinutes(15), endsAt: t0);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(endsAt: t0.add(const Duration(seconds: 1))), isNot(a));
      expect(a.copyWith(mode: const SleepTimerOff()).isActive, isFalse);
    });
  });
}
