import 'dart:io';

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import 'src/app.dart';
import 'src/context.dart';
import 'src/controller.dart';
import 'src/engine.dart';

/// Einstieg der Setup-Oberfläche. Wird nur vom Setup-Stub gestartet:
///   `linefm_setup.exe --context PFAD` (PFAD = context.json)
/// Bleibt für die Laufzeit bestehen, damit der Semantikbaum aktiv bleibt.
// ignore: unused_element
SemanticsHandle? _semantics;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Semantikbaum immer aufbauen: Windows meldet Screenreader und
  // UI-Automation nicht zuverlässig an, ohne das sähen sie nur eine Fläche.
  _semantics = SemanticsBinding.instance.ensureSemantics();
  final contextPath = _argValue(args, '--context');
  SetupContext? setup;
  if (contextPath != null) {
    try {
      setup = SetupContext.parse(await File(contextPath).readAsString());
    } on Object {
      setup = null;
    }
  }
  if (setup == null) {
    // Direkt gestartet oder Kontext beschädigt: der Stub zeigt dann einen
    // Hinweis auf die stille Installation (Exit-Code 1 = Parameter).
    exit(ExitCode.badArgs);
  }
  final controller = SetupController(
    context: setup,
    platform: NativeSetupPlatform(),
    exit: exit,
    licenseText: await _readLicense(),
  );
  runApp(SetupApp(controller: controller));
}

String? _argValue(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// LICENSE.txt liegt neben der Oberfläche (der Packer legt sie dort ab).
Future<String?> _readLicense() async {
  try {
    final dir = File(Platform.resolvedExecutable).parent.path;
    final text = await File('$dir${Platform.pathSeparator}LICENSE.txt')
        .readAsString();
    return text.trim().isEmpty ? null : text;
  } on Object {
    return null;
  }
}
