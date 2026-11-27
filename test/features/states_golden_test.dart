@Tags(<String>['golden'])
library;

// Goldens for states that the other golden tests do not cover: history with
// load error, empty and loading, the alarm screen (empty and with rules) and
// settings, each in dark and light. Reference images are created on the CI
// runner only, see docs/ENTWICKLUNG.md ("Goldens aktualisieren").
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/features/alarm/alarm_screen.dart';
import 'package:linefm_radio/features/history/history_screen.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_support.dart';
import '../support/test_doubles.dart';
import 'feature_host.dart';

enum _HistoryState { error, empty, loading }

class _HistoryRepo extends FakeNowPlayingRepository {
  _HistoryRepo(this.state);

  final _HistoryState state;

  @override
  Stream<List<HistoryEntry>> watchHistory(Station station) => switch (state) {
    _HistoryState.error => Stream<List<HistoryEntry>>.error(
      StateError('offline'),
    ),
    _HistoryState.empty => Stream<List<HistoryEntry>>.value(
      const <HistoryEntry>[],
    ),
    // Never emits: the screen stays in its loading state.
    _HistoryState.loading => StreamController<List<HistoryEntry>>().stream,
  };
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Brightness brightness,
  required Size size,
  FeatureHost? host,
  bool scaffold = true,
}) async {
  useGoldenSize(tester, size);
  final h = host ?? FeatureHost();
  await h.prefs.writeSettings(const AppSettings(marquee: false));
  await tester.pumpWidget(
    h.app(screen, brightness: brightness, scaffold: scaffold),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _matches(String name, Brightness brightness) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/${name}_${variant(brightness)}.png'),
);

void main() {
  setUpAll(prepareGoldens);

  const phone = Size(390, 844);

  for (final brightness in Brightness.values) {
    group('Golden states ${variant(brightness)}', () {
      for (final state in _HistoryState.values) {
        testWidgets('history ${state.name} phone 390', (tester) async {
          await _pump(
            tester,
            const HistoryScreen(),
            brightness: brightness,
            size: phone,
            host: FeatureHost(repository: _HistoryRepo(state)),
          );
          await _matches('history_${state.name}_390', brightness);
        });
      }

      testWidgets('alarm empty phone 390', (tester) async {
        await _pump(
          tester,
          const AlarmScreen(),
          brightness: brightness,
          size: phone,
          scaffold: false,
        );
        await _matches('alarm_empty_390', brightness);
      });

      testWidgets('alarm with rules phone 390', (tester) async {
        final host = FeatureHost();
        await host.prefs.writeAlarms(const <AlarmRule>[
          AlarmRule(
            id: 'a',
            hour: 7,
            minute: 0,
            stationSlug: 'linefm',
            weekdays: <int>{1, 2, 3, 4, 5},
          ),
          AlarmRule(
            id: 'b',
            hour: 9,
            minute: 30,
            stationSlug: 'linefmlofi',
            enabled: false,
          ),
        ]);
        await _pump(
          tester,
          const AlarmScreen(),
          brightness: brightness,
          size: phone,
          host: host,
          scaffold: false,
        );
        await _matches('alarm_rules_390', brightness);
      });

      testWidgets('settings phone 390', (tester) async {
        await _pump(
          tester,
          const SettingsScreen(),
          brightness: brightness,
          size: const Size(390, 1800),
        );
        await _matches('settings_390', brightness);
      });
    });
  }
}
