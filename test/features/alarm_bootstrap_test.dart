import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/alarm/alarm_bootstrap.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_permissions.dart';
import 'package:linefm_radio/services/alarm/alarm_wiring.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';

class _Platform implements AlarmPlatform {
  final StreamController<AlarmRing> controller =
      StreamController<AlarmRing>.broadcast();
  final List<AlarmRule> scheduled = <AlarmRule>[];

  @override
  Stream<AlarmRing> get rings => controller.stream;

  @override
  bool get ringsItself => true;

  /// Anzahl der Aufrufe von init, die noch fehlschlagen sollen (Q-04).
  int initFailures = 0;

  @override
  Future<void> init() async {
    if (initFailures > 0) {
      initFailures--;
      throw StateError('Plugin nicht bereit');
    }
  }

  @override
  Future<void> schedule(AlarmRule rule) async => scheduled.add(rule);

  @override
  Future<void> cancel(String ruleId) async {}

  @override
  Future<void> removeOrphans(Set<String> knownRuleIds) async {}

  @override
  Future<AlarmRingState> ringState(AlarmRing ring) async =>
      AlarmRingState.ringing;

  @override
  Future<void> silence(AlarmRing ring) async {}

  @override
  Future<void> dispose() async {}
}

class _Gateway implements AlarmPermissionGateway {
  bool exact = false;
  bool timeChanged = false;

  @override
  Future<bool> consumeRescheduleFlag() async {
    final v = timeChanged;
    timeChanged = false;
    return v;
  }

  @override
  Future<bool> canScheduleExactAlarms() async => exact;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<bool> canUseFullScreenIntent() async => true;

  @override
  Future<void> openFullScreenIntentSettings() async {}

  @override
  Future<void> requestNotifications() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kaltstart: Koordinator wird gelesen, plant neu und lauscht', (
    tester,
  ) async {
    final platform = _Platform();
    final gateway = _Gateway();
    final prefs = InMemoryPrefsStore();
    await prefs.writeAlarms(<AlarmRule>[
      AlarmRule(
        id: 'r1',
        hour: 7,
        minute: 0,
        stationSlug: stationsCatalog.first.slug,
        weekdays: const <int>{1, 2},
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        ...alarmAndSleepOverrides(
          permissions: gateway,
          platformFactory: (_) => platform,
          isAndroid: true,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AlarmBootstrap(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(platform.scheduled.map((r) => r.id), <String>[
      'r1',
    ], reason: 'rescheduleAll beim Kaltstart');
    expect(platform.controller.hasListener, isTrue, reason: 'rings-Listener');
    expect(container.read(alarmPermissionStatusProvider).exactOk, isFalse);

    // Rueckkehr aus den Systemeinstellungen: Freigabe erteilt, neu planen.
    gateway.exact = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(platform.scheduled, hasLength(2));
    expect(container.read(alarmPermissionStatusProvider).exactOk, isTrue);

    // Zeitzonenwechsel im Hintergrund: Merkzeichen gesetzt, beim naechsten
    // Oeffnen wird neu geplant und das Merkzeichen geloescht.
    gateway.timeChanged = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(platform.scheduled, hasLength(3));
    expect(gateway.timeChanged, isFalse);
  });

  group('initAndReschedule (Q-04)', () {
    final rule = AlarmRule(
      id: 'r1',
      hour: 7,
      minute: 0,
      stationSlug: stationsCatalog.first.slug,
    );

    DefaultAlarmCoordinator coordinator(_Platform platform) =>
        DefaultAlarmCoordinator(
          platform: platform,
          clock: FakeClock(DateTime(2026, 11, 19, 6)),
          playback: NoopPlaybackService(),
          startStation: (_) async {},
          rules: () => <AlarmRule>[rule],
        );

    test('Fehler beim Start: geloggt, zweiter Versuch plant', () async {
      final platform = _Platform()..initFailures = 1;
      final waits = <Duration>[];
      final ok = await initAndReschedule(
        coordinator(platform),
        () => <AlarmRule>[rule],
        retryDelay: const Duration(seconds: 30),
        sleep: (d) async => waits.add(d),
      );
      expect(ok, isTrue);
      expect(waits, <Duration>[const Duration(seconds: 30)]);
      expect(platform.scheduled.map((r) => r.id), <String>['r1']);
    });

    test('zweimal Fehler: false, kein unbehandelter Fehler', () async {
      final platform = _Platform()..initFailures = 2;
      final ok = await initAndReschedule(
        coordinator(platform),
        () => <AlarmRule>[rule],
        sleep: (_) async {},
      );
      expect(ok, isFalse);
      expect(platform.scheduled, isEmpty);
    });
  });
}
