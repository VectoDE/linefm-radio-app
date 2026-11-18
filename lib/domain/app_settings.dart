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

  /// Tolerant: fehlende oder falsch typisierte Felder erhalten den Standard.
  factory AppSettings.fromJson(Object? json) {
    const defaults = AppSettings();
    if (json is! Map) return defaults;
    bool flag(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    final theme = json['themeMode'];
    return AppSettings(
      marquee: flag('marquee', defaults.marquee),
      rememberVolume: flag('rememberVolume', defaults.rememberVolume),
      autoplay: flag('autoplay', defaults.autoplay),
      closeToTray: flag('closeToTray', defaults.closeToTray),
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => defaults.themeMode,
      ),
    );
  }

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

  Map<String, Object?> toJson() => <String, Object?>{
    'marquee': marquee,
    'rememberVolume': rememberVolume,
    'autoplay': autoplay,
    'closeToTray': closeToTray,
    'themeMode': themeMode.name,
  };

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.marquee == marquee &&
      other.rememberVolume == rememberVolume &&
      other.autoplay == autoplay &&
      other.closeToTray == closeToTray &&
      other.themeMode == themeMode;

  @override
  int get hashCode =>
      Object.hash(marquee, rememberVolume, autoplay, closeToTray, themeMode);
}
