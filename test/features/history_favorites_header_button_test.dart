import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/features/favorites/favorites_header_button.dart';
import 'package:material_ui/material_ui.dart';

import 'history_favorites_helpers.dart';

void main() {
  group('FavoritesHeaderButton', () {
    testWidgets('Badge zeigt Anzahl, Semantik mit Zaehler, Tippen navigiert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final ctx = await pumpScreen(
        tester,
        const Align(
          alignment: Alignment.topRight,
          child: FavoritesHeaderButton(),
        ),
        favorites: <Favorite>[fav('A', 'x'), fav('B', 'x'), fav('C', 'x')],
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('Favoriten, 3 Songs'), findsOneWidget);

      await tester.tap(find.byType(FavoritesHeaderButton));
      await tester.pump();
      expect(ctx.container.read(navigationProvider), AppScreen.favorites);

      ctx.container.read(favoritesProvider.notifier).remove('linefm:x:a');
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ohne Favoriten kein Badge, ab 100 "99+"', (tester) async {
      final ctx = await pumpScreen(
        tester,
        const Align(
          alignment: Alignment.topRight,
          child: FavoritesHeaderButton(),
        ),
      );
      expect(find.byType(Text), findsNothing);

      final many = <Favorite>[for (var i = 0; i < 120; i++) fav('T$i', 'a')];
      ctx.container.read(prefsProvider).writeFavorites(many).ignore();
      ctx.container.invalidate(favoritesProvider);
      await tester.pump();
      expect(find.text('99+'), findsOneWidget);
    });
  });
}
