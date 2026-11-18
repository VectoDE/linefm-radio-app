/// Sleeptimer-Modus (Stub, Logik folgt in P02/P20).
sealed class SleepTimerMode {
  const SleepTimerMode();
}

final class SleepTimerOff extends SleepTimerMode {
  const SleepTimerOff();
}

final class SleepTimerMinutes extends SleepTimerMode {
  const SleepTimerMinutes(this.minutes);
  final int minutes;
}

final class SleepTimerEndOfSong extends SleepTimerMode {
  const SleepTimerEndOfSong();
}

class SleepTimerState {
  const SleepTimerState({this.mode = const SleepTimerOff(), this.endsAt});

  final SleepTimerMode mode;
  final DateTime? endsAt;

  bool get isActive => mode is! SleepTimerOff;
}

class SleepTimerLogic {
  const SleepTimerLogic._();

  /// Beginn des Ausblendens vor Ende.
  static const Duration fadeLead = Duration(seconds: 20);
}
