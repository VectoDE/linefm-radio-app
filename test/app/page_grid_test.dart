import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/ui/theme/page_insets.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:material_ui/material_ui.dart';

import 'app_host.dart';

const _noAutoplay = AppSettings(autoplay: false);

/// Left edge of the first heading's text and top of the heading row.
Offset _heading(WidgetTester tester) {
  final heading = find.byType(SectionHeading).first;
  final text = tester.getRect(
    find.descendant(of: heading, matching: find.byType(Text)).first,
  );
  return Offset(text.left, tester.getRect(heading).top);
}

double _wordmarkLeft(WidgetTester tester) =>
    tester.getRect(find.text('LINEFM').first).left;

void main() {
  group('Header and pages share one grid', () {
    for (final (width, gutter) in <(double, double)>[
      (390, PageInsets.compact),
      (1280, PageInsets.expanded),
    ]) {
      testWidgets('$width dp: wordmark and headings on one left edge', (
        tester,
      ) async {
        useSize(tester, width, 1000);
        final host = AppHost(settings: _noAutoplay);
        await pumpApp(tester, host);

        final wordmark = _wordmarkLeft(tester);
        final positions = <AppScreen, Offset>{};
        for (final screen in <AppScreen>[
          AppScreen.stations,
          AppScreen.history,
          AppScreen.favorites,
        ]) {
          host.container.read(navigationProvider.notifier).go(screen);
          await settleApp(tester);
          positions[screen] = _heading(tester);
        }

        final stations = positions[AppScreen.stations]!;
        // Compact: header and content both start at the window edge.
        if (width < 840) expect(wordmark, gutter);
        expect(stations.dx, wordmark);
        // Lists are centred on wide windows; on a phone they share the edge,
        // and the heading row starts at the same height on every page.
        for (final p in positions.values) {
          if (width < 840) expect(p.dx, stations.dx);
          expect(p.dy, stations.dy, reason: '$positions');
        }
        expect(tester.takeException(), isNull);
        await disposeApp(tester, host);
      });
    }
  });
}
