import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';

const _linefm =
    '{"id":12,"title":"River","started_at":"2026-11-18 21:31:46 +0100",'
    '"ends_at":"2026-11-18 21:32:46 +0100","artist":{"name":"Tom Gregory"},'
    '"live":true,"type":"song","station":"linefm"}';
const _other =
    '{"id":1,"type":"song","title":"X","artist":{"name":"Y"},'
    '"station":"rbsw2","started_at":"2026-11-18 21:14:00 +0100",'
    '"ends_at":"2026-11-18 21:17:10 +0100"}';

void main() {
  group('TrafficGuard', () {
    test('Plattformregel: nur Desktop', () {
      expect(
        TrafficGuard.platformAllowsWebSocket(TargetPlatform.windows),
        true,
      );
      expect(TrafficGuard.platformAllowsWebSocket(TargetPlatform.linux), true);
      expect(TrafficGuard.platformAllowsWebSocket(TargetPlatform.macOS), true);
      expect(
        TrafficGuard.platformAllowsWebSocket(TargetPlatform.android),
        false,
      );
      expect(TrafficGuard.platformAllowsWebSocket(TargetPlatform.iOS), false);
    });

    test('gleitendes 60-s-Fenster und Budget', () {
      final clock = FakeClock(DateTime.utc(2026));
      final guard = TrafficGuard(
        maxKbPerMinute: 100,
        platformAllowed: true,
        clock: clock,
      );
      for (var i = 0; i < 50; i++) {
        guard.record(2048);
        clock.advance(const Duration(seconds: 1));
      }
      expect(guard.kbPerMinute, 100);
      expect(guard.exceeded, isFalse);
      guard.record(2048);
      expect(guard.exceeded, isTrue);
      expect(guard.allowed, isFalse);
      clock.advance(const Duration(seconds: 61));
      expect(guard.kbPerMinute, 0);
      expect(guard.allowed, isTrue);
    });

    test('gemessenes laut.fm-Volumen ueberschreitet die mobile Schwelle', () {
      // 2240 KB/min gemessen (test/fixtures/laut/ws_measurement_*.json).
      final clock = FakeClock(DateTime.utc(2026));
      final guard = TrafficGuard(
        maxKbPerMinute: TrafficGuard.meteredThresholdKbPerMinute,
        platformAllowed: true,
        clock: clock,
      );
      for (var i = 0; i < 60; i++) {
        guard.record(38315);
        clock.advance(const Duration(milliseconds: 999));
      }
      expect(guard.exceeded, isTrue);
      final desktop = TrafficGuard(platformAllowed: true, clock: clock);
      for (var i = 0; i < 60; i++) {
        desktop.record(38315);
        clock.advance(const Duration(milliseconds: 999));
      }
      expect(desktop.exceeded, isFalse);
    });
  });

  test('Backoff 2 s -> 60 s mit Jitter unter 1 s', () {
    final socket = WebSocketSongChangeSocket(random: Random(1));
    expect(socket.backoffFor(1).inSeconds, 2);
    expect(socket.backoffFor(2).inSeconds, 4);
    expect(socket.backoffFor(3).inSeconds, 8);
    expect(socket.backoffFor(6).inSeconds, 60);
    expect(socket.backoffFor(20).inSeconds, 60);
  });

  group('gegen lokalen WebSocket-Server', () {
    late HttpServer server;
    late List<WebSocket> clients;

    setUp(() async {
      clients = <WebSocket>[];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final ws = await WebSocketTransformer.upgrade(req);
        clients.add(ws);
      });
    });

    tearDown(() async {
      for (final c in clients) {
        await c.close();
      }
      await server.close(force: true);
    });

    Uri uri() => Uri.parse('ws://127.0.0.1:${server.port}/');

    Future<void> until(bool Function() cond) async {
      for (var i = 0; i < 200 && !cond(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(cond(), isTrue);
    }

    test('liefert nur unsere Wechsel aus JSONL-Frames', () async {
      final socket = WebSocketSongChangeSocket(
        uri: uri(),
        guard: TrafficGuard(platformAllowed: true),
      );
      final got = <SongChange>[];
      final sub = socket.changes.listen(got.add);
      await socket.connect();
      expect(socket.state, SongChangeSocketState.connected);
      await until(() => clients.isNotEmpty);
      clients.single.add('$_other\n$_linefm\n$_other');
      await until(() => got.isNotEmpty);
      expect(got.single.stationSlug, 'linefm');
      expect(got.single.isLive, isTrue);
      expect(got.single.track.title, 'River');
      await sub.cancel();
      await socket.dispose();
      expect(socket.state, SongChangeSocketState.idle);
    });

    test('Traffic-Budget ueberschritten -> getrennt, nur Polling', () async {
      final socket = WebSocketSongChangeSocket(
        uri: uri(),
        guard: TrafficGuard(maxKbPerMinute: 1, platformAllowed: true),
      );
      await socket.connect();
      await until(() => clients.isNotEmpty);
      clients.single.add(List<String>.filled(10, _other).join('\n'));
      await until(() => socket.state == SongChangeSocketState.blockedByTraffic);
      await socket.dispose();
    });

    test('Plattform gesperrt -> keine Verbindung', () async {
      final socket = WebSocketSongChangeSocket(
        uri: uri(),
        guard: TrafficGuard(platformAllowed: false),
      );
      await socket.connect();
      expect(socket.state, SongChangeSocketState.blockedByTraffic);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(clients, isEmpty);
      await socket.dispose();
    });

    test('Verbindungsabbruch -> Reconnect, 3 Fehlschlaege -> Pause', () async {
      final socket = WebSocketSongChangeSocket(
        uri: uri(),
        guard: TrafficGuard(platformAllowed: true),
        minBackoff: const Duration(milliseconds: 10),
        maxBackoff: const Duration(milliseconds: 20),
        cooldown: const Duration(hours: 1),
        random: _NoJitter(),
      );
      final states = <SongChangeSocketState>[];
      final sub = socket.states.listen(states.add);
      await socket.connect();
      await until(() => clients.length == 1);
      await clients.last.close();
      await until(() => clients.length == 2);
      expect(states, contains(SongChangeSocketState.reconnecting));
      // Server weg: weitere Versuche scheitern bis zur Pause.
      await server.close(force: true);
      await clients.last.close();
      await until(() => socket.state == SongChangeSocketState.coolingDown);
      await sub.cancel();
      await socket.dispose();
    });
  });
}

class _NoJitter implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
