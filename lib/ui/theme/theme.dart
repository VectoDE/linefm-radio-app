import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Baut das Theme fuer den gewaehlten Modus. Basis, ausgebaut in P04.
ThemeData buildLinefmTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark
      ? LinefmColors.dark
      : LinefmColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4B4B7D),
    brightness: brightness,
  ).copyWith(surface: tokens.surface, onSurface: tokens.text);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.background,
    fontFamily: LinefmFonts.body,
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
