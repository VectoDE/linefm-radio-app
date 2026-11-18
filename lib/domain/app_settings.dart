/// Darstellungsmodus (Spec 4.2 Nr. 11).
enum AppThemeMode { system, light, dark }

/// Persistierte Einstellungen (Spec 3.4 settingsProvider).
class AppSettings {
  const AppSettings({
    this.marquee = true,
    this.rememberVolume = true,
    this.autoplay = true,
    this.closeToTray = true,
    this.themeMode = AppThemeMode.system,
  });

  /// Lauftext fuer lange Titel.
  final bool marquee;

  /// Lautstaerke merken.
  final bool rememberVolume;

  /// Autoplay beim Start.
  final bool autoplay;

  /// Beim Schliessen im Tray weiterlaufen (nur Desktop).
  final bool closeToTray;
  final AppThemeMode themeMode;

  AppSettings copyWith({
    bool? marquee,
    bool? rememberVolume,
    bool? autoplay,
    bool? closeToTray,
    AppThemeMode? themeMode,
  }) => AppSettings(
    marquee: marquee ?? this.marquee,
    rememberVolume: rememberVolume ?? this.rememberVolume,
    autoplay: autoplay ?? this.autoplay,
    closeToTray: closeToTray ?? this.closeToTray,
    themeMode: themeMode ?? this.themeMode,
  );
}
