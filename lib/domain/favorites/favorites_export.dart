import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

enum ExportFormat { csv, text }

/// Spaltenkoepfe des CSV-Exports je Sprache.
class FavoritesExportLabels {
  const FavoritesExportLabels({
    required this.title,
    required this.artist,
    required this.station,
    required this.savedAt,
  });

  static const FavoritesExportLabels de = FavoritesExportLabels(
    title: 'Titel',
    artist: 'Künstler',
    station: 'Sender',
    savedAt: 'Gemerkt am',
  );

  static const FavoritesExportLabels en = FavoritesExportLabels(
    title: 'Title',
    artist: 'Artist',
    station: 'Station',
    savedAt: 'Saved on',
  );

  final String title;
  final String artist;
  final String station;
  final String savedAt;
}

/// Export der Favoriten: CSV (UTF-8 mit BOM, Semikolon, CRLF; oeffnet in
/// deutschem Excel direkt korrekt) oder Textliste.
class FavoritesExport {
  const FavoritesExport._();

  /// Byte Order Mark, damit Excel UTF-8 erkennt.
  static const String bom = '﻿';

  static String build(
    List<Favorite> favorites,
    ExportFormat format, {
    FavoritesExportLabels labels = FavoritesExportLabels.de,
  }) => switch (format) {
    ExportFormat.csv => _csv(favorites, labels),
    ExportFormat.text => _text(favorites),
  };

  static String stationName(Favorite f) =>
      stationBySlug(f.stationSlug)?.displayName ?? f.stationSlug;

  static String _csv(List<Favorite> favorites, FavoritesExportLabels labels) {
    final rows = <List<String>>[
      <String>[labels.title, labels.artist, labels.station, labels.savedAt],
      for (final f in favorites)
        <String>[f.title, f.artist, stationName(f), formatDate(f.savedAt)],
    ];
    return bom + rows.map((r) => r.map(escapeCsv).join(';')).join('\r\n');
  }

  static String _text(List<Favorite> favorites) => favorites
      .map((f) {
        final who = f.artist.isEmpty ? f.title : '${f.artist} - ${f.title}';
        return '$who (${stationName(f)})';
      })
      .join('\n');

  /// Feldmaskierung nach RFC 4180 (Anfuehrungszeichen verdoppeln, Feld
  /// einklammern bei Trenner, Anfuehrungszeichen und Zeilenumbruch) plus
  /// Schutz vor Formel-Einschleusung in Tabellenkalkulationen: Felder, die mit
  /// `=`, `+`, `-`, `@`, Tab oder CR beginnen, erhalten ein vorangestelltes `'`.
  static String escapeCsv(String value) {
    var v = value;
    if (v.isNotEmpty && '=+-@\t\r'.contains(v[0])) v = "'$v";
    if (v.contains(';') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  /// `yyyy-MM-dd HH:mm` in lokaler Zeit; leer ohne Datum.
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}
