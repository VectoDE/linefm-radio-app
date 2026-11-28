import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/settings_switch.dart';
import 'package:material_ui/material_ui.dart';

/// Colour of the pill-shaped track inside the switch.
Color? _track(WidgetTester tester) {
  final box =
      tester
              .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
              .firstWhere((w) => w.constraints?.maxWidth == 46)
              .decoration!
          as BoxDecoration;
  return box.color;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness: on = accent track, off = neutral track', (
      tester,
    ) async {
      final theme = buildLinefmTheme(brightness);
      final c = theme.extension<LinefmColors>()!;
      Future<void> pump({required bool value}) => tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SettingsSwitch(
              title: 'T',
              subtitle: 'S',
              value: value,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await pump(value: true);
      await tester.pumpAndSettle();
      expect(_track(tester), c.accent);
      await pump(value: false);
      await tester.pumpAndSettle();
      expect(_track(tester), c.switchTrackOff);

      // Material switch in the theme follows the same rule.
      final states = <WidgetState>{WidgetState.selected};
      expect(theme.switchTheme.trackColor!.resolve(states), c.accent);
      expect(theme.switchTheme.thumbColor!.resolve(states), c.onAccent);
    });
  }
}
