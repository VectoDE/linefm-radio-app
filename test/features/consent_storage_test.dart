import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/consent/consent_dialog.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/settings/clear_storage.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/storage_notice/storage_notice.dart';
import 'package:linefm_radio/features/storage_notice/storage_notice_dialog.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

const PlatformInfo _web = PlatformInfo(
  isWeb: true,
  platform: TargetPlatform.windows,
);

/// Host mit bereits bestaetigtem Speicher-Hinweis: die Einwilligungs-Tests
/// sollen nicht vom Popup des Speicher-Hinweises (App) verdeckt werden.
FeatureHost _confirmedHost({
  AppConfig config = const AppConfig(),
  LegalAssetLoader? legalLoader,
}) {
  final host = FeatureHost(config: config, legalLoader: legalLoader);
  host.prefs.setStorageConsent(value: true).ignore();
  return host;
}

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
      final host = _confirmedHost();
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('mit Telemetrie erscheint er, beide Knoepfe gleichwertig', (
      tester,
    ) async {
      final host = _confirmedHost(config: telemetryConfig);
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
      final host = _confirmedHost(config: telemetryConfig);
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
      final host = _confirmedHost(config: telemetryConfig);
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ablehnen'));
      await tester.pumpAndSettle();
      expect(host.prefs.readTelemetryConsent(), isFalse);
    });

    testWidgets('bereits entschieden: kein erneutes Fragen', (tester) async {
      final host = _confirmedHost(config: telemetryConfig);
      await host.prefs.writeTelemetryConsent(value: false);
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Datenschutz-Link oeffnet den Rechtstext', (tester) async {
      final host = _confirmedHost(
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

  group('Speicher-Hinweis als Banner (nur Web)', () {
    testWidgets('Browser: Banner mit Web-Wortlaut, kein Popup', (tester) async {
      final host = FeatureHost(platform: _web);
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: StorageNotice())),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'LINEFM Radio speichert Einstellungen, Favoriten, den zuletzt '
          'gehörten Sender sowie zuletzt gespielte Titel in diesem Browser, damit die App sie beim nächsten '
          'Start kennt. Eine selbst gewählte Sprache bleibt immer gespeichert.',
        ),
        findsOneWidget,
      );
      expect(find.text('Verstanden'), findsOneWidget);
      expect(find.text('Datenschutz'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(StorageNoticeDialog), findsNothing);
    });

    testWidgets('App und Desktop: kein Banner', (tester) async {
      for (final p in TargetPlatform.values) {
        final host = FeatureHost(
          platform: PlatformInfo(isWeb: false, platform: p),
        );
        await tester.pumpWidget(host.app(const StorageNotice()));
        await tester.pump();
        expect(find.text('Verstanden'), findsNothing, reason: '$p');
        expect(find.byType(StorageNotice), findsOneWidget);
      }
    });

    testWidgets('Verstanden bestaetigt und blendet aus', (tester) async {
      final host = FeatureHost(platform: _web);
      await tester.pumpWidget(host.app(const StorageNotice()));
      await tester.pump();
      await tester.tap(find.text('Verstanden'));
      await tester.pumpAndSettle();
      expect(host.prefs.storageConsent, isTrue);
      expect(find.text('Verstanden'), findsNothing);
    });

    testWidgets('bereits bestaetigt: nichts zu sehen', (tester) async {
      final host = FeatureHost(platform: _web);
      await host.prefs.setStorageConsent(value: true);
      await tester.pumpWidget(host.app(const StorageNotice()));
      await tester.pumpAndSettle();
      expect(find.text('Verstanden'), findsNothing);
    });

    testWidgets('Speicher loeschen bringt den Banner zurueck', (tester) async {
      final host = FeatureHost(config: telemetryConfig, platform: _web);
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

  group('Speicher-Hinweis als Popup (App und Desktop)', () {
    Future<void> pumpGate(WidgetTester tester, FeatureHost host) async {
      await tester.pumpWidget(
        host.app(const TelemetryConsentGate(child: Text('App'))),
      );
      await tester.pumpAndSettle();
    }

    test('shouldShowStorageNoticeDialog', () {
      const native = PlatformInfo(
        isWeb: false,
        platform: TargetPlatform.windows,
      );
      expect(
        shouldShowStorageNoticeDialog(platform: native, confirmed: false),
        isTrue,
      );
      expect(
        shouldShowStorageNoticeDialog(platform: native, confirmed: true),
        isFalse,
      );
      expect(
        shouldShowStorageNoticeDialog(platform: _web, confirmed: false),
        isFalse,
      );
    });

    testWidgets('erscheint auf jeder Nicht-Web-Plattform mit Titel und Text', (
      tester,
    ) async {
      for (final p in TargetPlatform.values) {
        final host = FeatureHost(
          platform: PlatformInfo(isWeb: false, platform: p),
        );
        await pumpGate(tester, host);
        expect(find.byType(StorageNoticeDialog), findsOneWidget, reason: '$p');
        expect(find.text('Speicher auf diesem Gerät'), findsOneWidget);
        expect(
          find.text(
            'LINEFM Radio speichert Einstellungen, Favoriten, den zuletzt '
            'gehörten Sender sowie zuletzt gespielte Titel auf diesem Gerät, damit die App sie beim '
            'nächsten Start kennt. Eine selbst gewählte Sprache bleibt immer gespeichert.',
          ),
          findsOneWidget,
        );
        expect(find.text('Datenschutz'), findsOneWidget);
        expect(find.text('Verstanden'), findsOneWidget);
      }
    });

    testWidgets('Browser: kein Popup', (tester) async {
      await pumpGate(tester, FeatureHost(platform: _web));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Verstanden schliesst und merkt dauerhaft', (tester) async {
      final host = FeatureHost();
      await pumpGate(tester, host);
      await tester.tap(find.text('Verstanden'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(host.prefs.storageConsent, isTrue);

      // Neuer Start mit denselben Einstellungen: kein Popup mehr.
      final again = FeatureHost(prefs: host.prefs);
      await pumpGate(tester, again);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Tipp daneben, Esc und Zurueck schliessen nicht', (
      tester,
    ) async {
      final host = FeatureHost();
      await pumpGate(tester, host);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.byType(StorageNoticeDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(StorageNoticeDialog), findsOneWidget);

      // Android-Zurueck und Vorschau-Geste landen in maybePop.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(StorageNoticeDialog), findsOneWidget);
      expect(host.prefs.storageConsent, isFalse);
    });

    testWidgets('Datenschutz oeffnet die Seite, der Hinweis bleibt offen', (
      tester,
    ) async {
      final host = FeatureHost(
        legalLoader: (p) async => '{"title":"DS","updated":"","blocks":[{"type":"h1","text":"Datenschutz-Seite"}]}',
      );
      await pumpGate(tester, host);
      await tester.tap(find.text('Datenschutz'));
      await tester.pumpAndSettle();
      expect(find.text('DATENSCHUTZ-SEITE'), findsOneWidget);
      expect(host.prefs.storageConsent, isFalse);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('DATENSCHUTZ-SEITE'), findsNothing);
      expect(find.byType(StorageNoticeDialog), findsOneWidget);
      expect(host.prefs.storageConsent, isFalse);
    });

    testWidgets('Reihenfolge: erst Speicher-Hinweis, dann Einwilligung', (
      tester,
    ) async {
      final host = FeatureHost(config: telemetryConfig);
      await pumpGate(tester, host);
      // Nur ein Dialog zur Zeit.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(StorageNoticeDialog), findsOneWidget);
      expect(find.text('Statistik und Fehlerberichte'), findsNothing);

      await tester.tap(find.text('Verstanden'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(StorageNoticeDialog), findsNothing);
      expect(find.text('Statistik und Fehlerberichte'), findsOneWidget);
      expect(host.prefs.storageConsent, isTrue);

      await tester.tap(find.text('Erlauben'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(host.prefs.readTelemetryConsent(), isTrue);
    });

    testWidgets('Speicher loeschen: Popup erscheint erneut', (tester) async {
      final host = FeatureHost();
      await host.prefs.setStorageConsent(value: true);
      late WidgetRef captured;
      await tester.pumpWidget(
        host.app(
          TelemetryConsentGate(
            child: Consumer(
              builder: (context, ref, _) {
                captured = ref;
                return const Text('App');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await clearAppStorage(captured);
      await tester.pumpAndSettle();
      expect(find.byType(StorageNoticeDialog), findsOneWidget);
      expect(host.prefs.storageConsent, isFalse);
    });

    testWidgets('bedienbar bei 200 % Schrift, Ziele mindestens 48 dp', (
      tester,
    ) async {
      useSize(tester, 320, 480);
      final host = FeatureHost();
      await tester.pumpWidget(
        host.app(
          const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 480),
              textScaler: TextScaler.linear(2),
            ),
            child: TelemetryConsentGate(child: Text('App')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final ok = find.widgetWithText(FilledButton, 'Verstanden');
      expect(ok, findsOneWidget);
      expect(tester.getSize(ok).height, greaterThanOrEqualTo(48));
      final privacy = find.widgetWithText(TextButton, 'Datenschutz');
      expect(tester.getSize(privacy).height, greaterThanOrEqualTo(48));
    });

    testWidgets('Dialog hat Rolle und Namen', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGate(tester, FeatureHost());
      SemanticsData? role;
      for (
        SemanticsNode? n = tester.getSemantics(find.byType(AlertDialog));
        n != null;
        n = n.parent
      ) {
        if (n.getSemanticsData().role == SemanticsRole.alertDialog) {
          role = n.getSemanticsData();
          break;
        }
      }
      expect(role, isNotNull);
      expect(role!.label, 'Speicher auf diesem Gerät');
      expect(role.flagsCollection.namesRoute, isTrue);
      handle.dispose();
    });
  });
}
