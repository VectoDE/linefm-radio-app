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
