import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/tray.dart';
import 'package:linefm_radio/platform/desktop/window.dart';

class _FakeWindow implements DesktopWindow {
  final List<String> calls = <String>[];

  @override
  set trayAvailable(bool value) => calls.add('tray:$value');

  @override
  Future<void> show() async => calls.add('show');

  @override
  Future<void> hide() async => calls.add('hide');

  @override
  Future<void> setAlwaysOnTop({required bool value}) async =>
      calls.add('top:$value');

  @override
  Future<void> enterMini({required bool alwaysOnTop}) async =>
      calls.add('enterMini:$alwaysOnTop');

  @override
  Future<void> exitMini({required bool alwaysOnTop}) async =>
      calls.add('exitMini:$alwaysOnTop');

  @override
  Future<void> setCloseToTray({required bool value}) async =>
      calls.add('close:$value');

  @override
  Future<void> quit() async => calls.add('quit');
}

class _FakeTray implements TrayController {
  int refreshes = 0;
  bool disposed = false;

  @override
  Future<void> init() async {}

  @override
  bool get isAvailable => true;

  @override
  Future<void> setTooltip(String text) async {}

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeActions implements DesktopActions {
  final List<String> calls = <String>[];

  @override
  bool get isPlaying => false;

  @override
  Station get activeStation => stationsCatalog.first;

  @override
  Track? get currentTrack => null;

  @override
  double get volume => 0.5;

  @override
  Future<void> togglePlayback() async => calls.add('toggle');

  @override
  Future<void> startStation(Station station) async =>
      calls.add('start:${station.slug}');

  @override
  Future<void> stepStation(int delta) async => calls.add('step:$delta');

  @override
  Future<void> changeVolume(double delta) async => calls.add('vol:$delta');
}

void main() {
  late DesktopController desktop;
  late _FakeWindow window;
  late _FakeTray tray;

  setUp(() {
    desktop = DesktopController.instance
      ..miniMode.value = false
      ..alwaysOnTop.value = false;
    window = _FakeWindow();
    tray = _FakeTray();
    desktop
      ..window = window
      ..tray = tray
      ..restoreMiniOnTop(value: true);
  });

  test(
    'Mini-Fenster schaltet Vordergrund an und stellt ihn danach zurueck',
    () async {
      await desktop.enterMini();
      expect(desktop.miniMode.value, isTrue);
      expect(desktop.alwaysOnTop.value, isTrue);
      expect(window.calls, <String>['enterMini:true']);

      await desktop.exitMini();
      expect(desktop.miniMode.value, isFalse);
      expect(desktop.alwaysOnTop.value, isFalse);
      expect(window.calls.last, 'exitMini:false');
      expect(tray.refreshes, greaterThanOrEqualTo(2));
    },
  );

  test(
    'Vordergrund im Mini-Fenster wird fuer das naechste Mal gemerkt',
    () async {
      await desktop.enterMini();
      await desktop.setAlwaysOnTop(value: false);
      await desktop.exitMini();
      await desktop.enterMini();
      expect(window.calls.last, 'enterMini:false');
      await desktop.exitMini();
    },
  );

  test('Mini-Fenster doppelt betreten wirkt nur einmal', () async {
    await desktop.enterMini();
    await desktop.enterMini();
    expect(window.calls.where((c) => c.startsWith('enterMini')), hasLength(1));
    await desktop.exitMini();
    await desktop.exitMini();
    expect(window.calls.where((c) => c.startsWith('exitMini')), hasLength(1));
  });

  test('Aktionen gehen an die gebundenen App-Aktionen', () async {
    final actions = _FakeActions();
    desktop.bindActions(actions);
    await desktop.togglePlayback();
    await desktop.stepStation(1);
    await desktop.changeVolume(-0.1);
    await desktop.startStation(stationsCatalog.last);
    expect(actions.calls, <String>[
      'toggle',
      'step:1',
      'vol:-0.1',
      'start:${stationsCatalog.last.slug}',
    ]);
    desktop.bindActions(null);
    await desktop.togglePlayback();
    expect(actions.calls, hasLength(4));
  });

  test('Beenden baut Tray ab und zerstoert das Fenster', () async {
    await desktop.quit();
    expect(tray.disposed, isTrue);
    expect(window.calls, contains('quit'));
  });

  test('Zweiter Programmstart reicht die Argumente weiter', () async {
    final received = desktop.secondInstanceArgs.first;
    desktop.notifySecondInstance(<String>['linefm://play?station=rap']);
    expect(await received, <String>['linefm://play?station=rap']);
  });
}
