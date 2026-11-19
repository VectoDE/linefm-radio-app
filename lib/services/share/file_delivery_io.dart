import 'dart:io';
import 'dart:typed_data';

/// Download-Ordner des Nutzers: Windows `%USERPROFILE%\Downloads`, Linux
/// `XDG_DOWNLOAD_DIR` aus `~/.config/user-dirs.dirs` (sonst `~/Downloads`),
/// macOS `~/Downloads`. `null`, wenn kein Ordner ermittelbar ist.
Directory? downloadDirectory({
  Map<String, String>? environment,
  String Function(String path)? readFile,
}) {
  final env = environment ?? Platform.environment;
  final home = Platform.isWindows ? env['USERPROFILE'] : env['HOME'];
  if (home == null || home.isEmpty) return null;
  if (Platform.isLinux) {
    final xdg = _xdgDownloads(
      home,
      readFile ?? (p) => File(p).readAsStringSync(),
    );
    if (xdg != null) return Directory(xdg);
  }
  return Directory('$home${Platform.pathSeparator}Downloads');
}

String? _xdgDownloads(String home, String Function(String path) readFile) {
  try {
    final text = readFile('$home/.config/user-dirs.dirs');
    final m = RegExp(
      r'^XDG_DOWNLOAD_DIR="?([^"\n]+)"?',
      multiLine: true,
    ).firstMatch(text);
    if (m == null) return null;
    return m.group(1)!.replaceAll(r'$HOME', home);
  } on Object {
    return null;
  }
}

/// Freier Dateiname: haengt " (1)", " (2)" ... an, statt zu ueberschreiben.
String uniqueFileName(String fileName, bool Function(String name) exists) {
  if (!exists(fileName)) return fileName;
  final dot = fileName.lastIndexOf('.');
  final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
  final ext = dot > 0 ? fileName.substring(dot) : '';
  for (var i = 1; i < 1000; i++) {
    final candidate = '$stem ($i)$ext';
    if (!exists(candidate)) return candidate;
  }
  return fileName;
}

/// Schreibt die Datei in den Download-Ordner (legt ihn bei Bedarf an) und
/// liefert den vollen Pfad.
Future<String> saveToDownloadFolder(
  String fileName,
  Uint8List bytes, {
  Directory? into,
}) async {
  final dir = into ?? downloadDirectory();
  if (dir == null) {
    throw const FileSystemException('Download-Ordner nicht gefunden');
  }
  await dir.create(recursive: true);
  final name = uniqueFileName(
    fileName,
    (n) => File('${dir.path}${Platform.pathSeparator}$n').existsSync(),
  );
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// Nur im Browser verfuegbar.
void triggerBrowserDownload(String fileName, Uint8List bytes, String mime) =>
    throw UnsupportedError('Kein Browser-Download verfuegbar.');
