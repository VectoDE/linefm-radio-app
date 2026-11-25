import 'dart:async';

import 'package:flutter/foundation.dart';

import 'context.dart';
import 'engine.dart';

/// Schritte der Oberfläche.
enum SetupStep { welcome, license, options, progress, done, confirm }

/// Zustand und Ablauf des Setups. Unabhängig von Widgets, damit die Logik
/// ohne Fenster testbar ist.
class SetupController extends ChangeNotifier {
  SetupController({
    required this.context,
    required this.platform,
    required this.exit,
    this.licenseText,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       step = context.mode == SetupMode.uninstall
           ? SetupStep.confirm
           : SetupStep.welcome {
    final existing = context.installed;
    scope = existing?.scope ?? context.defaultScope;
    dir = existing?.dir.isNotEmpty == true ? existing!.dir : _defaultDir(scope);
    desktop = existing?.desktop ?? context.defaultDesktop;
    startMenu = existing?.startMenu ?? context.defaultStartMenu;
    autostart = existing?.autostart ?? context.defaultAutostart;
    _subs.add(platform.events.listen(_onEvent));
    _subs.add(platform.exits.listen(_onExit));
  }

  final SetupContext context;
  final SetupPlatform platform;

  /// Beendet den Prozess mit Exit-Code (Standard: `dart:io` `exit`).
  final void Function(int code) exit;

  /// Lizenztext (LICENSE.txt neben der Oberfläche), `null` wenn er fehlt.
  final String? licenseText;

  final List<StreamSubscription<Object?>> _subs = [];

  SetupStep step;
  late Scope scope;
  late String dir;
  bool _dirEdited = false;
  late bool desktop;
  late bool startMenu;
  late bool autostart;
  bool licenseAccepted = false;
  bool deleteUserData = false;
  bool launchAfter = true;

  /// Fehlermeldung auf der Optionsseite (z. B. UAC abgelehnt).
  String? optionsError;

  // Fortschritt
  bool running = false;
  bool waitingForElevation = false;
  bool cancelRequested = false;
  String phase = 'prepare';
  int progressDone = 0;
  int progressTotal = 0;

  final DateTime Function() _clock;
  DateTime? _started;
  double _shown = 0;
  DateTime? _sampleAt;
  double _sampleFraction = 0;
  double? _rate;

  /// Time since the engine was started.
  Duration get elapsed =>
      _started == null ? Duration.zero : _clock().difference(_started!);

  /// Estimated time left from the smoothed progress rate; null while the
  /// estimate is not yet reliable (first seconds, first 2 percent).
  Duration? get remaining {
    final rate = _rate;
    final f = progress;
    if (rate == null || rate <= 0 || f == null || f < 0.02) return null;
    if (elapsed < const Duration(seconds: 2)) return null;
    final seconds = (1 - f) / rate;
    if (!seconds.isFinite || seconds > 24 * 3600) return null;
    return Duration(seconds: seconds.ceil());
  }

  final List<String> log = [];

  /// Laufende Programme, zu denen die Engine eine Antwort erwartet.
  List<String>? runningApps;

  // Ergebnis
  int? resultCode;
  String resultMessage = '';

  bool get isUninstall => context.mode == SetupMode.uninstall;
  Installed? get existing => context.installed;
  bool get isUpdate => !isUninstall && existing != null;

  /// Installierte Version ist neuer als die angebotene.
  bool get isDowngrade =>
      isUpdate && compareVersions(context.version, existing!.version) < 0;

  bool get isSameVersion =>
      isUpdate && compareVersions(context.version, existing!.version) == 0;

  /// Bereich und Ordner sind beim Update festgelegt.
  bool get locationLocked => isUpdate;

  List<SetupStep> get steps => isUninstall
      ? const [SetupStep.confirm, SetupStep.progress, SetupStep.done]
      : const [
          SetupStep.welcome,
          SetupStep.license,
          SetupStep.options,
          SetupStep.progress,
          SetupStep.done,
        ];

  int get stepIndex => steps.indexOf(step);

  /// Share of the real work done (bytes copied plus small fixed weights,
  /// reported by the engine). Never goes back, and shows 100 % only once
  /// the engine reported its result.
  double? get progress {
    if (progressTotal <= 0) return resultCode == null ? null : 1;
    if (resultCode != null && resultCode == ExitCode.ok) return 1;
    return _shown >= 1 ? 0.99 : _shown;
  }

  void _sample(int done, int total) {
    if (total <= 0) return;
    final f = (done / total).clamp(0.0, 1.0);
    if (f < _shown) return; // monotonic
    _shown = f;
    final now = _clock();
    final last = _sampleAt;
    if (last == null) {
      _sampleAt = now;
      _sampleFraction = f;
      return;
    }
    final dt = now.difference(last).inMilliseconds / 1000;
    if (dt < 0.5) return;
    final inst = (f - _sampleFraction) / dt;
    // Exponential smoothing keeps the estimate calm.
    _rate = _rate == null ? inst : 0.3 * inst + 0.7 * _rate!;
    _sampleAt = now;
    _sampleFraction = f;
  }

  bool get succeeded => resultCode == ExitCode.ok;

  String _defaultDir(Scope s) =>
      s == Scope.machine ? context.machineDir : context.userDir;

  /// Prüft den Zielordner grob (die Engine prüft streng nach).
  String? validateDir(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'empty';
    if (context.os.isPosix) return _validatePosixDir(v);
    final drive = RegExp(r'^[A-Za-z]:\\');
    if (!drive.hasMatch(v) || v.length > 180 || v.contains('..')) {
      return 'invalid';
    }
    if (RegExp(r'[<>"|?*]').hasMatch(v.substring(2))) return 'invalid';
    return null;
  }

  /// macOS and Linux: absolute path, no `..`, no control characters, no
  /// system folder. macOS installs a bundle, so the path ends in `.app`.
  String? _validatePosixDir(String v) {
    if (!v.startsWith('/') || v.length > 400 || v.contains('/../')) {
      return 'invalid';
    }
    if (v.endsWith('/..') || RegExp(r'[\x00-\x1f\x7f"`$\\]').hasMatch(v)) {
      return 'invalid';
    }
    final parts = v.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return 'invalid';
    if (context.os == HostOs.macos && !v.endsWith('.app')) return 'invalid';
    return null;
  }

  bool get canGoNext => switch (step) {
    SetupStep.welcome => !isDowngrade,
    SetupStep.license => licenseAccepted,
    SetupStep.options => validateDir(dir) == null,
    SetupStep.confirm => true,
    SetupStep.progress => false,
    SetupStep.done => true,
  };

  bool get canGoBack => step == SetupStep.license || step == SetupStep.options;

  void setScope(Scope value) {
    if (locationLocked || scope == value) return;
    if (value == Scope.machine && !context.machineScopeAvailable) return;
    scope = value;
    if (!_dirEdited) dir = _defaultDir(value);
    optionsError = null;
    notifyListeners();
  }

  void setDir(String value) {
    if (locationLocked) return;
    dir = value;
    _dirEdited = true;
    notifyListeners();
  }

  void setDesktop(bool value) {
    desktop = value;
    notifyListeners();
  }

  void setStartMenu(bool value) {
    startMenu = value;
    notifyListeners();
  }

  void setAutostart(bool value) {
    autostart = value;
    notifyListeners();
  }

  void setLicenseAccepted(bool value) {
    licenseAccepted = value;
    notifyListeners();
  }

  void setDeleteUserData(bool value) {
    deleteUserData = value;
    notifyListeners();
  }

  void setLaunchAfter(bool value) {
    launchAfter = value;
    notifyListeners();
  }

  /// Springt direkt zu einem Schritt (Tests und Bildschirmfotos).
  @visibleForTesting
  void goTo(SetupStep value) {
    step = value;
    notifyListeners();
  }

  void back() {
    if (!canGoBack) return;
    step = steps[stepIndex - 1];
    notifyListeners();
  }

  Future<void> next() async {
    if (!canGoNext) return;
    switch (step) {
      case SetupStep.welcome:
        step = SetupStep.license;
      case SetupStep.license:
        step = SetupStep.options;
      case SetupStep.options:
      case SetupStep.confirm:
        await _startEngine();
        return;
      case SetupStep.done:
        await finish();
        return;
      case SetupStep.progress:
        return;
    }
    notifyListeners();
  }

  List<String> engineArgs() {
    if (isUninstall) {
      return [
        'uninstall',
        '--target',
        context.target,
        if (deleteUserData) '--delete-user-data',
      ];
    }
    return [
      'install',
      '--scope',
      scope.arg,
      if (!locationLocked) ...['--dir', dir.trim()],
      '--desktop',
      desktop ? '1' : '0',
      '--startmenu',
      startMenu ? '1' : '0',
      '--autostart',
      autostart ? '1' : '0',
    ];
  }

  bool get needsElevation =>
      !isUninstall && scope == Scope.machine && !context.elevated;

  Future<void> _startEngine() async {
    optionsError = null;
    final previous = step;
    step = SetupStep.progress;
    running = true;
    cancelRequested = false;
    phase = 'prepare';
    progressDone = 0;
    progressTotal = 0;
    _started = _clock();
    _shown = 0;
    _sampleAt = null;
    _sampleFraction = 0;
    _rate = null;
    resultCode = null;
    resultMessage = '';
    waitingForElevation = needsElevation;
    notifyListeners();
    final result = await platform.start(
      exe: context.engine,
      args: engineArgs(),
      elevate: needsElevation,
    );
    waitingForElevation = false;
    if (result != StartResult.ok) {
      running = false;
      step = previous;
      optionsError = result == StartResult.cancelledByUser
          ? 'elevation'
          : 'start';
    }
    notifyListeners();
  }

  void _onEvent(EngineEvent event) {
    switch (event) {
      case HelloEvent():
        waitingForElevation = false;
      case PhaseEvent(:final name):
        phase = name;
      case ProgressEvent(:final done, :final total):
        progressDone = done;
        progressTotal = total;
        _sample(done, total);
      case RunningEvent(:final apps):
        runningApps = apps.isEmpty ? const ['LINEFM Radio'] : apps;
      case LogEvent(:final text):
        log.add(text);
        if (log.length > 500) log.removeAt(0);
      case ResultEvent(:final code, :final message):
        resultCode = code;
        resultMessage = message;
    }
    notifyListeners();
  }

  void _onExit(int code) {
    running = false;
    runningApps = null;
    resultCode ??= code;
    step = SetupStep.done;
    notifyListeners();
  }

  /// Antwort auf die Frage nach laufenden Programmen.
  Future<void> answerRunningApps({required bool close}) async {
    runningApps = null;
    notifyListeners();
    await platform.send(close ? 'close' : 'keep');
  }

  /// Abbruch während der Installation: die Engine nimmt alles zurück.
  Future<void> cancelRunning() async {
    if (!running || cancelRequested) return;
    cancelRequested = true;
    notifyListeners();
    await platform.send('cancel');
  }

  /// Schliessen ohne laufende Engine.
  void quit() {
    if (running) return;
    exit(resultCode ?? ExitCode.cancelled);
  }

  /// Fertig-Knopf: ggf. App starten, dann mit Ergebnis beenden.
  Future<bool> finish() async {
    var launched = true;
    if (succeeded && !isUninstall && launchAfter) {
      launched = await platform.launch(installedExe);
    }
    exit(resultCode ?? ExitCode.cancelled);
    return launched;
  }

  /// Pfad der installierten App (Ergebnis der Engine = Installationsordner).
  String get installedExe {
    final base = resultMessage.isNotEmpty && succeeded
        ? resultMessage
        : (existing?.dir ?? dir);
    // macOS: the bundle itself is opened (no executable name).
    if (context.exeName.isEmpty) return base;
    final osSep = context.os.separator;
    final sep = base.endsWith(osSep) ? '' : osSep;
    return '$base$sep${context.exeName}';
  }

  String get installedDir =>
      succeeded && resultMessage.isNotEmpty ? resultMessage : dir;

  Future<void> browse(String title) async {
    final picked = await platform.pickFolder(initial: dir, title: title);
    if (picked == null || picked.isEmpty) return;
    // Wie bei anderen Setups: Produktordner an den gewählten Ordner hängen,
    // sofern er nicht schon so heisst.
    final name = context.folderName;
    final sep = context.os.separator;
    final trimmed = picked.length > 1 && picked.endsWith(sep)
        ? picked.substring(0, picked.length - 1)
        : picked;
    setDir(
      trimmed.toLowerCase().endsWith('$sep${name.toLowerCase()}')
          ? trimmed
          : '$trimmed${trimmed.endsWith(sep) ? '' : sep}$name',
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
