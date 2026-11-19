import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Prueft, ob die Plattform den Wecker erlauben kann (Android: genaue Alarme).
/// Liefert `false`, wenn die Freigabe fehlt. Der Wecker-Dienst (P20) ueber-
/// schreibt den Provider; Standard: immer erlaubt.
typedef AlarmPermissionCheck = Future<bool> Function();

final alarmPermissionCheckProvider = Provider<AlarmPermissionCheck>(
  (ref) =>
      () async => true,
);

/// Oeffnet die Systemeinstellung fuer die Wecker-Freigabe (Android). Der
/// Wecker-Dienst (P20) ueberschreibt den Provider; Standard: keine Aktion.
final alarmOpenSystemSettingsProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Stand der Wecker-Freigaben (Android). Standard: alles in Ordnung.
class AlarmPermissionStatus {
  const AlarmPermissionStatus({this.exactOk = true, this.fullScreenOk = true});

  /// Genaue Alarme erlaubt (`SCHEDULE_EXACT_ALARM`).
  final bool exactOk;

  /// Vollbild-Wecken erlaubt (`USE_FULL_SCREEN_INTENT`, Android 14+).
  final bool fullScreenOk;

  @override
  bool operator ==(Object other) =>
      other is AlarmPermissionStatus &&
      other.exactOk == exactOk &&
      other.fullScreenOk == fullScreenOk;

  @override
  int get hashCode => Object.hash(exactOk, fullScreenOk);
}

/// Stille Pruefung beider Freigaben (ohne Rueckfrage an den Nutzer).
final alarmStatusCheckProvider =
    Provider<Future<AlarmPermissionStatus> Function()>(
      (ref) =>
          () async => const AlarmPermissionStatus(),
    );

/// Oeffnet die Systemeinstellung fuer Vollbild-Benachrichtigungen (Android).
final alarmOpenFullScreenSettingsProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Liest und loescht das Merkzeichen "Zeitzone/Uhrzeit geaendert" (Android).
final alarmRescheduleFlagProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => false,
);

class AlarmPermissionStatusNotifier extends Notifier<AlarmPermissionStatus> {
  @override
  AlarmPermissionStatus build() => const AlarmPermissionStatus();

  /// Liest den aktuellen Stand neu (App-Start, Rueckkehr aus den
  /// Systemeinstellungen).
  Future<AlarmPermissionStatus> refresh() async {
    final next = await ref.read(alarmStatusCheckProvider)();
    state = next;
    return next;
  }
}

final alarmPermissionStatusProvider =
    NotifierProvider<AlarmPermissionStatusNotifier, AlarmPermissionStatus>(
      AlarmPermissionStatusNotifier.new,
    );
