// Senderliste als Konfigurationsdatei (Issue #91).
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

// ---------------------------------------------------------------------------
// Pruefung der Inhalte
// ---------------------------------------------------------------------------

class _Validator {
  _Validator(this._knownLogoAssets);

  final Set<String>? _knownLogoAssets;
  final List<StationsConfigIssue> _errors = <StationsConfigIssue>[];
  final List<StationsConfigIssue> _notes = <StationsConfigIssue>[];

  void _error(String message, int line) =>
      _errors.add(StationsConfigIssue(message, line: line));

  static const Set<String> _topKeys = <String>{
    'hinweis',
    'schemaVersion',
    'sender',
  };
  static const Set<String> _entryKeys = <String>{
    'kuerzel',
    'name',
    'farbe',
    'logo',
    'logoDatei',
    'aktiv',
  };

  /// Unbekannte Felder sind fast immer Tippfehler ("nmae" statt "name").
  void _unknownKeys(Map<String, _Node> map, Set<String> allowed, String where) {
    for (final entry in map.entries) {
      if (allowed.contains(entry.key)) continue;
      final lower = entry.key.toLowerCase();
      final guess = allowed.firstWhere(
        (k) => _close(k.toLowerCase(), lower),
        orElse: () => '',
      );
      _error(
        '$where: Das Feld "${entry.key}" kennt die App nicht.'
        '${guess.isEmpty ? '' : ' Meintest du "$guess"?'}'
        ' Erlaubt sind: ${allowed.join(', ')}.',
        entry.value.line,
      );
    }
  }

