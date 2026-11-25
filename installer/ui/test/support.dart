import 'dart:async';

import 'package:linefm_setup/src/context.dart';
import 'package:linefm_setup/src/engine.dart';

/// Attrappe für den Windows-Runner.
class FakePlatform implements SetupPlatform {
  final StreamController<EngineEvent> eventsCtrl =
      StreamController<EngineEvent>.broadcast(sync: true);
  final StreamController<int> exitsCtrl = StreamController<int>.broadcast(
    sync: true,
  );
  final StreamController<void> closeCtrl = StreamController<void>.broadcast(
    sync: true,
  );

  StartResult startResult = StartResult.ok;
  final List<({String exe, List<String> args, bool elevate})> starts = [];
  final List<String> sent = [];
  final List<String> launched = [];
  String? folder;

  void emit(String line) {
    final event = EngineEvent.parse(line);
    if (event != null) eventsCtrl.add(event);
  }

  @override
  Stream<EngineEvent> get events => eventsCtrl.stream;

  @override
  Stream<int> get exits => exitsCtrl.stream;

  @override
  Stream<void> get closeRequests => closeCtrl.stream;

  @override
  Future<StartResult> start({
    required String exe,
    required List<String> args,
    required bool elevate,
  }) async {
    starts.add((exe: exe, args: args, elevate: elevate));
    return startResult;
  }

  @override
  Future<bool> send(String line) async {
    sent.add(line);
    return true;
  }

  @override
  Future<String?> pickFolder({
    required String initial,
    required String title,
  }) async => folder;

  @override
  Future<bool> launch(String exe) async {
    launched.add(exe);
    return true;
  }

  @override
  Future<bool> openUrl(String url) async => true;

  final List<String> windowActions = [];

  @override
  Future<void> windowAction(String action) async => windowActions.add(action);
}

const String installJson = '''
{"mode":"install","engine":"C:\\\\Users\\\\a\\\\Downloads\\\\setup.exe",
 "product":{"name":"LINEFM Radio","version":"1.2.0","publisher":"LineFM Studios","manufacturer":"Tim Hauke",
  "exe":"linefm_radio.exe","url":"https://app.linefm.de"},
 "installed":{"user":null,"machine":null},
 "defaults":{"scope":"user",
  "userDir":"C:\\\\Users\\\\a\\\\AppData\\\\Local\\\\Programs\\\\LINEFM Radio",
  "machineDir":"C:\\\\Program Files\\\\LINEFM Radio",
  "desktop":true,"startMenu":true,"autostart":false},
 "elevated":false,"sizeBytes":73400320,"target":""}
''';

/// Paths of the test contexts per OS (Windows keeps the original values).
({String engine, String exe, String userDir, String machineDir, String dirName})
pathsFor(HostOs os) => switch (os) {
  HostOs.windows => (
    engine: r'C:\Users\a\Downloads\setup.exe',
    exe: 'linefm_radio.exe',
    userDir: r'C:\Users\a\AppData\Local\Programs\LINEFM Radio',
    machineDir: r'C:\Program Files\LINEFM Radio',
    dirName: '',
  ),
  HostOs.macos => (
    engine: '/Volumes/LINEFM Radio/LINEFM Radio Setup.app/Contents/Resources/setup/engine.sh',
    exe: '',
    userDir: '/Users/a/Applications/LINEFM Radio.app',
    machineDir: '/Applications/LINEFM Radio.app',
    dirName: 'LINEFM Radio.app',
  ),
  HostOs.linux => (
    engine: '/tmp/.mount_linefm/usr/lib/linefm-setup/setup/engine.sh',
    exe: 'linefm_radio',
    userDir: '/home/a/.local/share/linefm-radio',
    machineDir: '/opt/linefm-radio',
    dirName: 'linefm-radio',
  ),
};

SetupContext installContext({
  Installed? user,
  Installed? machine,
  bool elevated = false,
  HostOs os = HostOs.windows,
}) {
  final base = SetupContext.parse(installJson);
  final paths = pathsFor(os);
  return SetupContext(
    mode: SetupMode.install,
    os: os,
    dirName: paths.dirName,
    engine: os == HostOs.windows ? base.engine : paths.engine,
    productName: base.productName,
    version: base.version,
    publisher: base.publisher,
    manufacturer: base.manufacturer,
    exeName: paths.exe,
    url: base.url,
    installedUser: user,
    installedMachine: machine,
    defaultScope: base.defaultScope,
    userDir: paths.userDir,
    machineDir: paths.machineDir,
    defaultDesktop: base.defaultDesktop,
    defaultStartMenu: base.defaultStartMenu,
    defaultAutostart: base.defaultAutostart,
    elevated: elevated || os != HostOs.windows,
    sizeBytes: base.sizeBytes,
    target: base.target,
  );
}

SetupContext uninstallContext({HostOs os = HostOs.windows}) {
  final installed = Installed(
    version: '1.2.0',
    scope: Scope.user,
    dir: pathsFor(os).userDir,
    desktop: true,
    startMenu: true,
    autostart: false,
  );
  final base = installContext(user: installed, os: os);
  return SetupContext(
    mode: SetupMode.uninstall,
    os: os,
    dirName: base.dirName,
    engine: os == HostOs.windows
        ? r'C:\Users\a\AppData\Local\Temp\linefm-uninstall-1\uninstall.exe'
        : base.engine,
    productName: base.productName,
    version: base.version,
    publisher: base.publisher,
    manufacturer: base.manufacturer,
    exeName: base.exeName,
    url: base.url,
    installedUser: installed,
    installedMachine: null,
    defaultScope: base.defaultScope,
    userDir: base.userDir,
    machineDir: base.machineDir,
    defaultDesktop: true,
    defaultStartMenu: true,
    defaultAutostart: false,
    elevated: os != HostOs.windows,
    sizeBytes: 0,
    target: installed.dir,
  );
}

const String licenseSample =
    'LINEFM Radio\nCopyright (c) 2026 Tim Hauke.\n\n'
    'Beispieltext der Lizenz für Tests.';
