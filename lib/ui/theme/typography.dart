import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Schriftfamilien (lokal gebuendelt, Spec 4.5).
abstract final class LinefmFonts {
  /// Fliesstext, Gewichte 400 und 600.
  static const String body = 'Poppins';

  /// Marke, Stationsnamen, Navigation (Gewicht 700).
  static const String brand = 'Syncopate';
}

/// Textstile der Web-App (Spec 4.5). Farben kommen aus dem Theme, nicht aus
/// den Stilen; Aufrufer setzen sie ueber `copyWith(color: ...)`.
abstract final class LinefmText {
  static const TextStyle _brand = TextStyle(
    fontFamily: LinefmFonts.brand,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const TextStyle _body = TextStyle(
    fontFamily: LinefmFonts.body,
    fontWeight: FontWeight.w400,
  );

  /// Markenzug "LINEFM" im Header (2rem).
  static const TextStyle brandHeader = TextStyle(
    fontFamily: LinefmFonts.brand,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.2,
  );

  /// Ladebildschirm (2rem, ab 480 px 2,3rem).
  static TextStyle loaderBrand({bool compact = false}) =>
      brandHeader.copyWith(fontSize: compact ? 36.8 : 32);

  /// Abschnittsueberschrift (h1 der Web-App, 25 px, Grossbuchstaben).
  static final TextStyle sectionHeading = _brand.copyWith(
    fontSize: 25,
    height: 1.4,
  );

  // Untergrenze 12 sp fuer alle Texte (D7, A11Y-17); die Web-App nutzte
  // 9 bis 11 px.

  /// Stationsname in Liste und Grid (12).
  static TextStyle stationName({bool grid = false}) =>
      _brand.copyWith(fontSize: 12, height: 1.3);

  /// Ticker "Artist - Titel" (12).
  static final TextStyle ticker = _body.copyWith(fontSize: 12, height: 1.4);

  /// Songtitel im Player, `clamp(21, 7vw, 34)` aus der Breite.
  static TextStyle playerTitle(double viewportWidth) => _brand.copyWith(
    fontSize: math.min(34, math.max(21, viewportWidth * 0.07)),
    height: 1.25,
  );

  /// Kuenstler im Player (16).
  static final TextStyle playerArtist = _body.copyWith(
    fontSize: 16,
    height: 1.4,
  );

  /// Poppins SemiBold fuer Titel in Listen (echte 600, keine synthetische
  /// Fettung wie in der Web-App).
  static final TextStyle listTitleStrong = _body.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.4,
  );

  /// Listenzeile (14).
  static final TextStyle listTitle = _body.copyWith(fontSize: 14, height: 1.4);

  /// Listen-Nebenzeile (12).
  static final TextStyle listMeta = _body.copyWith(fontSize: 12, height: 1.4);

  /// Zeitangabe im Verlauf (9 der Web-App, auf 12 angehoben).
  static final TextStyle time = _body.copyWith(fontSize: 12, height: 1.2);

  /// Einstellungs-Titel (14, SemiBold).
  static final TextStyle settingTitle = _body.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.4,
  );

  /// Einstellungs-Beschreibung (12, Zeilenhoehe 1,5).
  static final TextStyle settingCopy = _body.copyWith(
    fontSize: 12,
    height: 1.5,
  );

  /// Navigation (Web-App 10 px, Spec 9; auf 12 angehoben, D7) mit
  /// 0,06 em Laufweite, damit "VERLAUF"/"STATIONS" auch bei 320 dp passen.
  static final TextStyle nav = _brand.copyWith(
    fontSize: 12,
    letterSpacing: 12 * 0.06,
  );

  /// Mini-Player Titel (18, Handy 14).
  static TextStyle miniTitle({bool compact = false}) => _body.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: compact ? 14 : 18,
    height: 1.3,
  );

  /// Mini-Player Kuenstler (14, Handy 11 -> 12 fuer Lesbarkeit).
  static TextStyle miniArtist({bool compact = false}) =>
      _body.copyWith(fontSize: compact ? 12 : 14, height: 1.3);

  /// Hinweistexte (Speicher-Hinweis, 12).
  static final TextStyle notice = _body.copyWith(fontSize: 12, height: 1.5);

  /// Vollstaendige Material-Textskala auf Poppins/Syncopate.
  static TextTheme textTheme(Color text) {
    TextStyle b(
      double size, {
      FontWeight w = FontWeight.w400,
      double h = 1.4,
    }) => TextStyle(
      fontFamily: LinefmFonts.body,
      fontSize: size,
      fontWeight: w,
      height: h,
      color: text,
    );
    TextStyle d(double size) => TextStyle(
      fontFamily: LinefmFonts.brand,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: text,
    );
    return TextTheme(
      displayLarge: d(34),
      displayMedium: d(28),
      displaySmall: d(25),
      headlineLarge: d(25),
      headlineMedium: d(20),
      headlineSmall: d(16),
      titleLarge: b(18, w: FontWeight.w600),
      titleMedium: b(16, w: FontWeight.w600),
      titleSmall: b(14, w: FontWeight.w600),
      bodyLarge: b(16),
      bodyMedium: b(14),
      bodySmall: b(12, h: 1.5),
      labelLarge: b(14, w: FontWeight.w600),
      labelMedium: b(12, w: FontWeight.w600),
      labelSmall: b(11),
    );
  }
}
