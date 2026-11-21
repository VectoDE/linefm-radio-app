import 'package:material_ui/material_ui.dart';

/// Design-Tokens aus der Web-App (Spec 4.4).
///
/// Dunkel ist 1:1 aus `styles.css` uebernommen, Hell ist daraus abgeleitet.
///
/// Gemessene WCAG-Kontraste (Verhaeltnis, Formel nach WCAG 2.x; abgesichert
/// durch `test/ui/theme/contrast_test.dart`):
///
/// | Paar (Vordergrund auf Grund)          | Dunkel | Hell  |
/// |---------------------------------------|--------|-------|
/// | `text` auf `background`               | 18,60  | 17,09 |
/// | `text` auf `surface`                  | 17,07  | 18,60 |
/// | `text` auf `surfaceRaised`            | 15,48  | 15,63 |
/// | `muted` auf `background`              |  5,66  |  6,26 |
/// | `muted` auf `surface`                 |  5,19  |  6,81 |
/// | `muted` auf `surfaceRaised`           |  4,71  |  5,72 |
/// | `tickerText` auf `surface`            |  7,14  |  8,21 |
/// | `heart` auf `background`              |  5,74  |  4,55 |
/// | `heart` auf `surface`                 |  5,27  |  4,96 |
/// | `heart` auf `surfaceRaised` (Icon)    |  4,78  |  4,17 |
/// | altes Footer-Grau `#73778a` (entfaellt)|  4,19  |   -   |
///
/// Alle Textpaare erreichen mindestens 4,5:1 (AA); `text` und `tickerText`
/// erreichen 7:1 (AAA), `muted` ist bewusst AA. Die statische Web-Shell
/// (`web/index.html`) nutzt dieselben Werte (`.muted` = `tickerText`). `heart` ist ein Icon und
/// braucht nur 3:1. Der ausgeschaltete Schalter (`switchTrackOff`) erreicht
/// nur 1,9:1 bzw. 1,5:1, deshalb bekommt er in `SettingsSwitch` einen
/// `muted`-Rahmen (5,66:1 bzw. 6,26:1, WCAG 1.4.11).
///
/// Text auf Senderfarben (Weiss / Tinte `#0f1221`, `Contrast.onColor`):
///
/// | Sender        | Farbe     | Weiss  | Tinte  | gewaehlt (Text) |
/// |---------------|-----------|--------|--------|-----------------|
/// | LineFM +MAIN  | `#4B4B7D` |  8,07  |  2,30  | Weiss           |
/// | LineFM +RAP   | `#FF0084` |  3,76  |  4,95  | Tinte (gross: Weiss) |
/// | LineFM +GAMING| `#4BBD71` |  2,38  |  7,81  | Tinte           |
/// | LineFM +LOFI  | `#546E7A` |  5,40  |  3,44  | Weiss           |
/// | Radio3FM      | `#177D29` |  5,25  |  3,55  | Weiss           |
/// | FobFM         | `#04FFF7` |  1,26  | 14,75  | Tinte           |
///
/// Das Web-Footer-Grau `#73778a` (Navigation inaktiv) ist durch `muted`
/// ersetzt (Spec 4.2 Nr. 17).
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
    switchTrackOn: Color.fromRGBO(255, 255, 255, 0.36),
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
    switchTrackOn: Color.fromRGBO(15, 18, 33, 0.60),
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

  /// Schalter an (Web: 36 % Weiss). Hell: dunkler, damit der Knopf sich abhebt.
  final Color switchTrackOn;

  /// Hintergrund des Lautstaerke-Popovers.
  final Color popoverBg;

  /// Schattenfarbe unter dem Cover (Spec 4.4: dunkel 35 % Schwarz).
  final Color coverShadow;

  /// Vordergrund auf `accent`-Flaechen (Badge, Auswahl).
  final Color onAccent;

  /// Schatten unter dem Header (dunkel wie das Web 50 % Schwarz, hell nur
  /// ein Hauch, sonst liegt ein grauer Balken unter dem Header, D1).
  final Color headerShadow;

  /// Schatten unter schwebenden Hinweisen (Speicher-Hinweis).
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

/// Abstandsskala im 4-dp-Raster, Standardschritte 4/8/12/16/24/32 (Spec 4.4).
/// `gutter` (20) ist der Seitenrand der Inhaltsseiten. Kein Wert ausserhalb
/// der Skala: Abstaende nur ueber diese Namen setzen.
abstract final class LinefmSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double gutter = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Schriftgroessenskala (modular, Faktor etwa 1,25): 12/14/16/20/25/32.
/// Untergrenze 12 sp (D7, A11Y-17). `hero` gilt nur fuer die Wortmarke im
/// Ladebildschirm auf breiten Geraeten.
abstract final class LinefmType {
  static const double caption = 12;
  static const double body = 14;
  static const double bodyLarge = 16;
  static const double title = 20;
  static const double heading = 25;
  static const double display = 32;
  static const double hero = 40;
}

