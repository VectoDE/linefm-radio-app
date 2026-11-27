// Screen reader contract of the app shell, checked on the semantics tree that
// TalkBack, VoiceOver and NVDA consume: the navigation announces its state,
// a change of area is announced by name, and the main landmarks exist. A real
// screen reader adds speech, gestures and verbosity settings on top; those
// stay manual checks (docs/GERAETETESTS.md).
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';

import '../app/app_host.dart';
import '../golden_support.dart';

const _noAutoplay = AppSettings(autoplay: false);

/// Collects the announcements sent over the accessibility channel.
List<String> _captureAnnouncements(WidgetTester tester) {
  final announced = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      if (message is Map && message['type'] == 'announce') {
        final data = message['data'];
        if (data is Map && data['message'] is String) {
          announced.add(data['message'] as String);
        }
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return announced;
}

/// All nodes of the semantics tree that are buttons.
Iterable<SemanticsNode> _buttons(WidgetTester tester) => tester
    .binding
    .renderViews
    .first
    .owner!
    .semanticsOwner!
    .rootSemanticsNode!
    .debugDescendants()
    .where((node) => node.flagsCollection.isButton);

extension on SemanticsNode {
  Iterable<SemanticsNode> debugDescendants() sync* {
    final stack = <SemanticsNode>[this];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      yield node;
      node.visitChildren((child) {
        stack.add(child);
        return true;
      });
    }
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('bottom navigation: named buttons, exactly one selected', (
    tester,
  ) async {
    ignoreDelegateWarning();
    final handle = tester.ensureSemantics();
    useSize(tester, 390, 844);
    final host = AppHost(settings: _noAutoplay);
    await pumpApp(tester, host);

    for (final label in <String>['Sender', 'Player', 'Verlauf']) {
      final matches = _buttons(tester).where((n) => n.label == label);
      expect(matches, hasLength(1), reason: label);
    }
    final selected = <String>[
      for (final label in <String>['Sender', 'Player', 'Verlauf'])
        if (_buttons(tester)
                .firstWhere((n) => n.label == label)
                .flagsCollection
                .isSelected ==
            Tristate.isTrue)
          label,
    ];
    expect(selected, <String>['Sender']);

    tester.semantics.tap(find.semantics.byLabel('Verlauf'));
    await settleApp(tester);
    final after = _buttons(tester).firstWhere((n) => n.label == 'Verlauf');
    expect(after.flagsCollection.isSelected, Tristate.isTrue);

    await disposeApp(tester, host);
    handle.dispose();
  });

  testWidgets('a change of area is announced by its name', (tester) async {
    ignoreDelegateWarning();
    final handle = tester.ensureSemantics();
    useSize(tester, 390, 844);
    final announced = _captureAnnouncements(tester);
    final host = AppHost(settings: _noAutoplay);
    await pumpApp(tester, host);

    for (final (label, screen, name) in <(String, AppScreen, String)>[
      ('Verlauf', AppScreen.history, 'Verlauf'),
      ('Player', AppScreen.player, 'Player'),
      ('Sender', AppScreen.stations, 'Sender'),
    ]) {
      announced.clear();
      tester.semantics.tap(
        find.semantics.byPredicate(
          (n) => n.label == label && n.flagsCollection.isButton,
        ),
      );
      await settleApp(tester);
      expect(announced, contains(name), reason: 'announcement for $screen');
    }

    await disposeApp(tester, host);
    handle.dispose();
  });

  testWidgets(
    'wide layout: rail targets are actionable and announce the area',
    (tester) async {
      ignoreDelegateWarning();
      final handle = tester.ensureSemantics();
      useSize(tester, 1100, 720);
      final announced = _captureAnnouncements(tester);
      final host = AppHost(settings: _noAutoplay);
      await pumpApp(tester, host);

      // NavigationRail adds the position ("Tab 1 von 3") to the label.
      SemanticsFinder tab(String name) => find.semantics.byPredicate(
        (n) =>
            n.getSemanticsData().hasAction(SemanticsAction.tap) &&
            n.label.startsWith('$name\nTab '),
      );
      for (final name in <String>['Sender', 'Verlauf', 'Favoriten']) {
        expect(tab(name), findsOneWidget, reason: name);
      }

      tester.semantics.tap(tab('Verlauf'));
      await settleApp(tester);
      expect(announced, contains('Verlauf'));

      await disposeApp(tester, host);
      handle.dispose();
    },
  );

  testWidgets('every button in the tree of every screen has a name', (
    tester,
  ) async {
    ignoreDelegateWarning();
    final handle = tester.ensureSemantics();
    useSize(tester, 390, 844);
    final host = AppHost(settings: _noAutoplay);
    await pumpApp(tester, host);

    for (final screen in <AppScreen>[
      AppScreen.stations,
      AppScreen.player,
      AppScreen.history,
      AppScreen.favorites,
      AppScreen.settings,
    ]) {
      host.container.read(navigationProvider.notifier).go(screen);
      await settleApp(tester);
      final unnamed = _buttons(tester)
          .where((n) => n.label.trim().isEmpty && n.tooltip.trim().isEmpty)
          .toList();
      expect(unnamed, isEmpty, reason: '${screen.name}: unnamed buttons');
    }

    await disposeApp(tester, host);
    handle.dispose();
  });
}
