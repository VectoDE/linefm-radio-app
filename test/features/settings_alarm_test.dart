import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/alarm/alarm_bootstrap.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';
import 'package:linefm_radio/features/alarm/alarm_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:linefm_radio/features/settings/sleep_timer_row.dart';
import 'package:linefm_radio/l10n/gen/app_localizations_de.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

class _FakeSleepTimer implements SleepTimerService {
  _FakeSleepTimer(this._clock);

  final DateTime Function() _clock;
  SleepTimerState _state = const SleepTimerState();
  final List<SleepTimerMode> started = <SleepTimerMode>[];

  @override
  SleepTimerState get state => _state;

  @override
  Stream<SleepTimerState> get states => const Stream<SleepTimerState>.empty();

  @override
  Future<void> start(SleepTimerMode mode, {Track? currentTrack}) async {
    started.add(mode);
    _state = SleepTimerLogic.start(mode, _clock(), currentTrack: currentTrack);
  }

  @override
  Future<void> cancel() async => _state = SleepTimerLogic.cancel();

  @override
  Future<void> dispose() async {}
}

class _RecordingAlarms implements AlarmCoordinator {
  final List<List<AlarmRule>> calls = <List<AlarmRule>>[];

  @override
  ValueListenable<AlarmRinging?> get ringing =>
      const NoopAlarmCoordinator().ringing;

  @override
  Future<void> rescheduleAll(List<AlarmRule> rules) async => calls.add(rules);

  @override
  Future<void> snooze(String ruleId) async {}

  @override
  Future<void> dismiss(String ruleId) async {}
}

