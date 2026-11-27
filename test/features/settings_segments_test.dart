import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

/// Segment labels of the settings (theme, language) never break inside a
/// word: on every width, locale and text scale they either fit on one line
/// or the segments stack.
void main() {
  const labels = <String, List<String>>{
    'de': <String>['Systemsprache', 'Deutsch', 'English', 'System'],
    'en': <String>['System language', 'Deutsch', 'English', 'System'],
  };

  for (final locale in labels.keys) {
    for (final width in <double>[320, 390, 600, 1280]) {
      for (final scale in <double>[1, 1.3, 2]) {
        testWidgets('$locale ${width.toInt()} dp at ${scale}x', (tester) async {
          tester.view.physicalSize = Size(width, 2400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final host = FeatureHost();
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: Size(width, 2400),
                textScaler: TextScaler.linear(scale),
              ),
              child: host.app(const SettingsScreen(), locale: Locale(locale)),
            ),
          );
          await tester.pump();
          for (final label in labels[locale]!) {
            final finder = find.descendant(
              of: find.byWidgetPredicate((w) => w is SegmentedButton),
              matching: find.text(label),
            );
            if (finder.evaluate().isEmpty) continue;
            await tester.ensureVisible(finder.first);
            for (final element in finder.evaluate()) {
              final paragraph = element.renderObject! as RenderParagraph;
              // Wrapped text is narrower than its unwrapped width.
              final full = paragraph.getMaxIntrinsicWidth(double.infinity);
              expect(
                paragraph.size.width,
                greaterThanOrEqualTo(full - 0.5),
                reason: '"$label" wraps at ${paragraph.size.width} < $full',
              );
            }
          }
        });
      }
    }
  }
}
