import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/volume_steps.dart';
import 'package:material_ui/material_ui.dart';

import '../stations/stations_test_host.dart';

void setSize(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget slotHost(Harness h, Widget child) =>
    h.app(Align(alignment: Alignment.bottomCenter, child: child));

class _FakeSleepTimer extends NoopSleepTimerService {
  _FakeSleepTimer();

  SleepTimerState _state = const SleepTimerState();

  @override
  SleepTimerState get state => _state;

  @override
  Future<void> start(SleepTimerMode mode, {Track? currentTrack}) async {
    _state = SleepTimerState(
      mode: mode,
      endsAt: DateTime.now().add(const Duration(minutes: 29, seconds: 30)),
    );
  }
}

void main() {
  testWidgets('Hell-Theme: Grundflaeche aus miniPlayerBg, nicht dunkel', (
    tester,
  ) async {
    setSize(tester, 390);
    final h = Harness(brightness: Brightness.light);
    addTearDown(h.container.dispose);
    await tester.pumpWidget(slotHost(h, const MiniPlayer()));
    await settle(tester);

    final base = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(MiniPlayer),
            matching: find.byType(ColoredBox),
          ),
        )
        .map((b) => b.color);
    expect(base, contains(LinefmColors.light.miniPlayerBg));
  });

  testWidgets('zeigt Titel, Kuenstler; Play startet, Stop stoppt, Ereignisse', (
    tester,
  ) async {
    setSize(tester, 390);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(slotHost(h, const MiniPlayer()));
    await settle(tester);

    expect(find.text("I Was Lovin' You"), findsWidgets);
    expect(find.text('James Hype'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Stream starten'));
    await settle(tester);
    expect(h.playback.state.status, PlayerStatus.playing);

    await tester.tap(find.bySemanticsLabel('Stream stoppen'));
    await settle(tester);
    expect(h.playback.state.status, PlayerStatus.idle);
    expect(h.sink.events.first, 'play {station: linefm}');
    expect(h.sink.events.last, 'stop {station: linefm, seconds_bucket: <10}');
  });

  testWidgets('Antippen oeffnet den Player', (tester) async {
    setSize(tester, 390);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(slotHost(h, const MiniPlayer()));
    await settle(tester);

    await tester.tap(find.text("I Was Lovin' You").first);
    await settle(tester);
    expect(h.container.read(navigationProvider), AppScreen.player);
  });

  testWidgets('Lautstaerke-Popover: oeffnen, Stufe waehlen, Esc schliesst', (
    tester,
  ) async {
    setSize(tester, 390);
    final handle = tester.ensureSemantics();
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(slotHost(h, const MiniPlayer()));
    await settle(tester);

    expect(find.bySemanticsLabel('Lautstärke'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Lautstärke öffnen'));
    await settle(tester);
    expect(find.bySemanticsLabel('Lautstärke schließen'), findsWidgets);

    final slider = find.bySemanticsLabel('Lautstärke');
    expect(slider, findsOneWidget);
    expect(tester.getSemantics(slider).value, 'Lautstärke 100 Prozent');

    // Unterste Stufe antippen: 10 %.
    final rect = tester.getRect(find.byType(VolumeSteps));
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 4));
    await settle(tester);
    expect(h.playback.state.volume, closeTo(0.1, 1e-9));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Lautstärke')).value,
      'Lautstärke 10 Prozent',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.bySemanticsLabel('Lautstärke'), findsNothing);
    handle.dispose();
  });

  testWidgets('Sleeptimer-Restzeit im Mini-Player', (tester) async {
    setSize(tester, 390);
    final service = _FakeSleepTimer();
    final h = Harness(
      extra: <Override>[sleepTimerServiceProvider.overrideWithValue(service)],
    );
    addTearDown(h.container.dispose);
    await tester.pumpWidget(slotHost(h, const MiniPlayer()));
    await settle(tester);
    expect(find.textContaining('Noch'), findsNothing);
    await h.container
        .read(sleepTimerProvider.notifier)
        .start(const SleepTimerMinutes(30));
    await settle(tester);
    expect(find.text('Noch 30 Min.'), findsOneWidget);
  });

  testWidgets('Slot: sichtbar ausser im Player-Screen und im breiten Layout', (
    tester,
  ) async {
    setSize(tester, 390);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(slotHost(h, const MiniPlayerSlot()));
    await settle(tester);
    expect(find.byType(MiniPlayer), findsOneWidget);

    h.container.read(navigationProvider.notifier).go(AppScreen.player);
    await settle(tester);
    expect(find.byType(MiniPlayer), findsNothing);

    setSize(tester, 1000);
    h.container.read(navigationProvider.notifier).go(AppScreen.stations);
    await settle(tester);
    expect(find.byType(MiniPlayer), findsNothing);
  });
}
