import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/ui/theme/contrast.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';

Color _hex(String h) =>
    Color(0xFF000000 | int.parse(h.substring(1), radix: 16));

Map<String, Color> _androidColors(String path) {
  final xml = File(path).readAsStringSync();
  return {
    for (final m in RegExp(
      r'<color name="(widget_\w+)">(#[0-9A-Fa-f]{6})</color>',
    ).allMatches(xml))
      m.group(1)!: _hex(m.group(2)!),
  };
}

Color _iosColor(String name, {required bool dark}) {
  final json = jsonDecode(
    File('ios/Shared/StationLogos.xcassets/$name.colorset/Contents.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final entries = (json['colors'] as List).cast<Map<String, dynamic>>();
  final entry = entries.firstWhere((e) => (e['appearances'] != null) == dark);
  final c = (entry['color'] as Map<String, dynamic>)['components'] as Map;
  int v(String k) => int.parse((c[k] as String).substring(2), radix: 16);
  return Color.fromARGB(255, v('red'), v('green'), v('blue'));
}

void main() {
  const dark = LinefmColors.dark;
  const light = LinefmColors.light;
  final expected = {
    false: {
      'widget_background': light.surface,
      'widget_text': light.text,
      'widget_muted': light.muted,
      'widget_button_background': light.accent,
      'widget_button_foreground': light.onAccent,
    },
    true: {
      'widget_background': dark.surface,
      'widget_text': dark.text,
      'widget_muted': dark.tickerText,
      'widget_button_background': dark.accent,
      'widget_button_foreground': dark.onAccent,
    },
  };

  for (final isDark in [false, true]) {
    final mode = isDark ? 'dark' : 'light';
    final path =
        'android/app/src/main/res/${isDark ? 'values-night' : 'values'}/colors.xml';

    test('Android widget colors ($mode) match the design tokens', () {
      final colors = _androidColors(path);
      expected[isDark]!.forEach((name, token) {
        expect(colors[name], token, reason: name);
      });
    });

    test('Android widget contrast ($mode) meets WCAG AA', () {
      final c = _androidColors(path);
      expect(
        Contrast.ratio(c['widget_text']!, c['widget_background']!),
        greaterThanOrEqualTo(Contrast.aaText),
      );
      expect(
        Contrast.ratio(c['widget_muted']!, c['widget_background']!),
        greaterThanOrEqualTo(Contrast.aaText),
      );
      expect(
        Contrast.ratio(
          c['widget_button_foreground']!,
          c['widget_button_background']!,
        ),
        greaterThanOrEqualTo(Contrast.aaLarge),
      );
    });

    test('iOS widget color assets ($mode) match tokens and meet AA', () {
      for (final name in ['widget_background', 'widget_text', 'widget_muted']) {
        expect(
          _iosColor(name, dark: isDark),
          expected[isDark]![name],
          reason: name,
        );
      }
      final bg = _iosColor('widget_background', dark: isDark);
      expect(
        Contrast.ratio(_iosColor('widget_text', dark: isDark), bg),
        greaterThanOrEqualTo(Contrast.aaText),
      );
      expect(
        Contrast.ratio(_iosColor('widget_muted', dark: isDark), bg),
        greaterThanOrEqualTo(Contrast.aaText),
      );
    });
  }
}
