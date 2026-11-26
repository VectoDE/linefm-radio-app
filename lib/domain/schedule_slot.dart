/// Wochentag eines Sendeplan-Eintrags (laut.fm: `mon` bis `sun`).
enum ScheduleDay {
  mon,
  tue,
  wed,
  thu,
  fri,
  sat,
  sun;

  /// Entspricht [DateTime.weekday] (Montag = 1 ... Sonntag = 7).
  int get weekday => index + 1;

  static ScheduleDay? tryParse(Object? value) {
    if (value is! String) return null;
    final key = value.trim().toLowerCase();
    for (final day in values) {
      if (day.name == key) return day;
    }
    return null;
  }
}

/// Ein Block des laut.fm-Sendeplans (`GET /station/{slug}/schedule`).
///
/// [startHour] ist die Startstunde (0 bis 23). [endHour] ist die Stunde,
/// in der der Block endet (1 bis 24); `null`, wenn laut.fm keine Endzeit
/// liefert (dann gilt der Block bis zum naechsten Eintrag, bei
/// Rund-um-die-Uhr-Sendern den ganzen Tag). Ein [endHour] kleiner oder
/// gleich [startHour] bedeutet, dass der Block ueber Mitternacht laeuft.
class ScheduleSlot {
  const ScheduleSlot({
    required this.name,
    required this.day,
    required this.startHour,
    this.id,
    this.endHour,
    this.description,
    this.colorHex,
    this.shuffled,
  });

  final int? id;
  final String name;
  final ScheduleDay day;
  final int startHour;
  final int? endHour;
  final String? description;

  /// Farbe als `#rrggbb`, wie von laut.fm geliefert.
  final String? colorHex;
  final bool? shuffled;
}