  /// Gleiche Buchstaben in anderer Reihenfolge oder gleich lang mit
  /// hoechstens zwei abweichenden Zeichen.
  static bool _close(String a, String b) {
    if ((a.split('')..sort()).join() == (b.split('')..sort()).join()) {
      return true;
    }
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) diff++;
    }
    return diff <= 2;
  }

  StationsConfigResult run(_Node root) {
    final top = root.object;
    if (top == null) {
      _error(
        'Die Datei muss oben die Felder schemaVersion und sender enthalten.',
        root.line,
      );
      return _result(const <StationConfigEntry>[]);
    }
    _unknownKeys(top, _topKeys, 'Die Datei');
    final version = top['schemaVersion'];
    if (version == null) {
      _error('"schemaVersion" fehlt. Trage "schemaVersion": 1 ein.', root.line);
    } else if (version.value != stationsConfigSchemaVersion) {
      _error(
        '"schemaVersion" muss $stationsConfigSchemaVersion sein. '
        'Eine andere Fassung kennt die App nicht.',
        version.line,
      );
    }
    final list = top['sender'];
    if (list == null) {
      _error('Die Liste "sender" fehlt.', root.line);
      return _result(const <StationConfigEntry>[]);
    }
    final items = list.array;
    if (items == null) {
      _error(
        '"sender" muss eine Liste sein: jeder Sender beginnt mit "- ".',
        list.line,
      );
      return _result(const <StationConfigEntry>[]);
    }
    if (items.length > stationsConfigMaxStations) {
      _error(
        'Es sind ${items.length} Sender eingetragen, erlaubt sind höchstens '
        '$stationsConfigMaxStations.',
        list.line,
      );
      return _result(const <StationConfigEntry>[]);
    }
    final entries = <StationConfigEntry>[];
    final seen = <String, int>{};
    for (var i = 0; i < items.length; i++) {
      final entry = _entry(items[i], i + 1);
      if (entry == null) continue;
      final before = seen[entry.slug];
      if (before != null) {
        _error(
          'Das Kürzel "${entry.slug}" steht schon in Zeile $before. '
          'Jeder Sender darf nur einmal vorkommen.',
          entry.line ?? items[i].line,
        );
        continue;
      }
      seen[entry.slug] = entry.line ?? items[i].line;
      entries.add(entry);
    }
    if (_errors.isEmpty && !entries.any((e) => e.active)) {
      _error(
        'Es ist kein Sender aktiv. Mindestens ein Sender muss angezeigt '
        'werden.',
        list.line,
      );
    }
    return _result(entries);
  }

  StationsConfigResult _result(List<StationConfigEntry> entries) =>
      StationsConfigResult(
        entries: _errors.isEmpty
            ? List<StationConfigEntry>.unmodifiable(entries)
            : const <StationConfigEntry>[],
        errors: List<StationsConfigIssue>.unmodifiable(_errors),
        notes: List<StationsConfigIssue>.unmodifiable(_notes),
      );

  StationConfigEntry? _entry(_Node node, int number) {
    final map = node.object;
    if (map == null) {
      _error(
        'Sender $number muss Felder wie kuerzel und name enthalten.',
        node.line,
      );
      return null;
    }
    final before = _errors.length;
    _unknownKeys(map, _entryKeys, 'Sender $number');

    final slug = _string(map, 'kuerzel', node, number);
    if (slug != null && !stationSlugPattern.hasMatch(slug.value as String)) {
      _error(
        '"kuerzel" darf nur Kleinbuchstaben (a-z), Ziffern, "_" und "-" '
        'enthalten und höchstens 64 Zeichen lang sein, z. B. "linefmrap". '
        'Es ist das Kürzel aus der laut.fm-Adresse.',
        slug.line,
      );
    }

    final nameNode = _string(map, 'name', node, number);
    String? name;
    if (nameNode != null) {
      name = cleanStationName(nameNode.value as String);
      if (name.isEmpty) {
        _error('"name" ist leer. Trage den Sendernamen ein.', nameNode.line);
      } else if (name.runes.length > stationNameMaxLength) {
        _error(
          '"name" ist zu lang (${name.runes.length} Zeichen, erlaubt sind '
          '$stationNameMaxLength).',
          nameNode.line,
        );
      }
    }

    final colorNode = _string(map, 'farbe', node, number);
    if (colorNode != null &&
        !_colorPattern.hasMatch(colorNode.value as String)) {
      _error(
        'Farbe muss wie #4B4B7D aussehen: # und genau sechs Zeichen aus '
        '0-9 und A-F.',
        colorNode.line,
      );
    }

    final logoNode = _string(map, 'logo', node, number);
    if (logoNode != null) {
      final problem = logoUrlProblem(logoNode.value as String);
      if (problem != null) _error(problem, logoNode.line);
    }

    String? logoAsset;
    final assetNode = map['logoDatei'];
    if (assetNode != null && assetNode.value != null) {
      final value = assetNode.value;
      if (value is! String) {
        _error('"logoDatei" muss in Anführungszeichen stehen.', assetNode.line);
      } else if (value.isEmpty) {
        // Leer = kein mitgeliefertes Logo.
      } else if (!stationLogoAssetPattern.hasMatch(value)) {
        _error(
          '"logoDatei" muss wie "assets/images/stations/main.png" aussehen. '
          'Für neue Sender diese Zeile weglassen und nur "logo" angeben.',
          assetNode.line,
        );
      } else if (_knownLogoAssets != null &&
          !_knownLogoAssets.contains(value)) {
        _notes.add(
          StationsConfigIssue(
            '"logoDatei" $value bringt diese App-Version nicht mit; '
            'sie zeigt das Logo von der Adresse.',
            line: assetNode.line,
          ),
        );
      } else {
        logoAsset = value;
      }
    }

    var active = true;
    final activeNode = map['aktiv'];
    if (activeNode != null) {
      final value = activeNode.value;
      if (value is bool) {
        active = value;
      } else {
        _error(
          '"aktiv" darf nur true (anzeigen) oder false (ausblenden) sein, '
          'ohne Anführungszeichen.',
          activeNode.line,
        );
      }
    }

    if (_errors.length != before ||
        slug == null ||
        name == null ||
        colorNode == null ||
        logoNode == null) {
      return null;
    }
    final hex = (colorNode.value as String).substring(1);
    return StationConfigEntry(
      slug: slug.value as String,
      name: name,
      color: 0xFF000000 | int.parse(hex, radix: 16),
      logoUrl: logoNode.value as String,
      logoAsset: logoAsset,
      active: active,
      line: node.line,
    );
  }

  _Node? _string(Map<String, _Node> map, String key, _Node owner, int number) {
    final node = map[key];
    if (node == null) {
      _error('Bei Sender $number fehlt "$key".${_example(key)}', owner.line);
      return null;
    }
    if (node.value is! String) {
      _error(
        '"$key" muss in Anführungszeichen stehen.${_example(key)}',
        node.line,
      );
      return null;
    }
    return node;
  }

  static String _example(String key) => switch (key) {
    'kuerzel' => ' Beispiel: "kuerzel": "linefmrap"',
    'name' => ' Beispiel: "name": "LineFM +RAP"',
    'farbe' => ' Beispiel: "farbe": "#FF0084"',
    'logo' => ' Beispiel: "logo": "https://cdn.linefm.de/images/icons/rap.png"',
    _ => '',
  };
}

