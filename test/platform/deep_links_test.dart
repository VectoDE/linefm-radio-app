import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/platform/deep_links.dart';

void main() {
  setUp(DeepLinks.resetForTest);

  group('stationFromUri', () {
    test('App-Link linefm://play?station=', () {
      for (final s in stationsCatalog) {
        expect(
          DeepLinks.stationFromUri(
            Uri.parse('linefm://play?station=${s.slug}'),
          ),
          s,
        );
      }
    });

    test('Web-Link https://app.linefm.de/?station=', () {
      expect(
        DeepLinks.stationFromUri(
          Uri.parse('https://app.linefm.de/?station=linefmrap'),
        ),
        stationBySlug('linefmrap'),
      );
      // Benannte Route plus Sender.
      expect(
        DeepLinks.stationFromUri(
          Uri.parse('https://app.linefm.de/history?station=linefm&lang=en'),
        ),
        stationBySlug('linefm'),
      );
    });

    test('unbekannt, leer, falsches Ziel, fremdes Schema', () {
      for (final bad in <String>[
        'linefm://play?station=gibtsnicht',
        'linefm://play',
        'linefm://play?station=',
        'linefm://settings?station=linefm',
        'javascript:alert(1)?station=linefm',
        'file:///x?station=linefm',
        'https://app.linefm.de/',
      ]) {
        expect(DeepLinks.stationFromUri(Uri.parse(bad)), isNull, reason: bad);
      }
    });
  });

  group('dispatch', () {
    test(
      'Kaltstart: Link vor dem ersten Zuhoerer wird nachgeliefert',
      () async {
        DeepLinks.dispatch(Uri.parse('linefm://play?station=linefmlofi'));
        final received = <Uri>[];
        final sub = DeepLinks.stream.listen(received.add);
        await Future<void>.delayed(Duration.zero);
        expect(received.map((u) => u.queryParameters['station']), <String>[
          'linefmlofi',
        ]);
        await sub.cancel();
      },
    );

    test('warm: Link kommt direkt an', () async {
      final received = <Uri>[];
      final sub = DeepLinks.stream.listen(received.add);
      DeepLinks.dispatch(Uri.parse('linefm://play?station=linefmrap'));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      await sub.cancel();
    });

    test('ungueltige Links werden verworfen', () async {
      final received = <Uri>[];
      final sub = DeepLinks.stream.listen(received.add);
      DeepLinks.dispatch(Uri.parse('linefm://play?station=nix'));
      DeepLinks.dispatch(Uri.parse('https://example.org/'));
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);
      await sub.cancel();
    });

    test('derselbe Link kurz hintereinander zaehlt einmal', () async {
      final received = <Uri>[];
      final sub = DeepLinks.stream.listen(received.add);
      final uri = Uri.parse('linefm://play?station=linefm');
      final t = DateTime(2026, 11, 19, 12);
      DeepLinks.dispatch(uri, now: t);
      DeepLinks.dispatch(uri, now: t.add(const Duration(milliseconds: 300)));
      DeepLinks.dispatch(uri, now: t.add(const Duration(seconds: 5)));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(2));
      await sub.cancel();
    });

    test('Startargumente (Windows/Linux)', () async {
      final received = <Uri>[];
      final sub = DeepLinks.stream.listen(received.add);
      DeepLinks.dispatchFromArguments(<String>[
        '--flag',
        'linefm://play?station=radio3fm',
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(received.single.queryParameters['station'], 'radio3fm');
      await sub.cancel();
    });
  });

  test('Routeninformation des Systems wird zum Deep Link', () async {
    final observer = DeepLinkObserver();
    final received = <Uri>[];
    final sub = DeepLinks.stream.listen(received.add);

    final handled = await observer.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('linefm://play?station=linefmgaming')),
    );
    final ignored = await observer.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('/settings')),
    );
    await Future<void>.delayed(Duration.zero);

    expect(handled, isTrue);
    expect(ignored, isFalse);
    expect(received.single.queryParameters['station'], 'linefmgaming');
    await sub.cancel();
  });
}
