import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/stations/favorite_stations.dart';
import 'package:linefm_radio/features/stations/stations_screen.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:material_ui/material_ui.dart';

import 'stations_test_host.dart';

/// Knopf mit [QuietTooltip] (der Material-Finder `byTooltip` kennt nur
/// Tooltips mit Semantik).
Finder _byQuietTooltip(String message) =>
    find.byWidgetPredicate((w) => w is QuietTooltip && w.message == message);

void main() {
  testWidgets('Stern merkt Sender als Favoriten-Sender, Songs unberuehrt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = Harness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    final stars = find.byKey(const ValueKey<String>('station-favorite-star'));
    expect(stars, findsNWidgets(6));
    expect(h.container.read(favoriteStationsProvider), isEmpty);

    // Vierte Karte: LineFM +LOFI.
    await tester.tap(stars.at(3));
    await settle(tester);
    expect(h.container.read(favoriteStationsProvider), <String>{'linefmlofi'});
    expect(
      h.container.read(favoriteStationListProvider).single.slug,
      'linefmlofi',
    );
    expect(h.container.read(favoritesProvider), isEmpty);
    expect(
      _byQuietTooltip('LineFM +LOFI aus den Favoriten-Sendern entfernen'),
      findsNWidgets(2),
    );
    // Antippen des Sterns startet keine Wiedergabe.
    expect(h.sink.events.where((e) => e.startsWith('play')), isEmpty);
    // U4: Gruppe "Deine Sender" oben mit der gemerkten Karte.
    expect(find.text('DEINE SENDER'), findsOneWidget);
    expect(stars, findsNWidgets(7));

    await tester.tap(
      _byQuietTooltip('LineFM +LOFI aus den Favoriten-Sendern entfernen').first,
    );
    await settle(tester);
    expect(h.container.read(favoriteStationsProvider), isEmpty);
    expect(find.text('DEINE SENDER'), findsNothing);
    expect(stars, findsNWidgets(6));
  });

  testWidgets('Screenreader: Zusatz im Label und eigene Aktion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    final h = Harness();
    addTearDown(h.container.dispose);
    h.container
        .read(favoriteStationsProvider.notifier)
        .toggle(h.container.read(activeStationProvider));
    await tester.pumpWidget(h.app(const StationsScreen()));
    await settle(tester);

    expect(
      find.bySemanticsLabel(
        "LineFM +MAIN, läuft: James Hype - I Was Lovin' You, Favoriten-Sender",
      ),
      // In "Deine Sender" (U4) und in der Gesamtliste.
      findsNWidgets(2),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Radio3FM'));
    final labels = node
        .getSemanticsData()
        .customSemanticsActionIds!
        .map((id) => CustomSemanticsAction.getAction(id)!.label)
        .toList();
    expect(labels, contains('Radio3FM als Favoriten-Sender merken'));
    expect(labels, contains('Sender teilen'));
    handle.dispose();
  });
}
