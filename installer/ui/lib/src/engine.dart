import 'dart:async';

import 'package:flutter/services.dart';

/// Exit-Codes der Engine (installer/windows/engine/src/common/base.h).
abstract final class ExitCode {
  static const int ok = 0;
  static const int badArgs = 1;
  static const int cancelled = 2;
  static const int failed = 3;
  static const int corrupt = 4;
  static const int appRunning = 5;
  static const int downgrade = 6;
  static const int elevation = 7;
  static const int badTarget = 8;
  static const int rollbackIncomplete = 9;
  static const int notInstalled = 10;
  static const int diskFull = 11;
  static const int otherScope = 12;
}

/// Meldung der Engine, eine Zeile des Pipe-Protokolls.
sealed class EngineEvent {
  const EngineEvent();

  /// Zerlegt eine Protokollzeile. Unbekannte Zeilen ergeben `null`.
  static EngineEvent? parse(String line) {
    final space = line.indexOf(' ');
    final tab = line.indexOf('\t');
    final cut = space < 0
        ? tab
        : tab < 0
        ? space
        : (space < tab ? space : tab);
    final verb = cut < 0 ? line : line.substring(0, cut);
    final rest = cut < 0 ? '' : line.substring(cut + 1);
    switch (verb) {
      case 'hello':
        return const HelloEvent();
      case 'phase':
        return PhaseEvent(rest.trim());
      case 'progress':
        final parts = rest.trim().split(' ');
        if (parts.length != 2) return null;
        final done = int.tryParse(parts[0]);
        final total = int.tryParse(parts[1]);
        if (done == null || total == null || done < 0 || total < 0) {
          return null;
        }
        return ProgressEvent(done, total);
      case 'running':
        return RunningEvent(
          rest.split('\t').where((n) => n.trim().isNotEmpty).toList(),
        );
      case 'log':
        return LogEvent(rest);
      case 'result':
        final sep = rest.indexOf(' ');
        final code = int.tryParse(sep < 0 ? rest : rest.substring(0, sep));
        if (code == null) return null;
        return ResultEvent(code, sep < 0 ? '' : rest.substring(sep + 1));
    }
    return null;
  }
}

class HelloEvent extends EngineEvent {
  const HelloEvent();
}

class PhaseEvent extends EngineEvent {
  const PhaseEvent(this.name);
  final String name;
}

class ProgressEvent extends EngineEvent {
  const ProgressEvent(this.done, this.total);
  final int done;
  final int total;
}

/// Laufende App gefunden; die Engine wartet auf `close` oder `keep`.
class RunningEvent extends EngineEvent {
  const RunningEvent(this.apps);
  final List<String> apps;
}

class LogEvent extends EngineEvent {
  const LogEvent(this.text);
  final String text;
}

class ResultEvent extends EngineEvent {
  const ResultEvent(this.code, this.message);
  final int code;
  final String message;
}

/// Ergebnis eines Startversuchs.
enum StartResult { ok, cancelledByUser, failed }

/// Schnittstelle zum Windows-Runner. In Tests durch eine Attrappe ersetzt.
abstract class SetupPlatform {
  /// Zeilen der Engine.
  Stream<EngineEvent> get events;

  /// Exit-Code, sobald der Engine-Prozess endet.
  Stream<int> get exits;

  /// Schliessen-Knopf des Fensters.
  Stream<void> get closeRequests;

  Future<StartResult> start({
    required String exe,
    required List<String> args,
    required bool elevate,
  });

  Future<bool> send(String line);

  Future<String?> pickFolder({required String initial, required String title});

  Future<bool> launch(String exe);

  Future<bool> openUrl(String url);
}

/// Echte Verbindung über den MethodChannel `linefm_setup/native`
/// (windows/runner/engine_bridge.cpp).
class NativeSetupPlatform implements SetupPlatform {
  NativeSetupPlatform() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const MethodChannel _channel = MethodChannel('linefm_setup/native');

  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();
  final StreamController<int> _exits = StreamController<int>.broadcast();
  final StreamController<void> _close = StreamController<void>.broadcast();

  Future<Object?> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'line':
        final event = EngineEvent.parse(call.arguments as String? ?? '');
        if (event != null) _events.add(event);
      case 'engineExit':
        _exits.add((call.arguments as int?) ?? ExitCode.failed);
      case 'closeRequested':
        _close.add(null);
    }
    return null;
  }

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
    try {
      await _channel.invokeMethod<bool>('start', <String, Object>{
        'exe': exe,
        'args': args,
        'elevate': elevate,
      });
      return StartResult.ok;
    } on PlatformException catch (e) {
      return e.code == 'cancelled'
          ? StartResult.cancelledByUser
          : StartResult.failed;
    }
  }

  @override
  Future<bool> send(String line) async =>
      await _channel.invokeMethod<bool>('send', line) ?? false;

  @override
  Future<String?> pickFolder({
    required String initial,
    required String title,
  }) => _channel.invokeMethod<String>('pickFolder', <String, Object>{
    'initial': initial,
    'title': title,
  });

  @override
  Future<bool> launch(String exe) async =>
      await _channel.invokeMethod<bool>('launch', exe) ?? false;

  @override
  Future<bool> openUrl(String url) async =>
      await _channel.invokeMethod<bool>('openUrl', url) ?? false;
}
