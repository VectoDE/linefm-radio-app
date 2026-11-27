import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/stations/station_card.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byType(StationCard),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

Future<void> _pump(WidgetTester tester, {required bool active}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildLinefmTheme(Brightness.dark),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: StationCard(
                station: stationsCatalog.first,
                semanticLabel: 'LineFM',
                onTap: () {},
                active: active,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  final accent = StationStyle.border(
    stationsCatalog.first.color,
    LinefmColors.dark,
  );

  testWidgets('Hover hebt die Karte an, Rahmen bleibt dem aktiven Sender', (
    tester,
  ) async {
    await _pump(tester, active: false);
    expect(_decoration(tester).boxShadow, isNull);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(StationCard)));
    await tester.pumpAndSettle();

    final hovered = _decoration(tester);
    expect(hovered.boxShadow, isNotEmpty);
    expect((hovered.border! as Border).top.color, isNot(accent));
  });

  testWidgets('Aktiver Sender: Rahmen in Senderfarbe, kein Schatten', (
    tester,
  ) async {
    await _pump(tester, active: true);
    final d = _decoration(tester);
    expect((d.border! as Border).top.color, accent);
    expect(d.boxShadow, isNull);
  });
}
