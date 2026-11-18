/// Wartezeiten fuer automatische Neuverbindungen nach Netzverlust
/// (Spec 3.3: bis zu 5 Versuche nach 2/4/8/16/30 s).
class ReconnectPolicy {
  const ReconnectPolicy({
    this.delays = const <Duration>[
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 16),
      Duration(seconds: 30),
    ],
  });

  final List<Duration> delays;

  int get maxAttempts => delays.length;

  /// Wartezeit vor Versuch [attempt] (0-basiert) oder `null`, wenn
  /// alle Versuche verbraucht sind.
  Duration? delayFor(int attempt) {
    if (attempt < 0 || attempt >= delays.length) return null;
    return delays[attempt];
  }
}
