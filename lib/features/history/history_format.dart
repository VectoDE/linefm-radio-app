import 'package:material_ui/material_ui.dart';

/// Uhrzeit im Verlauf in lokaler Zeit, je Sprache und Geraeteeinstellung
/// (I02): Deutsch `08:07`, Englisch `8:07 AM`, bei 24-Stunden-Einstellung
/// des Geraets `08:07`. Gleiche Regel wie die Weckzeit.
String formatClock(
  DateTime time,
  MaterialLocalizations localizations, {
  bool alwaysUse24HourFormat = false,
}) => localizations.formatTimeOfDay(
  TimeOfDay.fromDateTime(time.toLocal()),
  alwaysUse24HourFormat: alwaysUse24HourFormat,
);

/// [formatClock] mit Sprache und Einstellung aus [context].
String formatClockFor(BuildContext context, DateTime time) => formatClock(
  time,
  MaterialLocalizations.of(context),
  alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
);
