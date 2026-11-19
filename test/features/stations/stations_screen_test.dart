import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/stations/station_actions.dart';
import 'package:linefm_radio/features/stations/stations_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'stations_test_host.dart';

void setSize(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('zeigt Ueberschrift, 6 Karten und Ticker', (tester) async {
    setSize(tester, 390);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    expect(find.text('ALLE STATIONEN'), findsOneWidget);
    for (final s in stationsCatalog) {
      expect(find.text(s.displayName.toUpperCase()), findsOneWidget);
    }
    expect(find.text("James Hype - I Was Lovin' You"), findsWidgets);
  });

  testWidgets('Karte hat Screenreader-Label mit laufendem Titel', (
    tester,
  ) async {
    setSize(tester, 390);
    final handle = tester.ensureSemantics();
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    expect(
      find.bySemanticsLabel(
        "LineFM +MAIN, läuft: James Hype - I Was Lovin' You",
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Radio3FM'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Tippen: Sender waehlen, Player oeffnen, abspielen, Ereignis', (
    tester,
  ) async {
    setSize(tester, 390);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    await tester.tap(find.text('LINEFM +RAP'));
    await settle(tester);

    expect(h.container.read(activeStationProvider).slug, 'linefmrap');
    expect(h.container.read(navigationProvider), AppScreen.player);
    expect(h.playback.state.status, PlayerStatus.playing);
    expect(h.sink.events, contains('play {station: linefmrap}'));
  });

  testWidgets('gleicher Sender, der spielt: nur Player oeffnen', (
    tester,
  ) async {
    setSize(tester, 390);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    await tester.tap(find.text('LINEFM +MAIN'));
    await settle(tester);
    h.container.read(navigationProvider.notifier).go(AppScreen.stations);
    h.sink.events.clear();
    await tester.tap(find.text('LINEFM +MAIN'));
    await settle(tester);

    expect(h.container.read(navigationProvider), AppScreen.player);
    expect(h.sink.events, isEmpty);
  });

  testWidgets('breit: kein Navigationswechsel, Raster mit 2 Spalten', (
    tester,
  ) async {
    setSize(tester, 1000);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    final a = tester.getTopLeft(find.text('LINEFM +MAIN'));
    final b = tester.getTopLeft(find.text('LINEFM +RAP'));
    expect(b.dy, a.dy, reason: 'zweite Karte steht neben der ersten');

    await tester.tap(find.text('LINEFM +RAP'));
    await settle(tester);
    expect(h.container.read(navigationProvider), AppScreen.stations);
    expect(h.playback.state.status, PlayerStatus.playing);
  });

  testWidgets('Long-Press: Sender teilen mit Link', (tester) async {
    setSize(tester, 390);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    await tester.longPress(find.text('FOBFM'));
    await settle(tester);
    await tester.tap(find.text('Sender teilen'));
    await settle(tester);

    expect(h.shared, hasLength(1));
    expect(h.shared.single, contains('FobFM'));
    expect(h.shared.single, contains('https://app.linefm.de/?station=fobfm'));
  });

  test('stationShareUrl entfernt doppelten Schraegstrich', () {
    expect(
      stationShareUrl('https://app.linefm.de/', stationsCatalog.first),
      'https://app.linefm.de/?station=linefm',
    );
  });
}
