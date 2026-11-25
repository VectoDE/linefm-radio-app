import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/favorites/favorites_import.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Dateityp-Filter fuer den Dialog: eigener Export als CSV oder Text.
const XTypeGroup favoritesImportTypes = XTypeGroup(
  label: 'LINEFM',
  extensions: <String>['csv', 'txt'],
  mimeTypes: <String>['text/csv', 'text/plain', 'text/comma-separated-values'],
  uniformTypeIdentifiers: <String>[
    'public.comma-separated-values-text',
    'public.plain-text',
  ],
);

/// Oeffnet den Datei-Dialog des Systems. Austauschbar fuer Tests.
typedef FavoritesFilePicker = Future<XFile?> Function();

Future<XFile?> _systemPicker() =>
    openFile(acceptedTypeGroups: const <XTypeGroup>[favoritesImportTypes]);

/// Import-Einstieg: Datei waehlen (CSV oder Text aus dem eigenen
/// Export), lesen, mit den vorhandenen Favoriten zusammenfuehren, Ergebnis
/// als SnackBar. Web: `<input type=file>` ueber file_selector_web; Android,
/// iOS, macOS, Windows, Linux: System-Dateidialog.
Future<void> startFavoritesImport(
  BuildContext context,
  WidgetRef ref, {
  FavoritesFilePicker picker = _systemPicker,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  // Vorige Meldung (z. B. vom letzten Import) sofort ersetzen statt anstellen.
  void show(String text) => messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  final XFile? file;
  try {
    file = await picker();
  } on Object catch (e) {
    logError('Datei-Dialog fuer den Import nicht geoeffnet', e);
    show(l10n.favoritesImportFailed);
    return;
  }
  if (file == null) return;

  final FavoritesImportResult result;
  try {
    if (await file.length() > FavoritesImport.maxBytes) {
      throw const FormatException('Datei zu gross');
    }
    final bytes = await file.readAsBytes();
    result = FavoritesImport.parse(utf8.decode(bytes, allowMalformed: true));
  } on Object catch (e) {
    logError('Favoriten-Import: Datei nicht lesbar', e);
    show(l10n.favoritesImportFailed);
    return;
  }

  final added = ref
      .read(favoritesProvider.notifier)
      .importFavorites(result.favorites);
  final message = result.skipped == 0
      ? l10n.favoritesImportDone(added)
      : '${l10n.favoritesImportDone(added)} '
            '${l10n.favoritesImportSkipped(result.skipped)}';
  show(message);
}
