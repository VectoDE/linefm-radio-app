import 'package:material_ui/material_ui.dart';

/// Design-Tokens aus der Web-App (Spec 4.4). Kontrastpaare dokumentiert P04.
@immutable
class LinefmColors extends ThemeExtension<LinefmColors> {
  const LinefmColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.heart,
    required this.switchTrackOff,
    required this.miniPlayerBg,
    required this.navBg,
    required this.tickerText,
  });

  static const LinefmColors dark = LinefmColors(
    background: Color(0xFF0F1221),
    surface: Color(0xFF181B2B),
    surfaceRaised: Color(0xFF202337),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFF898DA1),
    line: Color.fromRGBO(255, 255, 255, 0.09),
    accent: Color(0xFFFFFFFF),
    heart: Color(0xFFFF4B6E),
    switchTrackOff: Color(0xFF414354),
    miniPlayerBg: Color.fromRGBO(15, 18, 33, 0.86),
    navBg: Color.fromRGBO(15, 18, 33, 0.96),
    tickerText: Color(0xFFA4A7B6),
  );

  static const LinefmColors light = LinefmColors(
    background: Color(0xFFF4F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE9EBF3),
    text: Color(0xFF0F1221),
    muted: Color(0xFF565A6E),
    line: Color.fromRGBO(15, 18, 33, 0.10),
    accent: Color(0xFF0F1221),
    heart: Color(0xFFD6264A),
    switchTrackOff: Color(0xFFC9CCD8),
    miniPlayerBg: Color.fromRGBO(255, 255, 255, 0.88),
    navBg: Color.fromRGBO(255, 255, 255, 0.96),
    tickerText: Color(0xFF4A4E62),
  );

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color text;
  final Color muted;
  final Color line;
  final Color accent;
  final Color heart;
  final Color switchTrackOff;
  final Color miniPlayerBg;
  final Color navBg;
  final Color tickerText;

  @override
  LinefmColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? text,
    Color? muted,
    Color? line,
    Color? accent,
    Color? heart,
    Color? switchTrackOff,
    Color? miniPlayerBg,
    Color? navBg,
    Color? tickerText,
  }) => LinefmColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    accent: accent ?? this.accent,
    heart: heart ?? this.heart,
    switchTrackOff: switchTrackOff ?? this.switchTrackOff,
    miniPlayerBg: miniPlayerBg ?? this.miniPlayerBg,
    navBg: navBg ?? this.navBg,
    tickerText: tickerText ?? this.tickerText,
  );

  @override
  LinefmColors lerp(ThemeExtension<LinefmColors>? other, double t) {
    if (other is! LinefmColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return LinefmColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      accent: l(accent, other.accent),
      heart: l(heart, other.heart),
      switchTrackOff: l(switchTrackOff, other.switchTrackOff),
      miniPlayerBg: l(miniPlayerBg, other.miniPlayerBg),
      navBg: l(navBg, other.navBg),
      tickerText: l(tickerText, other.tickerText),
    );
  }
}

extension LinefmColorsContext on BuildContext {
  LinefmColors get linefm => Theme.of(this).extension<LinefmColors>()!;
}
