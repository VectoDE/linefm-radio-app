import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:material_ui/material_ui.dart';

/// The very first frame after runApp must be the branded loading screen and
/// nothing else: no station list, no text of the app behind it. On native
/// platforms this frame directly follows the native splash (Android) or is the
/// first content of the window (desktop shows the window on the first frame).
void main() {
  for (final size in const <Size>[Size(390, 844), Size(1280, 800)]) {
    testWidgets('first frame is only the loader ($size)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      loaderShownThisProcess = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [prefsProvider.overrideWithValue(InMemoryPrefsStore())],
          child: const LinefmApp(),
        ),
      );

      // No extra pump: this is the first frame.
      final loader = find.byType(AppLoader);
      expect(loader, findsOneWidget);
      expect(tester.getRect(loader), Offset.zero & size);

      // Fully opaque on top of everything else.
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(of: loader, matching: find.byType(AnimatedOpacity)),
      );
      expect(opacity.opacity, 1);
      final background = tester.widget<Material>(
        find.descendant(of: loader, matching: find.byType(Material)).first,
      );
      expect(background.color, loaderBackground);
      expect(background.color!.a, 1);

      // The station list behind it is neither reachable nor announced.
      final semantics = tester.ensureSemantics();
      await tester.pump();
      for (final station in stationsCatalog) {
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(station.displayName))),
          findsNothing,
        );
      }
      semantics.dispose();

      await tester.pump(LoaderGate.nativeMinDuration);
      await tester.pump(LoaderGate.fadeDuration);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
