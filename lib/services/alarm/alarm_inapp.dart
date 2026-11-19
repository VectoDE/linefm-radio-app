import 'dart:async';

import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';

/// Desktop und Web: In-App-Timer gegen die Wanduhr. Der Wecker klingelt nur,
/// solange die App laeuft (Desktop auch minimiert im Tray, Web nur bei
/// offenem Tab). Die Pruefung alle [interval] (15 s) faengt Ruhezustand und
/// Uhrspruenge ab: Faellig ist jeder Termin zwischen der letzten Pruefung und
/// jetzt.
class InAppAlarmPlatform implements AlarmPlatform {
  InAppAlarmPlatform({
    required this._clock,
    this.interval = const Duration(seconds: 15),
  });

  final Clock _clock;
  final Duration interval;

  final StreamController<AlarmRing> _rings =
      StreamController<AlarmRing>.broadcast();
  final Map<String, AlarmRule> _rules = <String, AlarmRule>{};

  /// Zeitpunkt der letzten Pruefung je Regel (Startwert: Planungszeitpunkt,
  /// damit ein neu gestellter Wecker nicht sofort fuer die Vergangenheit
  /// klingelt).
  final Map<String, DateTime> _since = <String, DateTime>{};
  Timer? _timer;

  @override
  Stream<AlarmRing> get rings => _rings.stream;

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule(AlarmRule rule) async {
    if (!rule.enabled) {
      await cancel(rule.id);
      return;
    }
    final changed = _rules[rule.id] != rule;
    _rules[rule.id] = rule;
    if (changed || !_since.containsKey(rule.id)) {
      _since[rule.id] = _clock.now();
    }
    _timer ??= Timer.periodic(interval, (_) => check());
  }

  @override
  Future<void> cancel(String ruleId) async {
    _rules.remove(ruleId);
    _since.remove(ruleId);
    _stopTimerIfIdle();
  }

  @override
  Future<void> silence(AlarmRing ring) async {}

  /// Eine Pruefung gegen die Wanduhr. Oeffentlich fuer Tests.
  void check() {
    final now = _clock.now();
    for (final rule in _rules.values.toList()) {
      final previous = _since[rule.id] ?? now;
      _since[rule.id] = now;
      if (AlarmSchedule.isDue(rule, previousCheck: previous, now: now)) {
        _rings.add(AlarmRing(ruleId: rule.id, at: now));
        if (!rule.repeats) {
          _rules.remove(rule.id);
          _since.remove(rule.id);
        }
      }
    }
    _stopTimerIfIdle();
  }

  void _stopTimerIfIdle() {
    if (_rules.isNotEmpty) return;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _rings.close();
  }
}
