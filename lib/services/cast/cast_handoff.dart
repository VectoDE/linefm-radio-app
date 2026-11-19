import 'dart:async';

import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';

/// Übergabe zwischen lokaler Wiedergabe und Cast, unabhängig von Riverpod
/// und Plugin (Fake-Sitzung im Test).
///
/// - Sitzung steht: lokale Wiedergabe stoppen (Live-Radio: Stop statt Pause)
///   und den gewählten Sender samt aktuellem Titel an das Gerät übergeben.
/// - Solange gecastet wird: startet der Nutzer lokal einen Sender (Play,
///   Senderwechsel, Zufall), wandert der Start zum Cast-Gerät.
/// - Titelwechsel gehen als Metadaten an das Gerät.
/// - Lautstärkeänderungen des Players gehen an das Cast-Gerät.
/// - Sitzung endet: lokal bleibt es still; der Nutzer startet selbst neu.
class CastHandoff {
  CastHandoff({
    required this.service,
    required this.stopLocal,
    required this.activeStation,
    required this.currentTrack,
    double? initialVolume,
  }) : _volume = initialVolume;

  final CastService service;
  final Future<void> Function() stopLocal;
  final Station Function() activeStation;
  final Track? Function() currentTrack;

  bool _casting = false;
  bool _stopping = false;
  double? _volume;

  /// Zustand der Cast-Sitzung ([CastService.states]).
  void onCastState(CastState next) {
    final casting = next.isCasting;
    if (casting == _casting) return;
    _casting = casting;
    if (casting) {
      _handOver(activeStation());
    }
  }

  /// Zustand der lokalen Wiedergabe ([PlaybackService.stateStream]).
  void onLocalState(PlayerUiState next) {
    final previousVolume = _volume;
    _volume = next.volume;
    if (!_casting) return;
    if (previousVolume != null && previousVolume != next.volume) {
      unawaited(service.setVolume(next.volume));
    }
    if (_stopping) return;
    if (next.isPlaying || next.isBusy) {
      _handOver(next.station ?? activeStation());
    }
  }

  /// Neuer Titel (oder `null`, wenn keiner bekannt ist).
  void onTrack(Track? track) {
    if (!_casting) return;
    unawaited(service.updateTrack(activeStation(), track));
  }

  void _handOver(Station station) {
    _stopping = true;
    unawaited(() async {
      try {
        await stopLocal();
      } on Object catch (e) {
        logError('Lokale Wiedergabe nicht gestoppt', e);
      } finally {
        _stopping = false;
      }
    }());
    unawaited(service.cast(station, currentTrack()));
  }
}

/// Stream-URL für das Cast-Gerät: `stream_url` der laut.fm-API, Rückfall auf
/// die feste URL des Senders (gleiche Regeln wie lokal: nur https).
Future<Uri> resolveCastStreamUrl(LautApi api, Station station) async {
  try {
    final url = await api
        .streamUrl(station.slug)
        .timeout(const Duration(seconds: 4));
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      return uri;
    }
  } on Object catch (e) {
    logError('stream_url für Cast nicht ermittelt, Rückfall', e);
  }
  return Uri.parse(station.fallbackStreamUrl);
}
