import 'package:linefm_radio/domain/alarm/alarm_rule.dart';

/// Terminberechnung fuer Wecker, plattformneutral.
///
/// Rechnet mit lokaler Zeit (`DateTime` ohne UTC). Kalendertage werden ueber
/// den Konstruktor `DateTime(y, m, d + n, h, min)` weitergezaehlt und nie ueber
/// `+ Duration(days: n)`: Nur so bleibt die Uhrzeit bei der Zeitumstellung
/// (Europe/Berlin, letzter Sonntag im Maerz/Oktober) stabil. Faellt die Zeit
/// in die uebersprungene Stunde (z. B. 02:30 am Umstellungstag im Maerz),
/// verschiebt Dart sie auf den naechsten gueltigen Zeitpunkt (03:30), der
/// Wecker klingelt also etwas spaeter statt gar nicht. In der doppelten
/// Herbststunde gilt der erste Durchlauf.
class AlarmSchedule {
  const AlarmSchedule._();

  /// Schlummerdauer.
  static const Duration snooze = Duration(minutes: 9);

  /// Suchfenster: eine Woche plus ein Tag Puffer.
  static const int _searchDays = 8;

  /// Naechster Klingelzeitpunkt strikt nach [now]. `null`, wenn die Regel
  /// deaktiviert ist.
  ///
  /// Ohne Wochentage (einmalig): heute, falls die Uhrzeit noch bevorsteht,
  /// sonst morgen. Mit Wochentagen: der naechste passende Tag (ISO 1 = Montag).
  static DateTime? nextOccurrence(AlarmRule rule, DateTime now) {
    if (!rule.enabled) return null;
    for (var offset = 0; offset < _searchDays; offset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + offset,
        rule.hour,
        rule.minute,
      );
      final dayMatches =
          rule.weekdays.isEmpty || rule.weekdays.contains(candidate.weekday);
      if (dayMatches && candidate.isAfter(now)) return candidate;
    }
    return null;
  }

  /// Frueheste Klingelzeit aller Regeln, `null` ohne aktive Regel.
  static DateTime? nextOf(Iterable<AlarmRule> rules, DateTime now) {
    DateTime? best;
    for (final rule in rules) {
      final next = nextOccurrence(rule, now);
      if (next != null && (best == null || next.isBefore(best))) best = next;
    }
    return best;
  }

  /// Zeitpunkt nach dem Schlummern.
  static DateTime snoozeUntil(DateTime now) => now.add(snooze);

  /// Faelligkeitspruefung fuer Desktop/Web, wo ein Timer die Wanduhr alle
  /// ~15 s abfragt: War zwischen [previousCheck] (exklusiv) und [now]
  /// (inklusiv) ein Klingelzeitpunkt? Faengt Ruhezustand und Uhrspruenge ab.
  static bool isDue(
    AlarmRule rule, {
    required DateTime previousCheck,
    required DateTime now,
  }) {
    final next = nextOccurrence(rule, previousCheck);
    return next != null && !next.isAfter(now);
  }

  /// Regel nach dem Klingeln: Einmalige Wecker schalten sich aus,
  /// wiederkehrende bleiben unveraendert.
  static AlarmRule afterFired(AlarmRule rule) =>
      rule.repeats ? rule : rule.copyWith(enabled: false);
}
