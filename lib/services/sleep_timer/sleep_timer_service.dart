import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/track.dart';

/// Sleeptimer mit Ausblenden und "Ende des Songs" (Spec 4.2 Nr. 9).
/// Implementierung: P20.
abstract interface class SleepTimerService {
  SleepTimerState get state;

  Stream<SleepTimerState> get states;

  Future<void> start(SleepTimerMode mode, {Track? currentTrack});

  Future<void> cancel();

  Future<void> dispose();
}

class NoopSleepTimerService implements SleepTimerService {
  const NoopSleepTimerService();

  @override
  SleepTimerState get state => const SleepTimerState();

  @override
  Stream<SleepTimerState> get states =>
      Stream<SleepTimerState>.value(const SleepTimerState());

  @override
  Future<void> start(SleepTimerMode mode, {Track? currentTrack}) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}
