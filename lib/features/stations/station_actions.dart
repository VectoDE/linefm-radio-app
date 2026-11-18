import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Gruppiert die Hoerdauer fuer das Ereignis `stop` (keine exakten Werte, Spec
/// 2.3: `seconds_bucket`).
String secondsBucket(int seconds) {
  if (seconds < 10) return '0-9';
  if (seconds < 60) return '10-59';
  if (seconds < 300) return '60-299';
  if (seconds < 1800) return '300-1799';
  return '1800+';
}

/// Sendet die Ereignisse `play` {station} und `stop` {station,
/// seconds_bucket} der Stationsliste und des Mini-Players ueber den
/// `telemetryProvider`. Ohne Konfiguration oder Einwilligung ist der Hub ein
/// No-Op. Merkt sich den Startzeitpunkt fuer die Hoerdauer.
class PlayTelemetry {
  PlayTelemetry(this._ref);

  final Ref _ref;
  DateTime? _startedAt;

  void played(Station station) {
    _startedAt = _ref.read(clockProvider).now();
    unawaited(
      _ref.read(telemetryProvider).event('play', <String, Object>{
        'station': station.slug,
      }),
    );
  }

  void stopped(Station station) {
    final started = _startedAt;
    _startedAt = null;
    final seconds = started == null
        ? null
        : _ref.read(clockProvider).now().difference(started).inSeconds;
    unawaited(
      _ref.read(telemetryProvider).event('stop', <String, Object>{
        'station': station.slug,
        'seconds_bucket': seconds == null ? 'unknown' : secondsBucket(seconds),
      }),
    );
  }
}

final playTelemetryProvider = Provider<PlayTelemetry>(PlayTelemetry.new);

/// Teilt Text ueber das System-Teilen-Menue. Ueberschreibbar fuer Tests.
final stationShareFnProvider = Provider<Future<void> Function(String text)>(
  (ref) =>
      (text) => SharePlus.instance.share(ShareParams(text: text)),
);

/// Link auf einen Sender (Web-App oder Deep Link, Spec 2.2).
String stationShareUrl(String webBaseUrl, Station station) {
  final base = webBaseUrl.endsWith('/')
      ? webBaseUrl.substring(0, webBaseUrl.length - 1)
      : webBaseUrl;
  return '$base/?station=${station.slug}';
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
    read(playTelemetryProvider).played(station);
    await read(playerControllerProvider).startStation(station);
  }

  /// Play/Stop im Mini-Player.
  Future<void> toggleActiveStation() async {
    final state = read(playerStateProvider).value ?? const PlayerUiState();
    final station = read(activeStationProvider);
    if (state.isPlaying || state.isBusy) {
      read(playTelemetryProvider).stopped(station);
    } else {
      read(playTelemetryProvider).played(station);
    }
    await read(playerControllerProvider).togglePlayback();
  }
}
