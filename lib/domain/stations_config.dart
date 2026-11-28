// Senderliste als Konfigurationsdatei.
//
// Ohne Flutter (dart:convert und package:yaml): Dieselbe Pruefung nutzen
// die App (beim Start und beim Nachladen) und tool/check_config.dart. So gibt
// es genau eine Pruefregel.
//
// Format: YAML mit Kommentaren, siehe config/stations.yaml (JSON wird als
// Teilmenge von YAML ebenfalls angenommen):
//   schemaVersion: 1
//   sender:
//     - kuerzel: linefm
//       name: "LineFM +MAIN"
//       farbe: "#4B4B7D"
//       logo: https://cdn.linefm.de/images/icons/main.png
//       logoDatei: assets/images/stations/main.png
//       aktiv: true
// Reihenfolge in der Datei = Reihenfolge in der App. Stream- und
// API-Adressen leitet die App aus dem Kuerzel ab (stream.laut.fm,
// api.laut.fm); sie stehen bewusst nicht in der Datei.
import 'dart:convert';

import 'package:yaml/yaml.dart';

part 'stations_config_validator.dart';

/// Einzige unterstuetzte Fassung des Formats.
const int stationsConfigSchemaVersion = 1;

/// Hoechstgroesse der Datei in Bytes (vor und beim Lesen geprueft).
const int stationsConfigMaxBytes = 64 * 1024;

/// Hoechstzahl der Sender (aktiv und ausgeblendet zusammen).
const int stationsConfigMaxStations = 50;

/// Hoechstlaenge eines Anzeigenamens in Zeichen.
const int stationNameMaxLength = 40;

/// Hoechstlaenge einer Logo-Adresse.
const int stationLogoUrlMaxLength = 512;

/// Hosts, von denen Senderlogos geladen werden duerfen. Steht im Code (also
/// zur Bauzeit fest), nicht in der Datei: Wer die Datei aendert, kann keine
/// fremden Bildserver eintragen. Beide stehen auch in der CSP (img-src) der
/// Web-App.
const Set<String> stationLogoHosts = <String>{
  'cdn.linefm.de',
  'assets.laut.fm',
};

/// Kuerzel bei laut.fm: Kleinbuchstaben, Ziffern, `_` und `-`.
final RegExp stationSlugPattern = RegExp(r'^[a-z0-9_-]{1,64}$');

/// Mitgelieferte Logo-Datei der App.
final RegExp stationLogoAssetPattern = RegExp(
  r'^assets/images/stations/[a-z0-9_-]{1,64}\.png$',
);

final RegExp _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// Steuerzeichen und Richtungs-Steuerzeichen (Bidi), die in einem
/// Anzeigenamen nichts verloren haben.
final RegExp _unsafeChars = RegExp(
  '[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]',
);

/// Prueft das Format eines Kuerzels (ohne Abgleich mit der Liste).
bool isValidStationSlug(String slug) => stationSlugPattern.hasMatch(slug);

/// Ein Sender aus der Datei.
class StationConfigEntry {
  const StationConfigEntry({
    required this.slug,
    required this.name,
    required this.color,
    required this.logoUrl,
    this.logoAsset,
    this.active = true,
    this.line,
  });

  final String slug;
  final String name;

  /// Farbe als ARGB-Wert (Alpha immer 0xFF).
  final int color;
  final String logoUrl;

  /// Mitgeliefertes Logo, null wenn keins.
  final String? logoAsset;

  /// false = voruebergehend ausgeblendet.
  final bool active;

  /// Zeile des Eintrags in der Datei (fuer Meldungen).
  final int? line;
}

/// Eine Meldung der Pruefung, mit Zeile, wenn bekannt.
class StationsConfigIssue {
  const StationsConfigIssue(this.message, {this.line});

  final String message;
  final int? line;

  @override
  String toString() => line == null ? message : 'Zeile $line: $message';
}

/// Ergebnis der Pruefung. Nur mit [ok] darf die Liste verwendet werden.
class StationsConfigResult {
  const StationsConfigResult({
    this.entries = const <StationConfigEntry>[],
    this.errors = const <StationsConfigIssue>[],
    this.notes = const <StationsConfigIssue>[],
  });

  /// Alle Sender in Dateireihenfolge, auch ausgeblendete.
  final List<StationConfigEntry> entries;
  final List<StationsConfigIssue> errors;

  /// Hinweise, die die Datei nicht ungueltig machen.
  final List<StationsConfigIssue> notes;

  bool get ok => errors.isEmpty && active.isNotEmpty;

  /// Die angezeigten Sender in Dateireihenfolge.
  List<StationConfigEntry> get active => <StationConfigEntry>[
    for (final e in entries)
      if (e.active) e,
  ];
}

/// Prueft die Datei als Bytes: Groesse und UTF-8 vor dem Parsen.
StationsConfigResult parseStationsConfigBytes(
  List<int> bytes, {
  Set<String>? knownLogoAssets,
}) {
  if (bytes.length > stationsConfigMaxBytes) {
    return const StationsConfigResult(
      errors: <StationsConfigIssue>[
        StationsConfigIssue(
          'Die Datei ist größer als ${stationsConfigMaxBytes ~/ 1024} KB.',
        ),
      ],
    );
  }
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    return const StationsConfigResult(
      errors: <StationsConfigIssue>[
        StationsConfigIssue(
          'Die Datei ist nicht als UTF-8 gespeichert. Speichere sie als UTF-8.',
        ),
      ],
    );
  }
  return parseStationsConfig(text, knownLogoAssets: knownLogoAssets);
}

/// Prueft die Datei als Text.
///
/// [knownLogoAssets]: Logo-Dateien, die diese App mitbringt. Ist die Menge
/// gesetzt (nachgeladene Fassung), wird eine unbekannte `logoDatei` nicht als
/// Fehler gewertet, sondern weggelassen: aeltere App-Versionen haben neue
/// Dateien schlicht nicht und zeigen dann das Logo von der Adresse.
StationsConfigResult parseStationsConfig(
  String text, {
  Set<String>? knownLogoAssets,
}) {
  if (utf8.encode(text).length > stationsConfigMaxBytes) {
    return const StationsConfigResult(
      errors: <StationsConfigIssue>[
        StationsConfigIssue(
          'Die Datei ist größer als ${stationsConfigMaxBytes ~/ 1024} KB.',
        ),
      ],
    );
  }
  final _Node root;
  try {
    root = _readYaml(text);
  } on _ParseError catch (e) {
    return StationsConfigResult(
      errors: <StationsConfigIssue>[
        StationsConfigIssue(e.message, line: e.line),
      ],
    );
  }
  return _Validator(knownLogoAssets).run(root);
}
