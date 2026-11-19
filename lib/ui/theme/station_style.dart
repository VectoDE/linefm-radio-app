import 'package:linefm_radio/ui/theme/contrast.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Verlaeufe und Vordergrundfarben, die sich aus der Senderfarbe ergeben
/// (Web: `color-mix(in srgb, var(--station-color) N%, ...)`).
abstract final class StationStyle {
  /// Dunkle Tinte der Web-App fuer Verlaeufe im Dunkelmodus.
  static const Color _ink = Contrast.ink;

  /// Mischt [color] mit Anteil [amount] (0 bis 1) in [base], wie
  /// `color-mix(in srgb, color amount, base)`.
  static Color mix(Color color, double amount, Color base) =>
      Color.alphaBlend(color.withValues(alpha: amount), base);

  /// Verlauf der Stationskarte: 285 Grad, 20 % Senderfarbe in `surface` bis
  /// `surface` bei 61 %.
  static LinearGradient cardGradient(Color color, LinefmColors c) =>
      LinearGradient(
        begin: const Alignment(0.966, 0.259),
        end: const Alignment(-0.966, -0.259),
        colors: <Color>[mix(color, 0.20, c.surface), c.surface],
        stops: const <double>[0, 0.61],
      );

  /// Verlauf hinter dem Senderlogo (145 Grad, Senderfarbe bis `#171929`).
  static LinearGradient artGradient(Color color) => LinearGradient(
    begin: const Alignment(-0.574, -0.819),
    end: const Alignment(0.574, 0.819),
    colors: <Color>[color, const Color(0xFF171929)],
  );

  /// Hintergrund des Player-Screens. Dunkel wie die Web-App (84 % -> 38 % bei
  /// 38 % -> `#0f1221` bei 88 %), hell mit weicheren Anteilen in `background`.
  static LinearGradient playerGradient(
    Color color,
    LinefmColors c,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final base = dark ? _ink : c.background;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        mix(color, dark ? 0.84 : 0.62, base),
        mix(color, dark ? 0.38 : 0.26, base),
        base,
      ],
      stops: const <double>[0, 0.38, 0.88],
    );
  }

  /// Vordergrund fuer Elemente am oberen Rand des Player-Verlaufs (Header).
  static Color onPlayerTop(
    Color color,
    LinefmColors c,
    Brightness brightness,
  ) => Contrast.onColor(playerGradient(color, c, brightness).colors.first);

  /// Vordergrund fuer Titel und Knoepfe in der Mitte des Verlaufs.
  static Color onPlayerBody(
    Color color,
    LinefmColors c,
    Brightness brightness,
  ) => Contrast.onColor(playerGradient(color, c, brightness).colors[1]);

  /// Vordergrund fuer Text direkt auf der vollen Senderfarbe (Kuerzel,
  /// Badges). Siehe Tabelle in `tokens.dart`.
  static Color onStation(Color color, {bool large = false}) =>
      Contrast.onColor(color, large: large);

  /// Akzent der Stationskarte (Rahmen aktiv/Hover). Erreicht der Rahmen
  /// gegen den Grund keine 3:1 (WCAG 1.4.11), wird die Senderfarbe in Richtung
  /// Kontrast verschoben: im Dunkelmodus aufgehellt (z. B. +MAIN `#4B4B7D`,
  /// 2,3:1), im Hellmodus abgedunkelt (z. B. FobFM-Cyan auf Weiss).
  static Color border(Color color, LinefmColors c) {
    if (Contrast.ratio(color, c.background) >= Contrast.aaLarge) return color;
    final lighten = c.background.computeLuminance() < 0.5;
    final target = lighten ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    var t = color;
    for (var i = 1; i <= 16; i++) {
      t = mix(target, i * 0.04, color);
      if (Contrast.ratio(t, c.background) >= Contrast.aaLarge) return t;
    }
    return t;
  }
}
