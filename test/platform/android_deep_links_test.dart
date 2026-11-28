import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show RouteInformation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/platform/deep_links.dart';

import '../support/in_memory_prefs_store.dart';
import '../support/service_doubles.dart';

class _Playback extends NoopPlaybackService {
  final List<String> plays = <String>[];
  final StreamController<PlayerUiState> _states =
      StreamController<PlayerUiState>.broadcast();
  PlayerUiState _s = const PlayerUiState();

  @override
  PlayerUiState get state => _s;

  @override
  Stream<PlayerUiState> get stateStream => _states.stream;

  @override
  Future<void> playStation(Station station) async {
    plays.add(station.slug);
    _s = _s.copyWith(status: PlayerStatus.playing, station: station);
    _states.add(_s);
  }
}

Future<void> _flush() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.linefm.app/deep_links_test');
  const widgetLink = 'linefm://play?station=linefmrap';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(DeepLinks.resetForTest);
  tearDown(() {
    unbindAndroidDeepLinksForTest();
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> sendOnLink(String link) => messenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(MethodCall('onLink', link)),
    (_) {},
  );

  test(
    'Widget-Link beim Kaltstart fuehrt genau einmal zum Abspielen',
    () async {
      var initialCalls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInitialLink') {
          initialCalls++;
          return widgetLink;
        }
        return null;
      });

      // Wie main(): Links werden vor runApp gebunden, noch hoert niemand zu.
      await bindAndroidDeepLinks(channel);
      // Derselbe Link kommt kurz danach ein zweites Mal (onNewIntent bzw.
      // Routeninformation) - der Duplikatfilter verwirft ihn.
      await sendOnLink(widgetLink);
      await DeepLinkObserver().didPushRouteInformation(
        RouteInformation(uri: Uri.parse(widgetLink)),
      );
      // Zweites Binden (z. B. Hot Restart) fragt nicht erneut.
      await bindAndroidDeepLinks(channel);
      expect(initialCalls, 1);

      final prefs = InMemoryPrefsStore();
      await prefs.writeSettings(const AppSettings(autoplay: false));
      final playback = _Playback();
      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          playbackServiceProvider.overrideWithValue(playback),
        ],
      );
      addTearDown(container.dispose);
      container.listen(playerControllerProvider, (_, _) {});

      await container.read(playerControllerProvider).startup(web: false);
      await _flush();

      expect(playback.plays, <String>['linefmrap']);
      expect(container.read(activeStationProvider).slug, 'linefmrap');
    },
  );

  test('laufende App: onLink startet den Sender', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    await bindAndroidDeepLinks(channel);

    final received = <Uri>[];
    final sub = DeepLinks.stream.listen(received.add);
    addTearDown(sub.cancel);

    await sendOnLink('https://app.linefm.de/?station=fobfm');
    await sendOnLink('kaputt://x');
    await _flush();
    expect(received, <Uri>[Uri.parse('https://app.linefm.de/?station=fobfm')]);
  });

  test('fehlender Kanal (kein Android) bricht nichts', () async {
    await expectLater(bindAndroidDeepLinks(channel), completes);
  });
}
