import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/features/favorites/favorites_header_button.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:material_ui/material_ui.dart';

import 'app_host.dart';

const _noAutoplay = AppSettings(autoplay: false);

final _nav = find.byKey(const ValueKey<String>('shell-bottom-nav'));

Finder _fa(FaIconData icon) => find.byIcon(icon.data);

Finder _items() =>
    find.descendant(of: _nav, matching: find.byType(InkResponse));

/// Size of the bar and the rectangle of every destination.
List<Rect> _measure(WidgetTester tester) => <Rect>[
  tester.getRect(_nav),
  for (var i = 0; i < 4; i++) tester.getRect(_items().at(i)),
];

FocusNode _itemNode(WidgetTester tester, int i) => Focus.of(
  tester.element(
    find.descendant(of: _items().at(i), matching: find.byType(Column)).first,
  ),
);

void main() {
  group('Bottom navigation: fixed size in every language', () {
    for (final width in <double>[320, 390, 599, 768]) {
      testWidgets('$width dp: German and English share one geometry', (
        tester,
      ) async {
        useSize(tester, width, 900);
        final rects = <String, List<Rect>>{};
        for (final lang in <String>['de', 'en']) {
          final host = AppHost(settings: _noAutoplay);
          await pumpApp(
            tester,
            host,
            uri: Uri.parse('https://app.linefm.de/?lang=$lang'),
          );
          expect(_nav, findsOneWidget);
          expect(_items(), findsNWidgets(4));
          rects[lang] = _measure(tester);
          expect(tester.takeException(), isNull);
          await disposeApp(tester, host);
        }
        expect(rects['en'], rects['de']);
        expect(rects['de']!.first.height, LinefmMetrics.navHeight);
      });
    }

    testWidgets('live language switch at 390 dp keeps the bar steady', (
      tester,
    ) async {
      useSize(tester, 390, 2600);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      host.container.read(navigationProvider.notifier).go(AppScreen.settings);
      await settleApp(tester);
      final before = _measure(tester);

      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await settleApp(tester);
      expect(find.text('Language'), findsOneWidget);
      expect(_measure(tester), before);
      expect(tester.takeException(), isNull);
      await disposeApp(tester, host);
    });
  });

  group('Bottom navigation: large system text', () {
    for (final width in <double>[320, 390]) {
      testWidgets('$width dp at 200 % text keeps a gap between labels', (
        tester,
      ) async {
        useSize(tester, width, 900);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final host = AppHost(settings: _noAutoplay);
        await pumpApp(tester, host);
        final labels = find.descendant(
          of: _nav,
          matching: find.byKey(const ValueKey<String>('nav-label')),
        );
        expect(labels, findsNWidgets(4));
        for (var i = 0; i < 3; i++) {
          final left = tester.getRect(labels.at(i));
          final right = tester.getRect(labels.at(i + 1));
          expect(
            right.left - left.right,
            greaterThanOrEqualTo(4 * LinefmSpace.xs),
          );
        }
        expect(tester.takeException(), isNull);
        await disposeApp(tester, host);
      });
    }
  });

  group('Screen reader announcements', () {
    testWidgets('switching areas announces the area name', (tester) async {
      useSize(tester, 390, 900);
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            final map = message as Map<Object?, Object?>;
            if (map['type'] == 'announce') {
              announced.add(
                (map['data']! as Map<Object?, Object?>)['message']! as String,
              );
            }
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(
        tester,
        host,
        uri: Uri.parse('https://app.linefm.de/?lang=en'),
      );
      final nav = host.container.read(navigationProvider.notifier);
      for (final (screen, name) in <(AppScreen, String)>[
        (AppScreen.settings, 'Settings'),
        (AppScreen.favorites, 'Favorites'),
        (AppScreen.history, 'History'),
        (AppScreen.stations, 'Stations'),
      ]) {
        nav.go(screen);
        await settleApp(tester);
        expect(announced.last, name);
      }
      await disposeApp(tester, host);
    });

    testWidgets('destinations carry their name and the selected state', (
      tester,
    ) async {
      useSize(tester, 390, 900);
      final semantics = tester.ensureSemantics();
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(
        tester,
        host,
        uri: Uri.parse('https://app.linefm.de/?lang=en'),
      );
      host.container.read(navigationProvider.notifier).go(AppScreen.history);
      await settleApp(tester);
      final data = tester.getSemantics(_items().at(2)).getSemanticsData();
      expect(data.label, 'History');
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      final other = tester.getSemantics(_items().at(0)).getSemanticsData();
      expect(other.label, 'Stations');
      expect(other.flagsCollection.isSelected, Tristate.isFalse);
      semantics.dispose();
      await disposeApp(tester, host);
    });
  });

  group('Rail names', () {
    testWidgets('favorites destination reads its count, no stray number', (
      tester,
    ) async {
      useSize(tester, 1280, 800);
      final semantics = tester.ensureSemantics();
      final host = AppHost(settings: _noAutoplay);
      await host.prefs.writeFavorites(const <Favorite>[
        Favorite(key: 'k', stationSlug: 'linefm', title: 'T', artist: 'A'),
      ]);
      await pumpApp(
        tester,
        host,
        uri: Uri.parse('https://app.linefm.de/?lang=en'),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Favorites, 1 song(\n|$)')),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(RegExp(r'^1(\n|$)')), findsNothing);
      semantics.dispose();
      await disposeApp(tester, host);
    });
  });

  group('Bottom navigation: state and focus', () {
    testWidgets('active destination shows the pill indicator', (tester) async {
      useSize(tester, 390, 900);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      final pill = find.byKey(const ValueKey<String>('nav-indicator'));
      expect(pill, findsOneWidget);
      expect(
        find.descendant(of: _items().at(0), matching: pill),
        findsOneWidget,
      );
      expect(
        tester.getSize(pill),
        const Size(
          LinefmMetrics.navIndicatorWidth,
          LinefmMetrics.navIndicatorHeight,
        ),
      );

      host.container.read(navigationProvider.notifier).go(AppScreen.history);
      await settleApp(tester);
      expect(
        find.descendant(of: _items().at(2), matching: pill),
        findsOneWidget,
      );
      await disposeApp(tester, host);
    });

    testWidgets('Tab walks the destinations in visual order with a ring', (
      tester,
    ) async {
      useSize(tester, 390, 900);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      // Keyboard use switches Flutter to the traditional highlight mode.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      _itemNode(tester, 0).requestFocus();
      await tester.pump();
      expect(_itemNode(tester, 0).hasPrimaryFocus, isTrue);
      final ring = find.descendant(
        of: find.ancestor(of: _items().at(0), matching: find.byType(FocusRing)),
        matching: find.byType(IgnorePointer),
      );
      expect(ring, findsWidgets);

      for (var i = 1; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_itemNode(tester, i).hasPrimaryFocus, isTrue, reason: 'item $i');
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        expect(_itemNode(tester, i).hasPrimaryFocus, isFalse);
      }

      await disposeApp(tester, host);
    });
  });

  group('One navigation model on every width', () {
    final rail = find.byKey(const ValueKey<String>('shell-rail'));

    testWidgets('compact: stations, player, history, favorites', (
      tester,
    ) async {
      useSize(tester, 390, 900);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      for (final icon in <FaIconData>[
        FontAwesomeIcons.play,
        FontAwesomeIcons.headphones,
        FontAwesomeIcons.clockRotateLeft,
        FontAwesomeIcons.heart,
      ]) {
        expect(find.descendant(of: _nav, matching: _fa(icon)), findsOneWidget);
      }
      // Settings live in the header only, favorites in the navigation only.
      expect(_fa(FontAwesomeIcons.heart), findsOneWidget);
      expect(_fa(FontAwesomeIcons.gear), findsOneWidget);
      expect(
        find.descendant(of: _nav, matching: _fa(FontAwesomeIcons.gear)),
        findsNothing,
      );

      host.container.read(navigationProvider.notifier).go(AppScreen.favorites);
      await settleApp(tester);
      expect(
        find.descendant(
          of: _items().at(3),
          matching: find.byKey(const ValueKey<String>('nav-indicator')),
        ),
        findsOneWidget,
      );
      await disposeApp(tester, host);
    });

    testWidgets('wide: rail with stations, history, favorites; no doubles', (
      tester,
    ) async {
      useSize(tester, 1280, 800);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      expect(rail, findsOneWidget);
      final destinations = tester
          .widget<NavigationRail>(
            find.descendant(of: rail, matching: find.byType(NavigationRail)),
          )
          .destinations;
      expect(destinations, hasLength(3));
      expect(
        find.descendant(of: rail, matching: _fa(FontAwesomeIcons.gear)),
        findsNothing,
      );
      expect(
        find.descendant(of: rail, matching: _fa(FontAwesomeIcons.heart)),
        findsOneWidget,
      );
      expect(find.byType(FavoritesHeaderButton), findsNothing);
      expect(_fa(FontAwesomeIcons.gear), findsOneWidget);
      await disposeApp(tester, host);
    });

    testWidgets('wide: first rail icon sits on the header midline', (
      tester,
    ) async {
      useSize(tester, 1280, 800);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      final first = find.descendant(
        of: rail,
        matching: _fa(FontAwesomeIcons.play),
      );
      final railTop = tester.getTopLeft(rail).dy;
      expect(
        tester.getCenter(first).dy - railTop,
        moreOrLessEquals(LinefmMetrics.headerHeight / 2, epsilon: 0.5),
      );
      await disposeApp(tester, host);
    });

    testWidgets('settings gear shows the active state', (tester) async {
      useSize(tester, 1280, 800);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);
      IconButton gear() => tester.widget<IconButton>(
        find.ancestor(
          of: _fa(FontAwesomeIcons.gear),
          matching: find.byType(IconButton),
        ),
      );
      expect(gear().isSelected, isFalse);
      host.container.read(navigationProvider.notifier).go(AppScreen.settings);
      await settleApp(tester);
      expect(gear().isSelected, isTrue);
      await disposeApp(tester, host);
    });
  });

  group('Autoplay hint', () {
    final start = find.byKey(const ValueKey<String>('autoplay-start'));

    for (final (width, stacked) in <(double, bool)>[
      (320, true),
      (390, false),
    ]) {
      testWidgets('$width dp: button ${stacked ? 'below' : 'beside'} text', (
        tester,
      ) async {
        useSize(tester, width, 640);
        final host = AppHost(settings: _noAutoplay);
        await pumpApp(tester, host);
        host.container.read(autoplayBlockedProvider.notifier).set(value: true);
        await settleApp(tester);
        expect(start, findsOneWidget);
        final button = tester.getRect(start);
        // Stacked: the button spans the card; beside: it leaves room for text.
        if (stacked) {
          expect(button.width, greaterThan(width - 64));
        } else {
          expect(button.width, lessThan(width - 100));
        }
        expect(tester.takeException(), isNull);
        await disposeApp(tester, host);
      });
    }
  });
}
