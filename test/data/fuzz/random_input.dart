// Kleiner, deterministischer Zufallsgenerator fuer Robustheitstests der
// Parser. Bewusst ohne zusaetzliches Paket: dart:math reicht,
// und der feste Seed macht jeden Fehlschlag reproduzierbar.
import 'dart:convert';
import 'dart:math';

/// Erzeugt beliebige JSON-artige Werte, Texte und kaputte JSON-Dokumente.
///
/// [keys] steuert, welche Feldnamen in Maps bevorzugt vorkommen, damit die
/// Werte tief in die Parser hineinreichen statt sofort verworfen zu werden.
class RandomInput {
  RandomInput(int seed, {this.keys = const <String>[]}) : _rng = Random(seed);

  final Random _rng;
  final List<String> keys;

  /// Randfaelle fuer Texte: leer, Leerraum, Steuer- und Formatzeichen,
  /// Emoji, Surrogat-Haelften, sehr lang, URL-Varianten, Zeitstempel nahe
  /// am laut.fm-Format und ausserhalb des gueltigen Bereichs.
  static const List<String> edgeStrings = <String>[
    '',
    ' ',
    '\t\n\r',
    '\u0000',
    '​﻿ ',
    '\ud800',
    '\udfff',
    'Ä Ö Ü ß',
    '\u{1F3B5}\u{1F3A7}',
    '"',
    r'\',
    '{',
    '[]',
    'null',
    'true',
    '1e999',
    '-1e999',
    'NaN',
    'https://',
    'https://example.org/cover.jpg',
    'http://example.org/a b',
    'HTTPS://EXAMPLE.ORG',
    'javascript:alert(1)',
    'data:image/png;base64,AAAA',
    'file:///etc/passwd',
    '//example.org',
    'https://[::1',
    '2026-11-18 21:07:16 +0100',
    '2026-11-18T21:07:16+01:00',
    '2026-11-18 21:07 -05:30',
    '9999-99-99 99:99:99 +9999',
    '0000-00-00 00:00:00 -0000',
    '2026-02-30 25:61:61 +2500',
    '+999999-01-01T00:00:00Z',
    '-999999-01-01T00:00:00Z',
    '275760-09-13T00:00:00.001Z',
    '99999999999999999999-01-01',
    '100x100bb',
    'feat. feat. & & und ( [ ) ]',
    '(((((((((((((((((((((((((((((((((',
  ];

  /// Randfaelle fuer Zahlen, darunter Werte, die `jsonDecode` aus Texten
  /// wie `1e999` erzeugt (Unendlich) und Grenzen von `int`/`double`.
  static final List<Object> edgeNumbers = <Object>[
    0,
    -0.0,
    1,
    -1,
    42,
    1.5,
    -1.5,
    9007199254740993,
    -9223372036854775807 - 1,
    9223372036854775807,
    8640000000000001,
    -8640000000000001,
    double.maxFinite,
    double.minPositive,
    double.infinity,
    double.negativeInfinity,
    double.nan,
  ];

  bool chance(double p) => _rng.nextDouble() < p;

  int nextInt(int max) => _rng.nextInt(max);

  T pick<T>(List<T> items) => items[_rng.nextInt(items.length)];

  /// Zufaelliger Text aus Randfaellen, Mutationen davon und Zufallszeichen.
  String string() {
    switch (_rng.nextInt(4)) {
      case 0:
        return pick(edgeStrings);
      case 1:
        return mutate(pick(edgeStrings));
      case 2:
        if (keys.isNotEmpty && chance(0.5)) return pick(keys);
        return _randomChars(_rng.nextInt(12));
      default:
        return _randomChars(chance(0.05) ? 2000 : _rng.nextInt(40));
    }
  }

