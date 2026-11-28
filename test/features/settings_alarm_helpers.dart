import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';

import '../support/service_doubles.dart';

class FakeSleepTimer implements SleepTimerService {
  FakeSleepTimer(this._clock);

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

class RecordingAlarms implements AlarmCoordinator {
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
