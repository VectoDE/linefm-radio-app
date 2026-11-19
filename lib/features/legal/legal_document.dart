import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/core/config/app_config.dart';

/// Art des Rechtstexts. Die Dateinamen entsprechen `assets/legal/{de,en}/`.
enum LegalKind {
  imprint('impressum'),
  privacy('datenschutz');

  const LegalKind(this.assetName);

  /// Dateiname ohne Endung, zugleich Pfad der Web-Seite (`/impressum/`).
  final String assetName;
}

enum LegalBlockType { h1, h2, p, ul, link, mail }

/// Ein Block der Rechtstext-JSON (Spec 4.7): `h1`, `h2`, `p`, `ul`, `link`,
/// `mail`, optional mit `requires`.
class LegalBlock {
  const LegalBlock({
    required this.type,
    this.text = '',
    this.items = const <String>[],
    this.url = '',
    this.address = '',
    this.requires = const <String>[],
  });

  /// Tolerant: unbekannte Blocktypen ergeben `null` und werden uebersprungen.
  static LegalBlock? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final typeName = json['type'];
    final type = LegalBlockType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) return null;
    final items = json['items'];
    final requires = json['requires'];
    return LegalBlock(
      type: type,
      text: '${json['text'] ?? ''}',
      items: items is List
          ? <String>[for (final e in items) '$e']
          : const <String>[],
      url: '${json['url'] ?? ''}',
      address: '${json['address'] ?? ''}',
      requires: switch (requires) {
        null => const <String>[],
        final List<Object?> list => <String>[for (final e in list) '$e'],
        _ => <String>['$requires'],
      },
    );
  }

  final LegalBlockType type;
  final String text;
  final List<String> items;
  final String url;
  final String address;

  /// Anbieter-Bedingungen: `umami`, `sentry`, `firebase`, `telemetry`
  /// (mindestens einer), Praefix `!` negiert. Alle Eintraege muessen gelten.
  final List<String> requires;
}

/// Geladener und geparster Rechtstext.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.updated,
    required this.blocks,
  });

  /// Wirft [FormatException] bei ungueltiger Struktur.
  factory LegalDocument.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Rechtstext: Objekt erwartet.');
    }
    final blocks = json['blocks'];
    if (blocks is! List) {
      throw const FormatException('Rechtstext: "blocks" fehlt.');
    }
    return LegalDocument(
      title: '${json['title'] ?? ''}',
      updated: '${json['updated'] ?? ''}',
      blocks: <LegalBlock>[
        for (final b in blocks)
          if (LegalBlock.tryFromJson(b) case final LegalBlock block) block,
      ],
    );
  }

  factory LegalDocument.parse(String source) =>
      LegalDocument.fromJson(jsonDecode(source));

  final String title;

  /// Stand wie in der Datei (ISO-Datum).
  final String updated;
  final List<LegalBlock> blocks;

  /// Bloecke, deren `requires` fuer die aktiven Anbieter erfuellt ist.
  List<LegalBlock> visibleFor(Set<String> providers) => <LegalBlock>[
    for (final b in blocks)
      if (legalRequirementMet(b.requires, providers)) b,
  ];
}

/// Aktive Telemetrie-Anbieter aus der Build-Konfiguration, in den Schluesseln
/// der `requires`-Angaben (identisch zu `tool/gen_legal_html.dart`).
Set<String> activeLegalProviders(AppConfig config) => <String>{
  if (config.umamiConfigured) 'umami',
  if (config.sentryConfigured) 'sentry',
  if (config.firebaseConfigured) 'firebase',
};

/// Ist die `requires`-Liste fuer [providers] erfuellt? `telemetry` gilt, wenn
/// mindestens ein Anbieter aktiv ist. Leere Liste = immer sichtbar.
bool legalRequirementMet(List<String> requires, Set<String> providers) {
  for (final raw in requires) {
    final negate = raw.startsWith('!');
    final token = negate ? raw.substring(1) : raw;
    final active = token == 'telemetry'
        ? providers.isNotEmpty
        : providers.contains(token);
    if (active == negate) return false;
  }
  return true;
}

/// Deutsch bleibt Deutsch, alles andere faellt auf Englisch zurueck.
String legalLanguageFor(Locale locale) =>
    locale.languageCode == 'de' ? 'de' : 'en';

/// Liest Dateien aus den Assets. Tests ueberschreiben den Provider.
typedef LegalAssetLoader = Future<String> Function(String path);

final legalAssetLoaderProvider = Provider<LegalAssetLoader>(
  (ref) => rootBundle.loadString,
);

/// Laedt `assets/legal/<lang>/<kind>.json`. Fehlt die Datei oder ist sie
/// kaputt, wird die englische Fassung geladen (Fallback Englisch).
Future<LegalDocument> loadLegalDocument(
  LegalAssetLoader load,
  LegalKind kind,
  String lang,
) async {
  Future<LegalDocument> read(String l) async =>
      LegalDocument.parse(await load('assets/legal/$l/${kind.assetName}.json'));
  try {
    return await read(lang);
  } on Object {
    if (lang == 'en') rethrow;
    return read('en');
  }
}

final legalDocumentProvider =
    FutureProvider.family<LegalDocument, ({LegalKind kind, String lang})>(
      (ref, key) => loadLegalDocument(
        ref.watch(legalAssetLoaderProvider),
        key.kind,
        key.lang,
      ),
    );
