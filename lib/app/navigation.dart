import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bereiche der App. Stationen, Player, Verlauf, Favoriten und Einstellungen
/// zeigt die Shell selbst; Wecker, Ueber und Recht sind eigene Routen
/// (`openAlarm`, `openAbout`, `openLegal`), die die Shell oeffnet, wenn
/// jemand dorthin navigiert.
enum AppScreen {
  stations,
  player,
  history,
  favorites,
  settings,
  alarm,
  about,
  legal;

  /// Wird in der Shell als Inhalt gezeigt (statt als eigene Route).
  bool get isShellScreen => index <= AppScreen.settings.index;

  /// Name fuer `screen_<name>`. Verlauf und Favoriten melden sich selbst.
  String get telemetryName => name;
}

class NavigationNotifier extends Notifier<AppScreen> {
  @override
  AppScreen build() => AppScreen.stations;

  void go(AppScreen screen) => state = screen;

  /// Zurueck (Android-Zurueck, Esc): von jedem Bereich zu den Stationen.
  /// `false`, wenn schon die Stationen offen sind (App darf schliessen).
  bool back() {
    if (state == AppScreen.stations) return false;
    state = AppScreen.stations;
    return true;
  }
}
