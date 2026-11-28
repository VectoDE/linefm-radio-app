import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/alarm/alarm_android.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_permissions.dart';

import '../support/service_doubles.dart';

class FakeAlarmApi implements AndroidAlarmApi {
  final Map<int, AlarmSettings> alarms = <int, AlarmSettings>{};
  final Set<int> ringingIds = <int>{};
  final StreamController<List<AlarmSettings>> ringingController =
      StreamController<List<AlarmSettings>>.broadcast();
  final StreamController<(int, DateTime)> snoozedController =
      StreamController<(int, DateTime)>.broadcast();

  @override
  Future<bool> set(AlarmSettings settings) async {
    alarms[settings.id] = settings;
    return true;
  }

  @override
  Future<bool> stop(int id) async {
    ringingIds.remove(id);
    return alarms.remove(id) != null;
  }

  @override
  Future<List<AlarmSettings>> getAlarms() async => alarms.values.toList();

  @override
  Future<bool> isRinging(int id) async => ringingIds.contains(id);

  @override
  Stream<List<AlarmSettings>> get ringing => ringingController.stream;

  @override
  Stream<(int, DateTime)> get snoozed => snoozedController.stream;
}

class FakePlatform implements AlarmPlatform {
  final StreamController<AlarmRing> controller =
      StreamController<AlarmRing>.broadcast();
  final List<AlarmRule> scheduled = <AlarmRule>[];
  final List<String> cancelled = <String>[];
  final List<AlarmRing> silenced = <AlarmRing>[];
  final List<Set<String>> orphanCalls = <Set<String>>[];
  AlarmRingState state = AlarmRingState.ringing;
  bool disposed = false;

  bool itself = true;

  @override
  bool get ringsItself => itself;

  @override
  Stream<AlarmRing> get rings => controller.stream;

  @override
  Future<void> removeOrphans(Set<String> knownRuleIds) async =>
      orphanCalls.add(knownRuleIds);

  @override
  Future<AlarmRingState> ringState(AlarmRing ring) async => state;

  @override
  Future<void> dispose() async => disposed = true;

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule(AlarmRule rule) async => scheduled.add(rule);

  @override
  Future<void> cancel(String ruleId) async => cancelled.add(ruleId);

  @override
  Future<void> silence(AlarmRing ring) async => silenced.add(ring);
}

/// Spielt erst, wenn der Test [playingNow] aufruft (oder sofort, wenn
/// [autoPlay]).
class Playback extends NoopPlaybackService {
  Playback({this.autoPlay = true});

  final bool autoPlay;
  final List<double> volumes = <double>[];
  final List<Station> started = <Station>[];

  Future<void> playingNow() => super.playStation(stationsCatalog.first);

  Future<void> playingOther() => super.playStation(stationsCatalog.last);

  @override
  Future<void> playStation(Station station) async {
    started.add(station);
    if (autoPlay) await super.playStation(station);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
    await super.setVolume(volume);
  }
}

AlarmRule rule({
  String id = '1700000000000000',
  int hour = 7,
  int minute = 0,
  Set<int> weekdays = const <int>{},
  bool enabled = true,
  double volume = 0.7,
}) => AlarmRule(
  id: id,
  hour: hour,
  minute: minute,
  stationSlug: stationsCatalog.first.slug,
  weekdays: weekdays,
  volume: volume,
  enabled: enabled,
);

class Gateway implements AlarmPermissionGateway {
  Gateway({required this.exact});

  final bool exact;
  int notificationRequests = 0;
  int opened = 0;

  @override
  Future<bool> canScheduleExactAlarms() async => exact;

  @override
  Future<void> openExactAlarmSettings() async => opened++;

  @override
  Future<bool> canUseFullScreenIntent() async => true;

  @override
  Future<void> openFullScreenIntentSettings() async {}

  @override
  Future<void> requestNotifications() async => notificationRequests++;

  @override
  Future<bool> consumeRescheduleFlag() async => false;
}