  String _randomChars(int length) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.writeCharCode(_char());
    }
    return buffer.toString();
  }

  int _char() {
    switch (_rng.nextInt(6)) {
      case 0:
        return _rng.nextInt(0x20); // Steuerzeichen
      case 1:
        return 0x80 + _rng.nextInt(0x780); // Latin-1 bis Kyrillisch usw.
      case 2:
        return 0xD800 + _rng.nextInt(0x800); // einzelne Surrogate
      case 3:
        return pick(const <int>[0x22, 0x5C, 0x7B, 0x7D, 0x5B, 0x5D, 0x3A]);
      default:
        return 0x20 + _rng.nextInt(0x5F); // druckbares ASCII
    }
  }

  /// Zahl aus Randfaellen oder zufaellig.
  Object number() {
    switch (_rng.nextInt(3)) {
      case 0:
        return pick(edgeNumbers);
      case 1:
        return _rng.nextInt(1 << 32) - (1 << 31);
      default:
        return (_rng.nextDouble() - 0.5) * pow(10, _rng.nextInt(400) - 200);
    }
  }

  /// Beliebiger JSON-artiger Wert bis zur Tiefe [depth]. Mit [finite] nur
  /// Zahlen, die `jsonEncode` kodieren kann.
  Object? value({int depth = 4, bool finite = false}) {
    final kind = depth <= 0 ? _rng.nextInt(5) : _rng.nextInt(7);
    switch (kind) {
      case 0:
        return null;
      case 1:
        return _rng.nextBool();
      case 2:
        final n = number();
        if (finite && n is double && !n.isFinite) return 0;
        return n;
      case 3:
      case 4:
        return string();
      case 5:
        return <Object?>[
          for (var i = _rng.nextInt(chance(0.05) ? 200 : 5); i > 0; i--)
            value(depth: depth - 1, finite: finite),
        ];
      default:
        return map(depth: depth, finite: finite);
    }
  }

  /// Map mit bevorzugten [keys] und gelegentlich fremden Schluesseln.
  Map<String, Object?> map({int depth = 4, bool finite = false}) {
    final result = <String, Object?>{};
    for (var i = _rng.nextInt(8); i > 0; i--) {
      final key = keys.isNotEmpty && chance(0.8) ? pick(keys) : string();
      result[key] = value(depth: depth - 1, finite: finite);
    }
    return result;
  }

  /// Kaputte Variante eines Textes: abgeschnitten, Zeichen ersetzt,
  /// eingefuegt, geloescht, verdoppelt oder mit Unendlich-Zahl ersetzt.
  String mutate(String text) {
    if (text.isEmpty) return _randomChars(1 + _rng.nextInt(3));
    var result = text;
    for (var n = 1 + _rng.nextInt(3); n > 0; n--) {
      if (result.isEmpty) break;
      final i = _rng.nextInt(result.length);
      switch (_rng.nextInt(6)) {
        case 0:
          result = result.substring(0, i);
        case 1:
          result = result.replaceRange(i, i + 1, String.fromCharCode(_char()));
        case 2:
          result = result.replaceRange(i, i, String.fromCharCode(_char()));
        case 3:
          result = result.replaceRange(i, i + 1, '');
        case 4:
          result = result + result.substring(i);
        default:
          result = result.replaceFirst(RegExp(r'-?\d+(\.\d+)?'), '1e999');
      }
    }
    return result;
  }

  /// JSON-Text: gueltig, gueltig mit Unendlich-Zahlen oder kaputt.
  String jsonText({int depth = 4}) {
    final valid = jsonEncode(value(depth: depth, finite: true));
    switch (_rng.nextInt(3)) {
      case 0:
        return valid;
      case 1:
        return valid.replaceAll(RegExp(r'(?<=[:\[,])-?\d+(\.\d+)?'), '1e999');
      default:
        return mutate(valid);
    }
  }
}

/// Kurze Darstellung eines Eingabewerts fuer Fehlermeldungen.
String describe(Object? input) {
  final text = input is String ? jsonEncode(input) : input.toString();
  return text.length > 300 ? '${text.substring(0, 300)}...' : text;
}