/// Feste Farben ausserhalb der Themes (Marken- und Hilfsfarben). Alles, was
/// nicht von Dunkel/Hell abhaengt, steht hier statt als Literal im Code.
abstract final class LinefmPalette {
  /// Tinte, identisch zu `LinefmColors.dark.background`; Splash, Logo-Kachel,
  /// Benachrichtigungsfarbe.
  static const Color ink = Color(0xFF0F1221);

  /// Reines Weiss fuer Schalterknopf, Logo-Kachel und Schrift auf Senderfarbe.
  static const Color paper = Color(0xFFFFFFFF);

  /// Herzfarbe im Dunkelmodus; auch der Ladebildschirm (immer dunkel) nutzt sie.
  static const Color heart = Color(0xFFFF4B6E);

  /// Reines Schwarz nur als Zielwert beim Abdunkeln von Senderfarben.
  static const Color black = Color(0xFF000000);

  /// Unterlage des Mini-Players unter der Senderfarbe.
  static const Color miniPlayerBase = Color(0xFF1B1D2B);

  /// Endfarbe des Verlaufs hinter dem Senderlogo.
  static const Color artGradientEnd = Color(0xFF171929);

  /// Markenfarbe der Senderfarbe +MAIN, zugleich Seed des Material-Schemas.
  static const Color seed = Color(0xFF4B4B7D);

  /// Voll transparentes Weiss/Schwarz fuer Verlaeufe und Masken (Farbton
  /// bleibt erhalten, damit der Verlauf nicht grau ueberblendet).
  static const Color clearWhite = Color(0x00FFFFFF);
  static const Color clearBlack = Color(0x00000000);

  /// Schlagschatten des Schalterknopfs (20 % Schwarz).
  static const Color knobShadow = Color(0x33000000);

  /// Ladebildschirm: Nebenzeile (55 % Weiss) und Lichtkante (5 % Schwarz).
  static const Color loaderCaption = Color(0x8CFFFFFF);
  static const Color loaderStripe = Color(0x0D000000);

  /// Abdunkelung hinter Dialogen und Sheets (54 % Schwarz).
  static const Color scrim = Color(0x8A000000);
}

/// Senderfarben des Katalogs (Quelle: streams.json).
abstract final class LinefmStationColors {
  static const Color main = Color(0xFF4B4B7D);
  static const Color rap = Color(0xFFFF0084);
  static const Color gaming = Color(0xFF4BBD71);
  static const Color lofi = Color(0xFF546E7A);
  static const Color radio3fm = Color(0xFF177D29);
  static const Color fobfm = Color(0xFF04FFF7);
}

/// Masse, Radien und Zeiten der Web-App (Spec 4.4) und der nativen
/// Verfeinerung.
abstract final class LinefmMetrics {
  static const double radiusCard = 6;
  static const double radiusLogo = 4;
  static const double radiusCover = 24;
  static const double radiusCoverCompact = 16;
  static const double radiusMiniPlayer = 18;
  static const double radiusPopover = 12;
  static const double radiusPill = 999;

  /// Kleinste Tippflaeche (Material 48 dp, WCAG 2.5.8 verlangt mindestens 24).
  static const double minTarget = 48;

  /// Hoehe der Bottom-Navigation.
  static const double navHeight = 69;

  /// Hoehe des Headers.
  static const double headerHeight = 80;

  /// Feste Breite der seitlichen Navigation (NavigationRail) in allen
  /// Sprachen. Vorher richtete sich die Leiste nach der laengsten
  /// Beschriftung und sprang beim Sprachwechsel (Issue #101).
  static const double railWidth = 104;

  /// Standarddauern (Web: .18 bis .35 s).
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  /// Lauftext: Web 18 s je Durchlauf, Abstand zwischen den Kopien 36.
  static const Duration marqueeLoop = Duration(seconds: 18);
  static const double marqueeGap = 36;

  /// Cover-Schatten (dunkel `0 24 55`, hell `0 16 40`).
  static List<BoxShadow> coverShadows(LinefmColors c, {bool dark = true}) =>
      <BoxShadow>[
        BoxShadow(
          color: c.coverShadow,
          blurRadius: dark ? 55 : 40,
          offset: Offset(0, dark ? 24 : 16),
        ),
      ];
}
