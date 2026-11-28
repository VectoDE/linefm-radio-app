import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/alarm/alarm_platform_factory.dart'
    as platforms;
import 'package:linefm_radio/services/audio/playback_service.dart';

part 'alarm_types.dart';

/// Initialisiert die Plattform-Seite des Weckers vor `runApp` (Android:
/// Paket `alarm`; sonst nichts).
Future<void> initAlarm() => platforms.initAlarmPlatform();

Future<void> _systemBeep() => SystemSound.play(SystemSoundType.alert);

/// Weckerverhalten: Plant Regeln, startet beim Klingeln den Sender mit
/// Lautstaerke-Rampe und beendet den Weckton erst, wenn der Stream der
/// Ziel-Station wirklich spielt. Scheitert der Stream (offline), klingelt der
/// Weckton weiter (kein stilles Verschlafen, Spec 2.2).
class DefaultAlarmCoordinator implements AlarmCoordinator {
  DefaultAlarmCoordinator({
    required this.platform,
    required this._clock,
    required this._playback,
    required this.startStation,
    required this.rules,
    this.onRuleFired,
    this.bringToFront,
    this.beep = _systemBeep,
    this.rampStart = 0.2,
    this.rampDuration = const Duration(seconds: 30),
    this.rampStep = const Duration(seconds: 1),
    this.streamTimeout = const Duration(seconds: 45),
    this.beepInterval = const Duration(seconds: 3),
    this.bannerTimeout = const Duration(minutes: 3),
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

  /// Speichert eine geaenderte Regel (einmaliger Wecker nach dem Klingeln,
  /// verpasster Termin): schaltet sie aus.
  final Future<void> Function(AlarmRule updated)? onRuleFired;

  /// Desktop: Fenster zeigen und fokussieren.
  final Future<void> Function()? bringToFront;

  /// Ersatzton, wenn weder Plattform-Ton noch Stream laufen (Desktop/Web).
  final Future<void> Function() beep;

  final double rampStart;
  final Duration rampDuration;
  final Duration rampStep;
  final Duration streamTimeout;
  final Duration beepInterval;
  final Duration bannerTimeout;

  final ValueNotifier<AlarmRinging?> _ringing = ValueNotifier<AlarmRinging?>(
    null,
  );
  StreamSubscription<AlarmRing>? _sub;
  Timer? _rampTimer;
  Timer? _beepTimer;
  Timer? _bannerTimer;
  AlarmRing? _activeRing;

  /// Klingeln, das der Nutzer waehrend des Sendestarts geschlummert hat.
  AlarmRing? _snoozedRing;

  /// Aenderungen, die der Koordinator selbst ausloest (Einmal-Wecker schaltet
  /// sich aus): kein Nutzer-Ausschalten.
  int _internalChange = 0;

  /// Zuletzt gesehener Einschaltzustand je Regel (erkennt Ausschalten durch
  /// den Nutzer).
  Map<String, bool> _enabledBefore = <String, bool>{};
  final Set<String> _handled = <String>{};

  /// Regel-IDs, die zuletzt geplant waren (erkennt geloeschte Regeln).
  Set<String> _known = <String>{};

  /// Regel-IDs, fuer die gerade eine Schlummer-Wiederholung geplant ist.
  final Set<String> _snoozing = <String>{};

  @override
  ValueListenable<AlarmRinging?> get ringing => _ringing;

  AlarmRule? _ruleById(String id) {
    for (final rule in rules()) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  @override
  Future<void> rescheduleAll(List<AlarmRule> rules) async {
    final ids = <String>{for (final r in rules) r.id};
    for (final removed in _known.difference(ids)) {
      _snoozing.remove(removed);
      await platform.cancel(removed);
      await platform.cancel('$removed$snoozeSuffix');
    }
    _known = ids;

    final now = _clock.now();
    final before = _enabledBefore;
    _enabledBefore = <String, bool>{for (final r in rules) r.id: r.enabled};
    for (final rule in rules) {
      final at = rule.firesAt;
      if (rule.enabled && !rule.repeats && at != null && !at.isAfter(now)) {
        // Einmaliger Termin liegt hinter uns (verpasst oder gerade
        // klingelnd): ausschalten statt auf morgen zu legen.
        await _fired(rule.copyWith(enabled: false));
        continue;
      }
      await platform.schedule(rule);
      // Nur wenn der Nutzer die Regel selbst von an auf aus stellt, entfaellt
      // auch ihr Schlummer-Termin. Nach einem Neustart (kein Vorzustand) oder
      // wenn sich ein Einmal-Wecker nach dem Klingeln selbst ausschaltet, bleibt
      // ein geschlummerter Termin erhalten.
      if (!rule.enabled && before[rule.id] == true && _internalChange == 0) {
        _snoozing.remove(rule.id);
        await platform.cancel('${rule.id}$snoozeSuffix');
      }
    }
    await platform.removeOrphans(ids);
  }

  /// Wecker klingelt: Sender mit Rampe starten, Ton erst bei laufendem Stream
  /// der Ziel-Station beenden, danach naechste Termine planen. Oeffentlich
  /// fuer Tests.
  Future<void> handleRing(AlarmRing ring) async {
    if (!_handled.add(ring.key)) return;
    final rule = _ruleById(ring.baseRuleId);
    if (rule == null) {
      // Regel inzwischen geloescht: Ton nicht weiter klingeln lassen.
      await platform.silence(ring);
      return;
    }
    final station = alarmStationFor(rule.stationSlug);
    final target = rule.volume.clamp(0.1, 1.0);
    final start = rampStart < target ? rampStart : target;

    _activeRing = ring;
    _showRinging(AlarmRinging(ruleId: rule.id, station: station));
    try {
      await bringToFront?.call();
    } on Object {
      // Fenster zeigen ist nur Komfort.
    }

    final ok = await _startAndAwaitPlaying(station, start);
    if (!identical(_activeRing, ring)) {
      // Der Nutzer hat im Banner waehrend der Wartezeit geschlummert oder
      // ausgeschaltet: weder Rampe noch Piepton. Nach Schlummern das Radio
      // wieder stoppen, das inzwischen angelaufen sein kann.
      if (identical(_snoozedRing, ring)) {
        _snoozedRing = null;
        await _playback.stopPlayback();
      }
    } else if (ok) {
      switch (await platform.ringState(ring)) {
        case AlarmRingState.ringing:
          await platform.silence(ring);
          _startRamp(from: start, to: target);
          _armBannerTimeout();
        case AlarmRingState.snoozed:
          // Nutzer hat in der Benachrichtigung geschlummert: Radio aus, der
          // native Termin bleibt bestehen.
          _rampTimer?.cancel();
          await _playback.stopPlayback();
          _clearRinging();
        case AlarmRingState.ended:
          _startRamp(from: start, to: target);
          _armBannerTimeout();
      }
    } else if (!platform.ringsItself) {
      // Ohne Stream bleiben Banner und Piepton, bis der Nutzer waehlt.
      _startBeeping();
    }
    if (ring.isSnoozeRing) {
      _snoozing.remove(rule.id);
    } else {
      await _afterFired(rule);
    }
  }

  /// Startet den Sender und wartet auf `playing` genau dieser Station.
  Future<bool> _startAndAwaitPlaying(Station station, double volume) async {
    final done = Completer<bool>();
    bool matches(PlayerUiState s) => s.isPlaying && s.station == station;
    final sub = _playback.stateStream.listen((s) {
      if (matches(s) && !done.isCompleted) done.complete(true);
    });
    final timer = Timer(streamTimeout, () {
      if (!done.isCompleted) done.complete(false);
    });
    try {
      await startStation(station);
      await _playback.setVolume(volume);
    } on Object {
      // Stream nicht startbar: Ton klingelt weiter, der Timer meldet false.
    }
    if (matches(_playback.state) && !done.isCompleted) done.complete(true);
    final result = await done.future;
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

  void _startBeeping() {
    _beepTimer?.cancel();
    unawaited(beep());
    _beepTimer = Timer.periodic(beepInterval, (_) => unawaited(beep()));
  }

  Future<void> _silenceActive() async {
    final ring = _activeRing;
    _activeRing = null;
    if (ring != null) await platform.silence(ring);
  }

  void _showRinging(AlarmRinging value) {
    _ringing.value = value;
    _bannerTimer?.cancel();
  }

  /// Banner blendet sich erst aus, wenn der Stream laeuft; ohne Stream bleibt
  /// er samt Ersatzton, bis der Nutzer Schlummern oder Aus waehlt.
  void _armBannerTimeout() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(bannerTimeout, _clearRinging);
  }

  void _clearRinging() {
    _bannerTimer?.cancel();
    _beepTimer?.cancel();
    _beepTimer = null;
    _ringing.value = null;
  }

  /// Einmalige Regeln schalten sich aus, wiederkehrende bekommen neue Termine.
  /// Ein noch klingelnder Alarm bleibt dabei unberuehrt (Plattform-Vertrag
  /// von [AlarmPlatform.schedule]).
  Future<void> _afterFired(AlarmRule rule) async {
    final updated = AlarmSchedule.afterFired(rule);
    if (updated != rule) {
      await _fired(updated);
    } else {
      await platform.schedule(rule);
    }
  }

  Future<void> _fired(AlarmRule updated) async {
    _internalChange++;
    try {
      await onRuleFired?.call(updated);
    } finally {
      _internalChange--;
    }
  }

  @override
  Future<void> snooze(String ruleId) async {
    final base = baseRuleIdOf(ruleId);
    final rule = _ruleById(base);
    if (rule == null) return;
    _rampTimer?.cancel();
    _snoozedRing = _activeRing;
    await _silenceActive();
    _clearRinging();
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
        firesAt: at,
      ),
    );
  }

  @override
  Future<void> dismiss(String ruleId) async {
    final base = baseRuleIdOf(ruleId);
    _rampTimer?.cancel();
    await _silenceActive();
    _clearRinging();
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
    _beepTimer?.cancel();
    _bannerTimer?.cancel();
    await _sub?.cancel();
    await platform.dispose();
    _ringing.dispose();
  }
}
