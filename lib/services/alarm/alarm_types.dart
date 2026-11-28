part of 'alarm_coordinator.dart';

/// Ein klingelnder Wecker. [ruleId] kann das Suffix [snoozeSuffix] tragen
/// (Schlummer-Wiederholung).
class AlarmRing {
  const AlarmRing({required this.ruleId, this.handle, this.at});

  final String ruleId;

  /// Plattform-Kennung (Android: Alarm-ID), nur fuer [AlarmPlatform.silence].
  final int? handle;

  /// Klingelzeitpunkt; unterscheidet Wiederholungen (Schlummern) desselben
  /// Alarms von erneut gemeldeten Ereignissen.
  final DateTime? at;

  /// Schluessel gegen doppelte Verarbeitung.
  String get key =>
      '$ruleId@${handle ?? ''}@${at?.millisecondsSinceEpoch ?? ''}';

  bool get isSnoozeRing => ruleId.endsWith(snoozeSuffix);

  /// Regel-ID ohne Schlummer-Suffix.
  String get baseRuleId => baseRuleIdOf(ruleId);
}

/// Anhang an die Regel-ID fuer die Schlummer-Wiederholung.
const String snoozeSuffix = '~snooze';

String baseRuleIdOf(String ruleId) => ruleId.endsWith(snoozeSuffix)
    ? ruleId.substring(0, ruleId.length - snoozeSuffix.length)
    : ruleId;

/// Zustand eines klingelnden Alarms nach Sicht der Plattform.
enum AlarmRingState {
  /// Der Weckton laeuft noch.
  ringing,

  /// Der Nutzer hat ueber die System-Benachrichtigung geschlummert.
  snoozed,

  /// Beendet (gestoppt oder entfernt).
  ended,
}

/// Plattformabhaengige Wecker-Ausfuehrung (alarm_android, alarm_ios,
/// alarm_inapp).
abstract interface class AlarmPlatform {
  /// Meldet jeden klingelnden Wecker, solange die App laeuft (Android,
  /// Desktop, Web). iOS meldet nichts; dort startet das Antippen der
  /// Mitteilung den Sender ueber den Deep Link `linefm://play?station=`.
  Stream<AlarmRing> get rings;

  /// Spielt die Plattform selbst einen Weckton (Android: Systemton)? Sonst
  /// braucht der Koordinator bei fehlendem Stream einen Ersatzton.
  bool get ringsItself;

  Future<void> init();

  /// Ersetzt alle geplanten Termine der Regel durch die kommenden. Bei einer
  /// ausgeschalteten Regel entfallen alle kuenftigen Termine; ein klingelnder
  /// oder nativ geschlummerter Alarm bleibt unberuehrt (kein stilles
  /// Verschlafen).
  Future<void> schedule(AlarmRule rule);

  /// Entfernt alle Termine der Regel (auch Schlummer, auch einen laufenden
  /// Ton). Nur fuer geloeschte Regeln.
  Future<void> cancel(String ruleId);

  /// Entfernt alle Termine, deren Regel nicht in [knownRuleIds] steht
  /// (Schlummer-IDs zaehlen zur Basisregel). Raeumt Reste nach Loeschen und
  /// "Speicher loeschen" auf, auch nach einem Kaltstart.
  Future<void> removeOrphans(Set<String> knownRuleIds);

  /// Aktueller Zustand eines gemeldeten Klingelns.
  Future<AlarmRingState> ringState(AlarmRing ring);

  /// Beendet den Weckton, sobald der Sender laeuft (Android: Systemton;
  /// sonst nichts zu tun). Stoppt nur, solange der Alarm wirklich klingelt.
  Future<void> silence(AlarmRing ring);

  Future<void> dispose();
}

/// Was die Oberflaeche beim Klingeln zeigt (Banner mit Schlummern/Aus).
class AlarmRinging {
  const AlarmRinging({required this.ruleId, required this.station});

  /// Basis-Regel-ID.
  final String ruleId;
  final Station station;
}

/// Koordiniert Regeln, Plattform und Sendestart.
abstract interface class AlarmCoordinator {
  /// Klingelnder Wecker, solange der Nutzer nicht geschlummert oder
  /// ausgeschaltet hat; `null` sonst.
  ValueListenable<AlarmRinging?> get ringing;

  Future<void> rescheduleAll(List<AlarmRule> rules);

  Future<void> snooze(String ruleId);

  Future<void> dismiss(String ruleId);
}
