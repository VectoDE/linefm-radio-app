import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';

import '../../tool/gen_legal_html.dart' as generator;
import 'feature_host.dart';

const String _doc = '''
{"title":"Test","updated":"2026-01-01","blocks":[
 {"type":"h1","text":"Titel"},
 {"type":"p","text":"immer"},
 {"type":"p","text":"nur umami","requires":"umami"},
 {"type":"p","text":"nur sentry","requires":["sentry"]},
 {"type":"p","text":"irgendeine","requires":"telemetry"},
 {"type":"p","text":"keine","requires":"!telemetry"},
 {"type":"ufo","text":"unbekannt"}
]}''';

List<String> _texts(LegalDocument d, Set<String> providers) => <String>[
  for (final b in d.visibleFor(providers)) b.text,
];

void main() {
  group('LegalDocument', () {
    test('ignoriert unbekannte Blocktypen', () {
      final d = LegalDocument.parse(_doc);
      expect(d.blocks, hasLength(6));
      expect(d.title, 'Test');
    });

    test('requires gegen AppConfig gefiltert', () {
      final d = LegalDocument.parse(_doc);
      expect(_texts(d, activeLegalProviders(const AppConfig())), <String>[
        'Titel',
        'immer',
        'keine',
      ]);
      expect(
        _texts(
          d,
          activeLegalProviders(
            const AppConfig(umamiUrl: 'https://u', umamiWebsiteId: 'id'),
          ),
        ),
        <String>['Titel', 'immer', 'nur umami', 'irgendeine'],
      );
      expect(
        _texts(
          d,
          activeLegalProviders(const AppConfig(sentryDsn: 'https://k@h/1')),
        ),
        <String>['Titel', 'immer', 'nur sentry', 'irgendeine'],
      );
      expect(
        _texts(d, activeLegalProviders(const AppConfig(firebaseEnabled: true))),
        <String>['Titel', 'immer', 'irgendeine'],
      );
    });

    test('Filter entspricht dem Web-Generator fuer alle Kombinationen', () {
      const names = <String>['umami', 'sentry', 'firebase'];
      const requirements = <Object?>[
        null,
        'umami',
        'sentry',
        'firebase',
        'telemetry',
        '!telemetry',
        '!umami',
        <String>['telemetry', '!sentry'],
      ];
      for (var mask = 0; mask < 8; mask++) {
        final providers = <String>{
          for (var i = 0; i < 3; i++)
            if (mask & (1 << i) != 0) names[i],
        };
        for (final r in requirements) {
          final list = r == null
              ? const <String>[]
              : r is List
              ? r.cast<String>()
              : <String>[r as String];
          expect(
            legalRequirementMet(list, providers),
            generator.requirementMet(r, providers),
            reason: '$r mit $providers',
          );
        }
      }
    });

    test('Sprache: Deutsch bleibt Deutsch, sonst Englisch', () {
      expect(legalLanguageFor(const Locale('de')), 'de');
      expect(legalLanguageFor(const Locale('de', 'AT')), 'de');
      expect(legalLanguageFor(const Locale('en')), 'en');
      expect(legalLanguageFor(const Locale('fr')), 'en');
    });
  });

  group('loadLegalDocument', () {
    test('Fallback Englisch, wenn die Sprachdatei fehlt', () async {
      final asked = <String>[];
      final d = await loadLegalDocument(
        (path) async {
          asked.add(path);
          if (path.contains('/de/')) throw const FileSystemException('fehlt');
          return _doc;
        },
        LegalKind.privacy,
        'de',
      );
      expect(d.title, 'Test');
      expect(asked, <String>[
        'assets/legal/de/datenschutz.json',
        'assets/legal/en/datenschutz.json',
      ]);
    });

    test('kaputte Datei faellt ebenfalls auf Englisch zurueck', () async {
      final d = await loadLegalDocument(
        (path) async => path.contains('/de/') ? '{kaputt' : _doc,
        LegalKind.imprint,
        'de',
      );
      expect(d.blocks, isNotEmpty);
    });

    test('Englisch ohne Datei wirft', () {
      expect(
        loadLegalDocument(
          (path) async => throw const FileSystemException('fehlt'),
          LegalKind.imprint,
          'en',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test(
      'echte Assets: alle vier Dateien laden und enthalten Inhalt',
      () async {
        Future<String> disk(String path) => File(path).readAsString();
        for (final kind in LegalKind.values) {
          for (final lang in <String>['de', 'en']) {
            final d = await loadLegalDocument(disk, kind, lang);
            expect(d.blocks.length, greaterThan(5), reason: '$kind $lang');
            expect(d.title, isNotEmpty);
          }
        }
      },
    );
  });

  group('LegalScreen', () {
    testWidgets('zeigt Impressum, Platzhalter bleiben sichtbar', (
      tester,
    ) async {
      final host = FeatureHost(
        legalLoader: (path) async => File(path).readAsStringSync(),
      );
      await tester.pumpWidget(
        host.app(const LegalScreen(kind: LegalKind.imprint), scaffold: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('IMPRESSUM'), findsOneWidget);
      expect(find.textContaining('{{BETREIBER_NAME}}'), findsWidgets);
    });

    testWidgets('Datenschutz ohne Telemetrie hat keinen Umami-Abschnitt', (
      tester,
    ) async {
      useSize(tester, 400, 30000);
      final plain = FeatureHost(
        legalLoader: (path) async => File(path).readAsStringSync(),
      );
      await tester.pumpWidget(
        plain.app(const LegalScreen(kind: LegalKind.privacy), scaffold: false),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Umami'), findsNothing);

      final withUmami = FeatureHost(
        config: telemetryConfig,
        legalLoader: (path) async => File(path).readAsStringSync(),
      );
      await tester.pumpWidget(
        withUmami.app(
          const LegalScreen(kind: LegalKind.privacy),
          scaffold: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Umami'), findsWidgets);
    });

    testWidgets('Englisch bei englischer Sprache', (tester) async {
      final host = FeatureHost(
        legalLoader: (path) async => File(path).readAsStringSync(),
      );
      await tester.pumpWidget(
        host.app(
          const LegalScreen(kind: LegalKind.imprint),
          locale: const Locale('en'),
          scaffold: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('IMPRINT'), findsOneWidget);
    });
  });
}
