import 'dart:ui' show PlatformDispatcher;

/// Texte der System-Benachrichtigung des Weckers (Android-Dienst und iOS-
/// Mitteilung laufen ausserhalb des Widget-Baums, daher ohne BuildContext).
/// Folgt der Systemsprache: Deutsch, sonst Englisch.
class AlarmTexts {
  const AlarmTexts({
    required this.title,
    required this.stopButton,
    required this.snoozeButton,
    required this._body,
  });

  factory AlarmTexts.forLanguage(String languageCode) =>
      languageCode == 'de' ? german : english;

  factory AlarmTexts.system() =>
      AlarmTexts.forLanguage(PlatformDispatcher.instance.locale.languageCode);

  static final AlarmTexts german = AlarmTexts(
    title: 'LINEFM Radio',
    stopButton: 'Stoppen',
    snoozeButton: 'Schlummern',
    body: (station) => 'Wecker: $station',
  );

  static final AlarmTexts english = AlarmTexts(
    title: 'LINEFM Radio',
    stopButton: 'Stop',
    snoozeButton: 'Snooze',
    body: (station) => 'Alarm: $station',
  );

  final String title;
  final String stopButton;
  final String snoozeButton;
  final String Function(String stationName) _body;

  String body(String stationName) => _body(stationName);
}
