import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/features/consent/consent_dialog.dart';
import 'package:linefm_radio/features/settings/clear_storage.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/storage_notice/storage_notice.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

void main() {
  group('Einwilligungsdialog', () {
    test('shouldAskTelemetryConsent', () {
      expect(
        shouldAskTelemetryConsent(consentRequired: false, decision: null),
        isFalse,
      );
      expect(
        shouldAskTelemetryConsent(consentRequired: true, decision: null),
        isTrue,
      );
      expect(
        shouldAskTelemetryConsent(consentRequired: true, decision: true),
        isFalse,
      );
      expect(
        shouldAskTelemetryConsent(consentRequired: true, decision: false),
        isFalse,
      );
    });

    testWidgets('ohne konfigurierte Telemetrie erscheint kein Dialog', (
      tester,
    ) async {
      final host = FeatureHost();
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('mit Telemetrie erscheint er, beide Knoepfe gleichwertig', (
      tester,
    ) async {
      final host = FeatureHost(config: telemetryConfig);
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Statistik und Fehlerberichte'), findsOneWidget);

      final allow = find.widgetWithText(OutlinedButton, 'Erlauben');
      final decline = find.widgetWithText(OutlinedButton, 'Ablehnen');
      expect(allow, findsOneWidget);
      expect(decline, findsOneWidget);
      // Gleiche Groesse, gleicher Knopftyp, keine Vorauswahl.
      expect(tester.getSize(allow), tester.getSize(decline));
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('Erlauben speichert die Einwilligung', (tester) async {
      final host = FeatureHost(config: telemetryConfig);
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erlauben'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(host.prefs.readTelemetryConsent(), isTrue);
    });

    testWidgets('Ablehnen speichert false', (tester) async {
      final host = FeatureHost(config: telemetryConfig);
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ablehnen'));
      await tester.pumpAndSettle();
      expect(host.prefs.readTelemetryConsent(), isFalse);
    });

    testWidgets('bereits entschieden: kein erneutes Fragen', (tester) async {
      final host = FeatureHost(config: telemetryConfig);
      await host.prefs.writeTelemetryConsent(value: false);
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Datenschutz-Link oeffnet den Rechtstext', (tester) async {
      final host = FeatureHost(
        config: telemetryConfig,
        legalLoader: (p) async => '{"title":"DS","updated":"","blocks":[{"type":"h1","text":"Datenschutz-Seite"}]}',
      );
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mehr in der Datenschutzerklärung'));
      await tester.pumpAndSettle();
      expect(find.text('DATENSCHUTZ-SEITE'), findsOneWidget);
    });
  });

  group('Speicher-Hinweis', () {
    testWidgets('erscheint ohne Bestaetigung, Geraete-Wortlaut', (
      tester,
    ) async {
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const StorageNotice()));
      await tester.pump();
      expect(
        find.text(
          'LINEFM Radio speichert Einstellungen, Favoriten und den zuletzt '
          'gehörten Sender auf diesem Gerät, damit die App sie beim nächsten '
          'Start kennt.',
        ),
        findsOneWidget,
      );
      expect(find.text('Verstanden'), findsOneWidget);
      expect(find.text('Datenschutz'), findsOneWidget);
    });

    testWidgets('Web-Wortlaut im Browser', (tester) async {
      final host = FeatureHost(
        platform: const PlatformInfo(
          isWeb: true,
          platform: TargetPlatform.windows,
        ),
      );
      await tester.pumpWidget(host.app(const StorageNotice()));
      await tester.pump();
      expect(
        find.text(
          'LINEFM Radio speichert Einstellungen, Favoriten und den zuletzt '
          'gehörten Sender in diesem Browser, damit die App sie beim nächsten '
          'Start kennt.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('auf allen Plattformen sichtbar', (tester) async {
      for (final p in TargetPlatform.values) {
        final host = FeatureHost(
          platform: PlatformInfo(isWeb: false, platform: p),
        );
        await tester.pumpWidget(host.app(const StorageNotice()));
        await tester.pump();
        expect(find.text('Verstanden'), findsOneWidget, reason: '$p');
      }
    });

    testWidgets('Verstanden bestaetigt und blendet aus', (tester) async {
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const StorageNotice()));
      await tester.pump();
      await tester.tap(find.text('Verstanden'));
      await tester.pumpAndSettle();
      expect(host.prefs.storageConsent, isTrue);
      expect(find.text('Verstanden'), findsNothing);
    });

    testWidgets('bereits bestaetigt: nichts zu sehen', (tester) async {
      final host = FeatureHost();
      await host.prefs.setStorageConsent(value: true);
      await tester.pumpWidget(host.app(const StorageNotice()));
      await tester.pumpAndSettle();
      expect(find.text('Verstanden'), findsNothing);
    });

    testWidgets('Speicher loeschen bringt den Hinweis zurueck', (tester) async {
      final host = FeatureHost(config: telemetryConfig);
      await host.prefs.setStorageConsent(value: true);
      await host.prefs.writeTelemetryConsent(value: true);
      late WidgetRef captured;
      await tester.pumpWidget(
        host.app(
          Consumer(
            builder: (context, ref, _) {
              captured = ref;
              return const StorageNotice();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verstanden'), findsNothing);

      await clearAppStorage(captured);
      await tester.pumpAndSettle();
      expect(find.text('Verstanden'), findsOneWidget);
      expect(host.prefs.storageConsent, isFalse);
      expect(host.prefs.readTelemetryConsent(), isNull);
    });
  });
}
