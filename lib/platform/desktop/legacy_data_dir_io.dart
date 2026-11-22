import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

/// Company name the Windows runner used before #98 (`windows/runner/Runner.rc`).
const String legacyCompanyName = 'de.linefm';

/// Current company name in `Runner.rc`.
const String companyName = 'LineFM Studios';

/// Product name in `Runner.rc`.
const String productName = 'LINEFM Radio';

/// Moves the Windows data folder (favorites, settings, window state) from
/// `%APPDATA%\de.linefm\LINEFM Radio` to `%APPDATA%\LineFM Studios\LINEFM Radio`.
///
/// `path_provider_windows` derives the folder from CompanyName and
/// ProductName of the EXE, so renaming the company would otherwise start
/// the app with empty settings. Runs once, before anything opens
/// `SharedPreferences`. Does nothing on other platforms, when there is no
/// old folder, or when the new folder already holds data.
Future<void> migrateLegacyDataDir() async {
  if (!Platform.isWindows) return;
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) return;
  try {
    await migrateDataDir(
      from: Directory('$appData\\$legacyCompanyName\\$productName'),
      to: Directory('$appData\\$companyName\\$productName'),
    );
  } on Object catch (e) {
    // Never block the start: the app then runs with fresh settings.
    debugPrint('Legacy data folder not migrated: $e');
  }
}

/// Result of [migrateDataDir], for tests and logging.
enum DataDirMigration { noSource, targetHasData, moved, copied }

/// Moves [from] to [to]. Falls back to a recursive copy (then deletes the
/// source) when a rename is not possible. Leaves both untouched when [to]
/// already contains files.
@visibleForTesting
Future<DataDirMigration> migrateDataDir({
  required Directory from,
  required Directory to,
}) async {
  if (!from.existsSync()) return DataDirMigration.noSource;
  if (to.existsSync() && to.listSync().isNotEmpty) {
    return DataDirMigration.targetHasData;
  }
  to.parent.createSync(recursive: true);
  if (to.existsSync()) to.deleteSync();
  try {
    from.renameSync(to.path);
    _removeIfEmpty(from.parent);
    return DataDirMigration.moved;
  } on FileSystemException {
    await _copyDir(from, to);
    from.deleteSync(recursive: true);
    _removeIfEmpty(from.parent);
    return DataDirMigration.copied;
  }
}

Future<void> _copyDir(Directory from, Directory to) async {
  to.createSync(recursive: true);
  await for (final entity in from.list(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    final target = '${to.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      await _copyDir(entity, Directory(target));
    } else if (entity is File) {
      await entity.copy(target);
    }
  }
}

void _removeIfEmpty(Directory dir) {
  try {
    if (dir.existsSync() && dir.listSync().isEmpty) dir.deleteSync();
  } on FileSystemException {
    // Not important: an empty company folder may stay.
  }
}
