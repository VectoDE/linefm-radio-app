import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'src/app.dart';
import 'src/context.dart';
import 'src/controller.dart';
import 'src/engine.dart';
import 'src/posix.dart';

/// Einstieg der Setup-Oberfläche.
/// - Windows: nur vom Setup-Stub gestartet, `linefm_setup.exe --context PFAD`
///   (PFAD = context.json).
/// - macOS and Linux: started directly (installer app, AppImage or the kept
///   uninstaller); the start data comes from `engine.sh context`.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final posix = !Platform.isWindows;
  final setupDir = posix ? posixSetupDir() : null;
  SetupContext? setup;
  if (setupDir != null) {
    setup = await loadPosixContext(setupDir);
  } else {
    final contextPath = _argValue(args, '--context');
    if (contextPath != null) {
      try {
        setup = SetupContext.parse(await File(contextPath).readAsString());
      } on Object {
        setup = null;
      }
    }
  }
  if (setup == null) {
    // Direkt gestartet oder Kontext beschädigt: der Stub zeigt dann einen
    // Hinweis auf die stille Installation (Exit-Code 1 = Parameter).
    exit(ExitCode.badArgs);
  }
  final controller = SetupController(
    context: setup,
    platform: posix
        ? ProcessSetupPlatform(os: setup.os)
        : NativeSetupPlatform(),
    exit: exit,
    licenseText: await _readLicense(setupDir),
  );
  final autopilot = SetupAutopilot.folderFromEnvironment();
  final boundary = GlobalKey();
  runApp(
    RepaintBoundary(
      key: boundary,
      child: SetupApp(controller: controller),
    ),
  );
  if (autopilot != null) {
    unawaited(
      SetupAutopilot(
        controller: controller,
        boundary: boundary,
        outDir: Directory(autopilot),
        prefix: setup.os.name,
      ).run(),
    );
  }
}

String? _argValue(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// LICENSE.txt liegt neben der Oberfläche (Windows: der Packer legt sie dort
/// ab) bzw. im Setup-Ordner (macOS, Linux).
Future<String?> _readLicense(Directory? setupDir) async {
  try {
    final dir = setupDir?.path ?? File(Platform.resolvedExecutable).parent.path;
    final text = await File('$dir${Platform.pathSeparator}LICENSE.txt')
        .readAsString();
    return text.trim().isEmpty ? null : text;
  } on Object {
    return null;
  }
}
