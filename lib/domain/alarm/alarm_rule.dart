/// Weckerregel: Uhrzeit (lokale Zeit des Geraets), Sender, Wochentage.
class AlarmRule {
  const AlarmRule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.stationSlug,
    this.weekdays = const <int>{},
    this.volume = 1.0,
    this.enabled = true,
  }) : assert(hour >= 0 && hour < 24, 'hour 0..23'),
       assert(minute >= 0 && minute < 60, 'minute 0..59');

  /// Tolerant: gibt `null` zurueck, wenn Pflichtfelder fehlen oder ausserhalb
  /// des gueltigen Bereichs liegen. Ungueltige Wochentage werden verworfen,
  /// die Lautstaerke wird auf 0..1 begrenzt.
  static AlarmRule? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final hour = json['hour'];
    final minute = json['minute'];
    final slug = json['stationSlug'];
    if (id is! String || id.isEmpty) return null;
    if (hour is! int || hour < 0 || hour > 23) return null;
    if (minute is! int || minute < 0 || minute > 59) return null;
    if (slug is! String || slug.isEmpty) return null;
    final days = json['weekdays'];
    final volume = json['volume'];
    final enabled = json['enabled'];
    return AlarmRule(
      id: id,
      hour: hour,
      minute: minute,
      stationSlug: slug,
      weekdays: days is List
          ? <int>{
              for (final d in days)
                if (d is int && d >= 1 && d <= 7) d,
            }
          : const <int>{},
      volume: volume is num && volume.isFinite
          ? volume.toDouble().clamp(0.0, 1.0)
          : 1.0,
      enabled: enabled is bool ? enabled : true,
    );
  }

  final String id;
  final int hour;
  final int minute;
  final String stationSlug;

  /// ISO-Wochentage 1 (Mo) bis 7 (So); leer = einmalig.
  final Set<int> weekdays;
  final double volume;
  final bool enabled;

  /// Wiederholt sich die Regel (mindestens ein Wochentag)?
  bool get repeats => weekdays.isNotEmpty;

  AlarmRule copyWith({
    String? id,
    int? hour,
    int? minute,
    String? stationSlug,
    Set<int>? weekdays,
    double? volume,
    bool? enabled,
  }) => AlarmRule(
    id: id ?? this.id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    stationSlug: stationSlug ?? this.stationSlug,
    weekdays: weekdays ?? this.weekdays,
    volume: volume ?? this.volume,
    enabled: enabled ?? this.enabled,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'hour': hour,
    'minute': minute,
    'stationSlug': stationSlug,
    'weekdays': (weekdays.toList()..sort()),
    'volume': volume,
    'enabled': enabled,
  };

  @override
  bool operator ==(Object other) =>
      other is AlarmRule &&
      other.id == id &&
      other.hour == hour &&
      other.minute == minute &&
      other.stationSlug == stationSlug &&
      _sameSet(other.weekdays, weekdays) &&
      other.volume == volume &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(
    id,
    hour,
    minute,
    stationSlug,
    Object.hashAllUnordered(weekdays),
    volume,
    enabled,
  );

  @override
  String toString() =>
      'AlarmRule($id ${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')} $stationSlug)';
}

bool _sameSet(Set<int> a, Set<int> b) =>
    a.length == b.length && a.containsAll(b);
