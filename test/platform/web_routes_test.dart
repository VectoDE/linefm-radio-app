import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/platform/web_routes.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('WebRoutes', () {
    test('jeder Bereich hat einen eigenen Pfad und findet zurueck', () {
      expect(WebRoutes.paths.keys, containsAll(AppScreen.values));
      expect(
        WebRoutes.paths.values.toSet(),
        hasLength(AppScreen.values.length),
      );
      for (final screen in AppScreen.values) {
        expect(WebRoutes.screenFor(WebRoutes.pathFor(screen)), screen);
      }
    });

    test('Schreibweise: Gross/Klein und Schraegstrich am Ende', () {
      expect(WebRoutes.screenFor('/History/'), AppScreen.history);
      expect(WebRoutes.screenFor(''), AppScreen.stations);
      expect(WebRoutes.screenFor('/'), AppScreen.stations);
    });

    test('unbekannter Pfad', () {
      expect(WebRoutes.screenFor('/gibtsnicht'), isNull);
      expect(WebRoutes.screenFor('/assets/x.png'), isNull);
    });
  });

  group('WebRouteSync', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      Uri? uri, {
      bool enabled = true,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: WebRouteSync(
              enabled: enabled,
              initialUri: uri,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('Start auf /favorites oeffnet die Favoriten', (tester) async {
      final c = await pump(
        tester,
        Uri.parse('https://app.linefm.de/favorites'),
      );
      expect(c.read(navigationProvider), AppScreen.favorites);
    });

    testWidgets('Start auf / bleibt bei den Stationen', (tester) async {
      final c = await pump(
        tester,
        Uri.parse('https://app.linefm.de/?station=linefm'),
      );
      expect(c.read(navigationProvider), AppScreen.stations);
    });

    testWidgets('unbekannter Pfad bleibt bei den Stationen', (tester) async {
      final c = await pump(tester, Uri.parse('https://app.linefm.de/x'));
      expect(c.read(navigationProvider), AppScreen.stations);
    });

    testWidgets('ausserhalb des Web: wirkungslos', (tester) async {
      final c = await pump(
        tester,
        Uri.parse('https://app.linefm.de/history'),
        enabled: false,
      );
      expect(c.read(navigationProvider), AppScreen.stations);
    });
  });
}
