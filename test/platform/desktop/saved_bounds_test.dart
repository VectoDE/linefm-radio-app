import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/platform/desktop/saved_bounds.dart';

void main() {
  const minimum = Size(360, 520);

  test('Kodieren und Dekodieren sind umkehrbar', () {
    const bounds = SavedBounds(
      Rect.fromLTWH(40, 60, 1000, 700),
      maximized: true,
    );
    final back = SavedBounds.decode(bounds.encode(), minimum: minimum);
    expect(back, isNotNull);
    expect(back!.rect, const Rect.fromLTWH(40, 60, 1000, 700));
    expect(back.maximized, isTrue);
  });

  test('ohne Kennzeichen ist das Fenster nicht maximiert', () {
    final back = SavedBounds.decode('10;20;800;600', minimum: minimum);
    expect(back?.maximized, isFalse);
  });

  test('unsinnige Werte werden verworfen', () {
    expect(SavedBounds.decode(null), isNull);
    expect(SavedBounds.decode('abc'), isNull);
    expect(SavedBounds.decode('1;2;3'), isNull);
    expect(SavedBounds.decode('x;2;800;600'), isNull);
    expect(SavedBounds.decode('NaN;2;800;600'), isNull);
    // zu klein fuer das Layout
    expect(SavedBounds.decode('0;0;100;100', minimum: minimum), isNull);
    // riesig oder weit weg von jedem Bildschirm
    expect(SavedBounds.decode('0;0;20000;600'), isNull);
    expect(SavedBounds.decode('90000;0;800;600'), isNull);
  });
}
