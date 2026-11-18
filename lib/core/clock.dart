/// Uhr-Abstraktion fuer Timer- und Wecker-Logik (Tests nutzen [FakeClock]).
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void setTo(DateTime t) => _now = t;
}
