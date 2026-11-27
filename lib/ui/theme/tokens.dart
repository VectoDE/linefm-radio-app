import 'package:material_ui/material_ui.dart';

/// Design tokens from the web app (spec 4.4).
///
/// Dark is taken 1:1 from `styles.css`, light is derived from it.
///
/// Measured WCAG contrasts (ratio, formula per WCAG 2.x; backed by
/// `test/ui/theme/contrast_test.dart`):
///
/// | Pair (foreground on background)       | Dark   | Light |
/// |---------------------------------------|--------|-------|
/// | `text` on `background`                | 18.60  | 17.09 |
/// | `text` on `surface`                   | 17.07  | 18.60 |
/// | `text` on `surfaceRaised`             | 15.48  | 15.63 |
/// | `muted` on `background`               |  5.66  |  6.26 |
/// | `muted` on `surface`                  |  5.19  |  6.81 |
/// | `muted` on `surfaceRaised`            |  4.71  |  5.72 |
/// | `tickerText` on `surface`             |  7.14  |  8.21 |
/// | `heart` on `background`               |  5.74  |  4.55 |
/// | `heart` on `surface`                  |  5.27  |  4.96 |
/// | `heart` on `surfaceRaised` (icon)     |  4.78  |  4.17 |
/// | old footer grey `#73778a` (removed)   |  4.19  |   -   |
///
/// All text pairs reach at least 4.5:1 (AA); `text` and `tickerText` reach
/// 7:1 (AAA), `muted` is deliberately AA. The static web shell
/// (`web/index.html`) uses the same values (`.muted` = `tickerText`). `heart`
/// is an icon and only needs 3:1. The switched-off switch (`switchTrackOff`)
/// only reaches 1.9:1 and 1.5:1 respectively, so in `SettingsSwitch` it gets
/// a `muted` border (5.66:1 and 6.26:1, WCAG 1.4.11).
///
/// Text on station colours (white / ink `#0f1221`, `Contrast.onColor`):
///
/// | Station       | Colour    | White  | Ink    | chosen (text)   |
/// |---------------|-----------|--------|--------|-----------------|
/// | LineFM +MAIN  | `#4B4B7D` |  8.07  |  2.30  | White           |
/// | LineFM +RAP   | `#FF0084` |  3.76  |  4.95  | Ink (large: White) |
/// | LineFM +GAMING| `#4BBD71` |  2.38  |  7.81  | Ink             |
/// | LineFM +LOFI  | `#546E7A` |  5.40  |  3.44  | White           |
/// | Radio3FM      | `#177D29` |  5.25  |  3.55  | White           |
/// | FobFM         | `#04FFF7` |  1.26  | 14.75  | Ink             |
///
/// The web footer grey `#73778a` (inactive navigation) is replaced by `muted`
/// (spec 4.2 no. 17).
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
    required this.switchTrackOn,
    required this.popoverBg,
    required this.coverShadow,
    required this.onAccent,
    required this.headerShadow,
    required this.noticeShadow,
  });

  static const LinefmColors dark = LinefmColors(
    background: Color(0xFF0F1221),
    surface: Color(0xFF181B2B),
    surfaceRaised: Color(0xFF202337),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFF898DA1),
    line: Color.fromRGBO(255, 255, 255, 0.09),
    accent: Color(0xFFFFFFFF),
    heart: LinefmPalette.heart,
    switchTrackOff: Color(0xFF414354),
    miniPlayerBg: Color.fromRGBO(15, 18, 33, 0.86),
    navBg: Color.fromRGBO(15, 18, 33, 0.96),
    tickerText: Color(0xFFA4A7B6),
    switchTrackOn: Color(0xFFFFFFFF),
    popoverBg: Color.fromRGBO(15, 18, 33, 0.95),
    coverShadow: Color.fromRGBO(0, 0, 0, 0.35),
    onAccent: Color(0xFF0F1221),
    headerShadow: Color(0x80000000),
    noticeShadow: Color(0x47000000),
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
    switchTrackOn: Color(0xFF0F1221),
    popoverBg: Color.fromRGBO(255, 255, 255, 0.97),
    coverShadow: Color.fromRGBO(15, 18, 33, 0.18),
    onAccent: Color(0xFFFFFFFF),
    headerShadow: Color(0x1A0F1221),
    noticeShadow: Color(0x1F0F1221),
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

  /// Switch on: solid accent (white in dark, ink in light) so "on" reads
  /// clearly; the thumb uses `onAccent`. Contrast >= 3:1 against the
  /// surface and the thumb (WCAG 1.4.11), checked in contrast_test.dart.
  final Color switchTrackOn;

  /// Background of the volume popover.
  final Color popoverBg;

  /// Shadow colour under the cover (spec 4.4: dark 35 % black).
  final Color coverShadow;

  /// Foreground on `accent` surfaces (badge, selection).
  final Color onAccent;

  /// Shadow under the header (dark like the web 50 % black, light only a
  /// hint, otherwise a grey bar sits under the header).
  final Color headerShadow;

  /// Shadow under floating notices (storage notice).
  final Color noticeShadow;

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
    Color? switchTrackOn,
    Color? popoverBg,
    Color? coverShadow,
    Color? onAccent,
    Color? headerShadow,
    Color? noticeShadow,
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
    switchTrackOn: switchTrackOn ?? this.switchTrackOn,
    popoverBg: popoverBg ?? this.popoverBg,
    coverShadow: coverShadow ?? this.coverShadow,
    onAccent: onAccent ?? this.onAccent,
    headerShadow: headerShadow ?? this.headerShadow,
    noticeShadow: noticeShadow ?? this.noticeShadow,
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
      switchTrackOn: l(switchTrackOn, other.switchTrackOn),
      popoverBg: l(popoverBg, other.popoverBg),
      coverShadow: l(coverShadow, other.coverShadow),
      onAccent: l(onAccent, other.onAccent),
      headerShadow: l(headerShadow, other.headerShadow),
      noticeShadow: l(noticeShadow, other.noticeShadow),
    );
  }
}

