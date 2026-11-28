import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/features/player/player_screen.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:material_ui/material_ui.dart';

import 'app_host.dart';
import 'shell_helpers.dart';

void main() {
  group('Tastatur-Reihenfolge', () {
    testWidgets('Kompakt: Header, Inhalt, Hinweise, Mini-Player, Navigation', (
      tester,
    ) async {
      useSize(tester, 412, 860);
      final host = AppHost(settings: noAutoplay);
      await pumpApp(tester, host);

      final forward = await tabRegions(tester, LogicalKeyboardKey.tab, 60);
      // Ein voller Durchlauf: jeder Bereich kommt vor, keiner kehrt nach
      // einem spaeteren Bereich zurueck (keine Falle im unteren Stapel).
      final firstPass = untilWrap(forward);
      expect(firstPass.toSet(), containsAll(<int>[1, 2, 4, 5]));
      expect(isAscending(firstPass), isTrue, reason: '$firstPass');
      expect(firstPass.last, 5);
      // Danach verlaesst Tab die Bereiche (Shell selbst) oder beginnt
      // wieder beim Header.
      expect(forward[firstPass.length], anyOf(0, 1));

      final backward = await tabRegions(
        tester,
        LogicalKeyboardKey.tab,
        40,
        shift: true,
      );
      final backPass = untilWrap(backward, reverse: true);
      expect(
        isAscending(backPass.reversed.toList()),
        isTrue,
        reason: '$backPass',
      );
      await disposeApp(tester, host);
    });

    testWidgets('Kompakt: Favoriten und Einstellungen per Tab erreichbar', (
      tester,
    ) async {
      useSize(tester, 412, 860);
      final host = AppHost(settings: noAutoplay);
      await pumpApp(tester, host);

      final tooltips = <String>{};
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final context = FocusManager.instance.primaryFocus?.context;
        final tooltip = context?.findAncestorWidgetOfExactType<QuietTooltip>();
        if (tooltip != null) tooltips.add(tooltip.message);
      }
      expect(tooltips, contains('Einstellungen'));
      await disposeApp(tester, host);
    });
  });

  group('Tablet/Desktop', () {
    testWidgets('zweispaltig: Rail, Liste und eingebetteter Player', (
      tester,
    ) async {
      useSize(tester, 1280, 800);
      final host = AppHost(settings: noAutoplay);
      await pumpApp(tester, host);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.text('ALLE SENDER'), findsOneWidget);
      expect(find.byType(MiniPlayer), findsNothing);
      expect(find.text('PLAYER'), findsNothing);

      // Sender antippen: kein Wechsel weg von der Liste.
      await tester.tap(find.text('LINEFM +GAMING'));
      await settleApp(tester);
      expect(host.container.read(navigationProvider), AppScreen.stations);
      expect(host.active.slug, 'linefmgaming');
      await disposeApp(tester, host);
    });

    testWidgets('Wechsel der Fensterbreite wechselt das Layout', (
      tester,
    ) async {
      useSize(tester, 1280, 800);
      final host = AppHost(settings: noAutoplay);
      await pumpApp(tester, host);
      expect(find.byType(NavigationRail), findsOneWidget);

      tester.view.physicalSize = const Size(700, 900);
      await settleApp(tester);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('VERLAUF'), findsOneWidget);
      await disposeApp(tester, host);
    });
  });
}
