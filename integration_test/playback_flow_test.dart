// Integration test of the basic playback flow through the whole app (real
// widgets, navigation, controller and providers) with a fake audio backend
// and no network: pick a station, see it playing in the player with the
// current track, stop, start again.
//
// Runs headless on any CI runner, no device needed:
//   flutter test integration_test/playback_flow_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/features/player/player_screen.dart';
import 'package:linefm_radio/ui/widgets/play_button.dart';

import '../test/app/app_host.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Fixed station list, independent of the operator's config/stations.yaml
  // (same as test/flutter_test_config.dart for the unit tests).
  setUpAll(() {
    installBundledStations(
      parseStationsConfig(
        File('test/fixtures/stations/stations_6.json').readAsStringSync(),
      ),
    );
  });

  testWidgets('play, now playing, stop, play again', (tester) async {
    final semantics = tester.ensureSemantics();
    useSize(tester, 390, 844);
    final host = AppHost(settings: const AppSettings(autoplay: false));
    await pumpApp(tester, host);

    // Nothing plays before a station is chosen.
    expect(host.playback.state.status, PlayerStatus.idle);

    // Choosing a station opens the player and starts the stream.
    await tester.tap(find.text('LINEFM +RAP'));
    await settleApp(tester);
    expect(host.container.read(navigationProvider), AppScreen.player);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(host.active.slug, 'linefmrap');
    expect(host.playback.state.status, PlayerStatus.playing);
    expect(host.playback.state.station, host.active);

    // Now playing shows the track from the fake API; the control offers stop.
    expect(find.text('ERFOLG IST KEIN GLÜCK'), findsWidgets);
    expect(find.bySemanticsLabel('Stream stoppen'), findsOneWidget);

    // Stop.
    await tester.tap(find.byType(PlayButton));
    await settleApp(tester);
    expect(host.playback.state.status, PlayerStatus.idle);
    expect(find.bySemanticsLabel('Stream starten'), findsOneWidget);
    expect(find.bySemanticsLabel('Stream stoppen'), findsNothing);

    // Start again on the same station.
    await tester.tap(find.byType(PlayButton));
    await settleApp(tester);
    expect(host.playback.state.status, PlayerStatus.playing);
    expect(host.playback.state.station, host.active);
    expect(find.bySemanticsLabel('Stream stoppen'), findsOneWidget);

    // Leaving the player keeps the stream running in the mini player.
    host.container.read(navigationProvider.notifier).go(AppScreen.stations);
    await settleApp(tester);
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(host.playback.state.status, PlayerStatus.playing);

    expect(tester.takeException(), isNull);
    semantics.dispose();
    await disposeApp(tester, host);
  });
}
