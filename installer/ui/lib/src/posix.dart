import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'context.dart';
import 'controller.dart';
import 'engine.dart';

/// Folder with the POSIX engine (`engine.sh`), `product.env`, `LICENSE.txt`
/// and, in the installer, the payload. It ships inside the setup UI bundle:
/// `Contents/Resources/setup` on macOS, `setup/` next to the executable on
/// Linux.
Directory posixSetupDir() {
  final exeDir = File(Platform.resolvedExecutable).parent;
  return Platform.isMacOS
      ? Directory('${exeDir.parent.path}/Resources/setup')
      : Directory('${exeDir.path}/setup');
}

/// Asks the engine for the start data (`engine.sh context`). Returns null if
/// the engine is missing or answers with something that is not a context.
Future<SetupContext?> loadPosixContext(Directory setupDir) async {
  final engine = File('${setupDir.path}/engine.sh');
  if (!engine.existsSync()) return null;
  try {
    final result = await Process.run('/bin/sh', [engine.path, 'context']);
    if (result.exitCode != 0) return null;
    return SetupContext.parse(result.stdout as String);
  } on Object {
    return null;
  }
}

/// Connection to the POSIX engine (macOS, Linux): the engine runs as a child
/// process and speaks the same line protocol as the Windows engine, on
/// stdout instead of a named pipe; answers go to its stdin. No privilege
/// escalation: the engine runs with the rights of the signed-in user.
class ProcessSetupPlatform implements SetupPlatform {
  ProcessSetupPlatform({required this.os}) {
    // Close button and Cmd+Q: the runner (macos/Runner/MainFlutterWindow.swift,
    // linux/runner/my_application.cc) keeps the window open and asks the UI,
    // same confirmation flow as on Windows.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'closeRequested') _close.add(null);
      return null;
    });
  }

  static const MethodChannel _channel = MethodChannel('linefm_setup/native');

  final HostOs os;
  Process? _process;

  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();
  final StreamController<int> _exits = StreamController<int>.broadcast();
  final StreamController<void> _close = StreamController<void>.broadcast();

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Stream<int> get exits => _exits.stream;

  @override
  Stream<void> get closeRequests => _close.stream;

  @override
  Future<StartResult> start({
    required String exe,
    required List<String> args,
    required bool elevate,
  }) async {
    if (_process != null) return StartResult.failed;
    try {
      final process = await Process.start('/bin/sh', [exe, ...args]);
      _process = process;
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final event = EngineEvent.parse(line);
            if (event != null) _events.add(event);
          });
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _events.add(LogEvent(line)));
      unawaited(
        process.exitCode.then((code) {
          _process = null;
          _exits.add(code);
        }),
      );
      return StartResult.ok;
    } on Object {
      return StartResult.failed;
    }
  }

  @override
  Future<bool> send(String line) async {
    final process = _process;
    if (process == null) return false;
    try {
      process.stdin.writeln(line);
      await process.stdin.flush();
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> pickFolder({
    required String initial,
    required String title,
  }) async {
    try {
      final ProcessResult result;
      if (os == HostOs.macos) {
        // Values go in as arguments, never into the script text.
        result = await Process.run('/usr/bin/osascript', [
          '-e',
          'on run argv',
          '-e',
          'return POSIX path of (choose folder with prompt (item 1 of argv))',
          '-e',
          'end run',
          title,
        ]);
      } else {
        result = await Process.run('zenity', [
          '--file-selection',
          '--directory',
          '--title=$title',
          '--filename=$initial/',
        ]);
      }
      if (result.exitCode != 0) return null;
      final path = (result.stdout as String).trim();
      return path.isEmpty ? null : path;
    } on Object {
      // No folder dialog available (e.g. zenity missing): the path can
      // still be typed in.
      return null;
    }
  }

  @override
  Future<bool> launch(String exe) async {
    try {
      if (os == HostOs.macos) {
        final r = await Process.run('/usr/bin/open', [exe]);
        return r.exitCode == 0;
      }
      await Process.start(exe, const [], mode: ProcessStartMode.detached);
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return false;
    }
    try {
      final r = await Process.run(
        os == HostOs.macos ? '/usr/bin/open' : 'xdg-open',
        [uri.toString()],
      );
      return r.exitCode == 0;
    } on Object {
      return false;
    }
  }
}

/// Test driver for CI (`LF_SETUP_AUTOPILOT=<folder>`): walks through every
/// step with the defaults, saves a picture of each step as rendered by the
/// real app on this OS, runs the real engine and exits with its result code.
/// Only active when the variable is set; it cannot do anything a user
/// clicking through the default path could not.
class SetupAutopilot {
  SetupAutopilot({
    required this.controller,
    required this.boundary,
    required this.outDir,
    required this.prefix,
  });

  final SetupController controller;
  final GlobalKey boundary;
  final Directory outDir;
  final String prefix;
  int _shot = 0;

  static String? folderFromEnvironment() {
    final value = Platform.environment['LF_SETUP_AUTOPILOT'];
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> run() async {
    outDir.createSync(recursive: true);
    await _settle();
    final c = controller;
    var guard = 0;
    while (guard++ < 40) {
      await _capture(c.step.name);
      switch (c.step) {
        case SetupStep.welcome:
          await c.next();
        case SetupStep.license:
          c.setLicenseAccepted(true);
          await _settle();
          await _capture('license-accepted');
          await c.next();
        case SetupStep.options:
          final scope = Platform.environment['LF_SETUP_AUTOPILOT_SCOPE'];
          if (scope == 'user' || scope == 'machine') {
            c.setScope(Scope.parse(scope));
            await _settle();
          }
          await c.next();
        case SetupStep.confirm:
          c.setDeleteUserData(
            Platform.environment['LF_SETUP_AUTOPILOT_DELETE_DATA'] == '1',
          );
          await c.next();
        case SetupStep.progress:
          if (c.runningApps != null) {
            await c.answerRunningApps(close: true);
          }
          await _waitWhile(() => c.step == SetupStep.progress);
          continue;
        case SetupStep.done:
          c.setLaunchAfter(false);
          await _settle();
          await _capture('done-final');
          await c.finish();
          return;
      }
      await _settle();
    }
  }

  Future<void> _waitWhile(bool Function() condition) async {
    final until = DateTime.now().add(const Duration(minutes: 10));
    while (condition() && DateTime.now().isBefore(until)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await _settle();
  }

  Future<void> _settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await SchedulerBinding.instance.endOfFrame;
  }

  Future<void> _capture(String name) async {
    final object = boundary.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return;
    final view = ui.PlatformDispatcher.instance.implicitView;
    final image = await object.toImage(pixelRatio: view?.devicePixelRatio ?? 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return;
    _shot++;
    final index = _shot.toString().padLeft(2, '0');
    await File('${outDir.path}/$prefix-$index-$name.png')
        .writeAsBytes(bytes.buffer.asUint8List());
  }
}
