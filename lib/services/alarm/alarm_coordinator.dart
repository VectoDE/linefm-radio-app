import 'dart:async';

import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/alarm/alarm_platform_factory.dart'
    as platforms;
import 'package:linefm_radio/services/audio/playback_service.dart';

/// Ein klingelnder Wecker. [ruleId] kann das Suffix [snoozeSuffix] tragen
/// (Schlummer-Wiederholung).
class AlarmRing {
  const AlarmRing({required this.ruleId, this.handle, this.at});

  final String ruleId;

  /// Plattform-Kennung (Android: Alarm-ID), nur fuer [AlarmPlatform.silence].
  final int? handle;

  /// Klingelzeitpunkt; unterscheidet Wiederholungen (Schlummern) desselben
  /// Alarms von erneut gemeldeten Ereignissen.
  final DateTime? at;

  /// Schluessel gegen doppelte Verarbeitung.
  String get key =>
      '$ruleId@${handle ?? ''}@${at?.millisecondsSinceEpoch ?? ''}';

  bool get isSnoozeRing => ruleId.endsWith(snoozeSuffix);

  /// Regel-ID ohne Schlummer-Suffix.
  String get baseRuleId => baseRuleIdOf(ruleId);
}

/// Anhang an die Regel-ID fuer die Schlummer-Wiederholung.
const String snoozeSuffix = '~snooze';

String baseRuleIdOf(String ruleId) => ruleId.endsWith(snoozeSuffix)
    ? ruleId.substring(0, ruleId.length - snoozeSuffix.length)
    : ruleId;

/// Plattformabhaengige Wecker-Ausfuehrung (alarm_android, alarm_ios,
/// alarm_inapp).
abstract interface class AlarmPlatform {
  /// Meldet jeden klingelnden Wecker, solange die App laeuft (Android,
  /// Desktop, Web). iOS meldet nichts; dort startet das Antippen der
  /// Mitteilung den Sender ueber den Deep Link `linefm://play?station=`.
  Stream<AlarmRing> get rings;

  Future<void> init();

  /// Ersetzt alle geplanten Termine der Regel durch die kommenden.
  Future<void> schedule(AlarmRule rule);

  /// Entfernt alle Termine der Regel (auch Schlummer, auch einen laufenden
  /// Ton).
  Future<void> cancel(String ruleId);

  /// Beendet den Weckton, sobald der Sender laeuft (Android: Systemton;
  /// sonst nichts zu tun).
  Future<void> silence(AlarmRing ring);
}

/// Koordiniert Regeln, Plattform und Sendestart.
abstract interface class AlarmCoordinator {
  Future<void> rescheduleAll(List<AlarmRule> rules);

  Future<void> snooze(String ruleId);

  Future<void> dismiss(String ruleId);
}

class NoopAlarmCoordinator implements AlarmCoordinator {
  const NoopAlarmCoordinator();

  @override
  Future<void> rescheduleAll(List<AlarmRule> rules) async {}

  @override
  Future<void> snooze(String ruleId) async {}

  @override
  Future<void> dismiss(String ruleId) async {}
}

/// Initialisiert die Plattform-Seite des Weckers vor `runApp` (Android:
/// Paket `alarm`; sonst nichts).
Future<void> initAlarm() => platforms.initAlarmPlatform();

/// Weckerverhalten: Plant Regeln, startet beim Klingeln den Sender mit
/// Lautstaerke-Rampe und beendet den Weckton erst, wenn der Stream wirklich
/// spielt. Scheitert der Stream (offline), klingelt der Weckton weiter (kein
/// stilles Verschlafen, Spec 2.2).
class DefaultAlarmCoordinator implements AlarmCoordinator {
  DefaultAlarmCoordinator({
    required this.platform,
    required this._clock,
    required this._playback,
    required this.startStation,
    required this.rules,
    this.onRuleFired,
    this.bringToFront,
    this.rampStart = 0.2,
    this.rampDuration = const Duration(seconds: 30),
    this.rampStep = const Duration(seconds: 1),
    this.streamTimeout = const Duration(seconds: 45),
  }) {
    _sub = platform.rings.listen((ring) => unawaited(handleRing(ring)));
  }

  final AlarmPlatform platform;
  final Clock _clock;
  final PlaybackService _playback;

  /// Waehlt und startet einen Sender (App-Weg ueber den PlayerController).
  final Future<void> Function(Station station) startStation;

  /// Aktuelle Regeln (aus dem Speicher; funktioniert auch nach Kaltstart).
  final List<AlarmRule> Function() rules;

  /// Nach dem Klingeln einer einmaligen Regel: ausgeschaltete Regel speichern.
  final Future<void> Function(AlarmRule updated)? onRuleFired;

  /// Desktop: Fenster zeigen und fokussieren.
  final Future<void> Function()? bringToFront;

