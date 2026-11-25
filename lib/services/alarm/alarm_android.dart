import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_texts.dart';

/// Schmale Sicht auf das Paket `alarm` (fuer Tests austauschbar).
abstract interface class AndroidAlarmApi {
  Future<bool> set(AlarmSettings settings);

  Future<bool> stop(int id);

  Future<List<AlarmSettings>> getAlarms();

  Future<bool> isRinging(int id);

  /// Aktuell klingelnde Alarme (liefert beim Abonnieren sofort den Stand).
  Stream<List<AlarmSettings>> get ringing;

  /// Nativ geschlummerte Alarme (Knopf in der Benachrichtigung) mit dem
  /// neuen Termin.
  Stream<(int, DateTime)> get snoozed;
}

class PackageAlarmApi implements AndroidAlarmApi {
  const PackageAlarmApi();

  @override
  Future<bool> set(AlarmSettings settings) =>
      Alarm.set(alarmSettings: settings);

  @override
  Future<bool> stop(int id) => Alarm.stop(id);

  @override
  Future<List<AlarmSettings>> getAlarms() => Alarm.getAlarms();

  @override
  Future<bool> isRinging(int id) => Alarm.isRinging(id);

  @override
  Stream<List<AlarmSettings>> get ringing =>
      Alarm.ringing.map((set) => set.alarms.toList());

  @override
  Stream<(int, DateTime)> get snoozed => Alarm.events
      .where((e) => e is AlarmMoved && e.cause == AlarmEventCause.snooze)
      .cast<AlarmMoved>()
      .map((e) => (e.id, e.nextRingAt));
}

/// Android: Paket `alarm` (`AlarmManager.setAlarmClock`, Doze-fest, Vollbild-
/// Benachrichtigung). Weckton ist der Systemton (Entscheidung 40, kein
/// eigener Ton): `assetAudioPath` bleibt leer, das Paket nimmt dann den
/// Standard-Alarmton des Geraets.
///
/// Das Paket plant je Alarm genau einen Termin. Wiederkehrende Regeln legen
/// deshalb die naechsten Termine der kommenden [horizon] im Voraus an, damit
/// der Wecker auch klingelt, wenn die App wochenlang nicht geoeffnet wird;
/// jeder App-Start und jedes Klingeln plant nach.
class AndroidAlarmPlatform implements AlarmPlatform {
  AndroidAlarmPlatform({
    required this._clock,
    this._api = const PackageAlarmApi(),
    this._texts,
    this.horizon = const Duration(days: 21),
    this.maxSlots = 31,
  });

  final Clock _clock;
  final AndroidAlarmApi _api;
  final AlarmTexts? _texts;

  /// Wie weit wiederkehrende Regeln im Voraus eingeplant werden.
  final Duration horizon;

  /// Obergrenze der Termine je Regel (Platz fuer 255 Kennungen).
  final int maxSlots;

  StreamController<AlarmRing>? _rings;
  StreamSubscription<List<AlarmSettings>>? _ringSub;
  StreamSubscription<(int, DateTime)>? _snoozeSub;

  /// Nativ geschlummerte Alarm-IDs mit neuem Termin: bleiben beim Neuplanen
  /// erhalten.
  final Map<int, DateTime> _snoozed = <int, DateTime>{};

  @override
  bool get ringsItself => true;

