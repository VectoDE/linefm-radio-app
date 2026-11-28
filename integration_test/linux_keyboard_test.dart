// Runs the keyboard shortcut tests of the app shell in the real Linux build
// (flutter test -d linux), so key events travel through GTK and the X server
// instead of the headless test platform. CI: itest-linux.yml, under Xvfb with a
// window manager.
import 'package:integration_test/integration_test.dart';

import '../test/a11y/keyboard_shortcuts_linux_test.dart' as shortcuts;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  shortcuts.main();
}
