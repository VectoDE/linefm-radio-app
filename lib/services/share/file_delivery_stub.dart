import 'dart:typed_data';

/// Auf Plattformen ohne Dateizugriff nicht verfuegbar.
Future<String> saveToDownloadFolder(String fileName, Uint8List bytes) =>
    Future<String>.error(UnsupportedError('Kein Download-Ordner verfuegbar.'));

/// Auf Plattformen ohne Browser nicht verfuegbar.
void triggerBrowserDownload(String fileName, Uint8List bytes, String mime) =>
    throw UnsupportedError('Kein Browser-Download verfuegbar.');
