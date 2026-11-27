/// Uhr-Abstraktion fuer Timer- und Wecker-Logik (Tests nutzen eine eigene Uhr).
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
