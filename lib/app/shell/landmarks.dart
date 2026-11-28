part of '../shell.dart';

/// One area of the shell with a fixed tab and screen reader position.
///
/// Each area is its own [FocusTraversalGroup]: Tab runs through the whole
/// area first, then to the next one. Without this order Flutter sorts by
/// position on screen; in the compact layout cards sit behind the mini
/// player and navigation, and the focus used to jump back and forth
/// between them.
///
/// [role] and [label] turn the area into a landmark (main, navigation,
/// complementary, region) so screen readers can jump straight to it and
/// all content lies inside a landmark (axe `region`).
Widget _ordered(
  int order,
  Widget child, {
  SemanticsRole role = SemanticsRole.none,
  String? label,
}) => FocusTraversalOrder(
  order: NumericFocusOrder(order.toDouble()),
  child: FocusTraversalGroup(
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      sortKey: OrdinalSortKey(order.toDouble()),
      role: role,
      label: label,
      child: child,
    ),
  ),
);

/// Content of a shell area (without the player).
Widget _content(AppScreen screen, {required EdgeInsets stationsPadding}) =>
    switch (screen) {
      AppScreen.history => const HistoryScreen(),
      AppScreen.favorites => const FavoritesScreen(),
      AppScreen.settings => const SettingsScreen(),
      _ => StationsScreen(padding: stationsPadding),
    };

// ------------------------------------------------------------ Compact
