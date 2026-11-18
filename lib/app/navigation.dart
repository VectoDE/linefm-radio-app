import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppScreen {
  stations,
  player,
  history,
  favorites,
  settings,
  alarm,
  about,
  legal,
}

class NavigationNotifier extends Notifier<AppScreen> {
  @override
  AppScreen build() => AppScreen.stations;

  void go(AppScreen screen) => state = screen;
}
