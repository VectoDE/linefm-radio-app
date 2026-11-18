/// Weckerregel (Stub, wird in P02 ausgebaut).
class AlarmRule {
  const AlarmRule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.stationSlug,
    this.weekdays = const <int>{},
    this.volume = 1.0,
    this.enabled = true,
  });

  final String id;
  final int hour;
  final int minute;
  final String stationSlug;

  /// ISO-Wochentage 1 (Mo) bis 7 (So); leer = einmalig.
  final Set<int> weekdays;
  final double volume;
  final bool enabled;
}
