import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/l10n/system_l10n.dart';

/// Texte der System-Benachrichtigung des Weckers (Android-Dienst und iOS-
/// Mitteilung laufen ausserhalb des Widget-Baums, daher ohne BuildContext).
/// Quelle sind die ARB-Dateien (I05): `alarmNotificationTitle`,
/// `alarmDismiss`, `alarmSnooze`, `alarmNotificationBody`. Folgt der
/// Systemsprache: Deutsch, sonst Englisch.
class AlarmTexts {
  const AlarmTexts({
    required this.title,
    required this.stopButton,
    required this.snoozeButton,
    required this._body,
  });

  factory AlarmTexts.fromLocalizations(AppLocalizations l10n) => AlarmTexts(
    title: l10n.alarmNotificationTitle,
    stopButton: l10n.alarmDismiss,
    snoozeButton: l10n.alarmSnooze,
    body: l10n.alarmNotificationBody,
  );

  factory AlarmTexts.forLanguage(String languageCode) =>
      AlarmTexts.fromLocalizations(systemLocalizations(languageCode));

  factory AlarmTexts.system() =>
      AlarmTexts.fromLocalizations(systemLocalizations());

  static final AlarmTexts german = AlarmTexts.forLanguage('de');

  static final AlarmTexts english = AlarmTexts.forLanguage('en');

  final String title;
  final String stopButton;
  final String snoozeButton;
  final String Function(String stationName) _body;

  String body(String stationName) => _body(stationName);
}
