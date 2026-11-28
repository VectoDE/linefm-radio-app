import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:material_ui/material_ui.dart';

import 'support/service_doubles.dart';

void main() {
  testWidgets('App startet mit Stub-Providern, Loader, Shell und 6 Sendern', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    loaderShownThisProcess = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noopServiceOverrides(),
          prefsProvider.overrideWithValue(InMemoryPrefsStore()),
        ],
        child: const LinefmApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(AppLoader), findsOneWidget);

    // Kaltstart: Loader steht mindestens 1,2 s und blendet dann aus.
    await tester.pump();
    await tester.pump(LoaderGate.fadeDuration);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppLoader), findsNothing);

    expect(find.text('LINEFM'), findsOneWidget);
    expect(stationsCatalog, hasLength(6));
    // Stationsnamen stehen in Syncopate-Grossbuchstaben auf den Karten.
    for (final station in stationsCatalog) {
      expect(find.text(station.displayName.toUpperCase()), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
