import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';
import 'package:linefm_radio/features/alarm/alarm_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:linefm_radio/features/settings/sleep_timer_row.dart';
import 'package:linefm_radio/l10n/gen/app_localizations_de.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';
import 'settings_alarm_helpers.dart';

void main() {
  final l10n = AppLocalizationsDe();

  group('Sleeptimer', () {
    Future<(FeatureHost, FakeSleepTimer)> pumpRow(
      WidgetTester tester, {
      Track? track,
    }) async {
      useSize(tester, 420, 800);
      late FakeSleepTimer fake;
      final host = FeatureHost(
        noopSleepTimer: false,

        extra: <Override>[
          currentTrackProvider.overrideWithValue(AsyncData<Track?>(track)),
          sleepTimerServiceProvider.overrideWith(
            (ref) => fake = FakeSleepTimer(ref.read(clockProvider).now),
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
      final alarms = RecordingAlarms();
      final host = FeatureHost(
        noopAlarm: false,

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
}
