import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/alarm/alarm_texts.dart';

/// iOS: lokale Mitteilung mit Systemton (`UNCalendarNotificationTrigger`,
/// Stunde/Minute, Wochentage, `repeats: true`). iOS startet keine App zu
/// fester Zeit; Antippen der Mitteilung oeffnet `linefm://play?station=slug`
/// und startet den Sender ueber die Deep-Link-Auswertung. Kein Hintergrund-
/// Audio-Trick (App-Review 2.5.4).
///
/// Dart-Seite des Kanals `de.linefm.app/alarm_ios`. Native Seite (Swift,
/// Paket P17) muss folgende Methoden bereitstellen:
///
/// * `requestPermission` -> `bool` (UNUserNotificationCenter, alert + sound)
/// * `schedule` mit `{id, hour, minute, weekdays (Liste von Ints)
///   (ISO 1 = Montag, leer = einmalig), title: String, body: String,
///   url: String}` -> ersetzt Mitteilungen mit dieser `id` (je Wochentag eine
///   Kennung `id#wochentag`); Ton `UNNotificationSound.default`.
/// * `cancel` mit `{id: String}` -> entfernt alle zugehoerigen Mitteilungen.
class IosAlarmPlatform implements AlarmPlatform {
  IosAlarmPlatform({MethodChannel? channel, this._texts})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'de.linefm.app/alarm_ios';

  final MethodChannel _channel;
  final AlarmTexts? _texts;

  @override
  Stream<AlarmRing> get rings => const Stream<AlarmRing>.empty();

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule(AlarmRule rule) async {
    if (!rule.enabled) {
      await cancel(rule.id);
      return;
    }
    final texts = _texts ?? AlarmTexts.system();
    final station = stationBySlug(rule.stationSlug);
    try {
      await _channel.invokeMethod<bool>('requestPermission');
      await _channel.invokeMethod<void>('schedule', <String, Object?>{
        'id': rule.id,
        'hour': rule.hour,
        'minute': rule.minute,
        'weekdays': (rule.weekdays.toList()..sort()),
        'title': texts.title,
        'body': texts.body(station?.displayName ?? 'LINEFM'),
        'url': 'linefm://play?station=${rule.stationSlug}',
      });
    } on MissingPluginException {
      debugPrint('Wecker iOS: nativer Kanal $channelName fehlt.');
    }
  }

  @override
  Future<void> cancel(String ruleId) async {
    try {
      await _channel.invokeMethod<void>('cancel', <String, Object?>{
        'id': ruleId,
      });
    } on MissingPluginException {
      debugPrint('Wecker iOS: nativer Kanal $channelName fehlt.');
    }
  }

  @override
  Future<void> silence(AlarmRing ring) async {}
}
