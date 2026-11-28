import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/alarm/alarm_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';
import 'settings_alarm_helpers.dart';

void main() {
  group('Einstellungen', () {
    testWidgets('zeigt die Web-Texte im Wortlaut', (tester) async {
      useSize(tester, 420, 2600);
      await tester.pumpWidget(FeatureHost().app(const SettingsScreen()));
      await tester.pump();
      for (final text in <String>[
        'EINSTELLUNGEN',
        'Lauftext für lange Titel',
        'Lange Songtitel als Band anzeigen.',
        'Lautstärke merken',
        'Die gewählte Lautstärke auf diesem Gerät behalten.',
        'Sleeptimer',
        'Kein Sleeptimer aktiv.',
        'Speicher',
        'Lokal gespeichert werden: zuletzt gehörter Sender, zuletzt '
            'gespielte Titel samt Verlauf, Lautstärke, '
            'Favoriten, Favoriten-Sender, Wecker, Einstellungen, '
            'zwischengespeicherte Cover und am Computer die Fensterposition.',
        'Speicher löschen',
        'Ein Angebot von',
        'Website',
        'Impressum',
        'Datenschutz',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('Schalter schreiben in die Einstellungen', (tester) async {
      useSize(tester, 420, 2600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();

      await tester.tap(find.text('Lauftext für lange Titel'));
      await tester.pump();
      expect(host.prefs.readSettings().marquee, isFalse);

      await tester.tap(find.text('Lautstärke merken'));
      await tester.pump();
      expect(host.prefs.readSettings().rememberVolume, isFalse);

      await tester.tap(find.text('Beim Start abspielen'));
      await tester.pump();
      expect(host.prefs.readSettings().autoplay, isFalse);
    });

    testWidgets('Darstellung: Hell / Dunkel / System', (tester) async {
      useSize(tester, 420, 2600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();
      await tester.tap(find.text('Hell'));
      await tester.pump();
      expect(host.prefs.readSettings().themeMode, AppThemeMode.light);
      await tester.tap(find.text('Dunkel'));
      await tester.pump();
      expect(host.prefs.readSettings().themeMode, AppThemeMode.dark);
      await tester.tap(find.text('System'));
      await tester.pump();
      expect(host.prefs.readSettings().themeMode, AppThemeMode.system);
    });

    testWidgets('Cover-Speicher: 20 / 40 / 100 MB, Standard 40', (
      tester,
    ) async {
      useSize(tester, 420, 2600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();
      expect(find.text('Cover-Speicher'), findsOneWidget);
      expect(host.prefs.readSettings().coverCacheLimit, CoverCacheLimit.mb40);
      for (final label in <String>['20 MB', '40 MB', '100 MB']) {
        final segment = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        );
        expect(segment, findsOneWidget, reason: label);
        expect(tester.getSize(segment).height, greaterThanOrEqualTo(48));
      }
      expect(
        tester.getSemantics(find.text('40 MB')),
        matchesSemantics(
          label: '40 MB',
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasFocusAction: true,
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );

      await tester.tap(find.text('20 MB'));
      await tester.pump();
      expect(host.prefs.readSettings().coverCacheLimit, CoverCacheLimit.mb20);
      await tester.tap(find.text('100 MB'));
      await tester.pump();
      expect(host.prefs.readSettings().coverCacheLimit, CoverCacheLimit.mb100);
    });

    testWidgets('Tray-Zeile nur auf dem Desktop', (tester) async {
      useSize(tester, 420, 2600);
      await tester.pumpWidget(FeatureHost().app(const SettingsScreen()));
      await tester.pump();
      expect(find.text('Beim Schließen im Tray weiterlaufen'), findsNothing);

      final desktop = FeatureHost(
        platform: const PlatformInfo(
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
      );
      await tester.pumpWidget(desktop.app(const SettingsScreen()));
      await tester.pump();
      expect(find.text('Beim Schließen im Tray weiterlaufen'), findsOneWidget);
    });

    testWidgets('Web-Wortlaut fuer Lautstaerke und Autoplay', (tester) async {
      useSize(tester, 420, 2600);
      final host = FeatureHost(
        platform: const PlatformInfo(
          isWeb: true,
          platform: TargetPlatform.windows,
        ),
      );
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();
      expect(
        find.text('Die gewählte Lautstärke in diesem Browser behalten.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Der zuletzt gehörte Sender startet nach deinem ersten Tippen '
          'oder Klick.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Telemetrie-Zeile nur wenn konfiguriert, Widerruf moeglich', (
      tester,
    ) async {
      useSize(tester, 420, 2600);
      await tester.pumpWidget(FeatureHost().app(const SettingsScreen()));
      await tester.pump();
      expect(find.text('Statistik und Fehlerberichte'), findsNothing);

      final host = FeatureHost(config: telemetryConfig);
      await host.prefs.writeTelemetryConsent(value: true);
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();
      expect(find.text('Statistik und Fehlerberichte'), findsOneWidget);
      expect(
        find.text('Erlaubt. Du kannst das jederzeit widerrufen.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Statistik und Fehlerberichte'));
      await tester.pump();
      expect(host.prefs.readTelemetryConsent(), isFalse);
      expect(
        find.text('Nicht erlaubt. Es wird nichts gesendet.'),
        findsOneWidget,
      );
    });

    testWidgets('Speicher loeschen: Rueckfrage, dann alles weg', (
      tester,
    ) async {
      useSize(tester, 420, 2600);
      final alarms = RecordingAlarms();
      final host = FeatureHost(
        noopAlarm: false,

        config: telemetryConfig,
        extra: <Override>[alarmCoordinatorProvider.overrideWithValue(alarms)],
      );
      await host.prefs.setStorageConsent(value: true);
      await host.prefs.writeSettings(const AppSettings(marquee: false));
      await host.prefs.writeTelemetryConsent(value: true);
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();

      await tester.tap(find.text('Speicher löschen'));
      await tester.pumpAndSettle();
      expect(find.text('Speicher löschen?'), findsOneWidget);
      // Dialog hat einen Namen am Knoten mit role alertDialog (Web:
      // aria-label am role="alertdialog", axe aria-dialog-name).
      final semantics = tester.ensureSemantics();
      final dialogNode = tester.getSemantics(find.byType(AlertDialog));
      SemanticsData? roleData;
      for (SemanticsNode? n = dialogNode; n != null; n = n.parent) {
        if (n.getSemanticsData().role == SemanticsRole.alertDialog) {
          roleData = n.getSemanticsData();
          break;
        }
      }
      expect(roleData, isNotNull);
      expect(roleData!.label, 'Speicher löschen?');
      expect(roleData.flagsCollection.namesRoute, isTrue);
      semantics.dispose();

      // Abbrechen laesst alles stehen.
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(host.prefs.storageConsent, isTrue);

      await tester.tap(find.text('Speicher löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(host.prefs.storageConsent, isFalse);
      expect(host.prefs.readSettings(), const AppSettings());
      expect(host.prefs.readTelemetryConsent(), isNull);
      expect(alarms.calls.last, isEmpty);
      expect(find.text('Speicher gelöscht.'), findsOneWidget);
    });

    testWidgets('Speicher loeschen behaelt "Cover laden: aus"', (tester) async {
      useSize(tester, 420, 2600);
      final host = FeatureHost(
        noopAlarm: false,

        extra: <Override>[
          alarmCoordinatorProvider.overrideWithValue(RecordingAlarms()),
        ],
      );
      await host.prefs.setStorageConsent(value: true);
      await host.prefs.writeSettings(
        const AppSettings(loadArtwork: false, marquee: false),
      );
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();

      await tester.tap(find.text('Speicher löschen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('„Cover laden: aus“ bleibt'), findsOneWidget);
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(host.prefs.storageConsent, isFalse);
      expect(host.prefs.readSettings(), const AppSettings(loadArtwork: false));
    });

    testWidgets('Footer-Links: Rechtstexte in der App, Website extern', (
      tester,
    ) async {
      useSize(tester, 420, 2600);
      final host = FeatureHost(
        legalLoader: (p) async => '{"title":"I","updated":"","blocks":[{"type":"h1","text":"Rechtsseite"}]}',
      );
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();

      await tester.tap(find.text('Website'));
      await tester.pump();
      expect(host.opened.single.toString(), 'https://linefm.de');

      await tester.tap(find.text('Impressum'));
      await tester.pumpAndSettle();
      expect(find.text('RECHTSSEITE'), findsOneWidget);
    });

    testWidgets('Hellmodus rendert ohne Fehler', (tester) async {
      useSize(tester, 420, 2600);
      await tester.pumpWidget(
        FeatureHost().app(const SettingsScreen(), brightness: Brightness.light),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('neuer Wecker: Abbrechen in der Zeitauswahl legt nichts an', (
      tester,
    ) async {
      useSize(tester, 420, 1400);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const AlarmScreen(), scaffold: false));
      await tester.pump();
      await tester.tap(find.text('Wecker hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(host.prefs.readAlarms(), isEmpty);
    });

    testWidgets('schmal mit grosser Schrift ohne Ueberlauf', (tester) async {
      useSize(tester, 320, 2600);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(FeatureHost().app(const SettingsScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