  final double rampStart;
  final Duration rampDuration;
  final Duration rampStep;
  final Duration streamTimeout;

  StreamSubscription<AlarmRing>? _sub;
  Timer? _rampTimer;
  final Set<String> _handled = <String>{};

  /// Regel-IDs, fuer die gerade eine Schlummer-Wiederholung geplant ist.
  final Set<String> _snoozing = <String>{};

  AlarmRule? _ruleById(String id) {
    for (final rule in rules()) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  @override
  Future<void> rescheduleAll(List<AlarmRule> rules) async {
    for (final rule in rules) {
      if (rule.enabled) {
        await platform.schedule(rule);
      } else {
        await platform.cancel(rule.id);
        await platform.cancel('${rule.id}$snoozeSuffix');
      }
    }
  }

  /// Wecker klingelt: Sender mit Rampe starten, Ton erst bei laufendem Stream
  /// beenden, danach naechste Termine planen. Oeffentlich fuer Tests.
  Future<void> handleRing(AlarmRing ring) async {
    if (!_handled.add(ring.key)) return;
    final rule = _ruleById(ring.baseRuleId);
    if (rule == null) {
      // Regel inzwischen geloescht: Ton nicht weiter klingeln lassen.
      await platform.silence(ring);
      return;
    }
    final station = stationBySlug(rule.stationSlug) ?? stationsCatalog.first;
    final target = rule.volume.clamp(0.1, 1.0);
    final start = rampStart < target ? rampStart : target;

    try {
      await bringToFront?.call();
    } on Object {
      // Fenster zeigen ist nur Komfort.
    }

    final playing = _waitForPlaying();
    try {
      await startStation(station);
      await _playback.setVolume(start);
    } on Object {
      // Stream nicht startbar: Ton klingelt weiter, siehe unten.
    }

    final ok = await playing;
    if (ok) {
      await platform.silence(ring);
      _startRamp(from: start, to: target);
    }
    if (ring.isSnoozeRing) {
      _snoozing.remove(rule.id);
    } else {
      await _afterFired(rule);
    }
  }

  Future<bool> _waitForPlaying() async {
    if (_playback.state.isPlaying) return true;
    final completer = Completer<bool>();
    late final StreamSubscription<PlayerUiState> sub;
    final timer = Timer(streamTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });
    sub = _playback.stateStream.listen((s) {
      if (s.isPlaying && !completer.isCompleted) completer.complete(true);
    });
    final result = await completer.future;
    timer.cancel();
    await sub.cancel();
    return result;
  }

  void _startRamp({required double from, required double to}) {
    _rampTimer?.cancel();
    if (to <= from || rampDuration <= Duration.zero) {
      unawaited(_playback.setVolume(to));
      return;
    }
    final begin = _clock.now();
    _rampTimer = Timer.periodic(rampStep, (timer) {
      final elapsed = _clock.now().difference(begin);
      final t = elapsed.inMicroseconds / rampDuration.inMicroseconds;
      if (t >= 1) {
        timer.cancel();
        unawaited(_playback.setVolume(to));
        return;
      }
      unawaited(_playback.setVolume(from + (to - from) * t));
    });
  }

  /// Einmalige Regeln schalten sich aus, wiederkehrende bekommen neue Termine.
  Future<void> _afterFired(AlarmRule rule) async {
    final updated = AlarmSchedule.afterFired(rule);
    if (updated != rule) {
      await onRuleFired?.call(updated);
      await platform.cancel(rule.id);
    } else {
      await platform.schedule(rule);
    }
  }

  @override
  Future<void> snooze(String ruleId) async {
    final base = baseRuleIdOf(ruleId);
    final rule = _ruleById(base);
    if (rule == null) return;
    _rampTimer?.cancel();
    if (_playback.state.status != PlayerStatus.idle) {
      await _playback.stopPlayback();
    }
    var at = AlarmSchedule.snoozeUntil(_clock.now());
    // Wecker kennen nur Minuten: aufrunden, damit es nie weniger als 9 Minuten
    // sind.
    if (at.second > 0 || at.millisecond > 0) {
      at = DateTime(at.year, at.month, at.day, at.hour, at.minute + 1);
    }
    _snoozing.add(base);
    await platform.schedule(
      rule.copyWith(
        id: '$base$snoozeSuffix',
        enabled: true,
        hour: at.hour,
        minute: at.minute,
        weekdays: const <int>{},
      ),
    );
  }

  @override
  Future<void> dismiss(String ruleId) async {
    final base = baseRuleIdOf(ruleId);
    _rampTimer?.cancel();
    if (_snoozing.remove(base)) {
      await platform.cancel('$base$snoozeSuffix');
    }
    final rule = _ruleById(base);
    if (rule != null && rule.enabled && rule.repeats) {
      await platform.schedule(rule);
    }
  }

  Future<void> dispose() async {
    _rampTimer?.cancel();
    await _sub?.cancel();
  }
}
