import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/services/share/share_links.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// Teilt Text ueber den `ShareService` (Teilen-Menue, sonst Zwischenablage).
/// Ueberschreibbar fuer Tests.
final stationShareFnProvider = Provider<Future<void> Function(String text)>(
  (ref) =>
      (text) => ref.read(shareServiceProvider).shareText(text),
);

/// Link auf einen Sender (Web-App oder Deep Link, Spec 2.2).
String stationShareUrl(String webBaseUrl, Station station) {
  return ShareLinks.stationUrl(webBaseUrl, station);
}

/// Aktionen der Stationsliste und des Mini-Players.
extension StationActions on WidgetRef {
  /// Karte angetippt: Sender waehlen, Player oeffnen, abspielen. Spielt der
  /// Sender schon (oder verbindet er gerade), wird nur der Player geoeffnet.
  /// Im breiten Layout ist der Player immer sichtbar, dort wird nicht
  /// navigiert.
  Future<void> openStation(BuildContext context, Station station) async {
    final state = read(playerStateProvider).value ?? const PlayerUiState();
    final alreadyPlaying =
        read(activeStationProvider) == station &&
        (state.isPlaying || state.isBusy);
    if (WindowClass.of(context) != WindowClass.expanded) {
      read(navigationProvider.notifier).go(AppScreen.player);
    }
    if (alreadyPlaying) return;
    // Telemetrie play/stop meldet der PlayerController (eine Stelle).
    await read(playerControllerProvider).startStation(station);
  }

  /// Play/Stop im Mini-Player.
  Future<void> toggleActiveStation() =>
      read(playerControllerProvider).togglePlayback();
}
