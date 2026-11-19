import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/features/player/player_view.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(List<Widget> children) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Wrap(
        key: const ValueKey<String>('row'),
        children: <Widget>[for (final c in children) SlotGap(child: c)],
      ),
    ),
  );

  testWidgets('leerer Slot belegt keinen Platz, sichtbarer 5 dp je Seite', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const <Widget>[
        SizedBox(width: 40, height: 40),
        SizedBox.shrink(),
        SizedBox.shrink(),
      ]),
    );
    expect(tester.getSize(find.byKey(const ValueKey<String>('row'))).width, 50);
    expect(tester.getTopLeft(find.byType(SizedBox).first).dx, greaterThan(0));
  });

  testWidgets('Tippen trifft das versetzte Kind', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(<Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox(width: 40, height: 40),
        ),
      ]),
    );
    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);
  });
}