extension LinefmColorsContext on BuildContext {
  LinefmColors get linefm => Theme.of(this).extension<LinefmColors>()!;
}

/// Spacing scale on a 4 dp grid, standard steps 4/8/12/16/24/32 (spec 4.4).
/// `gutter` (20) is the side margin of content pages. No value outside the
/// scale: set spacing only via these names.
abstract final class LinefmSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double gutter = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Font size scale (modular, factor about 1.25): 12/14/16/20/25/32.
/// Lower bound 12 sp. `hero` applies only to the wordmark on the loading
/// screen on wide devices.
abstract final class LinefmType {
  static const double caption = 12;
  static const double body = 14;
  static const double bodyLarge = 16;
  static const double title = 20;
  static const double heading = 25;
  static const double display = 32;
  static const double hero = 40;
}

/// Fixed colours outside the themes (brand and helper colours). Everything
/// that does not depend on dark/light lives here instead of as a literal in
/// code.
abstract final class LinefmPalette {
  /// Ink, identical to `LinefmColors.dark.background`; splash, logo tile,
  /// notification colour.
  static const Color ink = Color(0xFF0F1221);

  /// Pure white for the switch thumb, logo tile and text on station colour.
  static const Color paper = Color(0xFFFFFFFF);

  /// Heart colour in dark mode; the loading screen (always dark) uses it too.
  static const Color heart = Color(0xFFFF4B6E);

  /// Pure black only as the target value when darkening station colours.
  static const Color black = Color(0xFF000000);

  /// End colour of the gradient behind the station logo.
  static const Color artGradientEnd = Color(0xFF171929);

  /// Brand colour of the +MAIN station colour, also the seed of the Material
  /// scheme.
  static const Color seed = Color(0xFF4B4B7D);

  /// Fully transparent white/black for gradients and masks (hue is kept so
  /// the gradient does not fade through grey).
  static const Color clearWhite = Color(0x00FFFFFF);
  static const Color clearBlack = Color(0x00000000);

  /// Drop shadow of the switch thumb (20 % black).
  static const Color knobShadow = Color(0x33000000);

  /// Loading screen: subline (55 % white) and highlight edge (5 % black).
  static const Color loaderCaption = Color(0x8CFFFFFF);
  static const Color loaderStripe = Color(0x0D000000);

  /// Dimming behind dialogs and sheets (54 % black).
  static const Color scrim = Color(0x8A000000);
}

/// Dimensions, radii and durations of the web app (spec 4.4) and of the
/// native refinement.
abstract final class LinefmMetrics {
  static const double radiusCard = 6;
  static const double radiusLogo = 4;
  static const double radiusCover = 24;
  static const double radiusCoverCompact = 16;
  static const double radiusMiniPlayer = 18;
  static const double radiusPopover = 12;
  static const double radiusPill = 999;

  /// Smallest tap target (Material 48 dp, WCAG 2.5.8 requires at least 24).
  static const double minTarget = 48;

  /// Height of the bottom navigation (8 dp grid), the same in all languages.
  static const double navHeight = 72;

  /// Icon size in bottom navigation and side rail.
  static const double navIcon = 20;

  /// Active indicator (pill behind the icon) of the bottom navigation, same
  /// shape as in the side rail.
  static const double navIndicatorWidth = 56;
  static const double navIndicatorHeight = 32;

  /// Height of the header.
  static const double headerHeight = 80;

  /// Top offset of the side rail: the centre of the first icon sits on the
  /// centre line of the header ([headerHeight] / 2).
  static const double railTopInset = 16;

  /// Fixed width of the side navigation (NavigationRail) in all languages.
  /// Previously the rail sized itself to the longest label and jumped when
  /// the language changed.
  static const double railWidth = 104;

  /// Default durations (web: .18 to .35 s).
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  /// Ticker: web 18 s per pass, gap between the copies 36.
  static const Duration marqueeLoop = Duration(seconds: 18);
  static const double marqueeGap = 36;

  /// Cover shadow (dark `0 24 55`, light `0 16 40`).
  static List<BoxShadow> coverShadows(LinefmColors c, {bool dark = true}) =>
      <BoxShadow>[
        BoxShadow(
          color: c.coverShadow,
          blurRadius: dark ? 55 : 40,
          offset: Offset(0, dark ? 24 : 16),
        ),
      ];
}
