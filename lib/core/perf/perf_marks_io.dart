import 'dart:io';

/// Haengt `<name>\t<Mikrosekunden seit 1970, UTC>` an die Datei aus
/// `LINEFM_PERF_FILE` an. Synchron, damit die Reihenfolge stimmt und nichts
/// verloren geht, falls der Messlauf den Prozess beendet. Fehler werden
/// geschluckt: die Messung darf die App nie stoeren.
void writeMark(String name) {
  final path = Platform.environment['LINEFM_PERF_FILE'];
  if (path == null || path.isEmpty) return;
  writeMarkTo(path, name);
}

/// Schreibt eine Messzeile nach [path] (getrennt fuer Tests).
void writeMarkTo(String path, String name) {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
  try {
    File(
      path,
    ).writeAsStringSync('$name\t$micros\n', mode: FileMode.append, flush: true);
  } on Object {
    // Messdatei nicht schreibbar: ohne Messung weiterlaufen.
  }
}
