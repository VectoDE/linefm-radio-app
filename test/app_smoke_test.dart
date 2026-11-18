import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

void main() {
  testWidgets('App startet mit Stub-Providern und zeigt 6 Sender', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(InMemoryPrefsStore())],
        child: const LinefmApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LINEFM | Radio'), findsOneWidget);
    expect(stationsCatalog, hasLength(6));
    for (final station in stationsCatalog) {
      expect(find.text(station.displayName), findsOneWidget);
    }
  });
}