  /// Alarm-ID: 23 Bit Hash der Regel-ID, darunter 8 Bit Terminnummer.
  static int keyOf(String ruleId) {
    // FNV-1a, 32 Bit.
    var h = 0x811c9dc5;
    for (final unit in ruleId.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffff;
  }

  static int idFor(String ruleId, int slot) => (keyOf(ruleId) << 8) | slot;

  static int keyOfId(int id) => id >> 8;

  @override
  Stream<AlarmRing> get rings {
    final controller = _rings ??= StreamController<AlarmRing>.broadcast(
      onListen: _attachRinging,
    );
    return controller.stream;
  }

  void _attachRinging() {
    _ringSub ??= _api.ringing.listen((list) {
      for (final alarm in list) {
        final rule = alarm.payload;
        if (rule == null || rule.isEmpty) continue;
        _rings?.add(
          AlarmRing(ruleId: rule, handle: alarm.id, at: alarm.dateTime),
        );
      }
    });
  }

  @override
  Future<void> init() async {
    _snoozeSub ??= _api.snoozed.listen((e) => _snoozed[e.$1] = e.$2);
  }

  Future<bool> _spared(int id) async {
    if (await _api.isRinging(id)) return true;
    final until = _snoozed[id];
    return until != null && until.isAfter(_clock.now());
  }

  @override
  Future<void> schedule(AlarmRule rule) async {
    final key = keyOf(rule.id);
    final existing = await _api.getAlarms();
    final busy = <int>{};
    for (final alarm in existing) {
      if (keyOfId(alarm.id) != key) continue;
      if (await _spared(alarm.id)) {
        // Klingelnden oder geschlummerten Alarm nicht anruehren; die ID bleibt
        // belegt.
        busy.add(alarm.id);
      } else {
        await _api.stop(alarm.id);
      }
    }
    if (!rule.enabled) return;

    final now = _clock.now();
    final limit = now.add(horizon);
    // Entfernter Sender: der erste der Liste, wie beim Klingeln.
    final station = alarmStationFor(rule.stationSlug);
    final texts = _texts ?? AlarmTexts.system();
    var cursor = now;
    var slot = 0;
    var planned = 0;
    while (planned < maxSlots && slot < 256) {
      final at = AlarmSchedule.nextOccurrence(rule, cursor);
      if (at == null || (planned > 0 && at.isAfter(limit))) break;
      cursor = at;
      // Belegte ID (klingelt oder geschlummert): der Termin darf nicht
      // verloren gehen, er bekommt die naechste freie Terminnummer.
      var id = idFor(rule.id, slot++);
      while (busy.contains(id) && slot < 256) {
        id = idFor(rule.id, slot++);
      }
      if (busy.contains(id)) break;
      final ok = await _api.set(
        AlarmSettings(
          id: id,
          dateTime: at,
          assetAudioPath: null,
          loopAudio: true,
          vibrate: true,
          volumeSettings: const VolumeSettings.fixed(),
          notificationSettings: NotificationSettings(
            title: texts.title,
            body: texts.body(station.displayName),
            stopButton: texts.stopButton,
            androidSnoozeButton: texts.snoozeButton,
          ),
          // Der Ton laeuft weiter, auch wenn die App beendet wird.
          androidStopAlarmOnTermination: false,
          warningNotificationOnKill: false,
          androidFullScreenIntent: true,
          allowSameSecondScheduling: true,
          androidSnoozeDuration: AlarmSchedule.snooze,
          payload: rule.id,
        ),
      );
      if (!ok) debugPrint('Wecker ${rule.id}: Termin $at nicht geplant');
      planned++;
      if (!rule.repeats) break;
    }
  }

  @override
  Future<void> cancel(String ruleId) async {
    final key = keyOf(ruleId);
    for (final alarm in await _api.getAlarms()) {
      if (keyOfId(alarm.id) == key) await _api.stop(alarm.id);
    }
  }

  @override
  Future<void> removeOrphans(Set<String> knownRuleIds) async {
    for (final alarm in await _api.getAlarms()) {
      final payload = alarm.payload;
      final base = payload == null ? null : baseRuleIdOf(payload);
      if (base == null || !knownRuleIds.contains(base)) {
        await _api.stop(alarm.id);
      }
    }
  }

  @override
  Future<AlarmRingState> ringState(AlarmRing ring) async {
    final id = ring.handle;
    if (id == null) return AlarmRingState.ended;
    if (await _api.isRinging(id)) return AlarmRingState.ringing;
    for (final alarm in await _api.getAlarms()) {
      if (alarm.id == id && alarm.dateTime.isAfter(_clock.now())) {
        return AlarmRingState.snoozed;
      }
    }
    return AlarmRingState.ended;
  }

  @override
  Future<void> silence(AlarmRing ring) async {
    final id = ring.handle;
    // Nur stoppen, solange er klingelt: ein nativ geschlummerter Termin
    // (gleiche ID) darf nicht geloescht werden.
    if (id != null && await _api.isRinging(id)) await _api.stop(id);
  }

  @override
  Future<void> dispose() async {
    await _snoozeSub?.cancel();
    await _ringSub?.cancel();
    await _rings?.close();
  }
}
