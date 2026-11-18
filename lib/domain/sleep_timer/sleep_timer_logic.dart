import 'package:linefm_radio/domain/track.dart';

/// Sleeptimer-Modus.
sealed class SleepTimerMode {
  const SleepTimerMode();
}

final class SleepTimerOff extends SleepTimerMode {
  const SleepTimerOff();

  @override
  bool operator ==(Object other) => other is SleepTimerOff;

  @override
  int get hashCode => (SleepTimerOff).hashCode;
}

final class SleepTimerMinutes extends SleepTimerMode {
  const SleepTimerMinutes(this.minutes);
  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is SleepTimerMinutes && other.minutes == minutes;

  @override
  int get hashCode => Object.hash(SleepTimerMinutes, minutes);
}

/// Stoppt am Ende des laufenden Songs (nutzt `ends_at` der API).
final class SleepTimerEndOfSong extends SleepTimerMode {
  const SleepTimerEndOfSong();

  @override
  bool operator ==(Object other) => other is SleepTimerEndOfSong;

  @override
  int get hashCode => (SleepTimerEndOfSong).hashCode;
}

class SleepTimerState {
  const SleepTimerState({this.mode = const SleepTimerOff(), this.endsAt});

  final SleepTimerMode mode;

  /// Zeitpunkt, zu dem die Wiedergabe endet. Bei [SleepTimerEndOfSong] `null`,
  /// wenn das Songende unbekannt ist; dann beendet der Dienst beim naechsten
  /// Titelwechsel.
  final DateTime? endsAt;

  bool get isActive => mode is! SleepTimerOff;

  SleepTimerState copyWith({SleepTimerMode? mode, DateTime? endsAt}) =>
      SleepTimerState(mode: mode ?? this.mode, endsAt: endsAt ?? this.endsAt);

  @override
  bool operator ==(Object other) =>
      other is SleepTimerState && other.mode == mode && other.endsAt == endsAt;

  @override
  int get hashCode => Object.hash(mode, endsAt);
}

/// Reine Rechenlogik des Sleeptimers. Zeit kommt immer als Parameter
/// (`Clock.now()`), damit alles ohne echte Uhr testbar ist.
class SleepTimerLogic {
  const SleepTimerLogic._();

  /// Beginn des Ausblendens vor Ende.
  static const Duration fadeLead = Duration(seconds: 20);

  /// Auswahl in den Einstellungen (Web-App: Aus/15/30/45/60 Minuten).
  static const List<int> presetMinutes = <int>[15, 30, 45, 60];

  /// Abgelaufen-Status ohne laufenden Timer.
  static const SleepTimerState off = SleepTimerState();

  /// Startet einen Timer. Minuten <= 0 ergeben "aus". Bei "Ende des Songs"
  /// zaehlt `currentTrack.endsAt`, sofern es in der Zukunft liegt; sonst ist
  /// das Ende unbekannt ([SleepTimerState.endsAt] `null`).
  static SleepTimerState start(
    SleepTimerMode mode,
    DateTime now, {
    Track? currentTrack,
  }) => switch (mode) {
    SleepTimerOff() => off,
    SleepTimerMinutes(:final minutes) =>
      minutes <= 0
          ? off
          : SleepTimerState(
              mode: mode,
              endsAt: now.add(Duration(minutes: minutes)),
            ),
    SleepTimerEndOfSong() => SleepTimerState(
      mode: mode,
      endsAt: _futureOrNull(currentTrack?.endsAt, now),
    ),
  };

  /// Abbruch.
  static SleepTimerState cancel() => off;

  /// Restzeit, nie negativ. `null` bei inaktivem Timer oder unbekanntem Ende.
  static Duration? remaining(SleepTimerState state, DateTime now) {
    final end = state.endsAt;
    if (!state.isActive || end == null) return null;
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Ende erreicht (nur bei bekanntem Ende).
  static bool isExpired(SleepTimerState state, DateTime now) {
    final left = remaining(state, now);
    return left != null && left == Duration.zero;
  }

  /// Zeitpunkt, ab dem die Lautstaerke ausgeblendet wird.
  static DateTime? fadeStartsAt(SleepTimerState state) {
    final end = state.endsAt;
    if (!state.isActive || end == null) return null;
    return end.subtract(fadeLead);
  }

  /// Lautstaerkefaktor 1.0 bis 0.0: voll bis [fadeLead] vor Ende, danach
  /// linear auf 0. Ohne aktiven Timer oder unbekanntes Ende: 1.0.
  static double fadeFactor(SleepTimerState state, DateTime now) {
    final left = remaining(state, now);
    if (left == null || left >= fadeLead) return 1;
    return left.inMicroseconds / fadeLead.inMicroseconds;
  }

  static DateTime? _futureOrNull(DateTime? t, DateTime now) =>
      t != null && t.isAfter(now) ? t : null;
}