void main() {
  final l10n = AppLocalizationsDe();

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
      final alarms = _RecordingAlarms();
      final host = FeatureHost(
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
        extra: <Override>[
          alarmCoordinatorProvider.overrideWithValue(_RecordingAlarms()),
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

  group('Sleeptimer', () {
    Future<(FeatureHost, _FakeSleepTimer)> pumpRow(
      WidgetTester tester, {
      Track? track,
    }) async {
      useSize(tester, 420, 800);
      late _FakeSleepTimer fake;
      final host = FeatureHost(
        extra: <Override>[
          currentTrackProvider.overrideWithValue(AsyncData<Track?>(track)),
          sleepTimerServiceProvider.overrideWith(
            (ref) => fake = _FakeSleepTimer(ref.read(clockProvider).now),
          ),
        ],
      );
      await tester.pumpWidget(host.app(const SleepTimerRow()));
      await tester.pump();
      return (host, fake);
    }

    testWidgets('Auswahl startet den Timer, Status laeuft mit', (tester) async {
      final (host, fake) = await pumpRow(tester);
      expect(find.text('Kein Sleeptimer aktiv.'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<SleepTimerMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 Min.').last);
      await tester.pumpAndSettle();
      expect(fake.started, <SleepTimerMode>[const SleepTimerMinutes(30)]);
      expect(find.text('Wiedergabe stoppt in 30 Minuten.'), findsOneWidget);

      host.clock.advance(const Duration(minutes: 10, seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Wiedergabe stoppt in 20 Minuten.'), findsOneWidget);

      host.clock.advance(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Sleeptimer abgelaufen.'), findsOneWidget);
    });

    testWidgets('Ende des Songs und Aus', (tester) async {
      final (_, fake) = await pumpRow(
        tester,
        track: Track(
          artist: 'A',
          title: 'T',
          endsAt: DateTime(2026, 11, 18, 6, 3),
        ),
      );
      expect(find.text(l10n.sleepTimerEndOfSongUnavailable), findsNothing);
      await tester.tap(find.byType(DropdownButton<SleepTimerMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ende des Songs').last);
      await tester.pumpAndSettle();
      expect(fake.started.single, const SleepTimerEndOfSong());
      expect(find.text('Wiedergabe stoppt am Ende des Songs.'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<SleepTimerMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aus').last);
      await tester.pumpAndSettle();
      expect(find.text('Kein Sleeptimer aktiv.'), findsOneWidget);
    });

    testWidgets('Live-Sendung: Ende des Songs gesperrt mit Hinweis', (
      tester,
    ) async {
      final (_, fake) = await pumpRow(
        tester,
        track: const Track(artist: 'A', title: 'Live'),
      );
      expect(find.text(l10n.sleepTimerEndOfSongUnavailable), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<SleepTimerMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ende des Songs').last);
      await tester.pumpAndSettle();
      expect(fake.started, isEmpty);
    });

    test('Statuswortlaut', () {
      final now = DateTime(2026, 11, 18, 6);
      expect(
        sleepTimerStatusText(l10n, const SleepTimerState(), now),
        'Kein Sleeptimer aktiv.',
      );
      expect(
        sleepTimerStatusText(
          l10n,
          SleepTimerLogic.start(const SleepTimerMinutes(15), now),
          now,
        ),
        'Wiedergabe stoppt in 15 Minuten.',
      );
      expect(
        sleepTimerStatusText(
          l10n,
          SleepTimerLogic.start(const SleepTimerMinutes(15), now),
          now.add(const Duration(minutes: 14, seconds: 30)),
        ),
        'Wiedergabe stoppt in 1 Minute.',
      );
    });
  });

  group('Wecker', () {
    testWidgets('Hinweis je Plattform', (tester) async {
      useSize(tester, 420, 1200);
      final cases = <(PlatformInfo, String)>[
        (
          const PlatformInfo(isWeb: true, platform: TargetPlatform.windows),
          l10n.alarmNoteWeb,
        ),
        (
          const PlatformInfo(isWeb: false, platform: TargetPlatform.iOS),
          l10n.alarmNoteIos,
        ),
        (
          const PlatformInfo(isWeb: false, platform: TargetPlatform.linux),
          l10n.alarmNoteDesktop,
        ),
        (
          const PlatformInfo(isWeb: false, platform: TargetPlatform.android),
          l10n.alarmNoteAndroid,
        ),
      ];
      for (final (platform, note) in cases) {
        await tester.pumpWidget(
          FeatureHost(platform: platform)
              .app(const AlarmScreen(), scaffold: false),
        );
        await tester.pump();
        expect(find.text(note), findsOneWidget, reason: '$platform');
      }
    });

    testWidgets('hinzufuegen, bearbeiten, loeschen', (tester) async {
      useSize(tester, 420, 1400);
      final alarms = _RecordingAlarms();
      final host = FeatureHost(
        extra: <Override>[alarmCoordinatorProvider.overrideWithValue(alarms)],
      );
      await tester.pumpWidget(host.app(const AlarmScreen(), scaffold: false));
      await tester.pump();
      expect(find.text('Kein Wecker gestellt.'), findsOneWidget);

      await tester.tap(find.text('Wecker hinzufügen'));
      await tester.pumpAndSettle();
      // U2: zuerst die Uhrzeit (Vorgabe 07:00) bestaetigen.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(host.prefs.readAlarms(), hasLength(1));
      expect(host.prefs.readAlarms().single.hour, 7);
      expect(alarms.calls, isNotEmpty);
      // Jetzt 06:00 -> naechster Wecker heute 07:00.
      expect(find.text('Nächster Wecker: 07:00'), findsOneWidget);

      await tester.tap(find.text('Mo'));
      await tester.pump();
      await tester.tap(find.text('Mi'));
      await tester.pumpAndSettle();
      expect(host.prefs.readAlarms().single.weekdays, <int>{1, 3});
      expect(find.text('Mo, Mi'), findsOneWidget);

      // A5: Loeschknopf mit Knopf-Rolle, Label genau einmal, Semantik-Tap.
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(find.semantics.byLabel('Wecker 07:00 löschen'), findsOneWidget);
      final del = tester
          .getSemantics(find.bySemanticsLabel('Wecker 07:00 löschen'))
          .getSemanticsData();
      expect(del.flagsCollection.isButton, isTrue);
      expect(del.hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.tap(find.semantics.byLabel('Wecker 07:00 löschen'));
      await tester.pumpAndSettle();
      handle.dispose();
      expect(host.prefs.readAlarms(), isEmpty);
      expect(alarms.calls.last, isEmpty);
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
      final host = FeatureHost();
      await host.prefs.writeAlarms(const <AlarmRule>[
        AlarmRule(
          id: 'a',
          hour: 7,
          minute: 30,
          stationSlug: 'linefmrap',
          weekdays: <int>{1, 2, 3, 4, 5},
        ),
      ]);
      await tester.pumpWidget(host.app(const AlarmScreen(), scaffold: false));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Android: fehlende Freigabe zeigt den Erklaerdialog', (
      tester,
    ) async {
      useSize(tester, 420, 1400);
      var opened = 0;
      final host = FeatureHost(
        extra: <Override>[
          alarmPermissionCheckProvider.overrideWithValue(() async => false),
          alarmOpenSystemSettingsProvider.overrideWithValue(() async {
            opened++;
          }),
        ],
      );
      await tester.pumpWidget(host.app(const AlarmScreen(), scaffold: false));
      await tester.pump();
      await tester.tap(find.text('Wecker hinzufügen'));
      await tester.pumpAndSettle();
      // U2: zuerst die Uhrzeit (Vorgabe 07:00) bestaetigen.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Wecker braucht eine Freigabe'), findsOneWidget);
      await tester.tap(find.text('Einstellungen öffnen'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('Einstellungen zeigen die naechste Weckzeit', (tester) async {
      useSize(tester, 420, 2600);
      final host = FeatureHost();
      await host.prefs.writeAlarms(const <AlarmRule>[
        AlarmRule(id: 'a', hour: 7, minute: 30, stationSlug: 'linefm'),
      ]);
      await tester.pumpWidget(host.app(const SettingsScreen()));
      await tester.pump();
      expect(find.text('Nächster Wecker: 07:30'), findsOneWidget);
    });
  });

  testWidgets('exact-alarm hint disappears on return to the app', (
    tester,
  ) async {
    useSize(tester, 420, 2600);
    var exact = false;
    final host = FeatureHost(
      extra: <Override>[
        alarmCoordinatorProvider.overrideWithValue(_RecordingAlarms()),
        alarmStatusCheckProvider.overrideWithValue(
          () async => AlarmPermissionStatus(exactOk: exact),
        ),
      ],
    );
    await tester.pumpWidget(
      host.app(const AlarmBootstrap(child: AlarmScreen()), scaffold: false),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.alarmExactMissingNote), findsOneWidget);

    // Permission granted in the system settings while the app was away.
    exact = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.alarmExactMissingNote), findsNothing);
  });
}
