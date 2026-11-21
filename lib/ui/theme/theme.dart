import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Baut das Theme fuer den gewaehlten Modus (Material 3, Spec 4.4).
ThemeData buildLinefmTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark
      ? LinefmColors.dark
      : LinefmColors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: LinefmPalette.seed,
        brightness: brightness,
      ).copyWith(
        primary: tokens.accent,
        onPrimary: tokens.onAccent,
        secondary: tokens.accent,
        onSecondary: tokens.onAccent,
        surface: tokens.surface,
        onSurface: tokens.text,
        onSurfaceVariant: tokens.muted,
        surfaceContainerLowest: tokens.background,
        surfaceContainerLow: tokens.surface,
        surfaceContainer: tokens.surface,
        surfaceContainerHigh: tokens.surfaceRaised,
        surfaceContainerHighest: tokens.surfaceRaised,
        outline: tokens.muted,
        outlineVariant: tokens.line,
        error: tokens.heart,
        onError: tokens.onAccent,
      );

  final focusRing = BorderSide(color: tokens.accent, width: 2);
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(LinefmMetrics.radiusLogo)),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.background,
    canvasColor: tokens.background,
    fontFamily: LinefmFonts.body,
    textTheme: LinefmText.textTheme(tokens.text),
    primaryTextTheme: LinefmText.textTheme(tokens.text),
    dividerColor: tokens.line,
    splashFactory: InkRipple.splashFactory,
    focusColor: tokens.accent.withValues(alpha: 0.14),
    hoverColor: tokens.accent.withValues(alpha: 0.06),
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: <ThemeExtension<dynamic>>[tokens],
    dividerTheme: DividerThemeData(color: tokens.line, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: tokens.text, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: tokens.text,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll<Color>(LinefmPalette.paper),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.selected)
            ? tokens.switchTrackOn
            : tokens.switchTrackOff,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : tokens.muted,
      ),
      trackOutlineWidth: const WidgetStatePropertyAll<double>(1.5),
      thumbIcon: const WidgetStatePropertyAll<Icon?>(null),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: tokens.accent,
      inactiveTrackColor: tokens.accent.withValues(alpha: 0.2),
      thumbColor: tokens.accent,
      overlayColor: tokens.accent.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.navBg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: LinefmMetrics.navHeight,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (states) => LinefmText.nav.copyWith(
          color: states.contains(WidgetState.selected)
              ? tokens.accent
              : tokens.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
        (states) => IconThemeData(
          size: 20,
          color: states.contains(WidgetState.selected)
              ? tokens.accent
              : tokens.muted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: tokens.background,
      indicatorColor: tokens.surfaceRaised,
      selectedIconTheme: IconThemeData(color: tokens.accent),
      unselectedIconTheme: IconThemeData(color: tokens.muted),
      selectedLabelTextStyle: LinefmText.nav.copyWith(color: tokens.accent),
      unselectedLabelTextStyle: LinefmText.nav.copyWith(color: tokens.muted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.surfaceRaised,
      contentTextStyle: LinefmText.listTitle.copyWith(color: tokens.text),
      actionTextColor: tokens.text,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
        side: BorderSide(color: tokens.line),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: tokens.surface,
      showDragHandle: true,
      dragHandleColor: tokens.muted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LinefmMetrics.radiusMiniPlayer),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      // Breite Fenster: Dialoge nicht ueber die Lesebreite ziehen (R4-D2,
      // Material 3: 280 bis 560 dp).
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusPopover),
        side: BorderSide(color: tokens.line),
      ),
      titleTextStyle: LinefmText.sectionHeading.copyWith(
        fontSize: LinefmType.bodyLarge,
        color: tokens.text,
      ),
      contentTextStyle: LinefmText.listTitle.copyWith(color: tokens.text),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
        border: Border.all(color: tokens.line),
      ),
      textStyle: LinefmText.listMeta.copyWith(color: tokens.text),
      waitDuration: const Duration(milliseconds: 500),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tokens.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      textStyle: LinefmText.listTitle.copyWith(color: tokens.text),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusPopover),
        side: BorderSide(color: tokens.line),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: tokens.text,
      textColor: tokens.text,
      subtitleTextStyle: LinefmText.settingCopy.copyWith(color: tokens.muted),
      titleTextStyle: LinefmText.settingTitle.copyWith(color: tokens.text),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tokens.accent,
      circularTrackColor: Colors.transparent,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size.square(LinefmMetrics.minTarget),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(tokens.text),
        overlayColor: WidgetStatePropertyAll<Color>(
          tokens.accent.withValues(alpha: 0.10),
        ),
        side: WidgetStateProperty.resolveWith<BorderSide?>(
          (states) => states.contains(WidgetState.focused) ? focusRing : null,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: tokens.text,
            textStyle: LinefmText.listTitle,
            minimumSize: const Size(LinefmMetrics.minTarget, 44),
            shape: buttonShape,
            side: BorderSide(color: tokens.line),
          ).copyWith(
            side: WidgetStateProperty.resolveWith<BorderSide>((states) {
              if (states.contains(WidgetState.focused)) return focusRing;
              if (states.contains(WidgetState.hovered)) {
                return BorderSide(color: tokens.text.withValues(alpha: 0.35));
              }
              return BorderSide(color: tokens.line);
            }),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.text,
        textStyle: LinefmText.listTitle,
        minimumSize: const Size(LinefmMetrics.minTarget, 44),
        shape: buttonShape,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: tokens.onAccent,
        textStyle: LinefmText.settingTitle,
        minimumSize: const Size(LinefmMetrics.minTarget, 44),
        shape: buttonShape,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(
        tokens.muted.withValues(alpha: 0.5),
      ),
      radius: const Radius.circular(LinefmMetrics.radiusPill),
    ),
  );
}
