import 'package:linefm_radio/data/storage/prefs_store.dart';

/// Web: bewusst No-Op. Die Daten der alten Web-App liegen im localStorage der
/// Origin app.linecast.de und sind unter der neuen Domain app.linefm.de nicht
/// erreichbar (Same-Origin-Policy). Begruendung in webapp_migration.dart.
Future<void> migrateWebappData(PrefsStore store) async {}
