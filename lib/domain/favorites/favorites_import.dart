import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

/// Ergebnis des Einlesens einer Export-Datei.
class FavoritesImportResult {
  const FavoritesImportResult({required this.favorites, required this.skipped});

  /// Gelesene Favoriten in Dateireihenfolge, ohne Doppelte.
  final List<Favorite> favorites;

  /// Zeilen, die nicht gelesen werden konnten (unbekannter Sender, kein
  /// Titel, kaputte Zeile).
  final int skipped;
}

/// Ergebnis des Zusammenfuehrens mit den vorhandenen Favoriten.
class FavoritesMergeResult {
  const FavoritesMergeResult({required this.favorites, required this.added});

  final List<Favorite> favorites;

  /// Neu hinzugekommene Favoriten.
  final int added;
}

/// Liest den eigenen Export wieder ein (Issue #9, Gegenstueck zu
/// [FavoritesExport]): CSV (Semikolon, optional BOM, Kopfzeile deutsch oder
/// englisch) oder Textliste (`Kuenstler - Titel (Sender)`).
class FavoritesImport {
  const FavoritesImport._();

  /// Groesste Datei, die eingelesen wird (Schutz vor versehentlich gewaehlten
  /// grossen Dateien). Ein Export mit 10.000 Favoriten hat etwa 1 MB.
  static const int maxBytes = 2 * 1024 * 1024;

  /// Erkennt das Format und liest alle Favoriten. Wirft [FormatException],
  /// wenn die Datei weder CSV noch Textliste des Exports ist.
  static FavoritesImportResult parse(String content) {
    var text = content;
    if (text.startsWith(FavoritesExport.bom)) text = text.substring(1);
    if (text.trim().isEmpty) {
      throw const FormatException('Leere Datei');
    }
    final firstLine = text.split(RegExp(r'\r?\n')).first;
    final header = _parseCsv(firstLine).firstOrNull ?? const <String>[];
    final columns = _columns(header);
    if (columns != null) return _fromCsv(text, columns);
    return _fromText(text);
  }

  /// Fuehrt [imported] mit [existing] zusammen: Vorhandene bleiben in ihrer
  /// Reihenfolge vorn, neue kommen in Dateireihenfolge dahinter. Doppelte
  /// (gleicher Schluessel: Sender, Kuenstler, Titel ohne Gross/Klein) werden
  /// zusammengefuehrt; fehlt beim vorhandenen das Datum, kommt es aus der
  /// Datei.
  static FavoritesMergeResult merge(
    List<Favorite> existing,
    List<Favorite> imported,
  ) {
    final byKey = <String, Favorite>{for (final f in imported) f.key: f};
    final result = <Favorite>[
      for (final f in existing)
        if (f.savedAt == null && byKey[f.key]?.savedAt != null)
          f.copyWith(savedAt: byKey[f.key]!.savedAt)
        else
          f,
    ];
    final known = <String>{for (final f in existing) f.key};
    var added = 0;
    for (final f in imported) {
      if (known.add(f.key)) {
        result.add(f);
        added++;
      }
    }
    return FavoritesMergeResult(favorites: result, added: added);
  }

  // ------------------------------------------------------------------ CSV

  static const List<FavoritesExportLabels> _labels = <FavoritesExportLabels>[
    FavoritesExportLabels.de,
    FavoritesExportLabels.en,
  ];

  /// Spaltenindizes (Titel, Kuenstler, Sender, Datum) aus der Kopfzeile;
  /// null, wenn es keine Kopfzeile des Exports ist.
  static (int, int, int, int?)? _columns(List<String> header) {
    final names = header.map((h) => h.trim().toLowerCase()).toList();
    for (final l in _labels) {
      final title = names.indexOf(l.title.toLowerCase());
      final artist = names.indexOf(l.artist.toLowerCase());
      final station = names.indexOf(l.station.toLowerCase());
      if (title < 0 || artist < 0 || station < 0) continue;
      final saved = names.indexOf(l.savedAt.toLowerCase());
      return (title, artist, station, saved < 0 ? null : saved);
    }
    return null;
  }

