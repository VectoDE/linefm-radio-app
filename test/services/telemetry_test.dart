import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/services/telemetry/sentry_sink.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/telemetry/umami_sink.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class _FakeAnalytics implements AnalyticsSink {
  int inits = 0;
  bool enabled = false;
  final List<String> events = <String>[];

  @override
  Future<void> init() async => inits++;

  @override
  Future<void> setEnabled({required bool enabled}) async =>
      this.enabled = enabled;

  @override
  Future<void> screen(String name) async => events.add('screen:$name');

  @override
  Future<void> event(
    String name, [
    Map<String, Object> props = const {},
  ]) async => events.add(name);
}

class _FakeCrash implements CrashSink {
  int inits = 0;
  bool enabled = false;
  final List<Object> errors = <Object>[];

  @override
  Future<void> init() async => inits++;

  @override
  Future<void> setEnabled({required bool enabled}) async =>
      this.enabled = enabled;

  @override
  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async => errors.add(error);
}

AppConfig _config({
  required bool umami,
  required bool sentry,
  required bool firebase,
}) => AppConfig(
  umamiUrl: umami ? 'https://stats.example.org' : '',
  umamiWebsiteId: umami ? 'site-1' : '',
  sentryDsn: sentry ? 'https://key@errors.example.org/1' : '',
  firebaseEnabled: firebase,
);

