/// Darstellungsmodus (Spec 4.2 Nr. 11).
enum AppThemeMode { system, light, dark }

/// App-Sprache: Systemsprache (Rueckfall Englisch) oder fest Deutsch bzw.
/// Englisch. Die App hat genau diese zwei Sprachen (dokumentierte Ausnahme
/// vom 31-Locales-Hausstandard, Entscheidung des Inhabers).
enum AppLanguage {
  system(null),
  de('de'),
  en('en');

  const AppLanguage(this.code);

  /// Sprachcode (`de`, `en`); `null` bei [system].
  final String? code;
}

/// Size limit of the on-device cover cache (native platforms).
enum CoverCacheLimit {
  mb20(20),
  mb40(40),
  mb100(100);

  const CoverCacheLimit(this.megabytes);

  final int megabytes;

  int get bytes => megabytes * 1024 * 1024;
}

/// Persistierte Einstellungen (Spec 3.4 settingsProvider).
class AppSettings {
  const AppSettings({
    this.marquee = true,
    this.rememberVolume = true,
    this.autoplay = true,
    this.closeToTray = true,
    this.themeMode = AppThemeMode.system,
    this.loadArtwork = true,
    this.keyboardShortcuts = true,
    this.language = AppLanguage.system,
    this.coverCacheLimit = CoverCacheLimit.mb40,
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
    final language = json['language'];
    final cacheLimit = json['coverCacheLimit'];
    return AppSettings(
      marquee: flag('marquee', defaults.marquee),
      rememberVolume: flag('rememberVolume', defaults.rememberVolume),
      autoplay: flag('autoplay', defaults.autoplay),
      closeToTray: flag('closeToTray', defaults.closeToTray),
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => defaults.themeMode,
      ),
      loadArtwork: flag('loadArtwork', defaults.loadArtwork),
      keyboardShortcuts: flag('keyboardShortcuts', defaults.keyboardShortcuts),
      language: AppLanguage.values.firstWhere(
        (l) => l.name == language,
        orElse: () => defaults.language,
      ),
      coverCacheLimit: CoverCacheLimit.values.firstWhere(
        (l) => l.name == cacheLimit,
        orElse: () => defaults.coverCacheLimit,
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

  /// Cover ueber die iTunes-Suche von Apple laden (L5). Aus: keine Anfrage
  /// an Apple, der Player zeigt das Senderlogo.
  final bool loadArtwork;

  /// Ein-Zeichen-Tastenkuerzel (F, S, 1-6) aktiv (WCAG 2.1.4, A11Y-08).
  final bool keyboardShortcuts;

  /// Gewaehlte App-Sprache; [AppLanguage.system] folgt dem Geraet.
  final AppLanguage language;

  /// Size limit of the on-device cover cache; lowering it trims at once.
  final CoverCacheLimit coverCacheLimit;

  AppSettings copyWith({
    bool? marquee,
    bool? rememberVolume,
    bool? autoplay,
    bool? closeToTray,
    AppThemeMode? themeMode,
    bool? loadArtwork,
    bool? keyboardShortcuts,
    AppLanguage? language,
    CoverCacheLimit? coverCacheLimit,
  }) => AppSettings(
    marquee: marquee ?? this.marquee,
    rememberVolume: rememberVolume ?? this.rememberVolume,
    autoplay: autoplay ?? this.autoplay,
    closeToTray: closeToTray ?? this.closeToTray,
    themeMode: themeMode ?? this.themeMode,
    loadArtwork: loadArtwork ?? this.loadArtwork,
    keyboardShortcuts: keyboardShortcuts ?? this.keyboardShortcuts,
    language: language ?? this.language,
    coverCacheLimit: coverCacheLimit ?? this.coverCacheLimit,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'marquee': marquee,
    'rememberVolume': rememberVolume,
    'autoplay': autoplay,
    'closeToTray': closeToTray,
    'themeMode': themeMode.name,
    'loadArtwork': loadArtwork,
    'keyboardShortcuts': keyboardShortcuts,
    'language': language.name,
    'coverCacheLimit': coverCacheLimit.name,
  };

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.marquee == marquee &&
      other.rememberVolume == rememberVolume &&
      other.autoplay == autoplay &&
      other.closeToTray == closeToTray &&
      other.themeMode == themeMode &&
      other.loadArtwork == loadArtwork &&
      other.keyboardShortcuts == keyboardShortcuts &&
      other.language == language &&
      other.coverCacheLimit == coverCacheLimit;

  @override
  int get hashCode => Object.hash(
    marquee,
    rememberVolume,
    autoplay,
    closeToTray,
    themeMode,
    loadArtwork,
    keyboardShortcuts,
    language,
    coverCacheLimit,
  );
}
