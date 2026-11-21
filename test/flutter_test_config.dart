import 'dart:async';
import 'dart:io';

import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';

/// Laeuft vor jeder Testdatei (Issue #91): Die Tests arbeiten mit einer
/// festen Senderliste (test/fixtures/stations/stations_6.json, Stand der
/// sechs Sender bei Einfuehrung der Datei), nicht mit
/// config/stations.yaml. So bricht keine Test, wenn der Betreiber in
/// der echten Datei Sender ergaenzt, entfernt oder umsortiert; die echte
/// Datei prueft test/domain/stations_config_test.dart und die CI.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  installBundledStations(
    parseStationsConfig(
      File('test/fixtures/stations/stations_6.json').readAsStringSync(),
    ),
  );
  await testMain();
}
