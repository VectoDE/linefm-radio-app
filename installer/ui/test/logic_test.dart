import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_setup/src/context.dart';
import 'package:linefm_setup/src/controller.dart';
import 'package:linefm_setup/src/engine.dart';
import 'package:linefm_setup/src/strings.dart';

import 'support.dart';

void main() {
  group('SetupContext', () {
    test('liest context.json des Stubs', () {
      final c = SetupContext.parse(installJson);
      expect(c.mode, SetupMode.install);
      expect(c.productName, 'LINEFM Radio');
      expect(c.version, '1.2.0');
      expect(c.publisher, 'LineFM Studios');
      expect(c.manufacturer, 'Tim Hauke');
      expect(c.defaultScope, Scope.user);
      expect(c.machineDir, r'C:\Program Files\LINEFM Radio');
      expect(c.installed, isNull);
      expect(c.sizeBytes, 73400320);
    });

    test('lehnt Nicht-Objekte ab', () {
      expect(() => SetupContext.parse('[]'), throwsFormatException);
    });
  });

  group('compareVersions wie die Engine', () {
    test('SemVer-Vorrang', () {
      expect(compareVersions('1.2.3', '1.2.4'), -1);
      expect(compareVersions('1.10.0', '1.9.9'), 1);
      expect(compareVersions('1.2.3-rc.1', '1.2.3'), -1);
      expect(compareVersions('1.2.3', '1.2.3'), 0);
      expect(compareVersions('1.2.3-rc.2', '1.2.3-rc.10'), -1);
      expect(compareVersions('1.2.3-dev.5', '1.2.3-rc.1'), -1);
    });
  });

  group('EngineEvent.parse', () {
    test('alle Zeilenarten', () {
      expect(EngineEvent.parse('hello 1234'), isA<HelloEvent>());
      expect(
        (EngineEvent.parse('phase copying')! as PhaseEvent).name,
        'copying',
      );
      final p = EngineEvent.parse('progress 50 200')! as ProgressEvent;
      expect((p.done, p.total), (50, 200));
      final r =
          EngineEvent.parse('running\tLINEFM Radio\tHelfer')! as RunningEvent;
      expect(r.apps, ['LINEFM Radio', 'Helfer']);
      final res =
          EngineEvent.parse(r'result 0 C:\Programme\LINEFM Radio')!
              as ResultEvent;
      expect(res.code, 0);
      expect(res.message, r'C:\Programme\LINEFM Radio');
      expect((EngineEvent.parse('log Ziel: X')! as LogEvent).text, 'Ziel: X');
    });

    test('Müll ergibt null', () {
      expect(EngineEvent.parse('progress a b'), isNull);
      expect(EngineEvent.parse('progress -1 3'), isNull);
      expect(EngineEvent.parse('result x'), isNull);
      expect(EngineEvent.parse('unbekannt'), isNull);
      expect(EngineEvent.parse(''), isNull);
    });
  });

  group('SetupController Installation', () {
    late FakePlatform platform;
    late List<int> exits;

    SetupController make({
      Installed? user,
      Installed? machine,
      bool elevated = false,
    }) {
      platform = FakePlatform();
      exits = [];
      return SetupController(
        context: installContext(
          user: user,
          machine: machine,
          elevated: elevated,
        ),
        platform: platform,
        exit: exits.add,
        licenseText: licenseSample,
      );
    }

    test('Ablauf pro Benutzer ohne UAC', () async {
      final c = make();
      expect(c.step, SetupStep.welcome);
      expect(c.scope, Scope.user);
      await c.next();
      expect(c.step, SetupStep.license);
      expect(c.canGoNext, isFalse, reason: 'Lizenz noch nicht akzeptiert');
      c.setLicenseAccepted(true);
      await c.next();
      expect(c.step, SetupStep.options);
      await c.next();
      expect(c.step, SetupStep.progress);
      final start = platform.starts.single;
      expect(start.elevate, isFalse);
      expect(start.args, [
        'install',
        '--scope',
        'user',
        '--dir',
        r'C:\Users\a\AppData\Local\Programs\LINEFM Radio',
        '--desktop',
        '1',
        '--startmenu',
        '1',
        '--autostart',
        '0',
      ]);
      platform.emit('hello 1');
      platform.emit('phase copying');
      platform.emit('progress 25 100');
      expect(c.progress, 0.25);
      platform.emit(r'result 0 C:\Users\a\AppData\Local\Programs\LINEFM Radio');
      platform.exitsCtrl.add(0);
      expect(c.step, SetupStep.done);
      expect(c.succeeded, isTrue);
      await c.finish();
      expect(platform.launched, [
        r'C:\Users\a\AppData\Local\Programs\LINEFM Radio\linefm_radio.exe',
      ]);
      expect(exits, [0]);
    });

    test('alle Benutzer: UAC nur dann, Ordner wechselt mit', () async {
      final c = make();
      c.setScope(Scope.machine);
      expect(c.dir, r'C:\Program Files\LINEFM Radio');
      expect(c.needsElevation, isTrue);
      c.setScope(Scope.user);
      expect(c.needsElevation, isFalse);
    });

    test('bereits erhoeht: keine UAC-Abfrage', () {
      final c = make(elevated: true);
      c.setScope(Scope.machine);
      expect(c.needsElevation, isFalse);
    });

    test('abgelehnte UAC fuehrt zurueck zu den Optionen', () async {
      final c = make();
      c.goTo(SetupStep.options);
      c.setScope(Scope.machine);
      platform.startResult = StartResult.cancelledByUser;
      await c.next();
      expect(platform.starts.single.elevate, isTrue);
      expect(c.step, SetupStep.options);
      expect(c.optionsError, 'elevation');
    });

    test('eigener Ordner bleibt beim Bereichswechsel', () {
      final c = make();
      c.setDir(r'D:\Apps\LINEFM Radio');
      c.setScope(Scope.machine);
      expect(c.dir, r'D:\Apps\LINEFM Radio');
    });

    test('ungueltige Ordner sperren Weiter', () {
      final c = make();
      c.goTo(SetupStep.options);
      for (final bad in ['', r'relativ\pfad', r'C:\a\..\b', r'C:\a|b']) {
        c.setDir(bad);
        expect(c.canGoNext, isFalse, reason: bad);
      }
      c.setDir(r'C:\Apps\LINEFM Radio');
      expect(c.canGoNext, isTrue);
    });

    test('Ordnerwahl haengt den Produktordner an', () async {
      final c = make();
      platform.folder = r'D:\Apps';
      await c.browse('x');
      expect(c.dir, r'D:\Apps\LINEFM Radio');
      platform.folder = r'E:\LINEFM Radio';
      await c.browse('x');
      expect(c.dir, r'E:\LINEFM Radio');
    });

    test('Update: Bereich und Ordner fest, Optionen uebernommen', () async {
      const old = Installed(
        version: '1.1.0',
        scope: Scope.machine,
        dir: r'C:\Program Files\LINEFM Radio',
        desktop: false,
        startMenu: true,
        autostart: true,
      );
      final c = make(machine: old);
      expect(c.isUpdate, isTrue);
      expect(c.isDowngrade, isFalse);
      expect(c.scope, Scope.machine);
      expect(c.desktop, isFalse);
      expect(c.autostart, isTrue);
      c.setScope(Scope.user);
      expect(c.scope, Scope.machine, reason: 'gesperrt');
      expect(c.engineArgs(), isNot(contains('--dir')));
      expect(c.engineArgs().sublist(0, 3), ['install', '--scope', 'machine']);
    });

    test('Downgrade wird blockiert', () {
      const newer = Installed(
        version: '2.0.0',
        scope: Scope.user,
        dir: r'C:\x\LINEFM Radio',
        desktop: true,
        startMenu: true,
        autostart: false,
      );
      final c = make(user: newer);
      expect(c.isDowngrade, isTrue);
      expect(c.canGoNext, isFalse);
    });

    test('laufende App: Antwort geht an die Engine', () async {
      final c = make();
      c.goTo(SetupStep.options);
      await c.next();
      platform.emit('running\tLINEFM Radio');
      expect(c.runningApps, ['LINEFM Radio']);
      await c.answerRunningApps(close: true);
      expect(platform.sent, ['close']);
      expect(c.runningApps, isNull);
    });

    test('Abbruch waehrend der Installation', () async {
      final c = make();
      c.goTo(SetupStep.options);
      await c.next();
      await c.cancelRunning();
      await c.cancelRunning();
      expect(platform.sent, ['cancel'], reason: 'nur einmal');
      platform.emit('phase rollback');
      platform.emit('result 2 Abgebrochen');
      platform.exitsCtrl.add(2);
      expect(c.step, SetupStep.done);
      expect(c.resultCode, ExitCode.cancelled);
      await c.finish();
      expect(platform.launched, isEmpty);
      expect(exits, [2]);
    });

    test('Fehlercode der Engine ohne result-Zeile', () {
      final c = make();
      c.running = true;
      platform.exitsCtrl.add(ExitCode.diskFull);
      expect(c.resultCode, ExitCode.diskFull);
      expect(c.succeeded, isFalse);
    });

    test('Schliessen ohne laufende Engine beendet mit 2', () {
      final c = make();
      c.quit();
      expect(exits, [2]);
    });
  });

  group('SetupController Deinstallation', () {
    test('Argumente mit und ohne Nutzerdaten', () async {
      final platform = FakePlatform();
      final exits = <int>[];
      final c = SetupController(
        context: uninstallContext(),
        platform: platform,
        exit: exits.add,
      );
      expect(c.step, SetupStep.confirm);
      expect(c.engineArgs(), [
        'uninstall',
        '--target',
        r'C:\Users\a\AppData\Local\Programs\LINEFM Radio',
      ]);
      c.setDeleteUserData(true);
      expect(c.engineArgs().last, '--delete-user-data');
      await c.next();
      expect(platform.starts.single.elevate, isFalse);
      platform.emit('result 0 ');
      platform.exitsCtrl.add(0);
      await c.finish();
      expect(
        platform.launched,
        isEmpty,
        reason: 'nach Deinstallation nie starten',
      );
      expect(exits, [0]);
    });
  });

  group('Texte', () {
    test('Deutsch und Englisch fuer jeden Exit-Code', () {
      for (final s in [S.german, S.english]) {
        for (var code = 0; code <= 12; code++) {
          expect(s.error(code), isNotEmpty);
        }
        for (final phase in [
          'prepare',
          'closing',
          'copying',
          'registry',
          'finalizing',
          'rollback',
          'removing',
          'x',
        ]) {
          expect(s.phase(phase), isNotEmpty);
        }
      }
      expect(S.forLocale(const Locale('de', 'AT')), S.german);
      expect(S.forLocale(const Locale('fr')), S.english);
      expect(S.german.formatBytes(73400320), '70 MB');
      expect(S.german.formatBytes(1572864), '1,5 MB');
    });
  });
  group('macOS and Linux', () {
    SetupController make(HostOs os, FakePlatform p) => SetupController(
      context: installContext(os: os),
      platform: p,
      exit: (_) {},
    );

    test('context.json carries os and dirName, Windows is the default', () {
      expect(SetupContext.parse(installJson).os, HostOs.windows);
      final json = installJson.replaceFirst(
        '"mode":"install"',
        '"os":"linux","mode":"install"',
      );
      expect(SetupContext.parse(json).os, HostOs.linux);
      expect(HostOs.parse('macos'), HostOs.macos);
      expect(HostOs.parse('beos'), HostOs.windows);
    });

    test('POSIX paths are validated without drive letters', () {
      final c = make(HostOs.linux, FakePlatform());
      expect(c.validateDir('/home/a/.local/share/linefm-radio'), isNull);
      expect(c.validateDir(r'C:\Programs\LINEFM Radio'), 'invalid');
      expect(c.validateDir('relative/path'), 'invalid');
      expect(c.validateDir('/home/a/../b/x'), 'invalid');
      expect(c.validateDir(r'/home/a/$HOME'), 'invalid');
      expect(c.validateDir('/home/a/x"y'), 'invalid');
      expect(c.validateDir('/x'), 'invalid');
      final m = make(HostOs.macos, FakePlatform());
      expect(m.validateDir('/Applications/LINEFM Radio.app'), isNull);
      expect(m.validateDir('/Applications/LINEFM Radio'), 'invalid');
    });

    test('Linux offers no machine scope and needs no elevation', () {
      final c = make(HostOs.linux, FakePlatform());
      c.setScope(Scope.machine);
      expect(c.scope, Scope.user);
      expect(c.needsElevation, isFalse);
      final m = make(HostOs.macos, FakePlatform());
      m.setScope(Scope.machine);
      expect(m.scope, Scope.machine);
      expect(m.dir, '/Applications/LINEFM Radio.app');
      expect(m.needsElevation, isFalse);
    });

    test('browse appends the folder name with slashes', () async {
      final p = FakePlatform()..folder = '/home/a/apps/';
      final c = make(HostOs.linux, p);
      await c.browse('x');
      expect(c.dir, '/home/a/apps/linefm-radio');
      p.folder = '/Users/a/Apps';
      final m = make(HostOs.macos, p);
      await m.browse('x');
      expect(m.dir, '/Users/a/Apps/LINEFM Radio.app');
    });

    test('installed app path per OS', () {
      final p = FakePlatform();
      final c = make(HostOs.linux, p)
        ..dir = '/home/a/.local/share/linefm-radio';
      expect(c.installedExe, '/home/a/.local/share/linefm-radio/linefm_radio');
      final m = make(HostOs.macos, p)..dir = '/Applications/LINEFM Radio.app';
      expect(m.installedExe, '/Applications/LINEFM Radio.app');
    });

    test('texts name the right OS, steps stay the same', () {
      const de = Locale('de');
      const en = Locale('en');
      final win = S.forLocale(en);
      final mac = S.forLocale(en, HostOs.macos);
      final lin = S.forLocale(de, HostOs.linux);
      expect(win.phase('registry'), 'Setting up Windows …');
      expect(mac.phase('registry'), 'Setting up macOS …');
      expect(lin.phase('registry'), 'Desktop wird eingerichtet …');
      expect(mac.startMenuShortcut, 'Keep in the Dock');
      expect(mac.scopeMachine, 'Everyone on this Mac');
      expect(lin.startMenuShortcut, 'Eintrag im App-Menü');
      expect(mac.stepOptions, win.stepOptions);
      expect(S.forLocale(de, HostOs.linux).stepWelcome, S.german.stepWelcome);
      expect(
        make(HostOs.macos, FakePlatform()).steps,
        make(HostOs.windows, FakePlatform()).steps,
      );
    });
  });
}
