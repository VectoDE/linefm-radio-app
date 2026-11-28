// Runs the keyboard shortcut tests of the app shell in the real Linux build
// (flutter test -d linux), so key events travel through GTK and the X server
// instead of the headless test platform. CI: itest-linux.yml, under Xvfb with a
// window manager.
//
// test/flutter_test_config.dart does not run for integration tests, so the
// fixed station list the shortcut tests expect is installed here.
import 'dart:io';

import 'package:integration_test/integration_test.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';

import '../test/a11y/keyboard_shortcuts_linux_test.dart' as shortcuts;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  installBundledStations(
    parseStationsConfig(
      File('test/fixtures/stations/stations_6.json').readAsStringSync(),
    ),
  );
  shortcuts.main();
}
