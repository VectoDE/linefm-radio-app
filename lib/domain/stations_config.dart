// Senderliste als Konfigurationsdatei (Issue #91).
//
// Nur dart:core und dart:convert: Dieselbe Datei pruefen die App (beim Start
// und beim Nachladen) und das Werkzeug tool/stations_check.dart (ohne
// Flutter). So gibt es genau eine Pruefregel.
//
// Format (assets/config/stations.json):
//   {
//     "schemaVersion": 1,
//     "sender": [
//       { "kuerzel": "linefm", "name": "LineFM +MAIN", "farbe": "#4B4B7D",
//         "logo": "https://cdn.linefm.de/images/icons/main.png",
//         "logoDatei": "assets/images/stations/main.png", "aktiv": true }
//     ]
//   }
// Reihenfolge in der Datei = Reihenfolge in der App. Stream- und
// API-Adressen leitet die App aus dem Kuerzel ab (stream.laut.fm,
// api.laut.fm); sie stehen bewusst nicht in der Datei.
import 'dart:convert';

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
  '[\u0000-\u001F\u007F-\u009F​-‏‪-‮⁠-⁯﻿]',
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
    return StationsConfigResult(
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
    return StationsConfigResult(
      errors: <StationsConfigIssue>[
        StationsConfigIssue(
          'Die Datei ist größer als ${stationsConfigMaxBytes ~/ 1024} KB.',
        ),
      ],
    );
  }
  final _Node root;
  try {
    root = _JsonReader(text).readDocument();
  } on _JsonError catch (e) {
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

  StationsConfigResult run(_Node root) {
    final top = root.object;
    if (top == null) {
      _error(
        'Die Datei muss mit { beginnen und mit } enden (ein JSON-Objekt).',
        root.line,
      );
      return _result(const <StationConfigEntry>[]);
    }
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
        '"sender" muss eine Liste in eckigen Klammern [ ] sein.',
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
        'Sender $number muss in geschweiften Klammern { } stehen.',
        node.line,
      );
      return null;
    }
    final before = _errors.length;

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
      _error(
        'Bei Sender $number fehlt "$key".${_example(key)}',
        owner.line,
      );
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
String cleanStationName(String raw) => raw
    .replaceAll(_unsafeChars, ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

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
// Kleiner JSON-Leser mit Zeilennummern
// ---------------------------------------------------------------------------
//
// jsonDecode kennt keine Zeilen und nimmt bei doppelten Schluesseln still den
// letzten Wert. Fuer verstaendliche Meldungen ("Zeile 12: ...") und strenge
// Pruefung liest dieser Leser JSON (RFC 8259) selbst, mit Tiefenbegrenzung.

class _Node {
  _Node(this.value, this.line, {this.object, this.array});

  final Object? value;
  final int line;
  final Map<String, _Node>? object;
  final List<_Node>? array;
}

class _JsonError implements Exception {
  _JsonError(this.message, this.line);

  final String message;
  final int line;
}

class _JsonReader {
  _JsonReader(String text)
    : _s = text.startsWith('﻿') ? text.substring(1) : text;

  static const int _maxDepth = 16;

  final String _s;
  int _i = 0;
  int _line = 1;

  _Node readDocument() {
    _skip();
    if (_i >= _s.length) throw _JsonError('Die Datei ist leer.', 1);
    final node = _value(0);
    _skip();
    if (_i < _s.length) {
      throw _JsonError(
        'Nach dem Ende der Liste steht noch Text. Prüfe die letzte '
        'schließende Klammer }.',
        _line,
      );
    }
    return node;
  }

  void _skip() {
    while (_i < _s.length) {
      final c = _s.codeUnitAt(_i);
      if (c == 0x0A) {
        _line++;
      } else if (c != 0x20 && c != 0x09 && c != 0x0D) {
        return;
      }
      _i++;
    }
  }

  _Node _value(int depth) {
    if (depth > _maxDepth) {
      throw _JsonError('Zu viele verschachtelte Klammern.', _line);
    }
    _skip();
    if (_i >= _s.length) {
      throw _JsonError(
        'Die Datei endet zu früh. Wahrscheinlich fehlt eine schließende '
        'Klammer } oder ].',
        _line,
      );
    }
    final c = _s[_i];
    final line = _line;
    switch (c) {
      case '{':
        return _object(depth, line);
      case '[':
        return _array(depth, line);
      case '"':
        return _Node(_string(), line);
      case 't':
        _literal('true');
        return _Node(true, line);
      case 'f':
        _literal('false');
        return _Node(false, line);
      case 'n':
        _literal('null');
        return _Node(null, line);
      default:
        if (c == '-' || (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39)) {
          return _Node(_number(), line);
        }
        if (c == '„' || c == '“' || c == '”' || c == "'") {
          throw _JsonError(
            'Hier steht ein falsches Anführungszeichen ($c). Erlaubt ist nur '
            'das gerade Zeichen ".',
            line,
          );
        }
        throw _JsonError(
          'Unerwartetes Zeichen "$c". Texte müssen in Anführungszeichen " '
          'stehen.',
          line,
        );
    }
  }

  _Node _object(int depth, int line) {
    _i++; // {
    final map = <String, _Node>{};
    _skip();
    if (_peek('}')) {
      _i++;
      return _Node(map, line, object: map);
    }
    while (true) {
      _skip();
      if (_peek('}')) {
        throw _JsonError(
          'Vor der schließenden Klammer } steht ein überzähliges Komma. '
          'Lösche das Komma am Ende der vorigen Zeile.',
          _line,
        );
      }
      if (!_peek('"')) {
        throw _JsonError(
          'Hier wird ein Feldname in Anführungszeichen erwartet, z. B. '
          '"name". Fehlt ein Komma oder steht eines zu viel?',
          _line,
        );
      }
      final keyLine = _line;
      final key = _string();
      _skip();
      if (!_peek(':')) {
        throw _JsonError(
          'Nach "$key" fehlt der Doppelpunkt :.',
          _line,
        );
      }
      _i++;
      final value = _value(depth + 1);
      if (map.containsKey(key)) {
        throw _JsonError(
          '"$key" steht in diesem Block doppelt.',
          keyLine,
        );
      }
      map[key] = value;
      _skip();
      if (_peek(',')) {
        _i++;
        continue;
      }
      if (_peek('}')) {
        _i++;
        return _Node(map, line, object: map);
      }
      throw _JsonError(
        'Hier fehlt ein Komma am Zeilenende (oder eine schließende Klammer }).',
        _prevLine(),
      );
    }
  }

  _Node _array(int depth, int line) {
    _i++; // [
    final list = <_Node>[];
    _skip();
    if (_peek(']')) {
      _i++;
      return _Node(list, line, array: list);
    }
    while (true) {
      _skip();
      if (_peek(']')) {
        throw _JsonError(
          'Nach dem letzten Eintrag darf kein Komma stehen. Lösche das Komma '
          'hinter der letzten }.',
          _line,
        );
      }
      list.add(_value(depth + 1));
      _skip();
      if (_peek(',')) {
        _i++;
        continue;
      }
      if (_peek(']')) {
        _i++;
        return _Node(list, line, array: list);
      }
      throw _JsonError(
        'Zwischen zwei Einträgen fehlt ein Komma (nach der schließenden '
        'Klammer }).',
        _prevLine(),
      );
    }
  }

  /// Zeile des letzten Zeichens vor der aktuellen Position, das kein
  /// Leerraum ist (dort fehlt meist das Komma).
  int _prevLine() {
    var line = _line;
    var j = _i - 1;
    while (j >= 0) {
      final c = _s.codeUnitAt(j);
      if (c == 0x0A) {
        line--;
      } else if (c != 0x20 && c != 0x09 && c != 0x0D) {
        break;
      }
      j--;
    }
    return line;
  }

  bool _peek(String c) => _i < _s.length && _s[_i] == c;

  void _literal(String word) {
    if (!_s.startsWith(word, _i)) {
      throw _JsonError(
        'Unbekanntes Wort. Erlaubt sind true, false oder Text in '
        'Anführungszeichen.',
        _line,
      );
    }
    _i += word.length;
  }

  num _number() {
    final start = _i;
    while (_i < _s.length && '+-0123456789.eE'.contains(_s[_i])) {
      _i++;
    }
    final raw = _s.substring(start, _i);
    final valid = RegExp(
      r'^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$',
    ).hasMatch(raw);
    if (!valid) throw _JsonError('Ungültige Zahl "$raw".', _line);
    return num.parse(raw);
  }

  String _string() {
    final line = _line;
    _i++; // "
    final out = StringBuffer();
    while (true) {
      if (_i >= _s.length) {
        throw _JsonError(
          'Ein Text ist nicht abgeschlossen: Es fehlt das schließende '
          'Anführungszeichen ".',
          line,
        );
      }
      final c = _s.codeUnitAt(_i);
      if (c == 0x22) {
        _i++;
        return out.toString();
      }
      if (c == 0x0A || c < 0x20) {
        throw _JsonError(
          'Ein Text ist nicht abgeschlossen: Es fehlt das schließende '
          'Anführungszeichen " am Zeilenende.',
          line,
        );
      }
      if (c == 0x5C) {
        _i++;
        if (_i >= _s.length) break;
        final e = _s[_i];
        switch (e) {
          case '"':
            out.write('"');
          case r'\':
            out.write(r'\');
          case '/':
            out.write('/');
          case 'b':
            out.write('\b');
          case 'f':
            out.write('\f');
          case 'n':
            out.write('\n');
          case 'r':
            out.write('\r');
          case 't':
            out.write('\t');
          case 'u':
            final hex = _i + 5 <= _s.length ? _s.substring(_i + 1, _i + 5) : '';
            final code = RegExp(r'^[0-9A-Fa-f]{4}$').hasMatch(hex)
                ? int.parse(hex, radix: 16)
                : null;
            if (code == null) {
              throw _JsonError('Ungültige Zeichenfolge \\u im Text.', _line);
            }
            out.writeCharCode(code);
            _i += 4;
          default:
            throw _JsonError(
              r'Ein \ im Text ist nur vor ", \, /, b, f, n, r, t oder u '
              'erlaubt.',
              _line,
            );
        }
        _i++;
        continue;
      }
      out.writeCharCode(c);
      _i++;
    }
    throw _JsonError('Ein Text ist nicht abgeschlossen.', line);
  }
}
