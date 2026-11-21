import 'dart:ui' show Color;

import 'package:linefm_radio/ui/theme/tokens.dart';

/// WCAG-2.x-Kontrastberechnung (relative Luminanz, Verhaeltnis 1:1 bis 21:1).
abstract final class Contrast {
  /// Mindestkontrast fuer normalen Text (AA).
  static const double aaText = 4.5;

  /// Mindestkontrast fuer grossen Text und Bedienelemente/Icons (AA).
  static const double aaLarge = 3.0;

  /// Erhoehter Kontrast fuer normalen Text (AAA).
  static const double aaaText = 7.0;

  /// Dunkler Vordergrund auf hellen Senderfarben (identisch zu `background`).
  static const Color ink = LinefmPalette.ink;

  /// Heller Vordergrund auf dunklen Senderfarben.
  static const Color paper = LinefmPalette.paper;

  /// Kontrastverhaeltnis zweier deckender Farben.
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Kontrast von [fg] auf [bg]; halbtransparentes [fg] wird zuerst auf [bg]
  /// gemischt.
  static double ratioOver(Color fg, Color bg) =>
      ratio(Color.alphaBlend(fg, bg), bg);

  /// Vordergrund auf [background]: [paper], solange er den Mindestkontrast
  /// erreicht (AA: 4,5:1, bei [large] 3:1), sonst der kontrastreichere von
  /// [paper] und [ink]. So bleibt der Web-Look (weisse Schrift) erhalten, wo
  /// er lesbar ist; FobFM (1,26:1) und +GAMING (2,38:1) bekommen dunklen Text.
  static Color onColor(Color background, {bool large = false}) {
    final paperRatio = ratio(paper, background);
    if (paperRatio >= (large ? aaLarge : aaText)) return paper;
    return paperRatio >= ratio(ink, background) ? paper : ink;
  }
}
