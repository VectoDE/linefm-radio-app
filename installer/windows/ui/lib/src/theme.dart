import 'package:material_ui/material_ui.dart';

/// Farben aus den Design-Tokens der App (lib/ui/theme/tokens.dart im
/// Hauptprojekt), damit Setup und App gleich aussehen.
@immutable
class SetupColors extends ThemeExtension<SetupColors> {
  const SetupColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.danger,
  });

  static const SetupColors dark = SetupColors(
    background: Color(0xFF0F1221),
    surface: Color(0xFF181B2B),
    surfaceRaised: Color(0xFF202337),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFA4A7B6),
    line: Color.fromRGBO(255, 255, 255, 0.14),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF0F1221),
    danger: Color(0xFFFF4B6E),
  );

  static const SetupColors light = SetupColors(
    background: Color(0xFFF4F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE9EBF3),
    text: Color(0xFF0F1221),
    muted: Color(0xFF4A4E62),
    line: Color.fromRGBO(15, 18, 33, 0.16),
    accent: Color(0xFF0F1221),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFD6264A),
  );

  /// Markenfläche links (Senderfarbe LineFM +MAIN `#4B4B7D` in die Tinte der
  /// App verlaufend). Weisse Schrift darauf: mindestens 8,07:1.
  static const Color brandTop = Color(0xFF4B4B7D);
  static const Color brandBottom = Color(0xFF0F1221);

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color text;
  final Color muted;
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color danger;

  /// Kräftigere Linien für den Windows-Kontrastmodus.
  SetupColors highContrast() => copyWith(line: text, muted: text);

  @override
  SetupColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? text,
    Color? muted,
    Color? line,
    Color? accent,
    Color? onAccent,
    Color? danger,
  }) => SetupColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    danger: danger ?? this.danger,
  );

  @override
  SetupColors lerp(SetupColors? other, double t) {
    if (other == null) return this;
    return SetupColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

abstract final class SetupFonts {
  static const String body = 'Poppins';
  static const String brand = 'Syncopate';
}

ThemeData buildTheme(Brightness brightness, {bool highContrast = false}) {
  var c = brightness == Brightness.dark ? SetupColors.dark : SetupColors.light;
  if (highContrast) c = c.highContrast();
  final scheme =
      ColorScheme.fromSeed(
        seedColor: SetupColors.brandTop,
        brightness: brightness,
      ).copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        onSurface: c.text,
        onSurfaceVariant: c.muted,
        outline: c.line,
        error: c.danger,
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    fontFamily: SetupFonts.body,
    extensions: [c],
  );
  final focusSide = BorderSide(color: c.text, width: 2);
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surfaceRaised,
        disabledForegroundColor: c.muted,
        minimumSize: const Size(120, 44),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        textStyle: const TextStyle(
          fontFamily: SetupFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(110, 44),
        side: BorderSide(color: c.line, width: highContrast ? 2 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(
          fontFamily: SetupFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(96, 44),
        textStyle: const TextStyle(
          fontFamily: SetupFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: c.muted, width: 2),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.accent
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(c.onAccent),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.muted,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.line, width: highContrast ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: focusSide,
      ),
      labelStyle: TextStyle(color: c.muted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surfaceRaised,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
    focusColor: c.text.withValues(alpha: 0.12),
  );
}

extension SetupThemeX on BuildContext {
  SetupColors get colors =>
      Theme.of(this).extension<SetupColors>() ?? SetupColors.dark;
}