/// Anzeigename als reiner Text: Steuer- und Richtungszeichen raus, Leerraum
/// zusammengefasst, Raender abgeschnitten.
String cleanStationName(String raw) =>
    raw.replaceAll(_unsafeChars, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

/// null, wenn die Logo-Adresse erlaubt ist, sonst die Meldung.
String? logoUrlProblem(String value) {
  const hosts = 'cdn.linefm.de oder assets.laut.fm';
  if (value.isEmpty) return '"logo" ist leer. Trage die Adresse des Logos ein.';
  if (value.length > stationLogoUrlMaxLength) {
    return '"logo" ist zu lang (höchstens $stationLogoUrlMaxLength Zeichen).';
  }
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.isAbsolute) {
    return '"logo" ist keine gültige Adresse. Sie muss mit https:// beginnen.';
  }
  if (uri.scheme != 'https') {
    return '"logo" muss mit https:// beginnen.';
  }
  if (uri.userInfo.isNotEmpty || (uri.hasPort && uri.port != 443)) {
    return '"logo" darf keinen Benutzernamen und keinen Port enthalten.';
  }
  if (!stationLogoHosts.contains(uri.host.toLowerCase())) {
    return '"logo" muss auf $hosts liegen (gefunden: ${uri.host}).';
  }
  if (uri.path.isEmpty || uri.path == '/') {
    return '"logo" muss auf eine Bilddatei zeigen.';
  }
  return null;
}

// ---------------------------------------------------------------------------
// YAML in Knoten mit Zeilennummern
// ---------------------------------------------------------------------------
//
// Die Datei ist YAML mit Kommentaren (JSON ist gueltiges YAML und wird
// ebenfalls angenommen). package:yaml liefert Zeilen und meldet doppelte
// Schluessel. Gegen aufgeblaehte Dateien (Anker/Aliase, "billion laughs")
// begrenzt die Umwandlung Tiefe und Knotenzahl.

class _Node {
  _Node(this.value, this.line, {this.object, this.array});

  final Object? value;
  final int line;
  final Map<String, _Node>? object;
  final List<_Node>? array;
}

class _ParseError implements Exception {
  _ParseError(this.message, this.line);

  final String message;
  final int? line;
}

const int _maxDepth = 16;
const int _maxNodes = 5000;

_Node _readYaml(String text) {
  final YamlNode doc;
  try {
    doc = loadYamlNode(text);
  } on YamlException catch (e) {
    final span = e.span;
    throw _ParseError(
      'Die Datei ist kein gueltiges YAML: ${e.message}. Haeufige Ursachen: '
      'falsche Einrueckung (immer zwei Leerzeichen, keine Tabs) oder eine '
      'Farbe ohne Anfuehrungszeichen ("#4B4B7D").',
      span == null ? null : span.start.line + 1,
    );
  }
  var count = 0;
  _Node convert(YamlNode node, int depth) {
    if (++count > _maxNodes || depth > _maxDepth) {
      throw _ParseError(
        'Die Datei ist zu tief verschachtelt oder zu gross.',
        node.span.start.line + 1,
      );
    }
    final line = node.span.start.line + 1;
    if (node is YamlMap) {
      final map = <String, _Node>{};
      for (final entry in node.nodes.entries) {
        final key = entry.key;
        final keyValue = key is YamlNode ? key.value : key;
        if (keyValue is! String) {
          throw _ParseError('Feldnamen muessen Text sein.', line);
        }
        map[keyValue] = convert(entry.value, depth + 1);
      }
      return _Node(null, line, object: map);
    }
    if (node is YamlList) {
      return _Node(
        null,
        line,
        array: <_Node>[for (final n in node.nodes) convert(n, depth + 1)],
      );
    }
    return _Node(node.value, line);
  }

  return convert(doc, 0);
}