  static FavoritesImportResult _fromCsv(
    String text,
    (int, int, int, int?) columns,
  ) {
    final (titleCol, artistCol, stationCol, savedCol) = columns;
    final rows = _parseCsv(text).skip(1);
    final out = <Favorite>[];
    final keys = <String>{};
    var skipped = 0;
    for (final row in rows) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      String cell(int i) => i < row.length ? _unescape(row[i]).trim() : '';
      final favorite = _build(
        title: cell(titleCol),
        artist: cell(artistCol),
        station: cell(stationCol),
        savedAt: savedCol == null ? null : _parseDate(cell(savedCol)),
      );
      if (favorite == null) {
        skipped++;
      } else if (keys.add(favorite.key)) {
        out.add(favorite);
      }
    }
    return FavoritesImportResult(favorites: out, skipped: skipped);
  }

  /// RFC-4180-Leser mit Semikolon: Felder in Anfuehrungszeichen duerfen
  /// Semikolon, Zeilenumbruch und verdoppelte Anfuehrungszeichen enthalten.
  static List<List<String>> _parseCsv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i += 2;
            continue;
          }
          quoted = false;
        } else {
          field.write(ch);
        }
        i++;
        continue;
      }
      switch (ch) {
        case '"' when field.isEmpty:
          quoted = true;
        case ';':
          row.add(field.toString());
          field.clear();
        case '\r':
          break;
        case '\n':
          row.add(field.toString());
          field.clear();
          rows.add(row);
          row = <String>[];
        default:
          field.write(ch);
      }
      i++;
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  /// Hebt den Formelschutz des Exports auf (`'=…` wird wieder `=…`).
  static String _unescape(String value) {
    if (value.length > 1 && value[0] == "'" && '=+-@\t\r'.contains(value[1])) {
      return value.substring(1);
    }
    return value;
  }

  /// `yyyy-MM-dd HH:mm` (lokale Zeit, wie exportiert); sonst null.
  static DateTime? _parseDate(String value) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})')
        .firstMatch(value);
    if (m == null) return null;
    int g(int i) => int.parse(m.group(i)!);
    final date = DateTime(g(1), g(2), g(3), g(4), g(5));
    return date.month == g(2) && date.day == g(3) ? date : null;
  }

  // ----------------------------------------------------------------- Text

  static final RegExp _textLine = RegExp(r'^(.+) \(([^()]+)\)$');

  static FavoritesImportResult _fromText(String text) {
    final out = <Favorite>[];
    final keys = <String>{};
    var skipped = 0;
    var recognized = 0;
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = _textLine.firstMatch(line);
      if (m == null) {
        skipped++;
        continue;
      }
      recognized++;
      final who = m.group(1)!.trim();
      // Export: "Kuenstler - Titel"; ohne Kuenstler nur der Titel. Titel
      // enthalten oefter " - " (Remix, Live) als Kuenstlernamen.
      final split = who.indexOf(' - ');
      final favorite = _build(
        title: split < 0 ? who : who.substring(split + 3).trim(),
        artist: split < 0 ? '' : who.substring(0, split).trim(),
        station: m.group(2)!.trim(),
        savedAt: null,
      );
      if (favorite == null) {
        skipped++;
      } else if (keys.add(favorite.key)) {
        out.add(favorite);
      }
    }
    if (recognized == 0) {
      throw const FormatException('Kein Export von LINEFM Radio');
    }
    return FavoritesImportResult(favorites: out, skipped: skipped);
  }

  // ------------------------------------------------------------ gemeinsam

  static Favorite? _build({
    required String title,
    required String artist,
    required String station,
    required DateTime? savedAt,
  }) {
    if (title.isEmpty) return null;
    final match = _station(station);
    if (match == null) return null;
    return Favorite(
      key: FavoritesLogic.keyFor(
        stationSlug: match.slug,
        artist: artist,
        title: title,
      ),
      stationSlug: match.slug,
      title: title,
      artist: artist,
      artworkUrl: match.logoUrl,
      stationLogoUrl: match.logoUrl,
      savedAt: savedAt,
    );
  }

  /// Sender ueber den Anzeigenamen (wie exportiert) oder den Slug.
  static Station? _station(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;
    for (final s in stationsCatalog) {
      if (s.displayName.toLowerCase() == v || s.slug == v) return s;
    }
    return null;
  }
}
