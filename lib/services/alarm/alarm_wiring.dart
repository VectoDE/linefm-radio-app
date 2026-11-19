import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/window.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_permissions.dart';
import 'package:linefm_radio/services/alarm/alarm_platform_factory.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';

/// Provider-Overrides fuer Wecker und Sleeptimer (eingehaengt in
/// `productionOverrides`).
///
/// Der Wecker-Koordinator wird beim App-Start von `AlarmBootstrap` einmal
/// gelesen, damit er Termine plant und auf klingelnde Wecker reagiert, auch
/// wenn der Nutzer den Wecker-Screen nie oeffnet.
///
/// [window]: Fenster, das beim Klingeln nach vorn kommt (Standard: das
/// Desktop-Fenster aus `DesktopController`). [platformFactory]: nur fuer
/// Tests. [isAndroid]: erzwingt die Plattform fuer die Freigabepruefung (Tests).
List<Override> alarmAndSleepOverrides({
  AlarmPermissionGateway permissions = const SystemAlarmPermissionGateway(),
  DesktopWindow? window,
  bool? isAndroid,
  AlarmPlatform Function(Clock clock) platformFactory = _defaultPlatform,
}) => <Override>[
  alarmPermissionCheckProvider.overrideWith(
    (ref) =>
        () => alarmPermissionCheck(permissions, isAndroid: isAndroid),
  ),
  alarmOpenSystemSettingsProvider.overrideWith(
    (ref) =>
        () => alarmOpenSystemSettings(permissions, isAndroid: isAndroid),
  ),
  alarmStatusCheckProvider.overrideWith(
    (ref) =>
        () => alarmPermissionStatus(permissions, isAndroid: isAndroid),
  ),
  alarmOpenFullScreenSettingsProvider.overrideWith(
    (ref) =>
        () => alarmOpenFullScreenSettings(permissions, isAndroid: isAndroid),
  ),
  alarmCoordinatorProvider.overrideWith((ref) {
    final clock = ref.watch(clockProvider);
    final coordinator = DefaultAlarmCoordinator(
      platform: platformFactory(clock),
      clock: clock,
      playback: ref.watch(playbackServiceProvider),
      startStation: (station) =>
          ref.read(playerControllerProvider).startStation(station),
      rules: () => ref.read(alarmProvider),
      onRuleFired: (updated) =>
          ref.read(alarmProvider.notifier).setRules(<AlarmRule>[
            for (final r in ref.read(alarmProvider))
              r.id == updated.id ? updated : r,
          ]),
      bringToFront: () => (window ?? DesktopController.instance.window).show(),
    );
    ref.onDispose(() => unawaited(coordinator.dispose()));
    unawaited(
      coordinator.platform.init().then(
        (_) => coordinator.rescheduleAll(ref.read(alarmProvider)),
      ),
    );
    return coordinator;
  }),
  sleepTimerServiceProvider.overrideWith((ref) {
    final tracks = StreamController<Track?>.broadcast();
    final service = DefaultSleepTimerService(
      clock: ref.watch(clockProvider),
      playback: ref.watch(playbackServiceProvider),
      tracks: tracks.stream,
    );
    ref
      ..listen(currentTrackProvider, (_, next) {
        if (!next.hasValue) return;
        tracks.add(next.value);
      })
      ..onDispose(() {
        unawaited(tracks.close());
        unawaited(service.dispose());
      });
    return service;
  }),
];

AlarmPlatform _defaultPlatform(Clock clock) =>
    createAlarmPlatform(clock: clock);