void main() {
  group('Konfigurationsschalter (8 Kombinationen x Einwilligung)', () {
    for (var mask = 0; mask < 8; mask++) {
      final umami = mask & 1 != 0;
      final sentry = mask & 2 != 0;
      final firebase = mask & 4 != 0;
      final configured = umami || sentry || firebase;
      final label = 'umami=$umami sentry=$sentry firebase=$firebase';

      test('$label: telemetryConfigured == $configured', () {
        final c = _config(umami: umami, sentry: sentry, firebase: firebase);
        expect(c.telemetryConfigured, configured);
        expect(TelemetryHub.noop(c).consentRequired, configured);
      });

      // Einwilligung: nie gefragt, erteilt, verweigert, widerrufen.
      for (final step in <String>['offen', 'ja', 'nein', 'widerrufen']) {
        test('$label, Einwilligung $step', () async {
          final c = _config(umami: umami, sentry: sentry, firebase: firebase);
          final a = _FakeAnalytics();
          final k = _FakeCrash();
          final hub = TelemetryHub(config: c, analytics: [a], crash: [k]);

          switch (step) {
            case 'ja':
              await hub.setConsent(value: true);
            case 'nein':
              await hub.setConsent(value: false);
            case 'widerrufen':
              await hub.setConsent(value: true);
              await hub.setConsent(value: false);
          }
          await hub.event('play');
          await hub.screen('player');
          await hub.record(StateError('x'), StackTrace.empty);

          final shouldSend = configured && step == 'ja';
          expect(hub.active, shouldSend);
          expect(a.enabled, shouldSend);
          expect(k.enabled, shouldSend);
          if (shouldSend) {
            expect(a.events, <String>['play', 'screen:player']);
            expect(k.errors, hasLength(1));
          } else {
            expect(a.events, isEmpty);
            expect(k.errors, isEmpty);
          }
          // Vor einer Einwilligung wird kein Sink initialisiert.
          if (step == 'offen' || step == 'nein') {
            expect(a.inits, 0);
            expect(k.inits, 0);
          }
        });
      }
    }
  });

  group('initTelemetry', () {
    test('ohne Konfiguration: NoOp-Hub, keine Sinks', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 200);
      });
      final prefs = InMemoryPrefsStore();
      await prefs.writeTelemetryConsent(value: true);
      final hub = await initTelemetry(
        config: const AppConfig(),
        prefs: prefs,
        client: client,
      );
      await hub.event('app_start');
      expect(hub.analytics, isEmpty);
      expect(hub.crash, isEmpty);
      expect(hub.active, isFalse);
      expect(calls, 0);
    });

    test('konfiguriert, aber ohne Einwilligung: kein Netzwerkaufruf', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 200);
      });
      final hub = await initTelemetry(
        config: _config(umami: true, sentry: false, firebase: false),
        prefs: InMemoryPrefsStore(),
        client: client,
      );
      await hub.event('play');
      await (hub.analytics.single as UmamiSink).flush();
      expect(hub.analytics, hasLength(1));
      expect(hub.active, isFalse);
      expect(calls, 0);
    });

    test('gespeicherte Einwilligung aktiviert Umami und app_start', () async {
      final bodies = <Map<String, Object?>>[];
      final client = MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, Object?>);
        return http.Response('', 200);
      });
      final prefs = InMemoryPrefsStore();
      await prefs.writeTelemetryConsent(value: true);
      final hub = await initTelemetry(
        config: _config(umami: true, sentry: false, firebase: false),
        prefs: prefs,
        client: client,
      );
      expect(hub.active, isTrue);
      await (hub.analytics.single as UmamiSink).flush();
      expect(bodies.single['type'], 'event');
      final payload = bodies.single['payload']! as Map<String, Object?>;
      expect(payload['name'], 'app_start');
      await hub.setConsent(value: false);
    });
  });

  group('UmamiSink', () {
    late List<http.Request> requests;
    late UmamiSink sink;

    setUp(() {
      requests = <http.Request>[];
      sink = UmamiSink(
        _config(umami: true, sentry: false, firebase: false),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('', 200);
        }),
        screenSize: () => '390x844',
        language: () => 'de-DE',
        userAgent: 'LINEFM-Radio/1.0.0 (test)',
        flushInterval: const Duration(hours: 1),
      );
    });

    tearDown(() => sink.setEnabled(enabled: false));

    test('sendet nichts, solange nicht aktiviert', () async {
      await sink.screen('player');
      await sink.event('play');
      await sink.flush();
      expect(sink.pending, 0);
      expect(requests, isEmpty);
    });

    test('Payload entspricht Spec 2.3', () async {
      await sink.setEnabled(enabled: true);
      await sink.screen('player');
      await sink.event('play', <String, Object>{'station': 'linefm'});
      await sink.flush();

      expect(requests, hasLength(2));
      expect(
        requests.first.url.toString(),
        'https://stats.example.org/api/send',
      );
      expect(requests.first.headers['Content-Type'], contains('json'));
      final pageview = jsonDecode(requests.first.body) as Map<String, Object?>;
      expect(pageview['type'], 'event');
      final p1 = pageview['payload']! as Map<String, Object?>;
      expect(p1['website'], 'site-1');
      expect(p1['hostname'], 'app.linefm');
      expect(p1['url'], '/screen/player');
      expect(p1['language'], 'de-DE');
      expect(p1['screen'], '390x844');
      expect(p1.containsKey('name'), isFalse);

      final p2 =
          (jsonDecode(requests.last.body) as Map<String, Object?>)['payload']!
              as Map<String, Object?>;
      expect(p2['name'], 'play');
      expect(p2['url'], '/screen/player');
      expect(p2['data'], <String, Object?>{'station': 'linefm'});
      expect(sink.pending, 0);
    });

    test('Warteschlange ist auf 50 begrenzt', () async {
      await sink.setEnabled(enabled: true);
      for (var i = 0; i < 80; i++) {
        await sink.event('e$i');
      }
      expect(sink.pending, 50);
    });

    test('Widerruf leert die Warteschlange', () async {
      await sink.setEnabled(enabled: true);
      await sink.event('play');
      await sink.setEnabled(enabled: false);
      expect(sink.pending, 0);
      await sink.flush();
      expect(requests, isEmpty);
    });

    test('Fehler beim Senden verwirft den Rest und wirft nicht', () async {
      var calls = 0;
      final failing = UmamiSink(
        _config(umami: true, sentry: false, firebase: false),
        client: MockClient((_) async {
          calls++;
          throw http.ClientException('offline');
        }),
        screenSize: () => '1x1',
        language: () => 'en',
      );
      await failing.setEnabled(enabled: true);
      await failing.event('a');
      await failing.event('b');
      await failing.flush();
      expect(calls, 1);
      expect(failing.pending, 0);
      await failing.setEnabled(enabled: false);
    });
  });

  group('SentrySink', () {
    test('SDK startet erst nach Einwilligung, Widerruf schliesst es', () async {
      var inits = 0;
      var closes = 0;
      final captured = <Object>[];
      final sink = SentrySink(
        _config(umami: false, sentry: true, firebase: false),
        initSdk: (_) async => inits++,
        capture: (e, _) async => captured.add(e),
        close: () async => closes++,
      );

      await sink.record(StateError('vorher'), StackTrace.empty);
      expect(inits, 0);
      expect(captured, isEmpty);

      await sink.setEnabled(enabled: true);
      await sink.setEnabled(enabled: true);
      expect(inits, 1);
      await sink.record(StateError('nachher'), StackTrace.empty);
      expect(captured, hasLength(1));

      await sink.setEnabled(enabled: false);
      expect(closes, 1);
      await sink.record(StateError('widerrufen'), StackTrace.empty);
      expect(captured, hasLength(1));
    });

    test('Optionen: keine PII, kein Tracing, DSN uebernommen', () {
      final sink = SentrySink(
        _config(umami: false, sentry: true, firebase: false),
      );
      final options = SentryFlutterOptions();
      sink.configureOptions(options);
      expect(options.dsn, 'https://key@errors.example.org/1');
      expect(options.sendDefaultPii, isFalse);
      expect(options.tracesSampleRate, 0);
      expect(options.attachScreenshot, isFalse);
      expect(options.beforeSend, isNotNull);
    });

    test('beforeSend entfernt Geraetename, Server-Name und Nutzer', () async {
      final event = SentryEvent(
        serverName: 'mein-rechner',
        user: SentryUser(ipAddress: '1.2.3.4'),
        contexts: Contexts(device: SentryDevice(name: 'Tims Handy')),
      );
      final result = await SentrySink.scrubEvent(event, Hint());
      expect(result!.serverName, isNull);
      expect(result.user, isNull);
      expect(result.contexts.device?.name, isNull);
    });
  });
}
